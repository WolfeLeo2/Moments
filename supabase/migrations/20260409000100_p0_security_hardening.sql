-- P0 security hardening
-- Applied via Supabase MCP on 2026-04-09.

BEGIN;

-- Reassert least-privilege insert policy for conversations.
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
CREATE POLICY "Users can create conversations"
  ON public.conversations
  FOR INSERT
  WITH CHECK ((SELECT auth.uid()) = created_by);

-- Remove overlapping update policies and keep a single participant-scoped policy.
-- Fine-grained non-sender field restrictions remain enforced by trigger:
-- public.check_message_update_permission().
DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update messages in their conversations" ON public.messages;
CREATE POLICY "Users can update messages in their conversations"
  ON public.messages
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1
      FROM public.conversation_participants cp
      WHERE cp.conversation_id = messages.conversation_id
        AND cp.user_id = (SELECT auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.conversation_participants cp
      WHERE cp.conversation_id = messages.conversation_id
        AND cp.user_id = (SELECT auth.uid())
    )
  );

-- Tighten EXECUTE grants for sensitive RPCs.
DO $$
DECLARE
  rec RECORD;
BEGIN
  FOR rec IN
    SELECT
      p.proname,
      pg_get_function_identity_arguments(p.oid) AS args
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN (
        'get_conversation_with_friend',
        'get_or_create_conversation',
        'get_recent_conversations',
        'mark_messages_delivered',
        'get_unread_chat_count',
        'get_unread_notification_count',
        'find_profiles_by_phone',
        'search_profiles',
        'create_moment_batch'
      )
  LOOP
    EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM PUBLIC', rec.proname, rec.args);
    EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM anon', rec.proname, rec.args);
    EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM authenticated', rec.proname, rec.args);
    EXECUTE format('REVOKE ALL ON FUNCTION public.%I(%s) FROM service_role', rec.proname, rec.args);
    EXECUTE format('GRANT EXECUTE ON FUNCTION public.%I(%s) TO authenticated, service_role', rec.proname, rec.args);
  END LOOP;
END $$;

-- Remove hardcoded bearer usage from SQL trigger path.
CREATE OR REPLACE FUNCTION public.resolve_edge_anon_token()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_token text;
BEGIN
  v_token := NULLIF(current_setting('app.settings.anon_key', true), '');

  IF v_token IS NULL THEN
    v_token := NULLIF(current_setting('app.settings.supabase_anon_key', true), '');
  END IF;

  BEGIN
    IF v_token IS NULL THEN
      SELECT ds.decrypted_secret
      INTO v_token
      FROM vault.decrypted_secrets ds
      WHERE ds.name IN ('supabase_anon_key', 'anon_key')
      ORDER BY CASE ds.name WHEN 'supabase_anon_key' THEN 0 ELSE 1 END
      LIMIT 1;
    END IF;
  EXCEPTION
    WHEN undefined_table OR invalid_schema_name THEN
      NULL;
  END;

  RETURN v_token;
END;
$$;

CREATE OR REPLACE FUNCTION public.forward_notification_to_edge()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_token text;
  v_headers text;
BEGIN
  v_token := public.resolve_edge_anon_token();

  IF v_token IS NULL THEN
    RAISE WARNING 'push-notification token not configured in db settings/vault; skipping edge call';
    RETURN NEW;
  END IF;

  v_headers := jsonb_build_object(
    'Content-type', 'application/json',
    'Authorization', 'Bearer ' || v_token
  )::text;

  PERFORM supabase_functions.http_request(
    'https://voxutceosbctxfmlqjfk.supabase.co/functions/v1/push-notification',
    'POST',
    v_headers,
    '{}'::text,
    '5000'
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS "push-notifications" ON public.notifications;
CREATE TRIGGER "push-notifications"
AFTER INSERT ON public.notifications
FOR EACH ROW
EXECUTE FUNCTION public.forward_notification_to_edge();

COMMIT;
