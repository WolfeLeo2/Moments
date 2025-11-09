# Moments App Development Plan

## 🎯 Project Overview
**Name**: Moments  
**Goal**: A Flutter app that displays interactive map-based "moments" (photo posts tied to locations)  
**Target Platforms**: iOS & Android  
**UI Inspiration**: Playful, layered, and dynamic with smooth motion similar to the reference image

## 📋 Core Requirements Breakdown

### 1. Main Features
- **Map Interface**: Google Maps as main screen with user location centering
- **Moment Markers**: Interactive cards on map showing:
  - Title (e.g., "PLACE OF POWER")
  - Date
  - Thumbnail image
  - Clustered display for nearby moments
- **Moment Details**: Full-screen view with:
  - Hero image with decorative stickers
  - Location name
  - Preview functionality
- **Add New Moment**: Floating action button for creating new moments

### 2. Technical Stack
- **Backend**: Supabase (authentication + database + storage)
- **Offline-First**: brick_offline_first_with_supabase
- **Animation**: motor (physics-based), flutter_animate (micro transitions)
- **Maps**: google_maps_flutter
- **Images**: cached_network_image
- **Navigation**: go_router
- **Environment**: flutter_dotenv
- **Fonts**: google_fonts

### 3. Data Architecture
- **Offline-First**: Use Brick for local caching, sync with Supabase
- **Image Storage**: Supabase bucket named "moments"
- **Camera/Gallery**: Users choose image source
- **Social Features**: Friends can see each other's moments

## 🏗️ Implementation Phases

### Phase 1: Project Setup & Core Infrastructure
1. Update pubspec.yaml with all required dependencies
2. Set up folder structure following clean architecture
3. Configure Supabase connection and environment variables
4. Create base theme and typography
5. Set up routing with go_router

### Phase 2: Data Layer
1. Create Moment model with Brick annotations
2. Set up Supabase tables and storage
3. Implement offline-first repository pattern
4. Create data sources and adapters

### Phase 3: Map Feature
1. Implement main map page with Google Maps
2. Create moment marker widgets
3. Add user location functionality
4. Implement marker clustering for nearby moments
5. Add smooth animations for marker interactions

### Phase 4: Moment Details & Creation
1. Create moment detail page with hero transitions
2. Implement photo upload functionality (camera/gallery)
3. Add decorative stickers and styling
4. Create add moment form with location picker

### Phase 5: Polish & Animations
1. Implement Motor physics-based animations
2. Add micro transitions with flutter_animate
3. Polish UI to match reference design
4. Test offline functionality and sync

## 🎨 Design System

### Typography
- **Headers**: Bebas Neue (bold, condensed, uppercase)
- **Body**: Inter (readable, modern)
- **Sizes**: Responsive scale

### Color Palette
- **Primary**: #306BFF (blue accent)
- **Background**: #FAF8F6 (light beige/cream)
- **Text**: #2D3748 (dark gray)
- **Cards**: #FFFFFF (white with shadows)

### Animation Principles
- **Bounce**: Scale effects (0.95 → 1.0) on interactions
- **Spring**: Physics-based transitions using Motor
- **Fade/Slide**: Smooth page transitions
- **Hero**: Image transitions between screens

## 📱 Navigation Structure
```
/ (MapPage) 
├── /moment/:id (MomentDetailPage)
├── /new (AddMomentPage)
└── /camera (CameraPage)
```

## 🗂️ Folder Structure
```
lib/
├── main.dart
├── core/
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── typography.dart
│   └── utils/
│       ├── constants.dart
│       └── extensions.dart
├── data/
│   ├── models/
│   ├── sources/
│   └── repositories/
├── features/
│   ├── map/
│   │   └── presentation/
│   └── moments/
│       ├── presentation/
│       └── data/
└── widgets/
    ├── bouncing_card.dart
    └── app_button.dart
```

## 🔄 Development Workflow
1. Create infrastructure and setup
2. Implement core data models
3. Build map interface
4. Add moment creation flow
5. Implement details view
6. Polish animations and transitions
7. Test offline functionality
8. Performance optimization

## 📊 Success Metrics
- [ ] App loads and shows user location on map
- [ ] Can create new moments with photos
- [ ] Moments display as interactive markers
- [ ] Smooth animations throughout the app
- [ ] Offline-first functionality works
- [ ] Clean, maintainable code structure
