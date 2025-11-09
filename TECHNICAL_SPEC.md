# Moments - Technical Specification

## 1. Core Functions & Logic

### 1.1 Map Display & Interaction
**Component:** `MapPage`

**Functions:**
- `initializeMap()` - Loads Google Maps with initial camera position
- `loadMomentsFromRepository()` - Fetches all moments (offline-first)
- `renderMomentMarkers()` - Displays moments as custom markers on map
- `onMarkerTapped(String momentId)` - Navigates to moment detail
- `onMapCameraMove()` - Updates visible markers based on viewport
- `clusterMarkers()` - Groups nearby markers when zoomed out

**State:**
```dart
class MapPageState {
  GoogleMapController? mapController;
  List<Moment> moments;
  Set<Marker> markers;
  LatLng currentPosition;
  bool isLoading;
  String? error;
}
```

**Logic Flow:**
1. App launches → Show splash/loading
2. Initialize Supabase & Brick
3. Load cached moments from local DB
4. Display map with cached markers immediately
5. Background sync with Supabase
6. Update markers if new data arrives
7. Listen for real-time updates (optional)

---

### 1.2 Moment Data Management
**Component:** `MomentRepository`

**Functions:**
```dart
// Read operations
Future<List<Moment>> getAllMoments()
Future<Moment?> getMomentById(String id)
Future<List<Moment>> getMomentsInBounds(LatLngBounds bounds)

// Write operations
Future<Moment> createMoment(CreateMomentDto dto)
Future<Moment> updateMoment(String id, UpdateMomentDto dto)
Future<void> deleteMoment(String id)

// Image operations
Future<String> uploadImage(File image, String momentId)
Future<List<String>> uploadMultipleImages(List<File> images, String momentId)

// Sync operations
Future<void> syncWithRemote()
Future<bool> hasLocalChanges()
```

**Offline-First Logic:**
```
CREATE/UPDATE Flow:
1. Validate input data
2. Save to local SQLite (via Brick)
3. Add to sync queue
4. Return success to UI immediately
5. Background: Attempt upload to Supabase
6. On success: Mark as synced
7. On failure: Retry with exponential backoff

READ Flow:
1. Query local SQLite first
2. Return cached data immediately
3. Background: Fetch from Supabase
4. Compare timestamps
5. Update local DB if remote is newer
6. Emit updated data to UI
```

**Conflict Resolution:**
- Last-write-wins for simple conflicts
- Show merge UI for complex conflicts
- Always preserve local data in conflict

---

### 1.3 Moment Creation Flow
**Component:** `AddMomentPage`

**Functions:**
- `pickImages()` - Opens image picker (camera or gallery)
- `selectLocation()` - Shows map picker or uses current location
- `validateForm()` - Ensures all required fields are filled
- `compressImages()` - Reduces image size before upload
- `saveMoment()` - Calls repository to create moment
- `showUploadProgress()` - Displays progress indicator

**Validation Rules:**
```dart
class MomentValidation {
  static bool validateTitle(String title) {
    return title.isNotEmpty && title.length >= 3 && title.length <= 100;
  }
  
  static bool validateLocation(String location) {
    return location.isNotEmpty;
  }
  
  static bool validateImages(List<File> images) {
    return images.isNotEmpty && images.length <= 10;
  }
  
  static bool validateCoordinates(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}
```

**State Machine:**
```
States:
- IDLE → User can fill form
- VALIDATING → Checking inputs
- UPLOADING → Sending to backend
- SUCCESS → Moment created
- ERROR → Show error message

Transitions:
IDLE → (submit) → VALIDATING
VALIDATING → (valid) → UPLOADING
VALIDATING → (invalid) → IDLE (show errors)
UPLOADING → (success) → SUCCESS → navigate back
UPLOADING → (failure) → ERROR → IDLE (retry)
```

---

### 1.4 Moment Detail View
**Component:** `MomentDetailPage`

**Functions:**
- `loadMomentDetails(String id)` - Fetches full moment data
- `preloadImages()` - Loads all images before displaying
- `animateEntry()` - Slide-up animation on page open
- `animateExit()` - Slide-down animation on close
- `handlePreview()` - Shows fullscreen photo viewer
- `handleShare()` - Shares moment (future feature)

**UI Elements & Logic:**
```dart
class MomentDetailUI {
  // Header
  Widget buildHeader() {
    return Stack([
      BackButton with spring animation,
      Title with animated text reveal,
      Share button (optional)
    ]);
  }
  
  // Photo collage
  Widget buildPhotoCollage() {
    return PageView or GridView with:
    - Cached images
    - Pinch to zoom
    - Swipe to navigate
    - Stickers/overlays
  }
  
  // Location info
  Widget buildLocationInfo() {
    return Row([
      Icon(location pin),
      Text(location name),
      Distance from user (optional)
    ]);
  }
  
  // Action toolbar
  Widget buildActionBar() {
    return Row([
      EmojiButton(),
      DrawButton(),
      TextButton(),
      PreviewButton() // Primary action
    ]);
  }
}
```

