-- Migration: create_moment_comments
-- Apply this to the Moments Supabase project (voxutceosbctxfmlqjfk)

CREATE TABLE IF NOT EXISTS public.moment_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id UUID NOT NULL REFERENCES public.moment(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content TEXT NOT NULL CHECK (char_length(content) > 0 AND char_length(content) <= 1000),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX idx_moment_comments_moment_id ON public.moment_comments(moment_id);
CREATE INDEX idx_moment_comments_user_id ON public.moment_comments(user_id);
CREATE INDEX idx_moment_comments_created_at ON public.moment_comments(created_at DESC);

-- RLS
ALTER TABLE public.moment_comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view comments"
  ON public.moment_comments FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create comments"
  ON public.moment_comments FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
  ON public.moment_comments FOR DELETE USING (auth.uid() = user_id);

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE public.moment_comments;
