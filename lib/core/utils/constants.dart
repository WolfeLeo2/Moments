class AppConstants {
  // App Information
  static const String appName = 'Moments';
  static const String appVersion = '1.0.0';

  // Map Configuration
  static const double defaultMapZoom = 15.0;
  static const double minMapZoom = 8.0;
  static const double maxMapZoom = 20.0;

  // Animation Durations (in milliseconds)
  static const int microAnimationDuration = 150;
  static const int standardAnimationDuration = 300;
  static const int longAnimationDuration = 500;
  static const int pageTransitionDuration = 400;

  // Image Configuration
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const int imageQuality = 85;
  static const double maxImageWidth = 1920;
  static const double maxImageHeight = 1920;
  static const double thumbnailSize = 300;

  // Supabase Configuration
  static const String momentsBucket = 'moments';
  static const String momentsTable = 'moments';

  // Location Configuration
  static const double locationAccuracy = 100; // meters
  static const int locationTimeoutSeconds = 30;

  // UI Constants
  static const double fabSize = 56;
  static const double momentMarkerSize = 80;
  static const double momentCardMaxWidth = 300;
  static const double bottomSheetMaxHeight = 0.9;

  // Offline Configuration
  static const int maxOfflineActions = 100;
  static const int syncRetryAttempts = 3;
  static const int syncRetryDelaySeconds = 5;

  // Cache Configuration
  static const int imageCacheMaxAge = 7; // days
  static const int dataCacheMaxAge = 24; // hours

  // Error Messages
  static const String locationPermissionDenied = 'Location permission is required to show your position on the map';
  static const String locationServiceDisabled = 'Location services are disabled. Please enable them in settings';
  static const String cameraPermissionDenied = 'Camera permission is required to take photos';
  static const String storagePermissionDenied = 'Storage permission is required to save photos';
  static const String networkError = 'Network connection error. Please check your internet connection';
  static const String unknownError = 'An unexpected error occurred. Please try again';

  // Success Messages
  static const String momentCreated = 'Moment created successfully!';
  static const String momentUpdated = 'Moment updated successfully!';
  static const String momentDeleted = 'Moment deleted successfully!';
}

