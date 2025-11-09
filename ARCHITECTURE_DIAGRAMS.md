# Moments App - Architecture Diagrams

This document contains visual representations of the Moments app architecture.

---

## 📐 System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         MOMENTS APP                          │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                        │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   MapPage    │  │ MomentDetail │  │ AddMoment    │      │
│  │              │  │     Page     │  │    Page      │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
┌────────────────────────────┼─────────────────────────────────┐
│                    STATE MANAGEMENT                          │
├────────────────────────────┼─────────────────────────────────┤
│                     Provider/Riverpod                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  AppProvider │  │   Moments    │  │     Map      │      │
│  │              │  │   Provider   │  │   Provider   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
┌────────────────────────────┼─────────────────────────────────┐
│                     BUSINESS LOGIC                           │
├────────────────────────────┼─────────────────────────────────┤
│                    MomentRepository                          │
│                            │                                 │
│         ┌──────────────────┼──────────────────┐             │
│         │                  │                  │             │
│    ┌────▼────┐      ┌─────▼─────┐     ┌─────▼─────┐       │
│    │  CRUD   │      │   Image   │     │   Sync    │       │
│    │  Logic  │      │  Upload   │     │   Logic   │       │
│    └─────────┘      └───────────┘     └───────────┘       │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
┌────────────────────────────┼─────────────────────────────────┐
│                    OFFLINE-FIRST LAYER                       │
├────────────────────────────┼─────────────────────────────────┤
│                      Brick Framework                         │
│         ┌──────────────────┼──────────────────┐             │
│         │                  │                  │             │
│    ┌────▼────┐      ┌─────▼─────┐     ┌─────▼─────┐       │
│    │ Cache   │      │   Sync    │     │ Conflict  │       │
│    │ Manager │      │   Queue   │     │ Resolution│       │
│    └────┬────┘      └─────┬─────┘     └─────┬─────┘       │
│         │                  │                  │             │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼─────────────┐
│         │         DATA SOURCES                │             │
├─────────┼──────────────────┼──────────────────┼─────────────┤
│    ┌────▼────────┐    ┌───▼──────────────────▼────┐        │
│    │   SQLite    │    │       Supabase            │        │
│    │   (Local)   │    │       (Remote)            │        │
│    ├─────────────┤    ├───────────────────────────┤        │
│    │ • moments   │    │ • PostgreSQL Database     │        │
│    │ • images    │    │ • Storage Bucket          │        │
│    │ • metadata  │    │ • Real-time Subscriptions │        │
│    └─────────────┘    └───────────────────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow Diagram

```
┌───────────────────────────────────────────────────────────┐
│                    CREATE MOMENT FLOW                      │
└───────────────────────────────────────────────────────────┘

User Taps "+ New Moment"
         │
         ▼
    AddMomentPage
         │
         ├─► Select Images ─────► ImagePicker
         │                             │
         ├─► Pick Location ────► LocationPicker
         │                             │
         ├─► Enter Title ──────► Form Validation
         │                             │
         ▼                             ▼
    User Taps "Save"
         │
         ▼
   MomentsProvider.createMoment()
         │
         ▼
   MomentRepository.createMoment()
         │
         ├─► Validate Input
         │
         ├─► Compress Images
         │
         ▼
   Save to Brick (Local First)
         │
         ├─► SQLite.insert() ──────► ✅ Local Success
         │                                  │
         ├─► Add to Sync Queue              │
         │                                  │
         ▼                                  ▼
   Return Success to UI         Show Moment on Map
         │
         ▼
   Background: Upload to Supabase
         │
         ├─► Upload Images to Storage
         │         │
         │         ├─► Success: Get URLs
         │         └─► Failure: Retry Queue
         │
         ├─► Insert to moments table
         │         │
         │         ├─► Success: Mark synced
         │         └─► Failure: Retry Queue
         │
         ▼
   ✅ Fully Synced
```

---

## 🗺️ Navigation Flow