---

### 1.5 Animation System
**Package Integration:** Motor + flutter_animate

**Animation Specifications:**

#### Map Marker Animations
```dart
// Marker appears
Motor.run(
  from: 0.0,
  to: 1.0,
  spring: Spring.snappy,
  duration: 400.ms,
  onUpdate: (value) {
    scale = value;
    opacity = value;
  }
);

// Marker tap
Motor.run(
  from: 1.0,
  to: 0.95,
  spring: Spring.gentle,
  duration: 100.ms,
  reverse: true,
);
```

#### Page Transitions
```dart
// Map → Detail
PageTransition(
  type: SlideUp,
  duration: 350.ms,
  curve: Curves.easeOutCubic,
  child: MomentDetailPage(),
);

// With Motor spring
Motor.run(
  from: screenHeight,
  to: 0,
  spring: Spring.bouncy,
  onUpdate: (value) => offset = Offset(0, value),
);
```

#### Button Press Feedback
```dart
GestureDetector(
  onTapDown: (_) => Motor.animate(scale, to: 0.98),
  onTapUp: (_) => Motor.animate(scale, to: 1.0),
  onTapCancel: () => Motor.animate(scale, to: 1.0),
);
```

---

### 1.6 State Management Architecture

**Chosen Approach:** Provider (can be switched to Riverpod)

**State Structure:**
```dart
// App-level state
class AppState extends ChangeNotifier {
  bool isInitialized = false;
  User? currentUser;
  
  Future<void> initialize() async {
    await Supabase.initialize();
    await BrickOfflineFirst.initialize();
    isInitialized = true;
    notifyListeners();
  }
}

// Feature state
class MomentsState extends ChangeNotifier {
  List<Moment> _moments = [];
  bool _isLoading = false;
  String? _error;
  
  List<Moment> get moments => _moments;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> loadMoments() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _moments = await _repository.getAllMoments();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> createMoment(CreateMomentDto dto) async {
    final newMoment = await _repository.createMoment(dto);
    _moments.insert(0, newMoment);
    notifyListeners();
  }
}
```

**Provider Setup:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppState()),
    ChangeNotifierProvider(create: (_) => MomentsState()),
    Provider(create: (_) => MomentRepository()),
  ],
  child: MyApp(),
);
```

---

### 1.7 Navigation Architecture

**Router Configuration:**
```dart
final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'map',
      builder: (context, state) => MapPage(),
    ),
    GoRoute(
      path: '/moment/:id',
      name: 'momentDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MomentDetailPage(momentId: id);
      },
      pageBuilder: (context, state) {
        final id = state.pathParameters['id']!;
        return CustomTransitionPage(
          child: MomentDetailPage(momentId: id),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/new',
      name: 'addMoment',
      builder: (context, state) => AddMomentPage(),
    ),
  ],
  errorBuilder: (context, state) => ErrorPage(error: state.error),
);
```

**Navigation Calls:**
```dart
// Navigate to moment detail
context.push('/moment/${moment.id}');

// Navigate to add moment
context.push('/new');

// Go back
context.pop();

// Replace current route
context.go('/');
```

---

### 1.8 Image Handling Pipeline

**Upload Flow:**
```dart
Future<String> uploadImage(File imageFile, String momentId) async {
  // 1. Compress image
  final compressed = await compressImage(
    imageFile,
    maxWidth: 1920,
    maxHeight: 1920,
    quality: 85,
  );
  
  // 2. Generate unique filename
  final fileName = '${momentId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
  
  // 3. Upload to Supabase Storage
  final path = await supabase.storage
    .from('moment-photos')
    .upload(fileName, compressed);
  
  // 4. Get public URL
  final url = supabase.storage
    .from('moment-photos')
    .getPublicUrl(fileName);
  
  return url;
}
```

**Display with Caching:**
```dart
CachedNetworkImage(
  imageUrl: moment.imageUrl,
  placeholder: (context, url) => Shimmer(...),
  errorWidget: (context, url, error) => Icon(Icons.error),
  fadeInDuration: Duration(milliseconds: 300),
  memCacheWidth: 800, // Resize for performance
  memCacheHeight: 800,
);
```

---

### 1.9 Error Handling Strategy

**Error Types:**
```dart
abstract class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, [this.code]);
}

class NetworkException extends AppException {
  NetworkException(String message) : super(message, 'NETWORK_ERROR');
}

class ValidationException extends AppException {
  final Map<String, String> fieldErrors;
  ValidationException(this.fieldErrors) : super('Validation failed', 'VALIDATION_ERROR');
}

