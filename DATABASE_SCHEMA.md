# Moments - Database & API Schema

## Supabase Database Schema

### Tables

#### 1. `moments` Table
Primary table for storing moment data.

```sql
CREATE TABLE moments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) >= 3 AND char_length(title) <= 100),
  location TEXT NOT NULL CHECK (char_length(location) > 0),
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
  image_url TEXT, -- Primary/thumbnail image
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_moments_user_id ON moments(user_id);
CREATE INDEX idx_moments_created_at ON moments(created_at DESC);
CREATE INDEX idx_moments_location ON moments USING GIST (
  ll_to_earth(latitude, longitude)
); -- Geospatial index for nearby searches

-- Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_moments_updated_at 
  BEFORE UPDATE ON moments 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();
```

**Columns:**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique identifier |
| `user_id` | UUID | FOREIGN KEY, NOT NULL | Creator's user ID |
| `title` | TEXT | NOT NULL, length 3-100 | Moment title |
| `location` | TEXT | NOT NULL | Human-readable location |
| `latitude` | DOUBLE PRECISION | NOT NULL, -90 to 90 | GPS latitude |
| `longitude` | DOUBLE PRECISION | NOT NULL, -180 to 180 | GPS longitude |
| `image_url` | TEXT | NULLABLE | Primary image URL |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Creation timestamp |
| `updated_at` | TIMESTAMP | DEFAULT NOW() | Last update timestamp |

---

#### 2. `moment_images` Table
Stores multiple images per moment (for photo collages).

```sql
CREATE TABLE moment_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  moment_id UUID REFERENCES moments(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  "order" INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_moment_images_moment_id ON moment_images(moment_id);
CREATE INDEX idx_moment_images_order ON moment_images(moment_id, "order");
```

**Columns:**
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| `id` | UUID | PRIMARY KEY | Unique identifier |
| `moment_id` | UUID | FOREIGN KEY, NOT NULL | Parent moment ID |
| `image_url` | TEXT | NOT NULL | Image URL in storage |
| `order` | INTEGER | DEFAULT 0 | Display order in collage |
| `created_at` | TIMESTAMP | DEFAULT NOW() | Upload timestamp |

---

#### 3. `profiles` Table (Future)
User profile information.

```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL CHECK (char_length(username) >= 3),
  display_name TEXT,
  avatar_url TEXT,
  bio TEXT CHECK (char_length(bio) <= 500),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_profiles_username ON profiles(username);
```

---

### Row Level Security (RLS) Policies

#### Moments Table Policies

```sql
-- Enable RLS
ALTER TABLE moments ENABLE ROW LEVEL SECURITY;

-- Policy: Users can read all moments
CREATE POLICY "Moments are viewable by everyone"
  ON moments FOR SELECT
  USING (true);

-- Policy: Authenticated users can create moments
CREATE POLICY "Authenticated users can create moments"
  ON moments FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own moments
CREATE POLICY "Users can update their own moments"
  ON moments FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own moments
CREATE POLICY "Users can delete their own moments"
  ON moments FOR DELETE
  USING (auth.uid() = user_id);
```

#### Moment Images Table Policies

```sql
-- Enable RLS
ALTER TABLE moment_images ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view images
CREATE POLICY "Images are viewable by everyone"
  ON moment_images FOR SELECT
  USING (true);

-- Policy: Users can add images to their moments
CREATE POLICY "Users can add images to their moments"
  ON moment_images FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM moments
      WHERE moments.id = moment_images.moment_id
      AND moments.user_id = auth.uid()
    )
  );

-- Policy: Users can delete their moment images
CREATE POLICY "Users can delete their moment images"
  ON moment_images FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM moments
      WHERE moments.id = moment_images.moment_id
      AND moments.user_id = auth.uid()
    )
  );
```

---

### Storage Buckets

#### `moment-photos` Bucket

