# Moments App - Implementation Checklist

## Pre-Development Setup ✅

- [x] Create project structure plan (PLAN.md)
- [x] Define coding rules and standards (RULES.md)
- [x] Document AI agent integration (AGENTS.md)
- [x] Write technical specifications (TECHNICAL_SPEC.md)
- [x] Design database schema (DATABASE_SCHEMA.md)
- [x] Update README with project info

## Phase 1: Foundation & Setup

### Environment Setup
- [ ] Set up Supabase project
  - [ ] Create new Supabase project
  - [ ] Run database migrations (from DATABASE_SCHEMA.md)
  - [ ] Create storage bucket `moment-photos`
  - [ ] Configure RLS policies
  - [ ] Get project URL and anon key
- [ ] Set up Google Maps
  - [ ] Create Google Cloud project
  - [ ] Enable Maps SDK for Android
  - [ ] Enable Maps SDK for iOS
  - [ ] Generate API keys
  - [ ] Enable billing (if needed)
- [ ] Create `.env` file with credentials
- [ ] Add `.env` to `.gitignore`

### Project Configuration
- [ ] Update `pubspec.yaml` with all dependencies
  - [ ] supabase_flutter
  - [ ] brick_offline_first_with_supabase
  - [ ] google_maps_flutter
  - [ ] motor
  - [ ] flutter_animate
  - [ ] go_router
  - [ ] provider
  - [ ] cached_network_image
  - [ ] flutter_dotenv
  - [ ] image_picker
  - [ ] logger
- [ ] Configure Android
  - [ ] Update `AndroidManifest.xml` with Maps key
  - [ ] Set minimum SDK version (21+)
  - [ ] Add internet permissions
- [ ] Configure iOS
  - [ ] Update `Info.plist` with Maps key
  - [ ] Add location permissions
  - [ ] Add photo library permissions
- [ ] Download and add fonts
  - [ ] Bebas Neue
  - [ ] Inter
- [ ] Run `flutter pub get`

### Core Structure
- [ ] Create folder structure
  - [ ] `lib/core/theme/`
  - [ ] `lib/core/utils/`
  - [ ] `lib/data/models/`
  - [ ] `lib/data/sources/local/`
  - [ ] `lib/data/sources/remote/`
  - [ ] `lib/data/repositories/`
  - [ ] `lib/features/map/presentation/`
  - [ ] `lib/features/moments/presentation/`
  - [ ] `lib/features/moments/data/`
  - [ ] `lib/widgets/`
- [ ] Create `analysis_options.yaml` with strict lints
- [ ] Create `.gitignore` entries

## Phase 2: Core Theme & Utilities

### Theme Setup
- [ ] Create `lib/core/theme/app_colors.dart`
  - [ ] Define color palette
  - [ ] Primary, background, text colors
- [ ] Create `lib/core/theme/app_typography.dart`
  - [ ] Define text styles
  - [ ] Bebas Neue for headings
  - [ ] Inter for body text
- [ ] Create `lib/core/theme/app_theme.dart`
  - [ ] Combine colors and typography
  - [ ] Define ThemeData
  - [ ] Set button styles, card styles
- [ ] Create `lib/core/utils/constants.dart`
  - [ ] API endpoints
  - [ ] Spacing constants
  - [ ] Animation durations
- [ ] Create `lib/core/utils/extensions.dart`
  - [ ] String extensions
  - [ ] DateTime extensions
  - [ ] BuildContext extensions

### Shared Widgets
- [ ] Create `lib/widgets/bouncing_card.dart`
  - [ ] Implement Motor spring animation
  - [ ] Scale on press
  - [ ] Configurable press scale
- [ ] Create `lib/widgets/app_button.dart`
  - [ ] Primary and secondary variants
  - [ ] Loading state
  - [ ] Disabled state
  - [ ] Use BouncingCard wrapper
- [ ] Create `lib/widgets/loading_indicator.dart`
  - [ ] Custom loading spinner
  - [ ] Match app theme
