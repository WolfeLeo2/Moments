# Emotional UI Implementation Guide

## Vision Statement

Transform Moments from a social media feed into a **personal time capsule** - a reflective, nostalgic experience where users **relive memories** rather than just scroll through content.

> "A way of saying 'ABC happened here' - emotional, sentimental, personal."

---

## Core Emotional Principles

### 1. Contemplative Over Consumptive
- Slow, purposeful interactions instead of endless scrolling
- Each moment deserves attention and space
- Encourage pausing, not swiping

### 2. Nostalgic Over Novel
- Design choices that evoke warmth and memory
- Vintage-inspired elements (polaroid frames, handwritten text)
- Temporal language: "Two summers ago" vs "July 15, 2024"

### 3. Personal Over Performative
- Your moments are your story, not content for others
- Private by default, shared intentionally
- Journal-like presentation

### 4. Spatial Over Chronological
- Moments tied to places, not just timestamps
- "Where" matters as much as "when"
- Maps as memory landscapes

---

## Emotional Color Palette

### Primary Colors (Playful & Bright)

```dart
// Core Emotional Palette (Bright, Memorable)
static const Color warmCream = Color(0xFFFFF8E7);      // Bright warm paper
static const Color softIvory = Color(0xFFFFFDF5);      // Warm card background
static const Color coralPink = Color(0xFFFF6B6B);      // Lively nostalgic pink
static const Color mintGreen = Color(0xFF51D88A);      // Fresh nature green
static const Color skyBlue = Color(0xFF54B7F5);        // Bright reflective blue
static const Color sunsetOrange = Color(0xFFFFAA5C);   // Warm sunset glow
static const Color lavenderPop = Color(0xFFA78BFA);    // Playful purple
```

### Contextual Tinting (Based on Moment Time)

| Time of Day | Tint Color | Opacity | Feeling |
|-------------|------------|---------|---------|
| Morning (5-11am) | Warm Amber | 5% | Fresh, hopeful |
| Afternoon (11am-5pm) | Neutral | 0% | Clear, present |
| Evening (5-9pm) | Dusty Rose | 5% | Warm, winding down |
| Night (9pm-5am) | Twilight Blue | 8% | Calm, intimate |

### Temporal Aging (Based on Moment Age)

| Age | Treatment | Effect |
|-----|-----------|--------|
| Today | Full saturation | Vibrant, immediate |
| This week | 95% saturation | Still fresh |
| This month | 90% saturation | Settling in |
| This year | 85% saturation | Comfortable |
| 1+ years | 80% saturation + warm tint | Nostalgic patina |
| 3+ years | 75% saturation + sepia 5% | Vintage memory |

---

## Memory Lane / Timeline View

### Overview

Replace the Instagram-style feed with a **vertical timeline** that feels like turning pages in a life journal.

### Visual Structure

