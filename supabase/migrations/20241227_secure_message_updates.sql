-- Secure Message Updates
-- Restrict non-senders to only update 'is_read' status

CREATE OR REPLACE FUNCTION public.check_message_update_permission()
RETURNS TRIGGER AS $$
BEGIN
  -- If the user is NOT the sender (i.e. they are marking it as read)
  IF OLD.sender_id != (select auth.uid()) THEN
    -- Prevent changing the sender_id
    IF NEW.sender_id IS DISTINCT FROM OLD.sender_id THEN
      RAISE EXCEPTION 'You cannot change the sender of a message.';
    END IF;

    -- Prevent changing content fields
    IF NEW.content IS DISTINCT FROM OLD.content OR
       NEW.media_url IS DISTINCT FROM OLD.media_url OR
       NEW.metadata IS DISTINCT FROM OLD.metadata OR
       NEW.payload IS DISTINCT FROM OLD.payload OR
       NEW.private IS DISTINCT FROM OLD.private OR
       NEW.message_type IS DISTINCT FROM OLD.message_type OR
       NEW.extension IS DISTINCT FROM OLD.extension OR
       NEW.event IS DISTINCT FROM OLD.event OR
       NEW.topic IS DISTINCT FROM OLD.topic THEN
       
       RAISE EXCEPTION 'You are not allowed to update the content of this message.';
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_check_message_update_permission ON public.messages;

CREATE TRIGGER trg_check_message_update_permission
BEFORE UPDATE ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.check_message_update_permission();
