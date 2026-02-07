-- Add audio note & music support to moments
-- Audio notes: voice notes attached to any moment
-- Music data: Deezer preview / curated track metadata as JSONB

ALTER TABLE moments
ADD COLUMN IF NOT EXISTS audio_path TEXT,
ADD COLUMN IF NOT EXISTS audio_duration INTEGER;

COMMENT ON COLUMN moments.audio_path IS 'Storage path for audio note attachment';
COMMENT ON COLUMN moments.audio_duration IS 'Duration of audio note in seconds';

ALTER TABLE moments
ADD COLUMN IF NOT EXISTS music_data JSONB;

COMMENT ON COLUMN moments.music_data IS 'JSON: {type, track_id, url, title, artist, album_art}';

-- Private audio storage bucket for voice notes
INSERT INTO storage.buckets (id, name, public)
VALUES ('moment-audio', 'moment-audio', false)
ON CONFLICT (id) DO NOTHING;

-- Public curated-audio bucket for app-curated tracks
INSERT INTO storage.buckets (id, name, public)
VALUES ('curated-audio', 'curated-audio', true)
ON CONFLICT (id) DO NOTHING;

-- moment-audio policies
CREATE POLICY "Users can upload their own audio notes"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'moment-audio'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY "Users can read audio notes from visible moments"
ON storage.objects FOR SELECT TO authenticated
USING (bucket_id = 'moment-audio');

CREATE POLICY "Users can delete their own audio notes"
ON storage.objects FOR DELETE TO authenticated
USING (
  bucket_id = 'moment-audio'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- curated-audio policies (public read)
CREATE POLICY "Anyone can read curated audio"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'curated-audio');

CREATE POLICY "Only admins can upload curated audio"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'curated-audio'
  AND auth.uid()::text IN (
    SELECT id::text FROM auth.users WHERE raw_user_meta_data->>'role' = 'admin'
  )
);

-- Updated create_moment_batch RPC with audio_path, audio_duration, music_data
CREATE OR REPLACE FUNCTION public.create_moment_batch(
  p_moments jsonb[],
  p_group_id uuid DEFAULT NULL,
  p_group_title text DEFAULT NULL,
  p_group_lat double precision DEFAULT NULL,
  p_group_lng double precision DEFAULT NULL,
  p_group_private boolean DEFAULT false
)
RETURNS jsonb
LANGUAGE plpgsql
AS $function$
DECLARE
  v_group_id uuid;
  v_moment jsonb;
  v_created_moments jsonb[] := ARRAY[]::jsonb[];
  v_user_id uuid;
  v_new_moment_record record;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  IF p_group_id IS NOT NULL THEN
    v_group_id := p_group_id;
  ELSIF p_group_title IS NOT NULL AND p_group_lat IS NOT NULL AND p_group_lng IS NOT NULL THEN
    INSERT INTO public.moment_groups (
      title, latitude, longitude, created_by, is_private
    ) VALUES (
      p_group_title, p_group_lat, p_group_lng, v_user_id, p_group_private
    ) RETURNING id INTO v_group_id;

    INSERT INTO public.moment_contributors (
      moment_id, user_id, role, accepted_at
    ) VALUES (v_group_id, v_user_id, 'owner', now());
  ELSE
    v_group_id := NULL;
  END IF;

  FOREACH v_moment IN ARRAY p_moments
  LOOP
    INSERT INTO public.moments (
      user_id, title, location, latitude, longitude, caption,
      media_path, media_type, thumbnail_path, duration,
      moment_group_id, is_private,
      audio_path, audio_duration, music_data
    ) VALUES (
      v_user_id,
      v_moment->>'title',
      v_moment->>'location',
      (v_moment->>'latitude')::double precision,
      (v_moment->>'longitude')::double precision,
      v_moment->>'caption',
      v_moment->>'media_path',
      COALESCE(v_moment->>'media_type', 'image'),
      v_moment->>'thumbnail_path',
      (v_moment->>'duration')::integer,
      v_group_id,
      COALESCE((v_moment->>'is_private')::boolean, false),
      v_moment->>'audio_path',
      (v_moment->>'audio_duration')::integer,
      (v_moment->'music_data')::jsonb
    ) RETURNING * INTO v_new_moment_record;

    v_created_moments := array_append(v_created_moments, row_to_json(v_new_moment_record)::jsonb);
  END LOOP;

  RETURN jsonb_build_object(
    'group_id', v_group_id,
    'moments', v_created_moments
  );
END;
$function$;
