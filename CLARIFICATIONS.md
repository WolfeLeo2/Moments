# Moments App - Clarifications & Updates

**Date:** November 8, 2025  
**Status:** Planning Refinements Based on User Feedback

---

## 🎯 Key Clarifications

### 1. Platform: Cross-Platform Flutter ✅
- **Target:** Both Android and iOS
- **Shared Codebase:** Same logic and UI for both platforms
- **Benefits:** Single codebase, faster development, consistent UX

### 2. Authentication: Post-MVP (Supabase Auth) ✅
- **MVP Approach:** Skip authentication for now
- **Future Implementation:** Supabase Authentication
  - Email/password login
  - Social OAuth (Google, Apple)
  - User profiles
  - Friend system
- **Current Database:** No `user_id` foreign key enforcement
- **Storage:** Public bucket for MVP, will add user folders after auth

### 3. Image Sources: Camera + Gallery ✅
- **Package:** `image_picker` from pub.dev
- **User Choice:** Bottom sheet with two options:
  1. 📷 Take Photo (Camera)
  2. 🖼️ Choose from Gallery
- **Permissions Required:**
  - Android: CAMERA, READ_EXTERNAL_STORAGE
  - iOS: Camera, Photo Library
- **Implementation:**
  ```dart
  // User gets a choice
  showModalBottomSheet(
    context: context,
    builder: (context) => ImageSourcePicker(
      onCameraSelected: () => pickImage(ImageSource.camera),
      onGallerySelected: () => pickImage(ImageSource.gallery),
    ),
  );
  ```

### 4. Storage: Public Bucket Named "moments" ✅
- **Bucket Name:** `moments` (not `moment-photos`)
- **Access Level:** Public read (for social sharing between friends)
- **Security Approach:**
  - MVP: Public upload/read (simpler for testing)
  - Post-Auth: Restrict uploads to authenticated users
  - Future: RLS policies per user
- **Social Context:** Friends can see each other's moments
  - Public URLs are acceptable for friend visibility
  - No sensitive/private data in images

### 5. Map Style: Default Google Maps ✅
- **Initial Style:** Default Google Maps style
- **Future Enhancement:** Custom map styling
  - Can be added via `GoogleMap` `mapStyle` parameter
  - JSON style definitions
  - Easy to swap later without architecture changes

### 6. Initial Map Viewport: User Location ✅
- **Behavior:** Center map on user's current location on app launch
- **Package:** `geolocator` for location services
- **Permission:** Request location permission on first launch
- **Fallback:** If permission denied, center on a default location (e.g., NYC)
- **Implementation Flow:**
  1. Request location permission
  2. Get current position
  3. Animate camera to user location
  4. Set appropriate zoom level (e.g., zoom: 14)

### 7. Offline Behavior: Queue Until Online ✅
- **Create Moment Offline:**
  1. User creates moment while offline
  2. Moment saved to local SQLite immediately
  3. Appears on map instantly (using local data)
  4. Added to sync queue
  5. Background service monitors connection
  6. When online: Upload to Supabase automatically
  7. Update local record with remote ID
- **Perfect Implementation:** Brick offline-first handles this automatically!

### 8. Photo Display: Hero Image + Decorative Stickers ✅
- **NOT Multi-Photo Collage** (for MVP)
- **Instead: Single Hero Image**
  - Main/primary photo displayed prominently
  - Decorative overlays (like "WOW", "Cool Statue" in reference)
  - Stickers can be static text overlays
  - Fun, playful visual elements
- **Multi-Photo Collage:** Post-MVP feature
  - If moment has multiple images, show them in a grid/carousel
  - For now, just use the first image as hero

**Example Structure:**
```dart
class MomentPhotoView extends StatelessWidget {
  final Moment moment;
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hero image
        CachedNetworkImage(
          imageUrl: moment.imageUrl,
          fit: BoxFit.cover,
        ),
        
        // Decorative stickers (future - for now, simple text overlays)
        Positioned(
          bottom: 20,
          right: 20,
          child: Text(
            'WOW',
            style: AppTypography.h1.copyWith(
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4)],
            ),
          ),
        ),
      ],
    );
  }
}
```

