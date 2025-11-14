# Brick Integration & Shared Moments Implementation Plan

## 🚨 Current State: Brick NOT Implemented

### Analysis:

After searching the codebase, **Brick offline-first is NOT currently implemented**. The project only has:

1. ✅ `brick_offline_first_with_supabase` in `pubspec.yaml`
2. ❌ No Brick models (`@ConnectOfflineFirstWithSupabase` annotations)
3. ❌ No Brick repository implementation
4. ❌ No offline caching layer
5. ❌ Direct Supabase calls in `MomentRepository`

### What This Means:

- **No offline support** - App requires internet connection
- **No caching** - Every fetch goes to Supabase
- **No sync queue** - Can't create moments offline
- **Map/markers NOT cached** - Fetched from Supabase every time

---

## 🔧 Required Brick Implementation

### Step 1: Create Brick-Annotated Models

**File: `lib/data/models/moment.dart`** (REPLACE current version)

```dart
import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'moments'),
)
class Moment extends OfflineFirstWithSupabaseModel {
  @Supabase(unique: true)
  @Sqlite(unique: true)
  final String id;

  @Supabase(name: 'user_id')
  @Sqlite(name: 'user_id')
  final String userId;

  final String title;
  final String location;
  final double latitude;
  final double longitude;

  @Supabase(name: 'image_url')
  @Sqlite(name: 'image_url')
  final String? imageUrl;

  @Supabase(name: 'media_path')
  @Sqlite(name: 'media_path')
  final String? mediaPath;

  final String? caption;

  @Supabase(name: 'created_at')
  @Sqlite(name: 'created_at')
  final DateTime createdAt;

  final DateTime timestamp;

  @Supabase(name: 'place_group_id')
  @Sqlite(name: 'place_group_id')
  final String? placeGroupId;

  Moment({
    required this.id,
    required this.userId,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.mediaPath,
    this.caption,
    required this.createdAt,
    required this.timestamp,
    this.placeGroupId,
  });
}
```

### Step 2: Generate Brick Code

```bash
cd /Users/app/AndroidStudioProjects/Moments
flutter pub run build_runner build
```

### Step 3: Initialize Brick in `main.dart`

```dart
import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';
import 'brick/brick.g.dart'; // Generated file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Supabase FIRST
  await SupabaseConfig.initialize();

  // Initialize Brick offline-first
  final repository = OfflineFirstWithSupabaseRepository(
    supabaseProvider: SupabaseProvider(
      SupabaseConfig.client,
      modelDictionary: supabaseModelDictionary,
    ),
    sqliteProvider: SqliteProvider(
      'moments_app.sqlite',
      modelDictionary: sqliteModelDictionary,
    ),
    migrations: migrations,
    offlineRequestQueue: OfflineRequestQueue(),
  );

  runApp(MyApp(repository: repository));
}
```

### Step 4: Update `MomentRepository` to Use Brick

```dart
class MomentRepository {
  final OfflineFirstWithSupabaseRepository _repository;

  MomentRepository(this._repository);

  // Get all moments (OFFLINE-FIRST)
  Future<List<Moment>> getMoments() async {
    return await _repository.get<Moment>(
      policy: OfflineFirstGetPolicy.awaitRemoteWhenNoneExist,
    );
  }

  // Create moment (QUEUED if offline)
  Future<Moment> createMoment(Moment moment) async {
    return await _repository.upsert<Moment>(moment);
  }

  // Sync all pending changes
  Future<void> sync() async {
    await _repository.migrate();
  }
}
```

---

## 📱 Shared Moments & Collaboration Feature

### Database Schema for Sharing

Your current database **DOES NOT** have sharing tables. We need to add:

#### 1. `moment_contributors` Table

```sql
CREATE TABLE moment_contributors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moment_id UUID REFERENCES moments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('owner', 'contributor', 'viewer')),
  invited_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  accepted_at TIMESTAMP WITH TIME ZONE,

  UNIQUE(moment_id, user_id)
);

CREATE INDEX idx_contributors_moment ON moment_contributors(moment_id);
CREATE INDEX idx_contributors_user ON moment_contributors(user_id);
```

#### 2. `moment_groups` Table (for shared locations)

```sql
CREATE TABLE moment_groups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  place_name TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  created_by UUID REFERENCES auth.users(id),
  is_shared BOOLEAN DEFAULT false, -- If true, anyone can contribute
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 3. `friendships` Table

```sql
CREATE TABLE friendships (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  friend_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'blocked')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),

  UNIQUE(user_id, friend_id)
);