```
┌──────────────────────────────────────────────────────┐
│  ┌─────┐                                             │
│  │ 📍  │  Memory Lane                                │
│  └─────┘                                             │
├──────────────────────────────────────────────────────┤
│                                                      │
│  ═══════════════════════════════════════════════════ │
│           ✦ This Week ✦                              │
│  ═══════════════════════════════════════════════════ │
│                                                      │
│      ┌────────────────────────────────────────┐      │
│      │                                        │      │
│      │   [Photo fills card beautifully]       │      │
│      │                                        │      │
│      │                                        │      │
│      │                                        │      │
│      │   ┌──────────────────────────────┐     │      │
│      │   │ 📍 Nakuru, Kenya             │     │      │
│      │   │ "The flamingos at sunrise"   │     │      │
│      │   │ Yesterday • 24°C ☀️           │     │      │
│      │   └──────────────────────────────┘     │      │
│      └────────────────────────────────────────┘      │
│                        │                             │
│                        │ (timeline connector)        │
│                        │                             │
│      ┌────────────────────────────────────────┐      │
│      │   [Another memory]                     │      │
│      └────────────────────────────────────────┘      │
│                                                      │
│  ═══════════════════════════════════════════════════ │
│           ✦ Last Month ✦                             │
│  ═══════════════════════════════════════════════════ │
│                                                      │
│      ┌────────────────────────────────────────┐      │
│      │   [Older memory with slight sepia]     │      │
│      └────────────────────────────────────────┘      │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### Chapter Headers (Time Groupings)

Moments are grouped into emotional chapters:

| Time Period | Header Text | Visual Style |
|-------------|-------------|--------------|
| Today | "Today" | Bold, no decoration |
| Yesterday | "Yesterday" | Subtle, warm |
| This Week | "This Week" | Handwritten style |
| Last Week | "Last Week" | Handwritten style |
| This Month | Month name ("February") | Decorative flourish |
| Past Months | "January 2026" | Decorative flourish |
| This Year | Season ("Winter 2026") | Illustrated icon |
| Past Years | "Two Years Ago" | Vintage badge |

### Memory Card Design

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ╔═══════════════════════════════════════════════╗     │
│   ║                                               ║     │
│   ║                                               ║     │
│   ║             [PHOTOGRAPH]                      ║     │
│   ║                                               ║     │
│   ║        16:9 or original aspect ratio          ║     │
│   ║                                               ║     │
│   ║                                               ║     │
│   ║   ┌─────────────────────────────────────┐     ║     │
│   ║   │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │     ║     │
│   ║   │ ░ Gradient overlay for readability ░ │     ║     │
│   ║   │ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ │     ║     │
│   ║   │                                     │     ║     │
│   ║   │  📍 Location Name                   │     ║     │
│   ║   │  "Caption or description..."        │     ║     │
│   ║   │                                     │     ║     │
│   ║   │  3 days ago • ☀️ 24°C               │     ║     │
│   ║   │                                     │     ║     │
│   ║   └─────────────────────────────────────┘     ║     │
│   ╚═══════════════════════════════════════════════╝     │
│                                                         │
│   Soft shadow, rounded corners (20px)                   │
│   1-2px subtle border in dustyRose @ 20%                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Timeline Connector

The vertical line connecting memories:

```dart
// Timeline connector specs
width: 2.0
color: dustyRose.withOpacity(0.3)
style: dashed (6px dash, 4px gap)
alignment: center of card stack

// Node dots at each memory
size: 12.0
color: dustyRose
border: 2px white
shadow: subtle glow
```

### Animations & Transitions

| Interaction | Animation | Duration | Curve |
|-------------|-----------|----------|-------|
| Card appear on scroll | Fade + slide up | 400ms | easeOutCubic |
| Tap card to expand | Scale + fade | 300ms | easeOutBack |
| Chapter header appear | Fade in | 500ms | easeInOut |
| Timeline dot pulse | Pulse glow | 2000ms | infinite, subtle |
| Pull to refresh | Soft bounce | 600ms | bounceOut |

---

## Relive Experience (Full Memory View)

When user taps a memory to "relive" it:

### Layout

```
┌─────────────────────────────────────────────────────────┐
│ ← Back                                    ⋮ Options     │
├─────────────────────────────────────────────────────────┤
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
│              [FULL SCREEN PHOTO/VIDEO]                  │
│                                                         │
│                 Pinch to zoom                           │
│                 Swipe for gallery                       │
│                                                         │
│                                                         │
│                                                         │
│                                                         │
├─────────────────────────────────────────────────────────┤
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │                                                 │   │
│   │  📍 Nakuru, Kenya                              │   │
│   │                                                 │   │
│   │  ─────────────────────────────────────────────  │   │
│   │                                                 │   │
│   │  "The day we saw the flamingos at sunrise.     │   │
│   │   I remember the mist over the lake and how    │   │
│   │   quiet everything was..."                     │   │
│   │                                                 │   │
│   │  ─────────────────────────────────────────────  │   │
│   │                                                 │   │
│   │  📅 Two years ago today                        │   │
│   │  ☀️ It was 24°C and sunny                      │   │
│   │  🎵 "Sunrise" by Norah Jones was popular       │   │
│   │                                                 │   │
│   └─────────────────────────────────────────────────┘   │
│                                                         │
│   ┌─────────────────────────────────────────────────┐   │
│   │  ❤️ 12 reactions   💬 Add to story...          │   │
│   └─────────────────────────────────────────────────┘   │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### Contextual Information (AI-Enhanced)

Display ambient data to enhance the memory:

| Data Point | Source | Display |
|------------|--------|---------|
| Weather | Historical weather API | "It was 24°C and sunny" |
| Moon phase | Calculation | "Full moon that night" |
| Day of week | Calculation | "It was a Saturday" |
| Time context | AI | "Two summers ago" |
| Popular music | Spotify API | "Song X was #1 that week" |
| World events | News API | "The Olympics were happening" |

