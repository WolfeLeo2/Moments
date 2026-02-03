# Moments Social Features Recommendations

## Overview

This document outlines strategic recommendations for enhancing the social experience in Moments, focusing on discovery, engagement, and scalability while maintaining the unique location-based identity of the app.

---

## 1. Map Library Marker Recommendations

### Current State: flutter_map + Custom Widget Markers
Your `StackedMomentMarker` is a complex Flutter widget with:
- Rotated card stacks with shadows
- Avatar stacks with cached images
- Reaction bubbles (Lottie animations)
- Heart counts and interactive gestures
- Spring animations via Motor

### If Migrating to Mapbox Maps Flutter or Google Maps Flutter

**Challenge:** Neither SDK supports Flutter widget markers directly. They require **bitmap markers** (pre-rendered images).

#### Recommended Approach: Hybrid Marker System

**Option A: Simplified Bitmap Markers (Recommended)**
```
┌─────────────────────────────────────────────────────────────┐
│  Design pre-rendered marker assets at various states:       │
│                                                             │
│  1. Single moment: Circular photo thumbnail (56px)          │
│  2. Cluster (2-5): Photo with count badge                   │
│  3. Large cluster (6+): Number bubble with gradient         │
│  4. Friend indicator: Colored ring around thumbnail         │
└─────────────────────────────────────────────────────────────┘
```

**Implementation:**
- Use `PointAnnotation` (Mapbox) or `Marker` with `BitmapDescriptor` (Google)
- Pre-generate marker bitmaps using `PictureRecorder` + `Canvas`
- Cache rendered bitmaps by moment ID + state hash
- On tap: Open detail sheet/page (no complex marker interactions)

**Pros:**
- Native performance (60fps scrolling/zooming)
- Battery efficient
- Works offline reliably

**Cons:**
- No real-time animations on markers
- Must pre-render all visual states
- Tap interactions only (no drag/long-press on marker itself)

**Option B: View Annotations (Mapbox Only)**
- Experimental "View Annotations" allow Flutter widgets at coordinates
- Performance concerns at scale (>50 markers)
- Not recommended for your use case

**Option C: Keep flutter_map (Recommended for Your App)**
Given your rich marker interactions and animations, staying with flutter_map is justified because:
1. Custom widget markers are a core feature
2. FMTC provides excellent offline tile caching
3. Performance is acceptable with proper clustering
4. No vendor lock-in or usage costs

---

## 2. Navigation Architecture

### Current: Single Map Page
All features accessed via modal sheets and the BlurredAppBar.

### Recommended: Bottom Tab Navigation

```
┌─────────────────────────────────────────────────────────────┐
│                    BlurredAppBar                            │
│  [Friends]          MOMENTS          [Notifications][👤]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│                    Content Area                             │
│              (Map / Feed / Chat)                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                   Bottom Navigation                         │
│    🗺️ Map    |    📸 Feed    |    💬 Chat                   │
└─────────────────────────────────────────────────────────────┘
```

### Tab Breakdown

| Tab | Purpose | Primary Action |
|-----|---------|----------------|
| **Map** | Location-based discovery | Explore friends' moments geographically |
| **Feed** | Chronological discovery | Instagram-style scrolling of recent moments |
| **Chat** | Direct communication | Message friends, share moments |

### Why This Works
1. **Map remains central** - Default tab, core identity
2. **Feed provides alternative** - For users who prefer chronological browsing
3. **Chat is elevated** - Social apps need messaging front-and-center
4. **Reduced app bar clutter** - Gallery/Chat icons move to tabs

---

## 3. Feed Page Design (Instagram-Inspired)

### Content Structure
```
┌─────────────────────────────────────────────────────────────┐
│ Stories Bar (Horizontal Scroll)                             │
│ [You] [Friend1] [Friend2] [Friend3] [Friend4] ...           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ [Avatar] Friend Name              📍 Location   ⋮   │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │                                                     │   │
│  │              Moment Image/Video                     │   │
│  │              (Double-tap to ❤️)                     │   │
│  │                                                     │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ ❤️ 💬 📤 🗺️                              🔖        │   │
│  │ 42 likes                                            │   │
│  │ Caption text goes here...                           │   │
│  │ 2 hours ago                                         │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  [Next Post...]                                             │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Unique Features for Moments
1. **Location Badge** - Tap to fly to location on map
2. **Map Action** - 🗺️ button opens map centered on moment
3. **Collaborative Indicator** - Show contributor avatars
4. **Time Context** - "2 hours ago at Sunset Beach"

### Feed Ordering Algorithm
```
Score = (recency_weight × time_decay) 
      + (engagement_weight × reaction_count)
      + (relationship_weight × friendship_closeness)
      + (location_weight × proximity_bonus)
