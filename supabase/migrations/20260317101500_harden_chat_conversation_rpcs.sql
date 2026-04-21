-- ============================================
-- HARDEN CHAT CONVERSATION RPCS
-- ============================================
-- Goals:
-- 1) Keep conversation creation in RPC (single trusted server-side path).
-- 2) Avoid race-condition duplicate direct conversations.
-- 3) Ensure RPCs are versioned in migrations with secure function settings.
-- 4) Tighten function execute grants and conversation insert convention.

BEGIN;

-- Ensure created_by is always populated and enforced.
UPDATE public.conversations c
SET created_by = picked.user_id
FROM LATERAL (
  SELECT cp.user_id
  FROM public.conversation_participants cp
  WHERE cp.conversation_id = c.id
  ORDER BY cp.joined_at NULLS LAST, cp.id
  LIMIT 1
) picked
WHERE c.created_by IS NULL;

ALTER TABLE public.conversations
  ALTER COLUMN created_by SET DEFAULT auth.uid();

ALTER TABLE public.conversations
  ALTER COLUMN created_by SET NOT NULL;

DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
CREATE POLICY "Users can create conversations"
  ON public.conversations
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = created_by);

CREATE OR REPLACE FUNCTION public.get_conversation_with_friend(p_friend_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_conversation_id uuid;
BEGIN
  IF v_user_id IS NULL OR p_friend_id IS NULL OR p_friend_id = v_user_id THEN
    RETURN NULL;
  END IF;

  SELECT cp.conversation_id
  INTO v_conversation_id
  FROM public.conversation_participants cp
  GROUP BY cp.conversation_id
  HAVING COUNT(*) = 2
     AND COUNT(DISTINCT cp.user_id) = 2
     AND BOOL_OR(cp.user_id = v_user_id)
     AND BOOL_OR(cp.user_id = p_friend_id)
  LIMIT 1;

  RETURN v_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_or_create_conversation(p_friend_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_conversation_id uuid;
  v_lock_a int;
  v_lock_b int;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  IF p_friend_id IS NULL THEN
    RAISE EXCEPTION 'Friend id is required';
  END IF;

  IF p_friend_id = v_user_id THEN
    RAISE EXCEPTION 'Cannot create a conversation with yourself';
  END IF;

  -- Serialize by canonical user-pair lock to avoid duplicate direct conversations.
  v_lock_a := LEAST(hashtext(v_user_id::text), hashtext(p_friend_id::text));
  v_lock_b := GREATEST(hashtext(v_user_id::text), hashtext(p_friend_id::text));
  PERFORM pg_advisory_xact_lock(v_lock_a, v_lock_b);

  SELECT cp.conversation_id
  INTO v_conversation_id
  FROM public.conversation_participants cp
  GROUP BY cp.conversation_id
  HAVING COUNT(*) = 2
     AND COUNT(DISTINCT cp.user_id) = 2
     AND BOOL_OR(cp.user_id = v_user_id)
     AND BOOL_OR(cp.user_id = p_friend_id)
  LIMIT 1;

  IF v_conversation_id IS NOT NULL THEN
    RETURN v_conversation_id;
  END IF;

  -- Enforce current product convention: direct chat creation is friend-scoped.
  IF NOT EXISTS (
    SELECT 1
    FROM public.friendships f
    WHERE f.status = 'accepted'
      AND (
        (f.user_id = v_user_id AND f.friend_id = p_friend_id)
        OR (f.user_id = p_friend_id AND f.friend_id = v_user_id)
      )
  ) THEN
    RAISE EXCEPTION 'Cannot create conversation with non-friend';
  END IF;

  INSERT INTO public.conversations (created_by)
  VALUES (v_user_id)
  RETURNING id INTO v_conversation_id;

  INSERT INTO public.conversation_participants (conversation_id, user_id)
  VALUES
    (v_conversation_id, v_user_id),
    (v_conversation_id, p_friend_id)
  ON CONFLICT (conversation_id, user_id) DO NOTHING;

  RETURN v_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_recent_conversations()
RETURNS TABLE (
  conversation_id uuid,
  other_user_id uuid,
  last_message_id uuid,
  last_message_content text,
  last_message_type text,
  last_message_sender_id uuid,
  last_message_created_at timestamptz,
  last_message_is_read boolean,
  unread_count integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  WITH my_conversations AS (
    SELECT cp.conversation_id
    FROM public.conversation_participants cp
    WHERE cp.user_id = v_user_id
  ),
  other_participants AS (
    SELECT
      cp.conversation_id,
      cp.user_id AS other_user_id
    FROM public.conversation_participants cp
    JOIN my_conversations mc ON mc.conversation_id = cp.conversation_id
    WHERE cp.user_id <> v_user_id
  ),
  last_messages AS (
    SELECT DISTINCT ON (m.conversation_id)
      m.conversation_id,
      m.id AS message_id,
      m.content,
      m.message_type,
      m.sender_id,
      m.created_at,
      m.is_read
    FROM public.messages m
    JOIN my_conversations mc ON mc.conversation_id = m.conversation_id
    WHERE COALESCE(m.is_deleted, false) = false
    ORDER BY m.conversation_id, m.created_at DESC
  ),
  unread_counts AS (
    SELECT
      m.conversation_id,
      COUNT(*)::int AS unread
    FROM public.messages m
    JOIN my_conversations mc ON mc.conversation_id = m.conversation_id
    WHERE m.sender_id <> v_user_id
      AND COALESCE(m.is_read, false) = false
      AND COALESCE(m.is_deleted, false) = false
    GROUP BY m.conversation_id
  )
  SELECT
    op.conversation_id,
    op.other_user_id,
    lm.message_id,
    lm.content,
    lm.message_type,
    lm.sender_id,
    lm.created_at,
    lm.is_read,
    COALESCE(uc.unread, 0)
  FROM other_participants op
  LEFT JOIN last_messages lm ON lm.conversation_id = op.conversation_id
  LEFT JOIN unread_counts uc ON uc.conversation_id = op.conversation_id
  WHERE lm.message_id IS NOT NULL
  ORDER BY lm.created_at DESC;
END;
$$;

CREATE OR REPLACE FUNCTION public.mark_messages_delivered(p_conversation_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_updated_count integer;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.conversation_participants cp
    WHERE cp.conversation_id = p_conversation_id
      AND cp.user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not a participant in this conversation';
  END IF;

  UPDATE public.messages
  SET delivered_at = NOW()
  WHERE conversation_id = p_conversation_id
    AND sender_id <> v_user_id
    AND delivered_at IS NULL
    AND COALESCE(is_deleted, false) = false;

  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  RETURN v_updated_count;
END;
$$;

-- Restrict function execution scope to authenticated application users.
REVOKE ALL ON FUNCTION public.get_conversation_with_friend(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_or_create_conversation(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_recent_conversations() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.mark_messages_delivered(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_conversation_with_friend(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_or_create_conversation(uuid) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.get_recent_conversations() TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION public.mark_messages_delivered(uuid) TO authenticated, service_role;

COMMIT;