---

## AI-Powered Features

### 1. Smart Grouping (Auto-Chapters)

**Purpose:** Automatically group moments into meaningful life chapters.

**How it works:**
```
Input: List of moments with (timestamp, location, caption)
Output: Grouped chapters with auto-generated titles

Algorithm:
1. Cluster by location proximity (within 5km)
2. Cluster by time proximity (within 48 hours)
3. If both match → same trip/event
4. Generate title based on:
   - Location name ("Kenya Safari")
   - Time period ("Summer 2024")
   - Caption keywords ("Beach Vacation")
```

**AI Model:** GPT-4 Mini or Claude Haiku for title generation
**Local Fallback:** Rule-based grouping with template titles

### 2. Auto-Generated Captions

**Purpose:** Suggest captions for moments without text.

**Prompt Template:**
```
You are a nostalgic journal writer. Given this context, write a brief,
emotional caption (max 100 characters) for a personal memory:

Location: {location_name}
Time: {relative_time} ({absolute_date})
Weather: {weather_conditions}
Time of day: {morning/afternoon/evening/night}
Other context: {any_extracted_metadata}

Write in first person, as if reminiscing. Be warm, not cheesy.
```

**Examples:**
- "The coffee was perfect that morning in Nairobi"
- "When the sunset painted everything gold"
- "I still remember how cold that water was"

### 3. Memory Insights

**Purpose:** Surface interesting patterns and anniversaries.

**Types:**
| Insight Type | Example | Trigger |
|--------------|---------|---------|
| Anniversary | "1 year ago at this spot..." | Same location, 1+ year ago |
| Pattern | "You always visit here in December" | 3+ visits same month |
| Milestone | "Your 100th moment!" | Round numbers |
| Throwback | "2 years ago today" | Exact date match |
| Journey | "You've been to 12 countries" | Aggregation |

### 4. Auto-Title for Moment Groups

**Purpose:** Name untitled moment groups meaningfully.

**Algorithm:**
```python
def generate_group_title(moments):
    # Priority 1: Use most common location
    locations = [m.location for m in moments]
    if len(set(locations)) == 1:
        return f"{locations[0]} memories"
    
    # Priority 2: Use date range
    start = min(m.timestamp for m in moments)
    end = max(m.timestamp for m in moments)
    if same_month(start, end):
        return f"{month_name(start)} {year(start)}"
    
    # Priority 3: Use extracted keywords from captions
    keywords = extract_keywords([m.caption for m in moments])
    if keywords:
        return f"{keywords[0].title()} Trip"
    
    # Fallback
    return f"Memories from {relative_time(start)}"
```

---

## Typography for Emotion

### Font Choices

| Use Case | Font | Weight | Size | Feeling |
|----------|------|--------|------|---------|
| Chapter headers | Playfair Display | 600 | 28sp | Elegant, timeless |
| Memory location | Inter | 600 | 16sp | Clear, modern |
| Memory caption | Lora | 400 | 15sp | Warm, readable |
| Relative time | Inter | 400 | 13sp | Understated |
| Handwritten notes | Caveat or Dancing Script | 400 | 18sp | Personal, intimate |

### Emotional Text Styling

```dart
// Location text
style: TextStyle(
  fontFamily: 'Inter',
  fontWeight: FontWeight.w600,
  fontSize: 16,
  color: charcoal,
  letterSpacing: 0.2,
)

// Caption text
style: TextStyle(
  fontFamily: 'Lora',
  fontWeight: FontWeight.w400,
  fontSize: 15,
  color: charcoal.withOpacity(0.9),
  height: 1.6, // Generous line height for readability
  fontStyle: FontStyle.italic, // Optional for quotes
)

// Relative time
style: TextStyle(
  fontFamily: 'Inter',
  fontWeight: FontWeight.w400,
  fontSize: 13,
  color: stoneGray,
)
```

---

## Micro-Interactions

### Haptic Feedback

| Action | Haptic Type | iOS | Android |
|--------|-------------|-----|---------|
| Open memory | Light | lightImpact | EFFECT_CLICK |
| Long press | Medium | mediumImpact | EFFECT_HEAVY_CLICK |
| Like/react | Soft | selectionClick | EFFECT_TICK |
| Scroll past chapter | Subtle | selectionClick | EFFECT_TICK |
| Error | Heavy | notificationError | EFFECT_DOUBLE_CLICK |