```sql
-- Create bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('moment-photos', 'moment-photos', true);

-- Storage policies
CREATE POLICY "Anyone can view moment photos"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'moment-photos');

CREATE POLICY "Authenticated users can upload photos"
  WITH CHECK (
  WITH CHECK (
    bucket_id = 'moment-photos' 
    AND auth.role() = 'authenticated'
  );
    AND auth.role() = 'authenticated'
CREATE POLICY "Users can update their own photos"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'moment-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'moment-photos' 
    AND auth.uid()::text = (storage.foldername(name))[1]
  );
- **Allowed MIME Types:** `image/jpeg`, `image/png`, `image/webp`

**File Organization:**
- **Name:** `moment-photos`
- **Public:** Yes (read-only)
  ├── {user_id}/
  │   ├── {moment_id}_1234567890.jpg
  │   ├── {moment_id}_1234567891.jpg
**File Organization:**
```
moment-photos/
#### Get All Moments
```typescript
// Query all moments
const { data, error } = await supabase
  .from('moments')
  .select('*')
  .order('created_at', { ascending: false });
```

#### Get Moment by ID
```typescript
const { data, error } = await supabase
  .from('moments')
  .select(`
    *,
    moment_images (
      id,
      image_url,
      order
    )
  `)
  .eq('id', momentId)
  .single();
```

#### Get Moments in Geographic Bounds
```typescript
// Get moments within a bounding box
const { data, error } = await supabase
  .from('moments')
  .select('*')
  .gte('latitude', southWestLat)
  .lte('latitude', northEastLat)
  .gte('longitude', southWestLng)
  .lte('longitude', northEastLng);
```

#### Get Nearby Moments
```typescript
// Using earth_distance (requires earthdistance extension)
const { data, error } = await supabase
  .rpc('nearby_moments', {
    lat: userLatitude,
    lng: userLongitude,
    radius_meters: 5000
  });

-- Function definition:
CREATE OR REPLACE FUNCTION nearby_moments(
  lat DOUBLE PRECISION,
  lng DOUBLE PRECISION,
  radius_meters INTEGER
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  location TEXT,
  latitude DOUBLE PRECISION,
  longitude DOUBLE PRECISION,
  image_url TEXT,
  distance_meters DOUBLE PRECISION
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    m.id,
    m.title,
    m.location,
    m.latitude,
    m.longitude,
    m.image_url,
    earth_distance(
      ll_to_earth(lat, lng),
      ll_to_earth(m.latitude, m.longitude)
    ) AS distance_meters
  FROM moments m
  WHERE earth_box(ll_to_earth(lat, lng), radius_meters) @> ll_to_earth(m.latitude, m.longitude)
  ORDER BY distance_meters ASC;
END;
$$ LANGUAGE plpgsql;
```

#### Create Moment
```typescript
const { data, error } = await supabase
  .from('moments')
  .insert({
    user_id: userId,
    title: 'Amazing Sunset',
    location: 'Central Park, NYC',
    latitude: 40.785091,
    longitude: -73.968285,
    image_url: imageUrl
  })
  .select()
  .single();
```

#### Update Moment
```typescript
const { data, error } = await supabase
  .from('moments')
  .update({
    title: 'Updated Title',
    location: 'New Location'
  })
  .eq('id', momentId)
  .select()
  .single();
```

#### Delete Moment
```typescript
const { error } = await supabase
  .from('moments')
  .delete()
  .eq('id', momentId);
```

---

### Moment Images

#### Add Images to Moment
```typescript
const images = [
  { moment_id: momentId, image_url: url1, order: 0 },
  { moment_id: momentId, image_url: url2, order: 1 },
];

const { data, error } = await supabase
  .from('moment_images')
  .insert(images)
  .select();
```

#### Get Moment Images
```typescript
const { data, error } = await supabase
  .from('moment_images')
  .select('*')
  .eq('moment_id', momentId)
  .order('order', { ascending: true });
```

---

### Storage

#### Upload Image
```typescript
const file = /* File object */;
const fileName = `${userId}/${momentId}_${Date.now()}.jpg`;

const { data, error } = await supabase.storage
  .from('moment-photos')
  .upload(fileName, file, {
    cacheControl: '3600',
    upsert: false
  });

// Get public URL
const { data: urlData } = supabase.storage
  .from('moment-photos')
  .getPublicUrl(fileName);
```

#### Delete Image
```typescript
const { error } = await supabase.storage
  .from('moment-photos')
  .remove([fileName]);
```

---

## Real-time Subscriptions (Optional)