```
                    ┌──────────────┐
                    │   App Start  │
                    └──────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
                  │ Initialize App │
                  │ - Supabase     │
                  │ - Brick        │
                  │ - Load Cache   │
                  └────────┬───────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │          MapPage (/)                 │
        │  ┌────────────────────────────────┐  │
        │  │    Google Maps Display          │  │
        │  │    • Show cached moments        │  │
        │  │    • Cluster markers            │  │
        │  │    • Background sync            │  │
        │  └────────────────────────────────┘  │
        └──┬───────────────────────────────┬───┘
           │                               │
      Tap Marker                    Tap "+ New"
           │                               │
           ▼                               ▼
┌──────────────────────┐      ┌──────────────────────┐
│ MomentDetailPage     │      │  AddMomentPage       │
│  (/moment/:id)       │      │     (/new)           │
├──────────────────────┤      ├──────────────────────┤
│ • Hero animation     │      │ • Pick images        │
│ • Slide up          │      │ • Select location    │
│ • Photo collage     │      │ • Enter details      │
│ • Location info     │      │ • Submit             │
│ • Action toolbar    │      └──────────┬───────────┘
└──────────┬───────────┘                 │
           │                             │
      Tap Back                      On Success
           │                             │
           └─────────────┬───────────────┘
                         │
                         ▼
                  Back to MapPage
              (with updated moments)
```

---

## 🎨 Component Hierarchy

```
MaterialApp (with go_router)
│
├── MapPage
│   ├── GoogleMap
│   │   └── Custom Markers
│   │       └── MomentMarker
│   │           ├── CachedNetworkImage
│   │           ├── Title Text (Bebas Neue)
│   │           └── Date Badge
│   │
│   ├── AppBar
│   │   ├── App Title
│   │   └── Profile Icon
│   │
│   └── AddMomentButton (FAB)
│       └── BouncingCard
│           └── Icon + Label
│
├── MomentDetailPage
│   ├── Stack
│   │   ├── PhotoCollage
│   │   │   └── PageView/GridView
│   │   │       └── CachedNetworkImage(s)
│   │   │
│   │   ├── MomentHeader
│   │   │   ├── Title (animated)
│   │   │   ├── Metadata
│   │   │   └── User Avatars
│   │   │
│   │   ├── LocationInfo
│   │   │   ├── Icon
│   │   │   └── Location Text
│   │   │
│   │   └── ActionToolbar
│   │       ├── EmojiButton
│   │       ├── EditButton
│   │       ├── TextButton
│   │       └── PreviewButton (AppButton)
│   │
│   └── BackButton (animated)
│
└── AddMomentPage
    ├── AppBar
    │   ├── Title
    │   └── Close Button
    │
    ├── Form
    │   ├── ImagePickerWidget
    │   │   ├── Selected Images Grid
    │   │   └── Add Image Button
    │   │
    │   ├── TextField (Title)
    │   ├── TextField (Location)
    │   │
    │   └── LocationPickerWidget
    │       ├── Mini Map
    │       └── Use Current Location Button
    │
    ├── LoadingOverlay (conditional)
    │
    └── Bottom Actions
        ├── Cancel Button
        └── Save Button (AppButton)
```

---

## 🔌 State Management Pattern

```
┌────────────────────────────────────────────────────┐
│                   PROVIDER PATTERN                  │
└────────────────────────────────────────────────────┘

MultiProvider
├── AppProvider (ChangeNotifier)
│   ├── State:
│   │   ├── bool isInitialized
│   │   ├── User? currentUser
│   │   └── bool isOnline
│   │
│   └── Methods:
│       ├── initialize()
│       ├── checkConnectivity()
│       └── updateOnlineStatus()
│
├── MomentsProvider (ChangeNotifier)
│   ├── State:
│   │   ├── List<Moment> moments
│   │   ├── bool isLoading
│   │   ├── String? error
│   │   └── Moment? selectedMoment
│   │
│   └── Methods:
│       ├── loadMoments()
│       ├── createMoment(dto)
│       ├── updateMoment(id, dto)
│       ├── deleteMoment(id)
│       ├── selectMoment(id)
│       └── syncWithRemote()
│
└── MapProvider (ChangeNotifier)
    ├── State:
    │   ├── LatLng cameraPosition
    │   ├── double zoomLevel
    │   ├── Set<Marker> visibleMarkers
    │   └── LatLngBounds? bounds
    │
    └── Methods:
        ├── updateCameraPosition()
        ├── updateZoomLevel()
        ├── updateBounds()
        └── clusterMarkers()


Widget Tree (Consumer Pattern)
└── Consumer<MomentsProvider>
    └── builder: (context, momentsProvider, child) {
        return ListView.builder(
          itemCount: momentsProvider.moments.length,
          itemBuilder: (context, index) {
            final moment = momentsProvider.moments[index];
            return MomentCard(moment: moment);
          },
        );
      }
```

---

## 🗄️ Database Relationships