### Sound Design (Optional)

| Action | Sound | Volume | Notes |
|--------|-------|--------|-------|
| Open memory | Soft shutter click | 20% | Camera-like |
| Chapter transition | Soft page turn | 15% | Paper-like |
| Like | Gentle chime | 25% | Warm tone |
| Delete | Soft whoosh | 20% | Not harsh |

---

## Alternative View Modes

The Memory Lane timeline is the default view, but users can switch between several emotional view modes. Each view represents a different way of *feeling* your memories rather than just seeing them.

---

### 1. Floating Memories

#### What It Is
A dreamy, physics-based view where memories float gently across the screen like thoughts drifting through your mind. Each memory is a rounded photo bubble that bobs and sways with soft physics — like fireflies, soap bubbles, or leaves on water.

#### What It Symbolises
**The way memories actually work in your head.** You don't think about your past in a neat timeline — memories float up randomly, some bigger (more important), some smaller, some overlapping. This view captures the *organic, non-linear* nature of human memory. It's meditative. It's the "staring out a window" mode.

#### Visual Structure

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│       ┌─────┐                                        │
│       │ 🏖️  │          ┌───────────┐                │
│       │     │          │           │                 │
│       └─────┘          │  🌅 BIG   │                │
│                        │  MEMORY   │    ┌────┐      │
│   ┌────────┐           │           │    │ 🌃 │      │
│   │        │           └───────────┘    └────┘      │
│   │  🗻    │                                        │
│   │        │     ┌──────┐                           │
│   └────────┘     │  ☕   │        ┌─────┐           │
│                  └──────┘        │ 🎶  │           │
│                                  └─────┘           │
│        ┌───┐                                        │
│        │🌸 │                 ┌─────────┐            │
│        └───┘                 │  🏔️     │            │
│                              └─────────┘            │
└──────────────────────────────────────────────────────┘

Bubbles float with gentle physics. Tap one to expand.
```

#### How We Use It
| Aspect | Detail |
|--------|--------|
| **Trigger** | User switches to "Float" view mode from the view picker |
| **Size** | Bubble size = emotional weight (reactions, revisits, caption length) |
| **Movement** | Gentle sine-wave drift + random wobble; respond to device tilt (gyroscope) |
| **Interaction** | Tap to expand into full memory view; long-press to "pin" a bubble (stops floating); drag to rearrange |
| **Clustering** | Memories from the same trip/group gently attract each other |
| **Background** | Soft gradient (backgroundBeige → warmCream) with subtle particle effects |
| **Sound** | Optional: gentle ambient chime when bubbles softly collide |

#### Implementation Notes
```dart
// Physics: Use a simple spring simulation
// Each bubble has: position, velocity, mass (based on importance)
// Forces: gravity (very weak, pulling center), repulsion (bubbles push apart),
//         attraction (same-group bubbles), damping (prevents chaos)
// Render: CustomPainter or Stack with AnimatedPositioned
// Performance: Limit to ~30 visible bubbles, lazy-load more on scroll-out
```

---

### 2. Constellation View

#### What It Is
A night-sky-themed map where each memory is a **star**, and memories from the same trip/group/location are connected by faint lines forming **constellations**. Your life's moments become star patterns on a dark canvas.

#### What It Symbolises
**Your life is a constellation — individual points of light that form something beautiful when connected.** Each star alone is a moment; together, they tell the story of who you are. This view transforms your memories from a list into a *night sky you authored*. It's aspirational, poetic, and deeply personal.

#### Visual Structure

```
┌──────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░ (dark gradient background) ░░░░░░░░░░░ │
│                                                      │
│     ★ ─ ─ ─ ─ ★                                     │
│     │ Kenya     \          ★                         │
│     │  Safari    ★ ─ ─ ─ /                          │
│     │                   /     ★ ─ ─ ★               │
│     ★         ★ ─ ─ ─ ★      │Paris │               │
│                  Europe       ★ ─ ─ ★               │
│                  Trip                                │
│          ★                           ★              │
│         (solo)        ★ ─ ─ ★ ─ ─ ★                │
│                       │  Home    │                   │
│     ★ ─ ─ ★           ★ ─ ─ ─ ─ ★                   │
│     │Beach│                                          │
│     ★ ─ ─ ★       ★                                 │
│                   (solo)                             │
│                                          ★          │
│                                                      │
│  ┌────────────────────────────────────────────┐      │
│  │ Constellation: "Kenya Safari" (4 moments)  │      │
│  │ ★ Tap a star or constellation to explore   │      │
│  └────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────┘

