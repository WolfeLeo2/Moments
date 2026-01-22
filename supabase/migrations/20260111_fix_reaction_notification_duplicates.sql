-- Fix duplicate reaction notifications
-- 1. Drop the duplicate trigger (there were two: on_moment_reaction_added and on_moment_reaction_created)
DROP TRIGGER IF EXISTS on_moment_reaction_added ON public.moment_reactions;

-- 2. Update the function to NOT include name in body (push notification already uses actor_name as title)
CREATE OR REPLACE FUNCTION public.handle_new_moment_reaction()
RETURNS TRIGGER AS $$
DECLARE
  moment_owner uuid;
BEGIN
  -- Get moment owner
  SELECT user_id INTO moment_owner FROM public.moments WHERE id = NEW.moment_id;
  
  -- Don't notify self-reactions
  IF moment_owner IS NULL OR moment_owner = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Insert notification (name is NOT in body - push function adds it as title)
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
    moment_owner,
    NEW.user_id,
    'moment_like',
    'New Reaction',
    'reacted ' || NEW.emoji || ' to your moment',
    NEW.moment_id::text,
    now(),
    false
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