```
┌─────────────────────────────────────────────────┐
│                 DATABASE SCHEMA                  │
└─────────────────────────────────────────────────┘

auth.users (Supabase Auth)
    │
    │ 1:N
    ▼
moments
├── id (PK)
├── user_id (FK) ────────────► auth.users.id
├── title
├── location
├── latitude
├── longitude
├── image_url
├── created_at
└── updated_at
    │
    │ 1:N
    ▼
moment_images
├── id (PK)
├── moment_id (FK) ──────────► moments.id
├── image_url
├── order
└── created_at


Storage: moment-photos
└── {user_id}/
    └── {moment_id}_{timestamp}.jpg
            ▲
            │
            └─────────── Referenced by image_url
```

---

## ⚡ Animation Timeline

```
┌─────────────────────────────────────────────────┐
│           MARKER TAP ANIMATION FLOW              │
└─────────────────────────────────────────────────┘

Time: 0ms
    │
    ├─► User taps marker
    │
▼ 0-100ms
    │
    ├─► Scale: 1.0 → 0.95 (Motor gentle spring)
    │
▼ 100-200ms
    │
    ├─► Scale: 0.95 → 1.0 (Motor bouncy spring)
    │
▼ 200ms
    │
    ├─► Navigation triggered
    │
▼ 200-550ms
    │
    ├─► Page transition (slide up)
    │   ├─► Background fade: 0 → 0.5
    │   ├─► Page offset: screenHeight → 0
    │   └─► Motor spring curve
    │
▼ 550ms
    │
    └─► Detail page fully visible


┌─────────────────────────────────────────────────┐
│          IMAGE LOAD ANIMATION FLOW               │
└─────────────────────────────────────────────────┘

Time: 0ms
    │
    ├─► Show shimmer placeholder
    │
▼ 0-800ms (network load time)
    │
    ├─► Image downloading
    │
▼ 800ms (image ready)
    │
    ├─► Fade in: opacity 0 → 1 (300ms)
    │
▼ 1100ms
    │
    └─► Image fully visible
```

---

## 🔄 Offline Sync Strategy

```
┌─────────────────────────────────────────────────┐
│            OFFLINE-FIRST SYNC FLOW               │
└─────────────────────────────────────────────────┘

                    App Launch
                        │
                        ▼
            ┌────────────────────┐
            │  Load from SQLite  │ ◄─── Always first
            └────────┬───────────┘
                     │
                     ▼
            Display Cached Data ────► User sees content
                     │                 immediately
                     │
                     ▼
            ┌────────────────────┐
            │ Check Network      │
            └────────┬───────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
    ▼ Online                  ▼ Offline
┌──────────────┐         ┌──────────────┐
│ Sync Queue   │         │ Queue Mode   │
│ Processing   │         │ Active       │
└──────┬───────┘         └──────────────┘
       │                        │
       ▼                        │
┌──────────────┐                │
│ Upload       │                │
│ Pending      │                │
│ Changes      │                │
└──────┬───────┘                │
       │                        │
       ▼                        │
┌──────────────┐                │
│ Download     │                │
│ Remote       │                │
│ Updates      │                │
└──────┬───────┘                │
       │                        │
       ▼                        │
┌──────────────┐                │
│ Merge &      │                │
│ Update Local │                │
└──────┬───────┘                │
       │                        │
       ▼                        │
  Notify UI    ◄────────────────┘
       │
       ▼
  User sees
  latest data
```

---

## 🎯 Performance Optimization Points

```
┌─────────────────────────────────────────────────┐
│          PERFORMANCE OPTIMIZATION MAP            │
└─────────────────────────────────────────────────┘

Map Rendering
├── Marker Clustering
│   ├── Group at zoom < 15
│   └── Individual at zoom >= 15
│
├── Viewport Filtering
│   ├── Only render visible markers
│   └── Update on camera move (debounced)
│
└── Lazy Image Loading
    ├── Load images when marker in view
    └── Unload when out of view


Image Handling
├── Compression
│   ├── Max dimension: 1920px
│   └── Quality: 85%
│
├── Caching
│   ├── Memory cache
│   ├── Disk cache
│   └── Cache key: image URL
│
└── Progressive Loading
    ├── Show thumbnail first
    └── Load full resolution


State Management
├── Targeted Rebuilds
│   ├── Use Consumer/Selector
│   └── Avoid rebuilding entire tree
│
├── Const Constructors
│   └── Wherever possible
│
└── Dispose Resources
    ├── Controllers
    ├── Streams
    └── Timers
```

---

These diagrams provide a visual understanding of the Moments app architecture, data flows, and implementation details!
