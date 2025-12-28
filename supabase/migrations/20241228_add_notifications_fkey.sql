-- Add foreign key for actor_id to profiles
ALTER TABLE public.notifications
ADD CONSTRAINT notifications_actor_id_fkey
FOREIGN KEY (actor_id)
REFERENCES public.profiles(id)
ON DELETE SET NULL;

-- Add foreign key for user_id to profiles (or auth.users, but profiles is usually safer for public schema joins)
-- Assuming user_id references auth.users, but we might want to join with profiles too if we ever need recipient info.
-- For now, actor_id is the critical one for display.
