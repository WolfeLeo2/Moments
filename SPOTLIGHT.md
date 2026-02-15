# Spotlight — Stories & Short-form Content

## Overview

Spotlight is a dedicated page for short-lived, quick-capture content — similar to Instagram Stories or Snapchat. Posts expire after 24 hours, encouraging authentic, in-the-moment sharing without the pressure of permanence.

**Phase 1 (Current):** 24-hour ephemeral stories — photos, short videos, and moment posts.
**Phase 2 (Future):** Full social feed with TikTok-style vertical swipe or IG-style grid feed.

---

## Phase 1: Stories / Snaps (24-hour Expiry)

### Core Concept

- Quick-capture: open camera → snap → post. Under 3 seconds to share.
- Content expires after 24 hours automatically.
- Friends can view, react, and reply (replies go to chat).
- Viewers list visible to the poster.
- Optional: add text overlays, stickers, location tag, music snippet.

### Data Model

```sql
CREATE TABLE public.stories (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid REFERENCES auth.users(id) NOT NULL,
  media_url   text NOT NULL,
  media_type  text NOT NULL CHECK (media_type IN ('photo', 'video')),
  thumbnail_url text,
  caption     text,
  location    text,
  latitude    double precision,
  longitude   double precision,
  music_id    text,                    -- Spotify/Apple Music clip reference
  duration_ms int DEFAULT 5000,        -- Display duration (photos default 5s)
  created_at  timestamptz DEFAULT now(),
  expires_at  timestamptz DEFAULT now() + interval '24 hours',
  view_count  int DEFAULT 0
);

CREATE TABLE public.story_views (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  story_id   uuid REFERENCES public.stories(id) ON DELETE CASCADE,
  viewer_id  uuid REFERENCES auth.users(id),
  viewed_at  timestamptz DEFAULT now(),
  reaction   text  -- emoji reaction (optional)
);

-- Index for fast "active stories" queries
CREATE INDEX idx_stories_active ON public.stories(user_id, expires_at)
  WHERE expires_at > now();

-- Auto-delete expired stories (Supabase Edge Function or pg_cron)
-- SELECT cron.schedule('delete-expired-stories', '*/30 * * * *',
--   'DELETE FROM public.stories WHERE expires_at < now()');
```

### UI Architecture

#### Stories Ring (Top of Explore Page)

```
┌────────────────────────────────────────────────┐
│  [+]    (You)   (Amy)   (Ben)   (Cat)   (Dan)  │
│  ┌──┐   ┌──┐   ┌──┐   ┌──┐   ┌──┐   ┌──┐     │
│  │📷│   │🟠│   │🔵│   │🔵│   │⚪│   │🔵│     │
│  └──┘   └──┘   └──┘   └──┘   └──┘   └──┘     │
│  Add   Your    Amy    Ben    Cat    Dan         │
│         Story                (seen)             │
└────────────────────────────────────────────────┘

🟠 = Your story (has content)
🔵 = Unseen stories (gradient ring)
⚪ = Already viewed (grey ring)
```

- Horizontal scroll row at the very top of the Explore page (above greeting).
- First circle is always "Add" (camera icon, dashed border).
- Second is "Your Story" if you have an active story.
- Friends sorted by: unseen first → most recent.

#### Story Viewer (Full-screen Immersive)

```
┌─────────────────────────────────────┐
│ ▸▸▸▸▸▸▸▸▸▸ progress bar ▸▸▸▸▸▸▸▸▸ │
│                                     │
│  ┌──┐  Amy Johnson        2h ago   │
│  │🖼│  @amyjohnson               ⋮ │
│  └──┘                               │
│                                     │
│                                     │
│         [ FULL SCREEN              │
│           PHOTO / VIDEO ]          │
│                                     │
│                                     │
│                                     │
│   📍 Central Park, NYC              │
│   🎵 "Blinding Lights" — The Weeknd │
│                                     │
│  ┌─────────────────────────┐  ❤️  ▲ │
│  │ Reply to Amy...         │  😂  │ │
│  └─────────────────────────┘  😮  │ │
└─────────────────────────────────────┘

Navigation:
  Tap left  = previous story
  Tap right = next story
  Swipe left  = next person's stories
  Swipe right = previous person's stories
  Long press  = pause
  Swipe up    = view story details / link
  Swipe down  = close viewer
```

- **Progress bar** at top shows segments per story from that user.
- **User info** top-left with avatar and time ago.
- **More menu** (⋮) top-right: Report, Mute.
- **Reply bar** at bottom: text input → sends message to DM.
- **Quick reactions** next to reply: emoji row (❤️ 😂 😮 🔥 👏 💯).
- **Location & music** overlays at bottom if present.

#### Story Camera / Capture

