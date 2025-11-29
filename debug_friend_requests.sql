-- Debug queries for friend request issue
-- Run these in Supabase SQL Editor to diagnose the problem

-- 1. Check if profiles table exists and has data
SELECT COUNT(*) as profile_count FROM profiles;

-- 2. Check if any profiles have invite codes
SELECT id, username, display_name, invite_code, created_at 
FROM profiles 
LIMIT 5;

-- 3. Check if friendships table exists and has data
SELECT COUNT(*) as friendship_count FROM friendships;

-- 4. Check recent friendship attempts
SELECT * FROM friendships 
ORDER BY created_at DESC 
LIMIT 10;

-- 5. Check RLS policies on friendships
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'friendships';

-- 6. Check RLS policies on profiles
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE tablename = 'profiles';

-- 7. Test if current user can insert into friendships (replace UUIDs with real ones)
-- SELECT auth.uid(); -- Get your current user ID first
-- Then try:
-- INSERT INTO friendships (user_id, friend_id, status) 
-- VALUES ('YOUR_USER_ID', 'SOME_OTHER_USER_ID', 'pending')
-- RETURNING *;
