# iOS Design Shift — Implementation Guide

> **Goal:** Adopt an iOS-_inspired_ aesthetic without fully converting to native Cupertino widgets. Keep Material widgets where they work, but apply iOS design tokens: colors, motion, shapes, icons, and interaction patterns.

---

## Design Tokens

### Shapes

- **Primary border shape:** `RoundedSuperellipseBorder` (squircle) for all containers, cards, bottom sheets, dialogs, buttons, avatars
- **Radius scale:** 8px (small chips), 12px (buttons, inputs), 16px (cards), 20px (large cards, sheets), 28px (FABs, modal corners)
- **No hard borders** — replace all `border: Border.all(color: black/dark)` with either no border or very subtle `color: Colors.grey.shade200` at 0.5–1px

### Colours

- **System Blue:** `Color(0xFF007AFF)` — primary actions, links, accent (already `AppTheme.primaryBlue`)
- **System Gray backgrounds:** `Color(0xFFF2F2F7)` — page background (already `AppTheme.backgroundBeige`)
- **System Gray 2:** `Color(0xFFAEAEB2)` — secondary text, icons
- **System Gray 5:** `Color(0xFFE5E5EA)` — borders, dividers
- **Destructive Red:** `Color(0xFFFF3B30)` — delete, remove
- **System Green:** `Color(0xFF34C759)` — success, online
- **Label colours:** primary = black87, secondary = grey.shade500, tertiary = grey.shade400
- Keep existing accent colours (coralPink, lavenderPop, sunsetOrange) for brand identity

### Typography

- **Headlines/Titles:** `GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: -0.5)` — tight tracking like SF Pro Display
- **Body:** `GoogleFonts.inter(fontWeight: FontWeight.w400–w500)` — already in use, keep
- **Captions/Labels:** `GoogleFonts.inter(fontSize: 11–12, fontWeight: FontWeight.w500)`
- **Eliminate:** Bangers (friend profile), Life Savers (details captions) — replace with Inter
- **Keep:** Bebas Neue for the map page "MOMENTS" header only (brand identity)
- **Keep:** Caveat for memory lane scrapbook (personal page aesthetic)
- **SpaceMono** — phase out gradually, replace with Inter monospaced where needed

### Icons

- **Primary icon set:** `CupertinoIcons` — use for all new work
- **Secondary:** Keep `HugeIcons` where already used, phase them out over time
- **Eliminate:** `FontAwesomeIcons` usage — replace with CupertinoIcons equivalents
- **No filled icons by default** — prefer outline/stroke style (iOS convention)

### Motion

- **Standard curve:** `Curves.easeInOutCubicEmphasized` (already used in some places)
- **Spring curves:** Keep `Motor` package springs — they feel iOS-native
- **Durations:** 250ms (buttons, state changes), 350ms (page transitions), 500ms (sheets, modals)
- **Haptics:** Already good (`HapticService`). Add haptics to segment control changes, switch toggles, card snaps

### Shadows

- **Card shadow:** `BoxShadow(color: black.withOpacity(0.06), blurRadius: 16, offset: Offset(0, 4))`
- **Elevated shadow:** `BoxShadow(color: black.withOpacity(0.1), blurRadius: 24, offset: Offset(0, 8))`
- **No neubrutalism shadows** — replace all `Offset(4, 4)` black shadows with diffused shadows
- Exception: Keep neubrutalism accents in Memory Lane only (scrapbook aesthetic)

---

## Page-by-Page Shift Plan

### 1. Moment Details Page (MAJOR)

- [ ] Replace `CarouselSlider` package with custom `PageView` + `Transform.scale` (no 3rd party dependency)
- [ ] Replace `Life Savers` font for captions → `GoogleFonts.inter` italic
- [ ] Remove random card rotation — use clean 0° alignment with subtle scale-on-select
- [ ] Replace card borders (white 4px) → borderless with `RoundedSuperellipseBorder`, subtle shadow
- [ ] Replace card border radius 18 → 20 with squircle shape
- [ ] Replace Material FAB → nav bar action button or inline CTA
- [ ] Replace privacy red pill badge → subtle lock icon overlay on image corner
- [ ] Use `CupertinoIcons` for all icons (heart, share, download, etc.)
- [ ] Add section grouping with subtle dividers between music/carousel/audio
- [ ] Contributor row: borderless avatars with subtle gradient ring instead of hard colored borders
- [ ] Reactions: iOS-like reaction bar below image (similar to iMessage reactions)

### 2. Chat Page

- [ ] Replace `IconButtonM3E` filled buttons in input bar → plain icon buttons with no fill
- [ ] Replace Material `TextField` → keep Material but style with `RoundedSuperellipseBorder` as decoration shape
- [ ] Simplify input row: embed "+" inside text field prefix, camera into text field suffix, send as suffix
- [ ] Replace long-press `showFloatingMessageMenu` → use `CupertinoContextMenu` or `CupertinoActionSheet`
- [ ] Scroll-to-bottom: replace black circle → translucent white pill with chevron
- [ ] Chat bubbles: use squircle `RoundedSuperellipseBorder` instead of `BorderRadius.circular`
- [ ] Time separator: use iOS-style centered grey pill labels

### 3. Chat List Page

