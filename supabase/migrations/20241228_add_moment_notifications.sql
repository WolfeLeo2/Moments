-- 1. Handle New Moment Group (Notify Friends)
CREATE OR REPLACE FUNCTION public.handle_new_moment_group()
RETURNS TRIGGER AS $$
DECLARE
  creator_name text;
  friend_record record;
BEGIN
  -- Get creator's name
  SELECT username INTO creator_name FROM public.profiles WHERE id = NEW.created_by;
  
  -- Loop through all friends
  FOR friend_record IN 
    SELECT CASE WHEN user_id = NEW.created_by THEN friend_id ELSE user_id END as friend_id
    FROM public.friendships
    WHERE (user_id = NEW.created_by OR friend_id = NEW.created_by)
    AND status = 'accepted'
  LOOP
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
      friend_record.friend_id,
      NEW.created_by,
      'new_moment_group',
      'New Moment',
      coalesce(creator_name, 'Someone') || ' posted a new moment',
      NEW.id::text,
      now(),
      false
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_moment_group_created ON public.moment_groups;
CREATE TRIGGER on_moment_group_created
AFTER INSERT ON public.moment_groups
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_moment_group();


-- 2. Handle New Moment Post (Notify Contributors)
CREATE OR REPLACE FUNCTION public.handle_new_moment_post()
RETURNS TRIGGER AS $$
DECLARE
  uploader_name text;
  group_title text;
  contributor_record record;
BEGIN
  -- Only proceed if it belongs to a group
  IF NEW.moment_group_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get uploader name and group title
  SELECT username INTO uploader_name FROM public.profiles WHERE id = NEW.user_id;
  SELECT title INTO group_title FROM public.moment_groups WHERE id = NEW.moment_group_id;

  -- Loop through contributors (excluding uploader)
  FOR contributor_record IN 
    SELECT user_id FROM public.moment_contributors
    WHERE moment_id = NEW.moment_group_id
    AND user_id != NEW.user_id
  LOOP
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
      contributor_record.user_id,
      NEW.user_id,
      'new_moment_post',
      'New Moment Added',
      coalesce(uploader_name, 'Someone') || ' added to ' || coalesce(group_title, 'a moment'),
      NEW.moment_group_id::text,
      now(),
      false
    );
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_moment_post_created ON public.moments;
CREATE TRIGGER on_moment_post_created
AFTER INSERT ON public.moments
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_moment_post();