```

Consider showing:
- Recent moments first (< 24 hours)
- Highly reacted moments
- Moments from close friends
- Moments near user's current location

---

## 4. Stories Feature (Future Enhancement)

### Concept
24-hour ephemeral moments shown as circular avatars at the top of Feed.

```
┌─────────────────────────────────────────────────────────────┐
│  Stories Implementation:                                    │
│                                                             │
│  1. Same data model as Moment, filtered by timestamp        │
│  2. Gradient ring indicates unwatched stories               │
│  3. Gray ring for viewed stories                            │
│  4. Tap opens fullscreen story viewer                       │
│  5. Auto-advance with progress bar                          │
└─────────────────────────────────────────────────────────────┘
```

### Database Consideration
Add `is_story` boolean or `story_expires_at` timestamp to Moment model.

---

## 5. Social Engagement Features

### 5.1 Reactions System (Already Implemented ✓)
- Heart reactions with counts
- Lottie animations
- Real-time updates via Supabase

### 5.2 Comments (Recommended Addition)
```sql
create table moment_comments (
  id uuid primary key default gen_random_uuid(),
  moment_id uuid references moments(id) on delete cascade,
  user_id uuid references profiles(id),
  content text not null,
  created_at timestamptz default now()
);
```

### 5.3 Mentions & Tags
- @username mentions in captions
- Location tags (already have location field)
- People tags (tap to view profile)

### 5.4 Share to Chat
One-tap sharing of moments to DM conversations.

---

## 6. Discovery Enhancements

### 6.1 Map Filtering UI
```
┌─────────────────────────────────────────────────────────────┐
│  Filter Chips (below app bar):                              │
│                                                             │
│  [Today] [This Week] [All Time]  |  [Close Friends] [All]   │
│                                                             │
│  Optional: [Photos] [Videos] [Collabs]                      │
└─────────────────────────────────────────────────────────────┘
```

### 6.2 Heat Map Mode
For areas with many moments, show density overlay instead of individual markers.

### 6.3 Friend Activity Feed
"Sarah just posted at Golden Gate Bridge" - push notification + in-app feed.

---

## 7. Privacy & Safety

### 7.1 Location Privacy
- [ ] Fuzzy location option (city-level only)
- [ ] Hide exact coordinates from non-friends
- [ ] Ghost mode (temporarily hide from map)

### 7.2 Content Controls
- [ ] Block/mute users
- [ ] Report inappropriate content
- [ ] Limit who can see your moments

---

## 8. Performance Recommendations

### 8.1 Feed Pagination
- Load 10 posts initially
- Infinite scroll with `offset` pagination
- Preload next 5 images while scrolling

### 8.2 Image Optimization
- Use WebP format for thumbnails
- Multiple resolutions (thumbnail, feed, full)
- Blur hash placeholders

### 8.3 Offline Support
- Cache recent feed posts in Drift
- Queue likes/comments when offline
- Sync on reconnection

---

## 9. Implementation Priority

### Phase 1 (Current Sprint)
1. ✅ Bottom navigation scaffold
2. ✅ Instagram-style feed page
3. ✅ Simplified BlurredAppBar

### Phase 2 (Next Sprint)
1. Stories bar component
2. Feed sorting algorithm
3. Map filter chips

### Phase 3 (Future)
1. Comments system
2. Share to chat
3. Heat map mode

---

## 10. Technical Notes

### State Management
Feed should use similar pattern to chat list:
```dart
@riverpod
Stream<List<Moment>> feedStream(Ref ref) async* {
  // 1. Yield cached moments from Drift (instant)
  // 2. Watch Supabase for realtime updates
  // 3. Apply sorting algorithm
}
```

### Navigation
Using GoRouter with `StatefulShellRoute` for bottom navigation preserves tab state.

### Theming
Feed page should follow existing Neubrutalism/Soft design:
- Rounded corners (16-20px)
- Soft shadows
- Off-white backgrounds
- Google Fonts (Inter, Rubik)

---

*Last Updated: February 2, 2026*
