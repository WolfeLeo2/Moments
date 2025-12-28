-- Fix Security: Set search_path for functions
ALTER FUNCTION public.get_friends_of_user(uuid) SET search_path = public;
ALTER FUNCTION public.handle_new_friend_request() SET search_path = public;
ALTER FUNCTION public.create_notification_preferences_for_new_user() SET search_path = public;
ALTER FUNCTION public.create_moment_batch(jsonb[], uuid, text, double precision, double precision) SET search_path = public;
ALTER FUNCTION public.create_moment_batch(jsonb[], uuid, text, double precision, double precision, boolean) SET search_path = public;
ALTER FUNCTION public.get_unread_chat_count() SET search_path = public;
ALTER FUNCTION public.update_conversation_timestamp() SET search_path = public;
ALTER FUNCTION public.get_user_conversation_ids() SET search_path = public;
ALTER FUNCTION public.handle_new_moment_group_notification() SET search_path = public;
ALTER FUNCTION public.can_add_participant(uuid) SET search_path = public;
ALTER FUNCTION public.generate_invite_code() SET search_path = public;
ALTER FUNCTION public.set_invite_code() SET search_path = public;
ALTER FUNCTION public.handle_updated_at() SET search_path = public;
ALTER FUNCTION public.update_geom_from_latlong() SET search_path = public;
ALTER FUNCTION public.update_moment_group_geom() SET search_path = public;
ALTER FUNCTION public.get_nearby_moment_groups(double precision, double precision, double precision) SET search_path = public;
ALTER FUNCTION public.assign_moment_group() SET search_path = public;
ALTER FUNCTION public.get_unread_notification_count() SET search_path = public;

-- Fix Performance: Add missing indexes on foreign keys
CREATE INDEX IF NOT EXISTS idx_conversations_created_by ON public.conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_notifications_actor_id ON public.notifications(actor_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_id ON public.user_devices(user_id);

-- Fix Performance: Remove duplicate index
ALTER TABLE public.moment_contributors DROP CONSTRAINT IF EXISTS moment_contributors_unique_user_moment;

-- Fix Performance: Optimize RLS policies (wrap auth.uid() in select)

-- Moments
DROP POLICY IF EXISTS "Users can create moments" ON public.moments;
CREATE POLICY "Users can create moments" ON public.moments FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update moments" ON public.moments;
CREATE POLICY "Users can update moments" ON public.moments FOR UPDATE USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete moments" ON public.moments;
CREATE POLICY "Users can delete moments" ON public.moments FOR DELETE USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can view moments" ON public.moments;
CREATE POLICY "Users can view moments" ON public.moments FOR SELECT USING (
  (select auth.uid()) = user_id 
  OR (
    NOT COALESCE(is_private, false) 
    AND user_id IN (SELECT get_friends_of_user((select auth.uid())))
    AND (
      moment_group_id IS NULL 
      OR moment_group_id IN (SELECT id FROM moment_groups WHERE NOT COALESCE(is_private, false))
    )
  )
);

-- Moment Contributors
DROP POLICY IF EXISTS "Contributors can update own records" ON public.moment_contributors;
CREATE POLICY "Contributors can update own records" ON public.moment_contributors FOR UPDATE USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Owners can invite contributors" ON public.moment_contributors;
CREATE POLICY "Owners can invite contributors" ON public.moment_contributors FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM moment_groups mg 
    WHERE mg.id = moment_contributors.moment_id 
    AND mg.created_by = (select auth.uid())
  )
);

DROP POLICY IF EXISTS "Users can delete contributors" ON public.moment_contributors;
CREATE POLICY "Users can delete contributors" ON public.moment_contributors FOR DELETE USING (
  (select auth.uid()) = user_id 
  OR EXISTS (
    SELECT 1 FROM moment_groups mg 
    WHERE mg.id = moment_contributors.moment_id 
    AND mg.created_by = (select auth.uid())
  )
);

DROP POLICY IF EXISTS "Users can view contributors" ON public.moment_contributors;
CREATE POLICY "Users can view contributors" ON public.moment_contributors FOR SELECT USING (
  (select auth.uid()) = user_id 
  OR EXISTS (
    SELECT 1 FROM moment_groups mg 
    WHERE mg.id = moment_contributors.moment_id 
    AND (
      mg.created_by = (select auth.uid()) 
      OR mg.created_by IN (SELECT get_friends_of_user((select auth.uid())))
    )
  )
);

-- Friendships
DROP POLICY IF EXISTS "Users can view their friendships" ON public.friendships;
CREATE POLICY "Users can view their friendships" ON public.friendships FOR SELECT USING (
  (select auth.uid()) = user_id OR (select auth.uid()) = friend_id
);

DROP POLICY IF EXISTS "Users can delete friendships" ON public.friendships;
CREATE POLICY "Users can delete friendships" ON public.friendships FOR DELETE USING (
  (select auth.uid()) = user_id OR (select auth.uid()) = friend_id
);

DROP POLICY IF EXISTS "Users can send friend requests" ON public.friendships;
CREATE POLICY "Users can send friend requests" ON public.friendships FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update friendships" ON public.friendships;
CREATE POLICY "Users can update friendships" ON public.friendships FOR UPDATE USING (
  (select auth.uid()) = friend_id OR (select auth.uid()) = user_id
);

-- Moment Reactions
DROP POLICY IF EXISTS "Users can view reactions" ON public.moment_reactions;
CREATE POLICY "Users can view reactions" ON public.moment_reactions FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM moments m 
    WHERE m.id = moment_reactions.moment_id 
    AND (
      m.user_id = (select auth.uid()) 
      OR m.user_id IN (SELECT get_friends_of_user((select auth.uid())))
    )
  )
);