```
┌─────────────────────────────────────┐
│                                     │
│                                     │
│         [ CAMERA PREVIEW ]          │
│                                     │
│                                     │
│  ⚡   ╔═══╗                         │
│       ║   ║  ← flip camera 🔄      │
│       ╚═══╝                         │
│                                     │
│   Aa    ○──────○    🎵   📍         │
│  text   [ CAPTURE ]  music  loc     │
│         hold = video                │
│                                     │
│  Gallery│ Photo │ Video │ Boomerang │
│  ────────────────────────────────── │
└─────────────────────────────────────┘

Post-capture editor:
┌─────────────────────────────────────┐
│  ✕                          Done →  │
│                                     │
│         [ CAPTURED IMAGE ]          │
│                                     │
│   Drag text overlay here            │
│                                     │
│  ┌──┬──┬──┬──┬──┬──┬──┐            │
│  │Aa│🎨│📍│🎵│⏰│😀│✨│            │
│  └──┴──┴──┴──┴──┴──┴──┘            │
│  Text Draw Location Music Timer     │
│       Color        Clip  24h  Sticker│
│                                     │
│  [ Share to Story ]                 │
│  [ Close Friends Only ]             │
└─────────────────────────────────────┘
```

### Flutter Implementation Plan

```
lib/features/spotlight/
├── data/
│   └── story_repository.dart          # CRUD for stories + views
├── presentation/
│   ├── stories_ring.dart              # Horizontal avatar ring widget
│   ├── story_viewer_page.dart         # Full-screen viewer with gestures
│   ├── story_camera_page.dart         # Quick capture screen
│   └── story_editor_page.dart         # Post-capture text/sticker editor
├── providers/
│   └── story_providers.dart           # Riverpod providers
└── widgets/
    ├── story_progress_bar.dart        # Segmented progress indicator
    ├── story_avatar_ring.dart         # Individual avatar circle with ring
    └── story_reply_bar.dart           # Bottom reply + reactions
```

### Key Interactions

| Gesture | Action |
|---------|--------|
| Tap story ring | Open viewer at that person's first unseen story |
| Tap "+" circle | Open story camera |
| Tap left/right in viewer | Previous/next story segment |
| Swipe left/right in viewer | Previous/next person |
| Long press in viewer | Pause playback |
| Swipe down in viewer | Close |
| Tap reply bar | Open keyboard → reply goes to DM chat |
| Tap reaction emoji | Send reaction (visible to poster) |
| Swipe up on own story | See viewers list |

---

## Phase 2: Full Social Feed ("Moments Feed")

### Concept

A permanent, scrollable social feed. Two layout modes:

1. **Vertical Swipe (TikTok-style)** — Full-screen cards, one per page.
2. **Grid Feed (IG-style)** — 3-column or 2-column grid with detail view.

The user can toggle between modes. This becomes the primary "Friends" social tab.

### UI: Vertical Swipe Feed

```
┌─────────────────────────────────────┐
│  ┌──┐ Amy Johnson         · 2h     │
│  │🖼│ 📍 Central Park, NYC         │
│  └──┘                               │
│                                     │
│                                     │
│         [ FULL-SCREEN              │
│           MOMENT CONTENT ]          │
│         (photo / video / audio      │
│          with waveform)             │
│                                     │
│                                     │
│                                     │
│  "Beautiful sunset walk today 🌅"   │
│                                     │
│  ❤️ 24    💬 3    🔁 Share    🔖    │
│                                     │
│  ─ ─ ─ ─ ─ (swipe up) ─ ─ ─ ─ ─   │
│                                     │
│  ┌──┐ Ben Park             · 5h    │
│  │🖼│ 📍 Brooklyn Bridge            │
│  └──┘                               │
│                                     │
│         [ NEXT MOMENT ]            │
│                                     │
└─────────────────────────────────────┘
```

**Feed Algorithm:**
1. Friends' moments first (chronological, newest on top)
2. Mutual friends' highlights (social graph expansion)
3. Trending moments nearby (location-based discovery)
4. "Moments Together" — shared/collaborative moments boosted

### UI: Grid Feed

```
┌─────────────────────────────────────┐
│  Moments Feed        ≡ (toggle) 🔔 │
│                                     │
│  ┌────┐ ┌────┐ ┌────┐              │
│  │    │ │    │ │    │              │
│  │ 📷 │ │ 🎥 │ │ 📷 │              │
│  │    │ │    │ │    │              │
│  └────┘ └────┘ └────┘              │
│  ┌────┐ ┌────┐ ┌────┐              │
│  │    │ │    │ │    │              │
│  │ 🎵 │ │ 📷 │ │ 🎥 │              │
│  │    │ │    │ │    │              │
│  └────┘ └────┘ └────┘              │
│                                     │
│  Each cell shows:                   │
│  - Thumbnail image/video            │
│  - Media type badge (🎥 for video)  │
│  - Like count overlay               │
│  - Multi-photo indicator (⬜⬜)      │
│  Tap → opens detail card            │
└─────────────────────────────────────┘
```

