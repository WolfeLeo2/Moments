-- ==============================================================================
-- Database Webhooks & Triggers for Push Notifications
-- ==============================================================================

-- This script sets up the necessary database triggers to enable push notifications.
-- Note: You must have the 'pg_net' extension enabled or use Supabase Dashboard
-- to configure the actual webhook endpoints if not using Edge Functions directly via triggers.
-- Here we assume a generic 'notify_user' function that calls an Edge Function.

-- 1. Create a generic function to call Edge Function for notifications
-- Replace 'YOUR_PROJECT_REF' and 'YOUR_ANON_KEY' with actual values if running manually,
-- or use Supabase Dashboard to create a Webhook.
-- For this script, we'll define the logic that *would* be in the trigger.

-- Function to handle new friend requests
CREATE OR REPLACE FUNCTION public.handle_new_friend_request()
RETURNS TRIGGER AS $$
BEGIN
  -- Call Edge Function 'push-notification'
  -- Payload: { type: 'friend_request', record: NEW }
  perform net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/push-notification',
    headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
    body := jsonb_build_object(
      'type', 'friend_request',
      'record', row_to_json(NEW)
    )
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new friend requests
DROP TRIGGER IF EXISTS on_friend_request_created ON public.friendships;
CREATE TRIGGER on_friend_request_created
  AFTER INSERT ON public.friendships
  FOR EACH ROW
  WHEN (NEW.status = 'pending')
  EXECUTE FUNCTION public.handle_new_friend_request();


-- 2. Function to handle new moments in groups (Collaborated Moments)
CREATE OR REPLACE FUNCTION public.handle_new_group_moment()
RETURNS TRIGGER AS $$
DECLARE
  contributor_ids uuid[];
BEGIN
  -- Only proceed if the moment belongs to a group
  IF NEW.place_group_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get all contributors for this group, excluding the creator
  SELECT array_agg(user_id) INTO contributor_ids
  FROM public.moment_contributors
  WHERE moment_group_id = NEW.place_group_id
  AND user_id != NEW.user_id;

  -- Call Edge Function 'push-notification'
  -- Payload: { type: 'new_group_moment', record: NEW, recipients: contributor_ids }
  IF contributor_ids IS NOT NULL THEN
    perform net.http_post(
      url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/push-notification',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer YOUR_ANON_KEY"}'::jsonb,
      body := jsonb_build_object(
        'type', 'new_group_moment',
        'record', row_to_json(NEW),
        'recipients', contributor_ids
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new moments
DROP TRIGGER IF EXISTS on_moment_created_in_group ON public.moments;
CREATE TRIGGER on_moment_created_in_group
  AFTER INSERT ON public.moments
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_group_moment();

-- Note: Ensure 'pg_net' extension is enabled:
-- CREATE EXTENSION IF NOT EXISTS "pg_net";
