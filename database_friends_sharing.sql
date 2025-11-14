-- ============================================
-- FRIENDS & SHARED MOMENTS DATABASE SCHEMA
-- ============================================

-- 1. PROFILES TABLE (Extended User Info)
-- ============================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    display_name TEXT,
    avatar_url TEXT,
    bio TEXT CHECK (char_length(bio) <= 500),
    invite_code TEXT UNIQUE NOT NULL, -- 6-character invite code
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- Index for fast invite code lookups
CREATE INDEX idx_profiles_invite_code ON profiles (invite_code);

CREATE INDEX idx_profiles_username ON profiles (username);

-- Trigger to update updated_at
CREATE TRIGGER update_profiles_updated_at 
  BEFORE UPDATE ON profiles 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 2. FRIENDSHIPS TABLE (Friend Connections)
-- ============================================
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'rejected', 'blocked')),
  requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  responded_at TIMESTAMP WITH TIME ZONE,

-- Ensure no duplicate friendships and no self-friendship
UNIQUE(user_id, friend_id), CHECK (user_id != friend_id) );

-- Indexes for fast friend queries
CREATE INDEX idx_friendships_user_id ON friendships (user_id);

CREATE INDEX idx_friendships_friend_id ON friendships (friend_id);

CREATE INDEX idx_friendships_status ON friendships (status);

-- ============================================
-- 3. MOMENT_GROUPS TABLE (Shared Locations)
-- ============================================
CREATE TABLE IF NOT EXISTS moment_groups (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
    place_name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL CHECK (
        latitude >= -90
        AND latitude <= 90
    ),
    longitude DOUBLE PRECISION NOT NULL CHECK (
        longitude >= -180
        AND longitude <= 180
    ),
    created_by UUID REFERENCES auth.users (id) ON DELETE SET NULL,
    is_public BOOLEAN DEFAULT false, -- If true, anyone can contribute
    created_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW(),
        updated_at TIMESTAMP
    WITH
        TIME ZONE DEFAULT NOW()
);

-- Geospatial index for nearby location groups
CREATE INDEX idx_moment_groups_location ON moment_groups USING GIST (
    ll_to_earth (latitude, longitude)
);

CREATE INDEX idx_moment_groups_created_by ON moment_groups (created_by);

-- Trigger to update updated_at
CREATE TRIGGER update_moment_groups_updated_at 
  BEFORE UPDATE ON moment_groups 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 4. MOMENT_CONTRIBUTORS TABLE (Multi-User Moments)
-- ============================================
CREATE TABLE IF NOT EXISTS moment_contributors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moment_id UUID REFERENCES moments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('owner', 'contributor', 'viewer')),
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,

-- One user per moment (no duplicates)
UNIQUE(moment_id, user_id) );

-- Indexes for contributor queries
CREATE INDEX idx_moment_contributors_moment_id ON moment_contributors (moment_id);

CREATE INDEX idx_moment_contributors_user_id ON moment_contributors (user_id);