CREATE INDEX idx_friendships_user ON friendships(user_id);
```

### RLS Policies for Shared Moments

```sql
-- Users can see moments they own OR contribute to
CREATE POLICY "Users can view their own or shared moments"
  ON moments FOR SELECT
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM moment_contributors
      WHERE moment_contributors.moment_id = moments.id
      AND moment_contributors.user_id = auth.uid()
      AND moment_contributors.accepted_at IS NOT NULL
    )
  );

-- Friends can see each other's moments
CREATE POLICY "Friends can view each other's moments"
  ON moments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM friendships
      WHERE (
        (friendships.user_id = auth.uid() AND friendships.friend_id = moments.user_id)
        OR
        (friendships.friend_id = auth.uid() AND friendships.user_id = moments.user_id)
      )
      AND friendships.status = 'accepted'
    )
  );
```

### Flutter Implementation

#### 1. Invite Friends to Moment

```dart
Future<void> inviteContributor(String momentId, String friendId) async {
  await SupabaseConfig.client
      .from('moment_contributors')
      .insert({
        'moment_id': momentId,
        'user_id': friendId,
        'role': 'contributor',
      });
}
```

#### 2. Accept Invitation

```dart
Future<void> acceptInvitation(String contributorId) async {
  await SupabaseConfig.client
      .from('moment_contributors')
      .update({'accepted_at': DateTime.now().toIso8601String()})
      .eq('id', contributorId);
}
```

#### 3. Add Moment to Shared Location

```dart
Future<Moment> addMomentToSharedLocation({
  required String placeGroupId,
  required String title,
  required File imageFile,
}) async {
  // User can add to shared location group
  final moment = await _momentRepository.createMoment(
    title: title,
    location: placeName,
    placeGroupId: placeGroupId, // Links to shared group
    imageFile: imageFile,
  );
  return moment;
}
```

#### 4. Fetch Shared Moments

```dart
Future<List<Moment>> getSharedMoments() async {
  final response = await SupabaseConfig.client
      .from('moments')
      .select()
      .or('user_id.eq.${currentUserId},place_group_id.in.(${sharedGroupIds})')
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => Moment.fromJson(json))
      .toList();
}
```

---

## 🎯 Implementation Priority

### Phase 1: Brick Setup (Critical)

1. ✅ Add Brick annotations to `Moment` model
2. ✅ Run build_runner to generate code
3. ✅ Initialize Brick repository in main.dart
4. ✅ Update MomentRepository to use Brick
5. ✅ Test offline-first behavior

### Phase 2: Database Schema

1. ✅ Create `moment_contributors` table
2. ✅ Create `moment_groups` table
3. ✅ Create `friendships` table
4. ✅ Set up RLS policies

### Phase 3: Friends Feature

1. ✅ Add friend invite UI
2. ✅ Friend search functionality
3. ✅ Friend list page
4. ✅ Accept/reject invitations

### Phase 4: Shared Moments

1. ✅ Invite friends to moments
2. ✅ Shared location groups
3. ✅ Collaborative moment creation
4. ✅ Filter: My moments / Shared / Friends

---

## 🔍 Caching Strategy

### What Should Be Cached:

1. **Map Markers** - YES (via Brick)

   - All moments cached locally
   - Instant map load
   - Background sync

2. **Images** - PARTIALLY (SignedUrlCache)

   - Currently caching signed URLs (good!)
   - Consider caching actual images (use `cached_network_image`)

3. **User Avatars** - NO (currently not cached)
   - Should cache avatar URLs
   - Add to `profiles` table with Brick

### Recommended Image Caching:

```dart
// Use cached_network_image for better caching
CachedNetworkImage(
  imageUrl: imageUrl,
  cacheManager: CacheManager(
    Config(
      'moment_images',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  ),
  fit: BoxFit.cover,
  placeholder: (context, url) => CircularProgressIndicator(),
)
```

---

## ✅ Summary of Required Actions

### Immediate Fixes:

1. ✅ Reduce spacing between avatars and carousel (DONE - changed to 16px)
2. ✅ Reduce transition duration to 200ms (DONE)
3. ✅ Load real user avatars on map stack (DONE - no fallbacks)

### Critical Missing: Brick Implementation

- ⚠️ **No offline-first caching currently exists**
- ⚠️ **Map markers fetched from network every time**
- ⚠️ **No offline moment creation**

### Database Schema Gaps:

- ❌ No `moment_contributors` table for sharing
- ❌ No `friendships` table for friend network
- ❌ No `moment_groups` for shared locations
- ❌ RLS policies don't support collaboration

### Recommended Next Steps:

1. **Implement Brick** (1-2 days) - Critical for offline-first
2. **Create sharing tables** (1 day) - Enable collaboration
3. **Build friends feature** (2-3 days) - Social layer
4. **Implement invite flow** (1-2 days) - Sharing UX
5. **Add image caching** (1 day) - Performance boost

Would you like me to start implementing any of these features?