- [ ] Replace Material `ListTile` → custom row with squircle avatar, proper iOS spacing
- [ ] Replace Material FAB ("New Message") → trailing icon in nav bar
- [ ] Add swipe-to-delete/mute/archive actions on rows (use `Dismissible` or custom swipe)
- [ ] Search bar: style with `RoundedSuperellipseBorder`, grey fill, CupertinoIcons.search

### 4. Friend Profile Page

- [ ] Replace `Bangers` font → `GoogleFonts.inter(fontWeight: w800, letterSpacing: -0.5)` for title
- [ ] Replace custom segmented control → `CupertinoSlidingSegmentedControl` (native spring + haptic)
- [ ] Avatar: remove hard 3px black border → no border or subtle 1px grey.shade300 ring
- [ ] Grid items: remove 1px black borders → borderless, tight 2px spacing (Instagram/Apple Photos style)
- [ ] Replace `PopupMenuButton` → `CupertinoActionSheet` from bottom
- [ ] Replace `AlertDialog` → `CupertinoAlertDialog` for block/remove confirmations
- [ ] "Message" button: replace flat black rectangle → `RoundedSuperellipseBorder` with system blue fill

### 5. Profile Page (Own)

- [ ] Apply same avatar/grid treatment as friend profile
- [ ] Use `CupertinoSlidingSegmentedControl` for any tabs
- [ ] Settings items: iOS-style grouped list with `RoundedSuperellipseBorder` container, grey background sections

### 6. Map Page (V1 — if kept as fallback)

- [ ] City name sticker: replace neubrutalism shadow → iOS pill with `RoundedSuperellipseBorder` + diffused shadow
- [ ] Remove neubrutalism from animated FAB → not needed if using V2 bottom cards
- [ ] Friends-in-view stack: use squircle avatars

### 7. Navigation / Main Scaffold

- [ ] Floating bottom bar: already uses `BorderRadius.circular(500)` — could switch to squircle but pill shape is fine
- [ ] Tab icons: already using `CupertinoIcons` — good
- [ ] Consider adding labels below tab icons for accessibility

### 8. Add Moment Page

- [ ] Form fields: `RoundedSuperellipseBorder` decoration, grey fill on focus
- [ ] Buttons: squircle shape, system blue for primary, grey for secondary
- [ ] Replace any Material dialogs → `CupertinoAlertDialog`

---

## Global Replacements (Cross-cutting)

### Replace Across All Files

| Find                                                           | Replace With                                                                    |
| -------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `BorderRadius.circular(N)` in card/container `ShapeDecoration` | `RoundedSuperellipseBorder(borderRadius: BorderRadius.all(Radius.circular(N)))` |
| `Icons.favorite` / `Icons.favorite_border`                     | `CupertinoIcons.heart_fill` / `CupertinoIcons.heart`                            |
| `Icons.share`                                                  | `CupertinoIcons.share`                                                          |
| `Icons.delete`                                                 | `CupertinoIcons.delete`                                                         |
| `Icons.search`                                                 | `CupertinoIcons.search`                                                         |
| `Icons.settings`                                               | `CupertinoIcons.gear`                                                           |
| `Icons.camera_alt`                                             | `CupertinoIcons.camera`                                                         |
| `Icons.photo`                                                  | `CupertinoIcons.photo`                                                          |
| `Icons.add`                                                    | `CupertinoIcons.plus`                                                           |
| `Icons.close`                                                  | `CupertinoIcons.xmark`                                                          |
| `Icons.arrow_back`                                             | `CupertinoIcons.back`                                                           |
| `Icons.more_vert`                                              | `CupertinoIcons.ellipsis`                                                       |
| `Icons.person`                                                 | `CupertinoIcons.person`                                                         |
| `showDialog` + `AlertDialog` (for destructive)                 | `showCupertinoDialog` + `CupertinoAlertDialog`                                  |
| `showModalBottomSheet` (for action menus)                      | `showCupertinoModalPopup` + `CupertinoActionSheet`                              |
| Hard black borders on cards                                    | Remove or use `Colors.grey.shade200` at 0.5px                                   |
| `Offset(4, 4)` neubrutalism shadows                            | Diffused: `BoxShadow(blurRadius: 16, offset: Offset(0, 4))`                     |
| `MaterialPageRoute`                                            | Keep — `CupertinoPageRoute` has different back-swipe. Evaluate per page.        |

---

## What NOT to Change

- **Memory Lane page** — the scrapbook aesthetic is intentional and personal. Keep washi tape, Caveat font, torn edges, ruled lines. It's a journal, not a feed.
- **Bebas Neue on map page** — brand identifier for "MOMENTS" title
- **BouncingScrollPhysics** — already iOS-like, keep everywhere
- **Motor spring animations** — they feel more native than `Curves.bounceOut`
- **HapticService** — already comprehensive, just add to new interactions
- **Riverpod state management** — purely backend, no visual impact
- **Drift/Supabase** — data layer, no visual impact

---

## Priority Order

1. **Friend profile page** — quick win, ~1 hour, high visual impact
2. **Chat list + chat page** — medium effort, daily-use screens
3. **Moment details page** — largest effort, most visible
4. **Global icon/border/shadow sweep** — can be done incrementally
5. **Add moment / profile / settings** — lower priority, less frequently viewed
