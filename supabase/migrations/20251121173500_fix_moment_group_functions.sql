-- Drop old triggers
DROP TRIGGER IF EXISTS assign_place_group_trigger ON public.moments;
DROP TRIGGER IF EXISTS on_moment_created_in_group ON public.moments;

-- Drop old functions
DROP FUNCTION IF EXISTS public.assign_place_group();
DROP FUNCTION IF EXISTS public.handle_new_group_moment();

-- Create updated function for assigning group (if needed)
CREATE OR REPLACE FUNCTION public.assign_moment_group()
RETURNS TRIGGER AS $$
DECLARE
    group_id uuid;
    distance_threshold double precision := 0.001; -- ~100 meters
BEGIN
    -- If group ID is already set, do nothing
    IF NEW.moment_group_id IS NOT NULL THEN
        RETURN NEW;
    END IF;

    -- Try to find existing group within radius
    SELECT id INTO group_id
    FROM public.moment_groups
    WHERE abs(center_latitude - NEW.latitude) + abs(center_longitude - NEW.longitude) < distance_threshold
    LIMIT 1;
    
    -- If group found, assign it
    IF group_id IS NOT NULL THEN
        NEW.moment_group_id := group_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create updated function for notifications
CREATE OR REPLACE FUNCTION public.handle_new_moment_group_notification()
RETURNS TRIGGER AS $$
DECLARE
  contributor_ids uuid[];
BEGIN
  -- Only proceed if the moment belongs to a group
  IF NEW.moment_group_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- Get all contributors for this group, excluding the creator
  SELECT array_agg(DISTINCT user_id) INTO contributor_ids
  FROM public.moments
  WHERE moment_group_id = NEW.moment_group_id
  AND user_id != NEW.user_id;

  -- Call Edge Function 'push-notification'
  IF contributor_ids IS NOT NULL THEN
    perform net.http_post(
      url := 'https://voxutceosbctxfmlqjfk.supabase.co/functions/v1/push-notification',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('request.header.authorization', true) || '"}',
      body := jsonb_build_object(
        'type', 'new_group_moment',
        'record', row_to_json(NEW),
        'recipients', contributor_ids
      )
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate triggers with new functions
CREATE TRIGGER assign_moment_group_trigger
BEFORE INSERT ON public.moments
FOR EACH ROW
EXECUTE FUNCTION public.assign_moment_group();

CREATE TRIGGER on_moment_created_in_group
AFTER INSERT ON public.moments
FOR EACH ROW
EXECUTE FUNCTION public.handle_new_moment_group_notification();

-- RPC for atomic batch creation
CREATE OR REPLACE FUNCTION create_moment_batch(
  p_moments jsonb[],
  p_group_id uuid DEFAULT NULL,
  p_group_title text DEFAULT NULL,
  p_group_lat double precision DEFAULT NULL,
  p_group_lng double precision DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
AS $$
DECLARE
  v_group_id uuid;
  v_moment jsonb;
  v_created_moments jsonb[] := ARRAY[]::jsonb[];
  v_user_id uuid;
  v_new_moment_record record;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Determine Group ID
  IF p_group_id IS NOT NULL THEN
    v_group_id := p_group_id;
  ELSIF p_group_title IS NOT NULL AND p_group_lat IS NOT NULL AND p_group_lng IS NOT NULL THEN
    -- Create new group
    INSERT INTO public.moment_groups (
      title,
      center_latitude,
      center_longitude,
      created_by,
      is_public
    ) VALUES (
      p_group_title,
      p_group_lat,
      p_group_lng,
      v_user_id,
      true
    ) RETURNING id INTO v_group_id;
  ELSE
    -- No group info provided, proceed without group (or let trigger assign it)
    v_group_id := NULL;
  END IF;

  -- Loop through moments and insert them
  FOREACH v_moment IN ARRAY p_moments
  LOOP
    INSERT INTO public.moments (
      user_id,
      title,
      location,
      latitude,
      longitude,
      caption,
      media_path,
      moment_group_id,
      is_private
    ) VALUES (
      v_user_id,
      v_moment->>'title',
      v_moment->>'location',
      (v_moment->>'latitude')::double precision,
      (v_moment->>'longitude')::double precision,
      v_moment->>'caption',
      v_moment->>'media_path',
      v_group_id,
      (v_moment->>'is_private')::boolean
    ) RETURNING * INTO v_new_moment_record;
    
    v_created_moments := array_append(v_created_moments, row_to_json(v_new_moment_record)::jsonb);
  END LOOP;

  RETURN jsonb_build_object(
    'group_id', v_group_id,
    'moments', v_created_moments
  );
END;
$$;