- [ ] Create `lib/widgets/error_view.dart`
  - [ ] Display error messages
  - [ ] Retry button
  - [ ] Empty state variant

## Phase 3: Data Layer

### Models
- [ ] Create `lib/data/models/moment.dart`
  - [ ] Add Brick annotations
  - [ ] Define all fields
  - [ ] Add validation methods
- [ ] Create `lib/data/models/moment_image.dart`
  - [ ] Add Brick annotations
  - [ ] Define fields
- [ ] Create DTOs
  - [ ] `lib/data/models/create_moment_dto.dart`
  - [ ] `lib/data/models/update_moment_dto.dart`
- [ ] Run build_runner
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```

### Data Sources
- [ ] Create `lib/data/sources/remote/supabase_data_source.dart`
  - [ ] Initialize Supabase client
  - [ ] Implement CRUD operations
  - [ ] Image upload methods
  - [ ] Error handling
- [ ] Create `lib/data/sources/local/brick_data_source.dart`
  - [ ] Initialize Brick
  - [ ] Configure SQLite
  - [ ] Set up sync policies

### Repository
- [ ] Create `lib/data/repositories/moment_repository.dart`
  - [ ] Implement offline-first pattern
  - [ ] getAllMoments()
  - [ ] getMomentById()
  - [ ] createMoment()
  - [ ] updateMoment()
  - [ ] deleteMoment()
  - [ ] uploadImage()
  - [ ] syncWithRemote()
- [ ] Create `lib/data/repositories/moment_repository_impl.dart`
  - [ ] Implement interface
  - [ ] Handle online/offline states
  - [ ] Queue operations when offline

## Phase 4: State Management

### Providers
- [ ] Create `lib/core/providers/app_provider.dart`
  - [ ] App initialization state
  - [ ] User authentication state
  - [ ] Network connectivity state
- [ ] Create `lib/features/moments/presentation/providers/moments_provider.dart`
  - [ ] Moments list state
  - [ ] Loading states
  - [ ] Error states
  - [ ] CRUD operations
- [ ] Create `lib/features/map/presentation/providers/map_provider.dart`
  - [ ] Map state
  - [ ] Camera position
  - [ ] Visible markers
  - [ ] Clustering logic

## Phase 5: Navigation

### Router Setup
- [ ] Create `lib/core/router/app_router.dart`
  - [ ] Define routes
  - [ ] Configure transitions
  - [ ] Error handling
- [ ] Define routes:
  - [ ] `/` → MapPage
  - [ ] `/moment/:id` → MomentDetailPage
  - [ ] `/new` → AddMomentPage
- [ ] Add custom page transitions
  - [ ] Slide up for detail page
  - [ ] Fade for modal pages

## Phase 6: Map Feature

### Map Page
- [ ] Create `lib/features/map/presentation/map_page.dart`
  - [ ] GoogleMap widget integration
  - [ ] Initial camera position
  - [ ] Map controls
  - [ ] AppBar with title and profile icon
- [ ] Create `lib/features/map/presentation/widgets/moment_marker.dart`
  - [ ] Custom marker design
  - [ ] Thumbnail image
  - [ ] Title and date
  - [ ] Tap animation
  - [ ] Match reference design
- [ ] Create `lib/features/map/presentation/widgets/add_moment_button.dart`
  - [ ] Floating action button
  - [ ] "+" icon with label
  - [ ] Bounce animation
  - [ ] Navigate to create page
- [ ] Implement marker clustering
  - [ ] Group markers when zoomed out
  - [ ] Show count badge
  - [ ] Expand on zoom in
- [ ] Add map interactions
  - [ ] Pan and zoom
  - [ ] Tap marker → navigate to detail
  - [ ] Long press → create moment here (optional)

### Map Logic
- [ ] Load moments from repository
- [ ] Convert moments to markers
- [ ] Update markers on data change
- [ ] Handle marker taps
- [ ] Optimize rendering (lazy load)

## Phase 7: Moment Detail Feature

### Detail Page
- [ ] Create `lib/features/moments/presentation/moment_detail_page.dart`
  - [ ] Hero animation from marker
  - [ ] Slide-up transition
  - [ ] Back button with animation
  - [ ] Scrollable content
- [ ] Create `lib/features/moments/presentation/widgets/photo_collage.dart`
  - [ ] Display multiple images
  - [ ] PageView or GridView
  - [ ] Pinch to zoom
  - [ ] Swipe navigation
  - [ ] Stickers/overlays (optional for MVP)
- [ ] Create `lib/features/moments/presentation/widgets/moment_header.dart`
  - [ ] Large title (Bebas Neue)
  - [ ] Photo count and date
  - [ ] User avatars
  - [ ] Share button (optional)
- [ ] Create `lib/features/moments/presentation/widgets/location_info.dart`
  - [ ] Location name
  - [ ] Distance from user (optional)
  - [ ] Map thumbnail (optional)
- [ ] Create `lib/features/moments/presentation/widgets/action_toolbar.dart`
  - [ ] Emoji button
  - [ ] Edit button
  - [ ] Text button
  - [ ] Preview button (primary)

### Detail Logic
- [ ] Fetch moment by ID
- [ ] Load all images
- [ ] Preload images for smooth scrolling
- [ ] Handle loading states
- [ ] Handle errors (moment not found)

## Phase 8: Create Moment Feature

### Add Moment Page
- [ ] Create `lib/features/moments/presentation/add_moment_page.dart`
  - [ ] Form fields (title, location)
  - [ ] Image picker integration
  - [ ] Location picker (map or current location)
  - [ ] Save button
  - [ ] Cancel button
  - [ ] Loading overlay during upload
- [ ] Create `lib/features/moments/presentation/widgets/image_picker_widget.dart`
  - [ ] Camera option
  - [ ] Gallery option
  - [ ] Display selected images
  - [ ] Remove image option
  - [ ] Reorder images (optional)
- [ ] Create `lib/features/moments/presentation/widgets/location_picker_widget.dart`
  - [ ] Mini map view
  - [ ] "Use Current Location" button
  - [ ] Manual address input
  - [ ] Geocoding (optional)
- [ ] Create `lib/features/moments/presentation/widgets/moment_form.dart`
  - [ ] Title text field
  - [ ] Location text field
  - [ ] Validation feedback
  - [ ] Form state management

### Create Logic
- [ ] Validate form inputs
- [ ] Compress images before upload
- [ ] Upload images to Supabase Storage
- [ ] Create moment record
- [ ] Handle offline creation (queue)
- [ ] Show upload progress
- [ ] Navigate back on success
- [ ] Handle errors gracefully

## Phase 9: Animations & Polish

### Motor Animations
- [ ] Marker appearance animation
- [ ] Marker tap animation
- [ ] Page transitions
- [ ] Button press feedback
- [ ] Card hover effects (optional)

### Flutter Animate
- [ ] Fade in for images
- [ ] Stagger animations for lists
- [ ] Scale animations for cards
- [ ] Shimmer for loading states

### Performance Optimization
- [ ] Image caching
- [ ] Lazy loading for markers
- [ ] Debounce map movements
- [ ] Optimize rebuild cycles
- [ ] Test on real devices

## Phase 10: Testing

### Unit Tests
- [ ] Test moment model
  - [ ] JSON serialization
  - [ ] Validation methods
  - [ ] Copy with method
- [ ] Test moment repository
  - [ ] CRUD operations
  - [ ] Offline behavior
  - [ ] Sync logic
  - [ ] Error handling
- [ ] Test utilities and extensions

### Widget Tests
- [ ] Test BouncingCard
- [ ] Test AppButton
- [ ] Test MomentMarker
- [ ] Test PhotoCollage
- [ ] Test forms and inputs

### Integration Tests
- [ ] Test create moment flow
  - [ ] Pick images
  - [ ] Fill form
  - [ ] Submit
  - [ ] Verify creation
- [ ] Test view moment flow
  - [ ] Tap marker
  - [ ] View details
  - [ ] Navigate back
- [ ] Test offline mode
  - [ ] Create moment offline
  - [ ] View cached moments
  - [ ] Sync when online

## Phase 11: Error Handling & Edge Cases

### Error Scenarios
- [ ] No internet connection
  - [ ] Show offline banner
  - [ ] Queue operations
  - [ ] Inform user
- [ ] Failed image upload
  - [ ] Retry logic
  - [ ] Save draft locally
  - [ ] User feedback
- [ ] Invalid location data
  - [ ] Validation messages
  - [ ] Fallback to default
- [ ] Moment not found
  - [ ] 404 page
  - [ ] Navigate back
- [ ] Database errors
  - [ ] Graceful degradation
  - [ ] Error logging

### Edge Cases
- [ ] Empty states
  - [ ] No moments yet
  - [ ] No images
  - [ ] No location
- [ ] Large datasets
  - [ ] Pagination
  - [ ] Virtual scrolling
- [ ] Slow network
  - [ ] Progress indicators
  - [ ] Timeout handling
- [ ] Permissions denied
  - [ ] Location permission
  - [ ] Camera permission
  - [ ] Photo library permission

## Phase 12: Documentation & Cleanup

### Code Documentation
- [ ] Add doc comments to all public APIs
- [ ] Document complex logic
- [ ] Add usage examples

### User Documentation
- [ ] Create user guide (optional)
- [ ] Add tooltips in app
- [ ] Onboarding screen (optional)

### Code Cleanup
- [ ] Remove unused imports
- [ ] Remove commented code
- [ ] Run `dart format .`
- [ ] Run `flutter analyze`
- [ ] Fix all warnings

## Phase 13: Pre-Launch

### Final Checks
- [ ] Test on multiple devices
  - [ ] Android (various screen sizes)
  - [ ] iOS (various models)
- [ ] Test all user flows
- [ ] Verify offline functionality
- [ ] Check performance
  - [ ] App startup time
  - [ ] Map rendering
  - [ ] Animation smoothness
- [ ] Security review
  - [ ] No hardcoded credentials
  - [ ] RLS policies working
  - [ ] Input validation
- [ ] Accessibility check
  - [ ] Screen reader support
  - [ ] Contrast ratios
  - [ ] Touch targets

### Deployment Prep
- [ ] Generate app icons
- [ ] Create splash screen
- [ ] Prepare app store assets
  - [ ] Screenshots
  - [ ] Description
  - [ ] Keywords
- [ ] Set up crash reporting (optional)
- [ ] Set up analytics (optional)
- [ ] Configure app signing
  - [ ] Android: keystore
  - [ ] iOS: provisioning profiles

## Post-MVP Features (Future)

- [ ] User authentication
  - [ ] Sign up / Login
  - [ ] Profile management
  - [ ] Password reset
- [ ] Social features
  - [ ] Like moments
  - [ ] Comment on moments
  - [ ] Share moments
  - [ ] Follow users
- [ ] Enhanced features
  - [ ] Filters and categories
  - [ ] Search moments
  - [ ] Private moments
  - [ ] Collaborative moments
- [ ] Advanced features
  - [ ] AR view mode
  - [ ] Stories feature
  - [ ] Push notifications
  - [ ] In-app messaging

---

## Daily Development Checklist

Each day before coding:
- [ ] Pull latest changes (if team)
- [ ] Review PLAN.md and RULES.md
- [ ] Check current phase tasks
- [ ] Run `flutter pub get` if needed

Each day after coding:
- [ ] Run `flutter analyze`
- [ ] Run `dart format .`
- [ ] Run relevant tests
- [ ] Commit changes with clear message
- [ ] Update this checklist
- [ ] Document any blockers or issues

---

## Notes & Issues

*Use this section to track blockers, questions, or important decisions*

---

**Progress:** 6/13 phases completed (Planning phase)
**Next Up:** Phase 1 - Foundation & Setup
**Estimated Time:** 4-5 weeks for MVP
