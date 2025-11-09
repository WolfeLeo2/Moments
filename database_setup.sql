-- Create moment_images table for multiple photos per moment
CREATE TABLE IF NOT EXISTS public.moment_images (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moments(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  media_path TEXT NOT NULL,
  caption TEXT,
  display_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_moment_images_moment_id ON public.moment_images(moment_id);
CREATE INDEX IF NOT EXISTS idx_moment_images_display_order ON public.moment_images(moment_id, display_order);

-- Enable RLS
ALTER TABLE public.moment_images ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view moment images"
  ON public.moment_images FOR SELECT
  TO authenticated, anon
  USING (true);

CREATE POLICY "Users can insert their own moment images"
  ON public.moment_images FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.moments
      WHERE moments.id = moment_id
      AND moments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own moment images"
  ON public.moment_images FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.moments
      WHERE moments.id = moment_id
      AND moments.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own moment images"
  ON public.moment_images FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.moments
      WHERE moments.id = moment_id
      AND moments.user_id = auth.uid()
    )
  );