DROP POLICY IF EXISTS "Users can add reactions" ON public.moment_reactions;
CREATE POLICY "Users can add reactions" ON public.moment_reactions FOR INSERT WITH CHECK (
  (select auth.uid()) = user_id 
  AND EXISTS (
    SELECT 1 FROM moments m 
    WHERE m.id = moment_reactions.moment_id 
    AND (
      m.user_id = (select auth.uid()) 
      OR m.user_id IN (SELECT get_friends_of_user((select auth.uid())))
    )
  )
);

DROP POLICY IF EXISTS "Users can update reactions" ON public.moment_reactions;
CREATE POLICY "Users can update reactions" ON public.moment_reactions FOR UPDATE USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete reactions" ON public.moment_reactions;
CREATE POLICY "Users can delete reactions" ON public.moment_reactions FOR DELETE USING ((select auth.uid()) = user_id);

-- Profiles
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile" ON public.profiles FOR UPDATE USING ((select auth.uid()) = id) WITH CHECK ((select auth.uid()) = id);

DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
CREATE POLICY "Users can create their own profile" ON public.profiles FOR INSERT WITH CHECK ((select auth.uid()) = id);

-- Moment Groups
DROP POLICY IF EXISTS "Users can create moment groups" ON public.moment_groups;
CREATE POLICY "Users can create moment groups" ON public.moment_groups FOR INSERT WITH CHECK (
  (select auth.uid()) = created_by OR created_by IS NULL
);

DROP POLICY IF EXISTS "Users can update their own groups" ON public.moment_groups;
CREATE POLICY "Users can update their own groups" ON public.moment_groups FOR UPDATE USING (
  (select auth.uid()) = created_by OR created_by IS NULL
) WITH CHECK (
  (select auth.uid()) = created_by OR created_by IS NULL
);

DROP POLICY IF EXISTS "Users can view moment groups" ON public.moment_groups;
CREATE POLICY "Users can view moment groups" ON public.moment_groups FOR SELECT USING (
  (select auth.uid()) = created_by 
  OR (
    NOT COALESCE(is_private, false) 
    AND created_by IN (SELECT get_friends_of_user((select auth.uid())))
  )
);

DROP POLICY IF EXISTS "Users can delete their own moment groups" ON public.moment_groups;
CREATE POLICY "Users can delete their own moment groups" ON public.moment_groups FOR DELETE USING (
  (select auth.uid()) = created_by OR created_by IS NULL
);

-- Notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
CREATE POLICY "Users can view their own notifications" ON public.notifications FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
CREATE POLICY "Users can update their own notifications" ON public.notifications FOR UPDATE USING ((select auth.uid()) = user_id);

-- User Devices
DROP POLICY IF EXISTS "Users can insert their own devices" ON public.user_devices;
CREATE POLICY "Users can insert their own devices" ON public.user_devices FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own devices" ON public.user_devices;
CREATE POLICY "Users can update their own devices" ON public.user_devices FOR UPDATE USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can delete their own devices" ON public.user_devices;
CREATE POLICY "Users can delete their own devices" ON public.user_devices FOR DELETE USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can select their own devices" ON public.user_devices;
CREATE POLICY "Users can select their own devices" ON public.user_devices FOR SELECT USING ((select auth.uid()) = user_id);

-- Messages
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
CREATE POLICY "Users can view messages in their conversations" ON public.messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_participants.conversation_id = messages.conversation_id 
    AND conversation_participants.user_id = (select auth.uid())
  )
);

DROP POLICY IF EXISTS "Users can send messages to their conversations" ON public.messages;
CREATE POLICY "Users can send messages to their conversations" ON public.messages FOR INSERT WITH CHECK (
  (select auth.uid()) = sender_id 
  AND EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_participants.conversation_id = messages.conversation_id 
    AND conversation_participants.user_id = (select auth.uid())
  )
);

DROP POLICY IF EXISTS "Users can update their own messages" ON public.messages;
CREATE POLICY "Users can update their own messages" ON public.messages FOR UPDATE USING ((select auth.uid()) = sender_id) WITH CHECK ((select auth.uid()) = sender_id);

DROP POLICY IF EXISTS "Users can update messages in their conversations" ON public.messages;
CREATE POLICY "Users can update messages in their conversations" ON public.messages FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_participants.conversation_id = messages.conversation_id 
    AND conversation_participants.user_id = (select auth.uid())
  )
) WITH CHECK (
  EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_participants.conversation_id = messages.conversation_id 
    AND conversation_participants.user_id = (select auth.uid())
  )
);

-- Conversations
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
CREATE POLICY "Users can view their conversations" ON public.conversations FOR SELECT USING (
  (select auth.uid()) = created_by 
  OR EXISTS (
    SELECT 1 FROM conversation_participants 
    WHERE conversation_participants.conversation_id = conversations.id 
    AND conversation_participants.user_id = (select auth.uid())
  )
);

-- Conversation Participants
DROP POLICY IF EXISTS "Users can add participants to conversations" ON public.conversation_participants;
CREATE POLICY "Users can add participants to conversations" ON public.conversation_participants FOR INSERT WITH CHECK (
  (select auth.uid()) = user_id OR can_add_participant(conversation_id)
);

-- Notification Preferences
DROP POLICY IF EXISTS "Users can view their own preferences" ON public.notification_preferences;
CREATE POLICY "Users can view their own preferences" ON public.notification_preferences FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can insert their own preferences" ON public.notification_preferences;
CREATE POLICY "Users can insert their own preferences" ON public.notification_preferences FOR INSERT WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "Users can update their own preferences" ON public.notification_preferences;
CREATE POLICY "Users can update their own preferences" ON public.notification_preferences FOR UPDATE USING ((select auth.uid()) = user_id);