class StorageException extends AppException {
  StorageException(String message) : super(message, 'STORAGE_ERROR');
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Not authorized', 'UNAUTHORIZED');
}
```

**Global Error Handler:**
```dart
class ErrorHandler {
  static void handle(dynamic error, {VoidCallback? onRetry}) {
    if (error is NetworkException) {
      _showSnackBar('No internet connection', action: onRetry);
    } else if (error is ValidationException) {
      _showValidationErrors(error.fieldErrors);
    } else if (error is UnauthorizedException) {
      _navigateToLogin();
    } else {
      _showSnackBar('Something went wrong', action: onRetry);
      _logError(error);
    }
  }
}
```

---

### 1.10 Performance Optimization

**Map Marker Clustering:**
```dart
class MarkerClusterManager {
  Set<Marker> clusterMarkers(List<Moment> moments, double zoomLevel) {
    if (zoomLevel > 15) {
      // Show individual markers
      return moments.map((m) => createMarker(m)).toSet();
    } else {
      // Cluster nearby markers
      final clusters = _gridBasedClustering(moments);
      return clusters.map((c) => createClusterMarker(c)).toSet();
    }
  }
}
```

**Image Lazy Loading:**
```dart
class LazyImageLoader {
  final Map<String, bool> _loadedImages = {};
  
  bool shouldLoadImage(String url, Rect viewport) {
    if (_loadedImages[url] == true) return false;
    
    // Only load if marker is in viewport
    final markerPosition = getMarkerPosition(url);
    return viewport.contains(markerPosition);
  }
}
```

**List Performance:**
```dart
// Use builder for long lists
ListView.builder(
  itemCount: moments.length,
  itemBuilder: (context, index) {
    final moment = moments[index];
    return MomentCard(
      key: ValueKey(moment.id), // Stable keys
      moment: moment,
    );
  },
);
```

---

## 2. UI Component Specifications

### 2.1 Design System

**Colors:**
```dart
class AppColors {
  static const primary = Color(0xFF306BFF);      // Blue
  static const background = Color(0xFFFAF8F6);   // Light beige
  static const surface = Color(0xFFFFFFFF);      // White
  static const textPrimary = Color(0xFF1A1A1A);  // Almost black
  static const textSecondary = Color(0xFF6B6B6B);// Gray
  static const error = Color(0xFFE63946);         // Red
  static const success = Color(0xFF06D6A0);       // Green
}
```

**Typography:**
```dart
  static const bodyFont = 'Inter';
  static const headingFont = 'Bebas Neue';
  static const bodyFont = 'Inter';
  
  static const h1 = TextStyle(
    fontFamily: headingFont,
    fontFamily: headingFont,
    fontSize: 48,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    height: 1.0,
  );
  static const h2 = TextStyle(
    fontFamily: headingFont,
  static const h2 = TextStyle(
    fontFamily: headingFont,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  static const body = TextStyle(
    fontFamily: bodyFont,
  );
}
```

**Shadows:**
```dart
class AppShadows {
  static const card = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
  
  static const floating = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}
```

---

### 2.2 Reusable Widgets

**BouncingCard Widget:**
```dart
class BouncingCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressScale;
  
  const BouncingCard({
    required this.child,
    this.onTap,
    this.pressScale = 0.98,
  });
  
  @override
  State<BouncingCard> createState() => _BouncingCardState();
}

class _BouncingCardState extends State<BouncingCard> {
  double _scale = 1.0;
  
  void _onTapDown(TapDownDetails details) {
    Motor.run(
      from: _scale,
      to: widget.pressScale,
      spring: Spring.gentle,
      onUpdate: (value) => setState(() => _scale = value),
    );
  }
  
  void _onTapUp(TapUpDetails details) {
    Motor.run(
      from: _scale,
      to: 1.0,
      spring: Spring.bouncy,
      onUpdate: (value) => setState(() => _scale = value),
    );
    widget.onTap?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      child: Transform.scale(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
```

**AppButton Widget:**
```dart
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isPrimary;
  
  const AppButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isPrimary = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return BouncingCard(
      onTap: isLoading ? null : onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [AppShadows.card],
        ),
        child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              label.toUpperCase(),
              style: AppTypography.button.copyWith(
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            ),
      ),
    );
  }
}
```

---

## 3. Data Models

**Moment Model (with Brick):**
```dart
@ConnectOfflineFirstWithSupabase()
class Moment extends OfflineFirstModel {
  @Supabase(unique: true)
  final String id;
  
  @Supabase(name: 'user_id')
  final String userId;
  
  final String title;
  final String location;
  final double latitude;
  final double longitude;
  
  @Supabase(name: 'image_url')
  final String imageUrl;
  
  @Supabase(name: 'created_at')
  final DateTime createdAt;
  
  @Supabase(name: 'updated_at')
  final DateTime updatedAt;
  
  // Optional: Multiple images
  @Supabase(ignore: true)
  List<MomentImage>? images;
  
  Moment({
    required this.id,
    required this.userId,
    required this.title,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.images,
  });
  
  // Brick will generate toJson, fromJson, copyWith
}
```

---

This technical specification covers all core functions, UI components, and logic flows for the Moments MVP. Ready to proceed with implementation whenever you are!

