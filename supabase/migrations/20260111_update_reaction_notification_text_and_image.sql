-- Update reaction notification to say "liked" and include moment image
CREATE OR REPLACE FUNCTION public.handle_new_moment_reaction()
RETURNS TRIGGER AS $$
DECLARE
  moment_owner uuid;
  moment_media_url text;
  moment_group_title text;
BEGIN
  -- Get moment owner and first media URL
  SELECT m.user_id, 
         COALESCE(m.media_url, (SELECT media_url FROM moments WHERE moment_group_id = m.moment_group_id ORDER BY created_at LIMIT 1)),
         mg.title
  INTO moment_owner, moment_media_url, moment_group_title
  FROM public.moments m
  LEFT JOIN public.moment_groups mg ON mg.id = m.moment_group_id
  WHERE m.id = NEW.moment_id;
  
  -- Don't notify self-reactions
  IF moment_owner IS NULL OR moment_owner = NEW.user_id THEN
    RETURN NEW;
  END IF;
  
  -- Insert notification (body says "liked", image_url is the moment's media)
  INSERT INTO public.notifications (
    user_id,
    actor_id,
    type,
    title,
    body,
    related_id,
    image_url,
    created_at,
    is_read
  ) VALUES (
    moment_owner,
    NEW.user_id,
    'moment_like',
    'New Like',
    CASE 
      WHEN moment_group_title IS NOT NULL THEN 'liked your moment in "' || moment_group_title || '"'
      ELSE 'liked your moment'
    END,
    NEW.moment_id::text,
    moment_media_url,
    now(),
    false
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;
