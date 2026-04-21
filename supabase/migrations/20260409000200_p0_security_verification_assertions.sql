-- P0 security verification assertions
-- Designed to fail fast if hardening regresses.

DO $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*)
  INTO v_count
  FROM information_schema.routine_privileges rp
  WHERE rp.specific_schema = 'public'
    AND rp.routine_name IN (
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
    AND rp.privilege_type = 'EXECUTE'
    AND rp.grantee IN ('PUBLIC', 'anon');

  IF v_count > 0 THEN
    RAISE EXCEPTION 'P0 verification failed: PUBLIC/anon still have EXECUTE on sensitive RPCs (% rows)', v_count;
  END IF;

  SELECT count(*)
  INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'messages'
    AND cmd = 'UPDATE'
    AND policyname = 'Users can update messages in their conversations';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'P0 verification failed: expected exactly one participant update policy on messages';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'messages'
    AND cmd = 'UPDATE'
    AND policyname = 'Users can update their own messages';

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'P0 verification failed: legacy own-message update policy still exists';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM pg_policies
  WHERE schemaname = 'public'
    AND tablename = 'conversations'
    AND cmd = 'INSERT'
    AND policyname = 'Users can create conversations';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'P0 verification failed: conversations insert policy missing';
  END IF;

  SELECT count(*)
  INTO v_count
  FROM pg_trigger t
  JOIN pg_class c ON c.oid = t.tgrelid
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname = 'notifications'
    AND t.tgname = 'push-notifications'
    AND NOT t.tgisinternal
    AND pg_get_triggerdef(t.oid, true) ILIKE '%forward_notification_to_edge%';

  IF v_count <> 1 THEN
    RAISE EXCEPTION 'P0 verification failed: notifications trigger not routed through forward_notification_to_edge';
  END IF;
END $$;