### 9. Fonts: Google Fonts Package ✅
- **Package:** `google_fonts` from pub.dev
- **Benefits:**
  - No manual font file downloads
  - No asset configuration in pubspec.yaml
  - Automatic font caching
  - Easy font switching
- **Fonts Used:**
  - **Bebas Neue:** Headings, titles (bold, condensed)
  - **Inter:** Body text, UI elements
- **Implementation:**
  ```dart
  import 'package:google_fonts/google_fonts.dart';
  
  TextStyle heading = GoogleFonts.bebasNeue(
    fontSize: 48,
    fontWeight: FontWeight.bold,
  );
  
  TextStyle body = GoogleFonts.inter(
    fontSize: 16,
  );
  ```

### 10. Friend Moments Clustering ✅
- **Feature:** Moments from same location (among friends) are clustered together
- **Visual:** Like in reference image - multiple small photos in one marker
- **Implementation:**
  - When multiple moments have same/similar coordinates
  - Group them into a cluster marker
  - Show count badge (e.g., "3 moments")
  - On tap: Expand to show all moments
  - Special UI for friend moment clusters
- **Post-Auth:** Will only cluster moments from friends
- **MVP:** Cluster all moments at same location

---

## 📦 Updated Package List

```yaml
name: moments
description: A location-based photo-sharing app

dependencies:
  flutter:
    sdk: flutter
  
  # Backend & Offline-First
  supabase_flutter: ^2.5.0
  brick_offline_first_with_supabase: ^4.0.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^11.0.0
  geocoding: ^3.0.0  # Optional: reverse geocoding for location names
  
  # UI & Design
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  
  # Animation
  motor: ^0.2.0
  flutter_animate: ^4.5.0
  
  # Navigation & State
  go_router: ^13.0.0
  provider: ^6.1.0
  
  # Media
  image_picker: ^1.0.7  # Camera & gallery support
  image: ^4.1.0  # Image compression
  
  # Utilities
  flutter_dotenv: ^5.1.0
  permission_handler: ^11.2.0
  logger: ^2.0.0
  uuid: ^4.3.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.0
  brick_offline_first_with_supabase_generator: ^4.0.0
  
  # Linting
  flutter_lints: ^6.0.0
```

---

## 🔄 Updated Implementation Priority

### Phase 1: Foundation (Days 1-3)
1. ✅ Set up pubspec.yaml with all packages
2. ✅ Configure Android (permissions, Maps key)
3. ✅ Configure iOS (permissions, Maps key)
4. ✅ Create theme with Google Fonts
5. ✅ Set up Supabase (database + storage bucket "moments")
6. ✅ Configure Brick offline-first

### Phase 2: Map + Location (Days 4-6)
1. ✅ Implement location permission request
2. ✅ Get user's current location
3. ✅ Initialize Google Maps centered on user
4. ✅ Create basic map page
5. ✅ Test on both Android and iOS

### Phase 3: Data Layer (Days 7-9)
1. ✅ Create Moment model (without user_id for now)
2. ✅ Set up Brick repositories
3. ✅ Connect to Supabase
4. ✅ Test offline-first sync

### Phase 4: Create Moment (Days 10-14)
1. ✅ Image picker with camera/gallery choice
2. ✅ Location selection (use map location or current)
3. ✅ Image compression
4. ✅ Upload to "moments" bucket
5. ✅ Save to database
6. ✅ Test offline creation → online sync

### Phase 5: Display Moments (Days 15-18)
1. ✅ Load moments from repository
2. ✅ Display as map markers
3. ✅ Implement basic clustering (same location)
4. ✅ Tap marker → view detail
5. ✅ Detail page with hero image

### Phase 6: Polish (Days 19-21)
1. ✅ Add Motor animations
2. ✅ Decorative text overlays
3. ✅ Test on both platforms
4. ✅ Performance optimization
5. ✅ Final testing

---

## 🚫 Explicitly Out of MVP Scope