### Listen to New Moments
```typescript
const subscription = supabase
  .channel('moments_changes')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'moments'
    },
    (payload) => {
      console.log('New moment created:', payload.new);
      // Update UI with new moment
    }
  )
  .subscribe();
```

### Listen to Moment Updates
```typescript
const subscription = supabase
  .channel('moment_updates')
  .on(
    'postgres_changes',
    {
      event: 'UPDATE',
      schema: 'public',
      table: 'moments',
      filter: `id=eq.${momentId}`
    },
    (payload) => {
      console.log('Moment updated:', payload.new);
    }
  )
  .subscribe();
```

---

## Dart/Flutter Data Models

### Moment Model (with Brick)

```dart
import 'package:brick_offline_first_with_supabase/brick_offline_first_with_supabase.dart';

@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'moments'),
)
class Moment extends OfflineFirstModel {
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

  @Supabase(name: 'created_at')
  @Sqlite(name: 'created_at')
  final DateTime createdAt;

  @Supabase(name: 'updated_at')
  @Sqlite(name: 'updated_at')
  final DateTime updatedAt;

  // Not stored in Supabase, populated via join
  @Supabase(ignore: true)
  final List<MomentImage>? images;

  Moment({
    required this.id,
    required this.userId,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.images,
  });

  // Brick will generate:
  // - toJson()
  // - fromJson()
  // - copyWith()
}
```

### MomentImage Model

```dart
@ConnectOfflineFirstWithSupabase(
  supabaseConfig: SupabaseSerializable(tableName: 'moment_images'),
)
class MomentImage extends OfflineFirstModel {
  @Supabase(unique: true)
  @Sqlite(unique: true)
  final String id;

  @Supabase(name: 'moment_id')
  @Sqlite(name: 'moment_id')
  final String momentId;

  @Supabase(name: 'image_url')
  @Sqlite(name: 'image_url')
  final String imageUrl;

  final int order;

  @Supabase(name: 'created_at')
  @Sqlite(name: 'created_at')
  final DateTime createdAt;

  MomentImage({
    required this.id,
    required this.momentId,
    required this.imageUrl,
    required this.order,
    required this.createdAt,
  });
}
```

---

## Migration Scripts

### Initial Setup

```sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "earthdistance" CASCADE;

-- Run table creation scripts (see above)
-- Run RLS policies (see above)
-- Create storage bucket (see above)
```

### Migration 001: Add Profiles Table

```sql
-- migrations/001_add_profiles.sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE moments 
  ADD COLUMN IF NOT EXISTS profile_id UUID REFERENCES profiles(id);
```

---

## Query Performance Tips

1. **Use indexes for frequently queried fields**
   - User ID, creation date, location

2. **Limit results with pagination**
   ```typescript
   .range(0, 19) // First 20 items
   ```

3. **Select only needed columns**
   ```typescript
   .select('id, title, latitude, longitude, image_url')
   ```

4. **Use geospatial functions for location queries**
   - More efficient than manual distance calculations

5. **Cache frequent queries**
   - Use Brick's offline-first capabilities

---

## Security Considerations

1. **Never expose service key in client**
   - Only use anon key in Flutter app

2. **Validate data on backend**
   - Use check constraints in database
   - Implement RLS policies

3. **Sanitize user inputs**
   - Check for SQL injection in text fields
   - Validate coordinates are within valid ranges

4. **Implement rate limiting**
   - Prevent spam moment creation
   - Limit storage uploads per user

5. **Use authenticated requests only**
   - Require auth for create/update/delete
   - Public read access is OK for MVP

---

## Testing Queries

Use Supabase SQL Editor or your MCP Supabase server to test:

```sql
-- Test: Get moments count
SELECT COUNT(*) FROM moments;

-- Test: Get moments with image count
SELECT 
  m.*,
  COUNT(mi.id) as image_count
FROM moments m
LEFT JOIN moment_images mi ON m.id = mi.moment_id
GROUP BY m.id
ORDER BY m.created_at DESC;

-- Test: Find moments near a point
SELECT * FROM nearby_moments(40.7128, -74.0060, 5000);
```

---

This schema provides a solid foundation for the Moments MVP with room for future expansion!

