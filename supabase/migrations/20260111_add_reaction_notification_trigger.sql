-- Create trigger for reaction notifications
-- Notifies moment owner when someone reacts to their moment

CREATE OR REPLACE FUNCTION public.handle_new_moment_reaction()
RETURNS TRIGGER AS $$
DECLARE
  reactor_name text;
  moment_owner uuid;
BEGIN
  -- Get reactor's display name (fallback to username)
  SELECT COALESCE(display_name, username) INTO reactor_name 
  FROM public.profiles WHERE id = NEW.user_id;
  
  -- Get moment owner
  SELECT user_id INTO moment_owner FROM public.moments WHERE id = NEW.moment_id;
  
  -- Don't notify self-reactions
  IF moment_owner IS NULL OR moment_owner = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
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
    moment_owner,
    NEW.user_id,
    'moment_like',
    'New Reaction',
    COALESCE(reactor_name, 'Someone') || ' reacted ' || NEW.emoji || ' to your moment',
    NEW.moment_id::text,
    now(),
    false
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Create trigger on moment_reactions table
DROP TRIGGER IF EXISTS on_moment_reaction_created ON public.moment_reactions;
CREATE TRIGGER on_moment_reaction_created
AFTER INSERT ON public.moment_reactions
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_moment_reaction();