Stars twinkle subtly. Lines glow when constellation selected.
```

#### How We Use It
| Aspect | Detail |
|--------|--------|
| **Trigger** | "Constellation" view mode from the view picker |
| **Star brightness** | Based on recency and reaction count (brighter = more significant) |
| **Star color** | Matches the time-of-day tint of the moment |
| **Lines** | Faint dashed lines connecting same-group memories; glow on hover/tap |
| **Constellation name** | Auto-generated or user-named group title displayed below |
| **Navigation** | Pinch to zoom in/out of the starfield; pan to explore |
| **Tap star** | Shows memory preview tooltip; double-tap opens full view |
| **Tap constellation** | Expands to show all connected memories in a mini-timeline |
| **Background** | Deep navy to indigo gradient with subtle star-dust particles |
| **Easter egg** | Shake device to trigger a "shooting star" animation across the screen |

#### Implementation Notes
```dart
// Layout: Force-directed graph algorithm (or simple grid with jitter)
// Each star positioned by (longitude, latitude) normalized to screen
// OR chronological X-axis + random Y with grouping attraction
// Stars: CustomPainter with glow effect (radial gradient)
// Lines: Path drawing with dash pattern
// Animation: Twinkle = opacity oscillation (sine wave, random phase)
// Package suggestion: flutter_force_directed_graph or custom Canvas
```

---

### 3. Stacked Polaroid / Deck View

#### What It Is
A stack of polaroid-style cards scattered casually (slightly rotated, overlapping) like photos tossed on a table. The user swipes through them one by one, each card lifting and flying away to reveal the next. Think of it like a Tinder-for-memories or a deck of playing cards.

#### What It Symbolises
**Rediscovery and surprise.** When you find a box of old photos and flip through them one by one, you don't know what's next — that's the magic. This view recreates that serendipitous feeling. Each swipe is a tiny surprise. The slight rotation and messy arrangement say *"these are real, not curated"* — like a shoebox of prints, not a polished album.

#### Visual Structure

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│                                                      │
│         ┌─────────────────────────────┐              │
│        ╱│                             │╲  ← slight   │
│       ╱ │     [PHOTO]                 │ ╲   rotation │
│      │  │                             │  │           │
│      │  │                             │  │           │
│      │  │                             │  │           │
│      │  ├─────────────────────────────┤  │           │
│      │  │                             │  │           │
│      │  │  📍 Mombasa, Kenya          │  │           │
│      │  │                             │  │ ← white   │
│      │  │  "salt air & sunburned     │  │   border  │
│      │  │   shoulders"               │  │ (Polaroid)│
│      │  │             — Feb 2025      │  │           │
│      │  │                             │  │           │
│       ╲ └─────────────────────────────┘ ╱            │
│        ╲─────────────────────────────╱               │
│                                                      │
│    ← Swipe to dismiss       Swipe back →             │
│                                                      │
│       ┌──┐  ┌──┐  ┌──┐  ┌──┐  ┌──┐                 │
│       │▒▒│  │▒▒│  │▒▒│  │▒▒│  │▒▒│  ← stack depth  │
│       └──┘  └──┘  └──┘  └──┘  └──┘    indicator     │
│                                                      │
│    12 of 47 memories                                 │
└──────────────────────────────────────────────────────┘

Each card has: thick white border, slight shadow, random rotation (±3°)
Caption in Caveat (handwritten) font
```

#### How We Use It
| Aspect | Detail |
|--------|--------|
| **Trigger** | "Deck" view mode or special "Shuffle Memories" action |
| **Gesture** | Swipe left/right to flip through; swipe up to "love" a memory; swipe down to skip |
| **Card style** | White border (~20px), slight drop shadow, random rotation (±1° to ±4°), rounded corners (8px) |
| **Caption font** | Caveat (handwritten) for the personal journal feel |
| **Stack depth** | Show 2-3 cards peeking behind the top card (offset + darker shadow) |
| **Order** | Default: random shuffle; options for chronological, location-based, or "surprise me" |
| **Swipe animation** | Card flies off screen with rotation acceleration + slight bounce for next card |
| **Long press** | Lifts card higher with shadow deepening; reveals "See full memory" button |
| **Shuffle** | Shake device or tap shuffle button → cards scatter and re-stack animation |
| **Daily Pick** | Show 1 random memory as notification: "Here's a memory for you today" |

