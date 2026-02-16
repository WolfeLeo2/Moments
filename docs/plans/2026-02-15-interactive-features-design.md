# 2026-02-15 Interactive Map & Social Design

## Overview
This design document details five new features to enhance the "Moments" app:
1.  **Ghost Mode (Live Location)**: Opt-in, real-time location sharing.
2.  **Live Pulse**: Real-time haptic/visual connection on the map (requires Ghost Mode).
3.  **Neon Trails**: Temporary glowing paths showing user movement history (requires Ghost Mode).
4.  **Moment Beams**: Vertical light beacons in 3D map view for moment discovery.
5.  **Moment Comments**: Public threads for social engagement on moments.

## 1. Ghost Mode (Live Location) & Visual Distinction
### User Story
"I want to let my friends know where I am right now, so I toggle 'Go Live'. My avatar appears on their map, pulsing and moving in real-time."

### Visual Distinction
To prevent confusion between **Moments** and **Live Friends**:

| Feature | **Moments** (Refactored) | **Live Friends** (New) |
| :--- | :--- | :--- |
| **Content** | **Moment Media Thumbnail** (Latest photo/video) | **User Avatar** (Profile Picture) |
| **Shape** | **Rounded Rectangle/Square** (with white border) | **Circle** (Ring color matches user/vibes) |
| **Movement** | **Static** (Pinned to location) | **Moving** (Smooth animations) |
| **Effect** | Shadow | **Pulsing Halo** ("Breathing" effect) |
| **Context** | "A memory captured here" | "A friend is here right now" |
| **Z-Index** | Below Live Markers | **Above** everything else |

### Technical Approach
-   **Supabase Realtime**: Broadcast `location` events via a `presence` channel.
-   **No Persistence**: Live location data is ephemeral; usually not stored in DB mainly (or only for trails).
-   **Toggle**: A "Ghost" FAB on the map.

## 2. Live Pulse (Immediate Connection)
### User Story
"I see my friend is online on the map. I tap their avatar, and they instantly feel a vibration and see my avatar glow on their screen, letting them know I'm thinking of them."

### UI/UX Design
-   **Sender**: Tapping a friend's avatar on the map triggers a radial ripple animation expanding outward from the sender's location towards the friend's location.
-   **Receiver**:
    -   **Visual**: The sender's avatar on the map pulses with a glowing halo.
    -   **Haptic**: A distinct, "heartbeat" vibration pattern plays.
    -   **Notification**: A transient in-app toast "John puls-ed you!" (if app is open) or a push notification (if backgrounded).

### Technical Approach
-   **Backend**: Supabase Realtime channel (e.g., `presence:map`) to broadcast `pulse` events.
-   **Frontend**:
    -   `mapbox_maps_flutter` for rendering the ripple effect (custom layer or animated icon).
    -   `vibration` or `haptic_feedback` package for the heartbeat effect.

## 2. Neon Trails (Playful Discovery)
### User Story
"I'm exploring the city and see glowing lines on the map where my friends have been in the last 30 minutes, creating a sense of activity and life."

### UI/UX Design
-   **Visual**: Moving users leave a "trail" behind them.
    -   **Style**: Glowing, neon-colored lines (e.g., Cyan, Magenta, Lime). Color is unique to each user (consistent with their avatar ring/theme).
    -   **Fade**: Trails fade opacity over time, disappearing completely after 30 minutes.
    -   **Smoothness**: Curves should be smoothed (Catmull-Rom splines) to avoid jagged GPS jitter.

### Technical Approach
-   **Data**: Store location history in a temporary/cache layer (Redis or ephemeral Supabase table `user_trails` with TTL).
-   **Rendering**: Mapbox `LineLayer` with a gradient `line-gradient` property to visualize the fading effect (older points = lower alpha).
-   **Optimization**: Only fetch/render trails for friends currently in the viewport.

## 3. Moment Beams (3D Discovery)
### User Story
"I open the map and tilt it into 3D. I see vertical beams of light shooting up into the sky in the distance. I tap one to fly over and see what moment was captured there."

### UI/UX Design
-   **Visual**:
    -   **2D View**: Standard moment markers (though maybe with a subtle glow).
    -   **3D View (Pitch > 30°)**: Vertical "beacon" lines extend upwards from the moment location.
    -   **Color**: Beams match the dominant color of the moment media or a category color.
-   **Interaction**: Tapping a beam selects the moment and centers the camera on it.

### Technical Approach
-   **Rendering**: Mapbox `FillExtrusionLayer` (using thin cylinders/pillars) or `ModelLayer` (if supported for simple primitives) to create 3D vertical lines.
    -   *Alternative*: A "wall" `LineLayer` with `line-z-offset` functionality if available, or just standard 3D object models placed at coordinates.
-   **Efficiency**: Clustering logic must aggregate beams when zoomed out to avoid clutter (e.g., one thick beam for a cluster).

## 4. Moment Comments (Social Engagement)
### User Story
"I view a friend's moment and want to say something. I tap 'Comment', type a message, and it appears publicly for everyone to see."

### UI/UX Design
-   **Access**: A "Comment" bubble icon on the Moment Details page (next to the Heart/Like button).
-   **Display**:
    -   **Sheet**: Tapping opens a bottom sheet with the comment thread.
    -   **Inline** (Optional extended goal): 1-2 most recent comments shown under the caption.
-   **Style**: TikTok/Instagram Reel style transparent overlay or detachable sheet.

### Technical Approach
-   **Database**: New `comments` table in Supabase.
    -   `id`, `moment_id`, `user_id`, `content`, `created_at`.
-   **Realtime**: Subscribe to `INSERT` on `comments` table to show new comments instantly as they arrive.
