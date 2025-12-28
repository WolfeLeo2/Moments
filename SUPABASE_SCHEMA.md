# Supabase Schema & Configuration

## Tables

### `moments`

Primary table for storing moment data.

- `id` (uuid, PK)
- `user_id` (uuid, FK -> auth.users.id)
- `caption` (text)
- `media_path` (text)
- `latitude` (float8)
- `longitude` (float8)
- `timestamp` (timestamptz)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
- `title` (text)
- `location` (text)
- `description` (text)
- `moment_group_id` (uuid, FK -> moment_groups.id)
- `is_private` (bool)
- `media_type` (text, default: 'image')
- `duration` (int4)
- `thumbnail_path` (text)
- `is_deleted` (bool)
- `geom` (geography)

### `moment_groups`

Groups of moments, often tied to a location.

- `id` (uuid, PK)
- `title` (text)
- `radius_meters` (float8)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
- `place_name` (text)
- `latitude` (float8)
- `longitude` (float8)
- `created_by` (uuid, FK -> auth.users.id)
- `is_private` (bool)
- `geom` (geometry)

### `moment_contributors`

Manages membership in moment groups.

- `id` (uuid, PK)
- `moment_id` (uuid, FK -> moment_groups.id)
- `user_id` (uuid, FK -> auth.users.id)
- `created_at` (timestamptz)
- `role` (text: 'owner', 'contributor')
- `invited_at` (timestamptz)
- `accepted_at` (timestamptz)

### `profiles`

Public user profiles.

- `id` (uuid, PK, FK -> auth.users.id)
- `username` (text, unique)
- `display_name` (text)
- `avatar_url` (text)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
- `bio` (text)
- `invite_code` (text, unique)

### `friendships`

Friend relationships.

- `id` (uuid, PK)
- `user_id` (uuid, FK -> auth.users.id)
- `friend_id` (uuid, FK -> auth.users.id)
- `status` (text: 'pending', 'accepted', 'rejected', 'blocked')
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
- `requested_at` (timestamptz)
- `responded_at` (timestamptz)

### `conversations`

Chat conversations.

- `id` (uuid, PK)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
- `created_by` (uuid, FK -> auth.users.id)

### `conversation_participants`

Users in a conversation.

- `id` (uuid, PK)
- `conversation_id` (uuid, FK -> conversations.id)
- `user_id` (uuid, FK -> auth.users.id)
- `joined_at` (timestamptz)
- `last_read_at` (timestamptz)

### `messages`

Chat messages.

- `id` (uuid, PK)
- `conversation_id` (uuid, FK -> conversations.id)
- `sender_id` (uuid, FK -> auth.users.id)
- `content` (text)
- `message_type` (text: 'text', 'image', 'file', 'audio')
- `media_url` (text)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
- `is_deleted` (bool)
- `is_read` (bool)
- `metadata` (jsonb)

### `moment_reactions`

Emoji reactions to moments.

- `id` (uuid, PK)
- `moment_id` (uuid, FK -> moments.id)
- `user_id` (uuid, FK -> auth.users.id)
- `emoji` (text)
- `created_at` (timestamptz)
- `photo_index` (int4)

### `notifications`

Centralized notifications table.

- `id` (uuid, PK)
- `user_id` (uuid, FK -> auth.users.id)
- `actor_id` (uuid, FK -> auth.users.id)
- `type` (text)
- `title` (text)
- `body` (text)
- `related_id` (text)
- `is_read` (bool)
- `created_at` (timestamptz)
- `image_url` (text)

### `user_devices`

FCM tokens for push notifications.

- `id` (uuid, PK)
- `user_id` (uuid, FK -> auth.users.id)
- `fcm_token` (text, unique)
- `platform` (text)
- `last_active_at` (timestamptz)
- `created_at` (timestamptz)

### `notification_preferences`

User settings for notifications.

- `id` (uuid, PK)
- `user_id` (uuid, FK -> auth.users.id)
- `push_enabled` (bool)
- `friend_request_enabled` (bool)
- `new_message_enabled` (bool)
- `moment_invite_enabled` (bool)
- `system_enabled` (bool)
- `promo_enabled` (bool)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)