#### Implementation Notes
```dart
// Widget: Stack with Draggable/GestureDetector on top card
// Or use a package like flutter_card_swiper / appinio_swiper
// Rotation: Transform.rotate(angle: randomAngle) per card
// Physics: Spring animation for snap-back if not swiped far enough
// Polaroid border: Container with thick white padding + shadow
// Stack: IndexedStack or manual Stack with offset transforms
```

---

### 4. Journal Entries View

#### What It Is
A long-scroll journal/diary format where each memory is presented as a **written entry** — date header, handwritten caption, photo embedded inline like a scrapbook page, with decorative elements (washi tape, stamps, doodles) around it. Think Day One app meets a real leather-bound journal.

#### What It Symbolises
**Intentional reflection.** A journal isn't something you mindlessly scroll — it's something you *read*, you *sit with*. This view says "your moments are worth words, not just likes." It transforms your photo stream into a **personal memoir**. The decorative elements (tape, stamps, stickers) make it feel handmade and precious — like someone took the time to paste these in, because they mattered.

#### Visual Structure

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│   ┌──────────────────────────────────────────────┐   │
│   │               📖 My Journal                  │   │
│   └──────────────────────────────────────────────┘   │
│                                                      │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                                      │
│   Tuesday, February 4, 2026                          │
│   ──────────────────────                            │
│                                                      │
│   ┌──────────────────────────┐  ╱╱╱╱╱╱╱             │
│   │                          │  ╱ washi ╱            │
│   │      [PHOTO]             │  ╱ tape  ╱            │
│   │                          │  ╱╱╱╱╱╱╱             │
│   │                          │                       │
│   └──────────────────────────┘                       │
│                                                      │
│   📍 Nairobi, Kenya                                  │
│                                                      │
│   "We walked through the market early in the         │
│    morning. The smell of roasted coffee beans         │
│    was everywhere. I bought that blue mug —           │
│    it's sitting on my desk right now."                │
│                                                      │
│    ✦ 24°C and sunny   ✦ It was a Tuesday            │
│                                                      │
│   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │
│                                                      │
│   Monday, February 3, 2026                           │
│   ──────────────────────                            │
│                                                      │
│   📍 Lake Nakuru                                     │
│                                                      │
│   (continued entries...)                             │
│                                                      │
│   [📎 Stamp: "KENYA 2026"]  [✈️ Boarding pass icon]  │
│                                                      │
└──────────────────────────────────────────────────────┘

