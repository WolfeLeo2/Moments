-- 1. Cleanup: Drop direct webhook triggers (we will route through notifications table)
DROP TRIGGER IF EXISTS on_new_message_notification ON public.messages;
DROP FUNCTION IF EXISTS public.handle_new_message_notification();

-- Note: We keep the trigger on friendships but update the function to insert into notifications instead of calling webhook directly.

-- 2. Function to handle new messages -> Insert into notifications
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
DECLARE
  sender_name text;
  participant_id uuid;
BEGIN
  -- Get sender's name
  SELECT username INTO sender_name FROM public.profiles WHERE id = NEW.sender_id;
  IF sender_name IS NULL THEN
    sender_name := 'Someone';
  END IF;

  -- Loop through all other participants in the conversation
  FOR participant_id IN 
    SELECT user_id FROM public.conversation_participants 
    WHERE conversation_id = NEW.conversation_id 
    AND user_id != NEW.sender_id
  LOOP
    -- Insert notification
    INSERT INTO public.notifications (
      user_id,
      actor_id,
      type,
      title,
      body,
      related_id,
      created_at,
      is_read
    ) VALUES (
      participant_id,
      NEW.sender_id,
      'message',
      sender_name,
      CASE 
        WHEN NEW.message_type = 'image' THEN 'Sent an image'
        WHEN NEW.message_type = 'video' THEN 'Sent a video'
        ELSE left(NEW.content, 100) -- Truncate long messages
      END,
      NEW.conversation_id::text,
      now(),
      false
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger for messages
CREATE TRIGGER on_message_created
AFTER INSERT ON public.messages
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_message();


-- 3. Update Friend Request Handler -> Insert into notifications
CREATE OR REPLACE FUNCTION public.handle_new_friend_request()
RETURNS TRIGGER AS $$
DECLARE
  sender_name text;
BEGIN
  -- Get sender's name
  SELECT username INTO sender_name FROM public.profiles WHERE id = NEW.user_id;
  
  INSERT INTO public.notifications (
    user_id,
    actor_id,
    type,
    title,
    body,
    related_id,
    created_at,
    is_read
  ) VALUES (
    NEW.friend_id, -- The person receiving the request
    NEW.user_id,   -- The person sending the request
    'friend_request',
    'New Friend Request',
    coalesce(sender_name, 'Someone') || ' sent you a friend request',
    NEW.id::text,
    now(),
    false
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- 4. Handle Moment Invites -> Insert into notifications
CREATE OR REPLACE FUNCTION public.handle_new_moment_invite()
RETURNS TRIGGER AS $$
DECLARE
  inviter_name text;
  moment_title text;
  inviter_id uuid;
BEGIN
  -- Get inviter's name and moment title
  -- We assume the creator of the group is the inviter for now
  SELECT p.username, mg.title, mg.created_by INTO inviter_name, moment_title, inviter_id
  FROM public.moment_groups mg
  JOIN public.profiles p ON p.id = mg.created_by
  WHERE mg.id = NEW.moment_id;

  INSERT INTO public.notifications (
    user_id,
    actor_id,
    type,
    title,
    body,
    related_id,
    created_at,
    is_read
  ) VALUES (
    NEW.user_id, -- The person invited
    inviter_id, -- The inviter (group creator)
    'moment_invite', -- Standardized type
    'Moment Invite',
    coalesce(inviter_name, 'Someone') || ' invited you to ' || coalesce(moment_title, 'a moment'),
    NEW.moment_id::text,
    now(),
    false
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Trigger for moment invites
DROP TRIGGER IF EXISTS on_moment_invite_created ON public.moment_contributors;
CREATE TRIGGER on_moment_invite_created
AFTER INSERT ON public.moment_contributors
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_moment_invite();