- ❌ User authentication (Supabase Auth)
- ❌ User profiles
- ❌ Friend system
- ❌ Comments
- ❌ Likes/reactions
- ❌ Multi-photo collage (just hero image)
- ❌ Custom map styles
- ❌ Decorative sticker picker (static overlays only)
- ❌ Sharing to other apps
- ❌ Push notifications

---

## ✅ MVP Feature Set (Final)

1. **Map View**
   - Google Maps (default style)
   - Centered on user location
   - Show all moments as markers
   - Cluster moments at same location
   - Tap marker → view detail

2. **Create Moment**
   - Pick image from camera OR gallery
   - Add title
   - Add/edit location
   - Save (works offline, syncs when online)

3. **View Moment**
   - Hero image display
   - Title (Bebas Neue font)
   - Location name
   - Date
   - Simple static text overlay (like "WOW")

4. **Offline-First**
   - All data cached locally
   - Create/view works offline
   - Auto-sync when online
   - Queue-based upload

5. **Cross-Platform**
   - Android support
   - iOS support
   - Same codebase, same UX

---

## 🔐 Permissions Required

### Android (`AndroidManifest.xml`)
```xml
<!-- Location -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

<!-- Camera -->
<uses-permission android:name="android.permission.CAMERA" />

<!-- Storage (for older Android versions) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />

<!-- Internet -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### iOS (`Info.plist`)
```xml
<!-- Location -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show moments near you and to tag your photos</string>

<!-- Camera -->
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to take photos for moments</string>

<!-- Photo Library -->
<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photo library to select photos for moments</string>
```

---

## 🗺️ Map Initialization Code (Reference)

```dart
class MapPage extends StatefulWidget {
  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = LatLng(40.7128, -74.0060); // Default: NYC
  bool _locationLoaded = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      // Request permission
      LocationPermission permission = await Geolocator.requestPermission();
      
      if (permission == LocationPermission.denied) {
        // Use default location
        return;
      }
      
      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _locationLoaded = true;
      });
      
      // Animate camera to user location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 14),
      );
    } catch (e) {
      // Handle error, use default location
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 14,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          if (_locationLoaded) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLngZoom(_initialPosition, 14),
            );
          }
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        // markers, etc.
      ),
    );
  }
}
```

---

## 📝 Updated Database Schema Notes

### Moments Table (MVP - No Auth)
```sql
CREATE TABLE moments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  -- user_id removed for MVP, will add after auth
  title TEXT NOT NULL,
  location TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  image_url TEXT NOT NULL,  -- Single hero image
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for geospatial queries (clustering)
CREATE INDEX idx_moments_location ON moments USING GIST (
  ll_to_earth(latitude, longitude)
);
```

### Post-Auth Migration
When we add Supabase Auth, we'll run:
```sql
ALTER TABLE moments ADD COLUMN user_id UUID REFERENCES auth.users(id);
UPDATE moments SET user_id = '00000000-0000-0000-0000-000000000000' WHERE user_id IS NULL;
ALTER TABLE moments ALTER COLUMN user_id SET NOT NULL;
```

---

## 🎨 Design Clarifications

### Moment Marker on Map
```
┌────────────────────┐
│   [Thumbnail]      │  ← Small photo preview
│                    │
│   PLACE OF POWER   │  ← Title (Bebas Neue, uppercase)
│   May 25           │  ← Date
└────────────────────┘
```

### Moment Detail Page
```
┌─────────────────────────────────┐
│  ← Back              Share      │  ← Header
│                                 │
│  PLACE OF POWER                 │  ← Large title
│  By @photos • May 25, 2024      │  ← Metadata
│  👤👤👤                          │  ← User avatars
│                                 │
│  ┌──────────────────────────┐  │
│  │                          │  │
│  │    [Hero Image]          │  │  ← Main photo
│  │                          │  │
│  │         WOW ←──────────  │  │  ← Decorative text
│  └──────────────────────────┘  │
│                                 │
│  📍 Midtown Manhattan           │  ← Location
│                                 │
│  😀  ✏️  Aa  [Preview]         │  ← Action toolbar
└─────────────────────────────────┘
```

---

This document captures all your clarifications and updates the plan accordingly. Ready to start Phase 1 implementation! 🚀