Full text in Caveat (handwritten). Dates in Rubik (bold/playful).
Decorative elements are randomised per entry.
```

#### How We Use It
| Aspect | Detail |
|--------|--------|
| **Trigger** | "Journal" view mode from the view picker |
| **Layout** | Single scrollable column, generous spacing, paper-textured background |
| **Date headers** | Full date in Rubik bold, underlined with a decorative rule |
| **Photo placement** | Alternating left/right alignment, sometimes full-width, slight rotation (±1°) |
| **Caption font** | Caveat at 18-20sp, dark text, generous line height (1.7) |
| **Decorations** | Random per entry: washi tape strips, corner stamps, small sticker icons, paper clip overlays |
| **Metadata** | Weather, day of week, moon phase shown as subtle footnotes |
| **Writing prompt** | If a moment has no caption, show a soft prompt: *"What were you feeling that day?"* — tap to add |
| **Export** | "Export as PDF" to generate a printable journal page |
| **Paging** | Optional "page turn" animation between entries (horizontal swipe) |

#### Decorative Elements Library

| Element | Visual | Usage |
|---------|--------|-------|
| Washi tape | Colored translucent strip at corner of photo | Random attachment illusion |
| Paper clip | Small metallic clip at top of photo | "Clipping" photo to the page |
| Stamp | Vintage-style circle stamp with location + year | Placed at bottom of entries |
| Sticker | Small emoji-style icon (plane, camera, heart, coffee) | Random decoration near date |
| Ink splatter | Tiny watercolor dot | Background texture element |
| Ruled lines | Faint horizontal lines | Optional journal paper background |

#### Implementation Notes
```dart
// Background: Subtle paper texture (asset or generated noise)
// Decorations: Stack of positioned SVG/PNG overlays with random placement
// Per-entry randomization seed: use moment.id.hashCode for consistent random
// Export: Use pdf package to render journal pages
// Writing prompt: AnimatedOpacity + TextField that saves to caption field
```

---

### View Mode Picker

Users switch between views via a floating action button or toolbar:

```
┌──────────────────────────────────────┐
│  View As:                            │
│                                      │
│  📜 Timeline    (default)            │
│  🫧 Floating    Memories             │
│  ✨ Constellation                    │
│  🃏 Polaroid    Deck                 │
│  📓 Journal     Entries              │
│  🗺️ Map         (existing)           │
│                                      │
└──────────────────────────────────────┘
```

Each view mode persists as a user preference. The same underlying data (moments) powers all views — only the presentation changes.

---

## Scrapbook Design Language

All views share a common **scrapbook design language** that reinforces the handmade, personal feel:

### Key Scrapbook Elements

| Element | Where Used | Purpose |
|---------|-----------|---------|
| **White photo borders** | Polaroid deck, journal | Polaroid / print feel |
| **Slight rotation** | All card-based views | "Placed by hand", not machine-perfect |
| **Handwritten font (Caveat)** | Captions everywhere | Personal, intimate, journal-like |
| **Washi tape / paper clips** | Journal view, detail page | Scrapbook attachment illusion |
| **Stamps & stickers** | Journal, deck | Playful decoration, travel feel |
| **Paper texture** | Journal background | Tactile, physical notebook feel |
| **Drop shadows** | All cards | Depth, "sitting on a surface" |
| **Soft corners** | Photo cards | Friendly, approachable |

### When to Apply Scrapbook vs Clean
| Screen | Style | Reason |
|--------|-------|--------|
| Memory Lane timeline | Clean + subtle scrapbook | Readability first, nostalgia second |
| Journal view | Full scrapbook | The whole point is a handmade journal |
| Polaroid deck | Medium scrapbook | Polaroid is inherently scrapbook |
| Constellation | Minimal (clean dark sky) | Stars should shine, not be cluttered |
| Floating memories | Minimal (clean bubbles) | Dreamy simplicity |
| Moment detail page | Scrapbook touches | Stamps, tape on photos enhance the "relive" feel |
| Chat, settings, profile | Clean / no scrapbook | Functional screens stay functional |

---

### Phase 1: Foundation (Current Sprint)
- [ ] Update AppTheme with emotional palette
- [ ] Create Memory Lane timeline view
- [ ] Implement chapter grouping (rule-based)
- [ ] Add temporal language helpers ("Two years ago")
- [ ] Memory card redesign

### Phase 2: Contextual Data
- [ ] Integrate historical weather API
- [ ] Add "X years ago today" insights
- [ ] Time-of-day tinting
- [ ] Age-based saturation adjustment

### Phase 3: AI Enhancement
- [ ] Auto-caption generation
- [ ] Smart chapter naming
- [ ] Memory insights & patterns
- [ ] Duplicate/similar moment detection

### Phase 4: Relive Experience
- [ ] Full-screen memory view
- [ ] Contextual information panel
- [ ] Music integration
- [ ] Story/journal export

---

## API Requirements

### Historical Weather
- **Service:** OpenWeatherMap Historical or Visual Crossing
- **Data needed:** Temperature, conditions, icon
- **Cache:** Store with moment, one-time fetch

### AI/LLM
- **Service:** OpenAI GPT-4 Mini or Anthropic Claude Haiku
- **Use cases:** Caption generation, chapter naming, insights
- **Rate limit:** Cache aggressively, batch requests

### Music Context (Optional)
- **Service:** Spotify Web API
- **Data needed:** Top songs for date/region
- **Complexity:** High (auth required)

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Time spent per moment | +50% vs feed | Analytics |
| Moments revisited | 3+ per session | Analytics |
| "Relive" feature usage | 30% of users | Analytics |
| User sentiment | "Nostalgic", "Personal" | Surveys |
| Daily active moments viewed | 10+ | Analytics |

---

## Reference Apps

- **Apple Photos Memories**: Auto-generated collections with music
- **Google Photos**: "X years ago" notifications
- **Day One Journal**: Beautiful timeline, emotional typography
- **1 Second Everyday**: Video timeline of life
- **Timehop**: Daily throwbacks

---

*Last Updated: February 5, 2026*