-- ============================================
-- 5. UPDATE MOMENTS TABLE (Add place_group_id if not exists)
-- ============================================
-- This links moments to shared location groups
ALTER TABLE moments
ADD COLUMN IF NOT EXISTS place_group_id UUID REFERENCES moment_groups (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_moments_place_group_id ON moments (place_group_id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- PROFILES POLICIES
-- ============================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Anyone can view profiles (for friend discovery)
CREATE POLICY "Profiles are viewable by everyone" ON profiles FOR
SELECT USING (true);

-- Users can update their own profile
CREATE POLICY "Users can update their own profile" ON profiles FOR
UPDATE USING (auth.uid () = id)
WITH
    CHECK (auth.uid () = id);

-- Users can insert their own profile
CREATE POLICY "Users can create their own profile" ON profiles FOR
INSERT
WITH
    CHECK (auth.uid () = id);

-- FRIENDSHIPS POLICIES
-- ============================================
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

-- Users can view friendships where they are involved
CREATE POLICY "Users can view their own friendships" ON friendships FOR
SELECT USING (
        auth.uid () = user_id
        OR auth.uid () = friend_id
    );

-- Users can send friend requests (create pending friendships)
CREATE POLICY "Users can send friend requests" ON friendships FOR
INSERT
WITH
    CHECK (auth.uid () = user_id);

-- Users can update friendships where they are the recipient
CREATE POLICY "Users can respond to friend requests" ON friendships FOR
UPDATE USING (auth.uid () = friend_id)
WITH
    CHECK (auth.uid () = friend_id);

-- Users can delete their own friend connections
CREATE POLICY "Users can delete their friendships" ON friendships FOR DELETE USING (
    auth.uid () = user_id
    OR auth.uid () = friend_id
);

-- MOMENTS POLICIES (UPDATED FOR SHARING)
-- ============================================
-- Drop existing policies to recreate
DROP POLICY IF EXISTS "Moments are viewable by everyone" ON moments;

DROP POLICY IF EXISTS "Users can view their own or shared moments" ON moments;

DROP POLICY IF EXISTS "Friends can view each other's moments" ON moments;

-- Policy: Users can view their own moments, contributed moments, and friends' moments
CREATE POLICY "Users can view own, shared, and friends moments" ON moments FOR
SELECT USING (
        -- Own moments
        auth.uid () = user_id
        OR
        -- Moments user is a contributor to
        EXISTS (
            SELECT 1
            FROM moment_contributors
            WHERE
                moment_contributors.moment_id = moments.id
                AND moment_contributors.user_id = auth.uid ()
                AND moment_contributors.accepted_at IS NOT NULL
        )
        OR
        -- Friends' moments
        EXISTS (
            SELECT 1
            FROM friendships
            WHERE (
                    (
                        friendships.user_id = auth.uid ()
                        AND friendships.friend_id = moments.user_id
                    )
                    OR (
                        friendships.friend_id = auth.uid ()
                        AND friendships.user_id = moments.user_id
                    )
                )
                AND friendships.status = 'accepted'
        )
        OR
        -- Public shared location groups
        EXISTS (
            SELECT 1
            FROM moment_groups
            WHERE
                moment_groups.id = moments.place_group_id
                AND moment_groups.is_public = true
        )
    );

-- MOMENT_GROUPS POLICIES
-- ============================================
ALTER TABLE moment_groups ENABLE ROW LEVEL SECURITY;

-- Users can view groups they created or public groups or groups with their moments
CREATE POLICY "Users can view relevant moment groups" ON moment_groups FOR
SELECT USING (
        created_by = auth.uid ()
        OR is_public = true
        OR EXISTS (
            SELECT 1
            FROM moments
            WHERE
                moments.place_group_id = moment_groups.id
                AND moments.user_id = auth.uid ()
        )
    );

-- Users can create moment groups
CREATE POLICY "Users can create moment groups" ON moment_groups FOR
INSERT
WITH
    CHECK (auth.uid () = created_by);

-- Users can update their own groups
CREATE POLICY "Users can update their own groups" ON moment_groups FOR
UPDATE USING (auth.uid () = created_by)
WITH
    CHECK (auth.uid () = created_by);

-- MOMENT_CONTRIBUTORS POLICIES
-- ============================================
ALTER TABLE moment_contributors ENABLE ROW LEVEL SECURITY;

-- Users can view contributors for moments they have access to
CREATE POLICY "Users can view contributors of accessible moments" ON moment_contributors FOR
SELECT USING (
        EXISTS (
            SELECT 1
            FROM moments
            WHERE
                moments.id = moment_contributors.moment_id
                AND (
                    moments.user_id = auth.uid ()
                    OR EXISTS (
                        SELECT 1
                        FROM moment_contributors mc2
                        WHERE
                            mc2.moment_id = moments.id
                            AND mc2.user_id = auth.uid ()
                    )
                )
        )
    );

-- Moment owners can invite contributors
CREATE POLICY "Moment owners can invite contributors" ON moment_contributors FOR
INSERT
WITH
    CHECK (
        EXISTS (
            SELECT 1
            FROM moments
            WHERE
                moments.id = moment_contributors.moment_id
                AND moments.user_id = auth.uid ()
        )
    );

-- Contributors can accept invitations
CREATE POLICY "Contributors can accept invitations" ON moment_contributors FOR
UPDATE USING (auth.uid () = user_id)
WITH
    CHECK (auth.uid () = user_id);

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Function to generate random 6-character invite code
CREATE OR REPLACE FUNCTION generate_invite_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- Exclude ambiguous chars
  result TEXT := '';
  i INTEGER;
BEGIN
  FOR i IN 1..6 LOOP
    result := result || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN result;
END;
$$ LANGUAGE plpgsql;

-- Function to auto-generate invite code on profile creation
CREATE OR REPLACE FUNCTION set_invite_code()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.invite_code IS NULL THEN
    NEW.invite_code := generate_invite_code();
    -- Ensure uniqueness
    WHILE EXISTS (SELECT 1 FROM profiles WHERE invite_code = NEW.invite_code) LOOP
      NEW.invite_code := generate_invite_code();
    END LOOP;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_profile_invite_code
  BEFORE INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_invite_code();

-- Function to create reciprocal friendship
CREATE OR REPLACE FUNCTION create_reciprocal_friendship()
RETURNS TRIGGER AS $$
BEGIN
  -- When a friendship is accepted, create the reverse connection
  IF NEW.status = 'accepted' AND OLD.status = 'pending' THEN
    INSERT INTO friendships (user_id, friend_id, status, requested_at, responded_at)
    VALUES (NEW.friend_id, NEW.user_id, 'accepted', NEW.requested_at, NOW())
    ON CONFLICT (user_id, friend_id) DO UPDATE
    SET status = 'accepted', responded_at = NOW();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auto_reciprocal_friendship
  AFTER UPDATE ON friendships
  FOR EACH ROW
  WHEN (NEW.status = 'accepted')
  EXECUTE FUNCTION create_reciprocal_friendship();

-- ============================================
-- INITIAL DATA / MIGRATION
-- ============================================

-- Create profiles for existing users (if they don't have one)
INSERT INTO
    profiles (id, invite_code)
SELECT id, generate_invite_code ()
FROM auth.users
WHERE
    id NOT IN(
        SELECT id
        FROM profiles
    ) ON CONFLICT (id) DO NOTHING;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if tables exist
SELECT table_name
FROM information_schema.tables
WHERE
    table_schema = 'public'
    AND table_name IN (
        'profiles',
        'friendships',
        'moment_groups',
        'moment_contributors'
    );

-- Check RLS is enabled
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE
    tablename IN (
        'profiles',
        'friendships',
        'moment_groups',
        'moment_contributors'
    );