### Social Interactions

| Feature | Description |
|---------|-------------|
| **Likes** | Heart animation (double-tap or button), count visible |
| **Comments** | Threaded comments with @mentions |
| **Shares** | Share to DM, share to story, external share |
| **Save/Bookmark** | Save to personal collection |
| **Reactions** | Emoji reactions on moments (🔥 ❤️ 😂 😮 👏 💯) |
| **Duets** | Reply to a moment with your own photo/video (side-by-side) |
| **Remix** | Add your own take on a friend's moment (overlay or split) |

### Data Model Additions

```sql
-- Reactions on moments
CREATE TABLE public.moment_reactions (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id  uuid REFERENCES public.moments(id) ON DELETE CASCADE,
  user_id    uuid REFERENCES auth.users(id),
  reaction   text NOT NULL, -- emoji string
  created_at timestamptz DEFAULT now(),
  UNIQUE(moment_id, user_id, reaction)
);

-- Comments
CREATE TABLE public.moment_comments (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  moment_id   uuid REFERENCES public.moments(id) ON DELETE CASCADE,
  user_id     uuid REFERENCES auth.users(id),
  parent_id   uuid REFERENCES public.moment_comments(id), -- threading
  content     text NOT NULL CHECK (char_length(content) <= 500),
  created_at  timestamptz DEFAULT now()
);

-- Bookmarks / Saved moments
CREATE TABLE public.saved_moments (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid REFERENCES auth.users(id),
  moment_id  uuid REFERENCES public.moments(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(user_id, moment_id)
);
```

### Navigation Integration

#### Option A: New Bottom Tab

```
Current:  [ Map ] [ Explore ] [ Chat ]
                      ↑
              (Discover + Memory Lane)

With Feed: [ Map ] [ Feed ] [ Explore ] [ Chat ]
                     ↑            ↑#
              Social Feed    Discover + Memory Lane

Or:       [ Map ] [ Explore ] [ Spotlight ] [ Chat ]
                                   ↑
                          Stories + Feed Combined
```

#### Option B: Sub-tabs within Explore

```
┌─────────────────────────────────────┐
│  Explore ⌄                      🔔 │
│                                     │
│  [ Stories ring... ]                │
│                                     │
│  ┌──────────┬──────────┐            │
│  │ Discover │   Feed   │            │
│  └──────────┴──────────┘            │
│                                     │
│  (Discover content or Feed content) │
└─────────────────────────────────────┘
```

The dropdown switcher already supports "Discover" and "Memory Lane". Adding "Feed" as a third option is trivial.

### Flutter File Structure (Phase 2)

```
lib/features/spotlight/
├── data/
│   ├── story_repository.dart
│   ├── feed_repository.dart          # Feed sorting + pagination
│   └── reaction_repository.dart
├── presentation/
│   ├── stories_ring.dart
│   ├── story_viewer_page.dart
│   ├── story_camera_page.dart
│   ├── story_editor_page.dart
│   ├── feed_page.dart                # Main feed (vertical or grid)
│   ├── feed_detail_page.dart         # Full moment view from grid
│   └── comments_sheet.dart           # Bottom sheet for comments
├── providers/
│   ├── story_providers.dart
│   ├── feed_providers.dart
│   └── reaction_providers.dart
└── widgets/
    ├── story_progress_bar.dart
    ├── story_avatar_ring.dart
    ├── story_reply_bar.dart
    ├── feed_card.dart                # Individual feed post card
    ├── reaction_bar.dart             # Like/comment/share actions
    ├── comment_tile.dart
    └── media_viewer.dart             # Fullscreen photo/video viewer
```

---

## Implementation Priority

| Priority | Feature | Effort |
|----------|---------|--------|
| P0 | Stories ring + camera + viewer | 2-3 days |
| P0 | Story data model + repository | 1 day |
| P0 | Story expiry logic (Edge Function) | 0.5 day |
| P1 | Text/sticker overlays on stories | 1-2 days |
| P1 | Story reactions + replies → DM | 1 day |
| P2 | Vertical swipe feed | 2-3 days |
| P2 | Likes + comments system | 2 days |
| P3 | Grid feed view | 1-2 days |
| P3 | Bookmarks / saved moments | 0.5 day |
| P3 | Duets / Remixes | 3-4 days |

---

## Design Principles

1. **Speed over perfection** — Stories should feel instantaneous. Optimize capture → post pipeline.
2. **Authentic > Curated** — 24h expiry encourages real moments, not polished feeds.
3. **Social proximity** — Content from close friends ranks higher. Mutual moments are boosted.
4. **Location-aware** — Stories and feed content are tagged with location, enabling map integration.
5. **Privacy by default** — Close Friends list for restricted sharing. View counts only visible to poster.
