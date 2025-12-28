# Moments App - Interactive Map-Based Photo Sharing

A Flutter app that allows users to create location-based photo moments and view them on an interactive map.

## Features

- 📍 **Map-Based Interface**: Interactive Google Maps showing moment locations
- 📸 **Photo Moments**: Create moments with photos, titles, and descriptions
- 🌍 **Location Services**: Auto-detect current location or manually select
- 📱 **Cross-Platform**: iOS and Android support
- 🎨 **Beautiful UI**: Playful, layered design with smooth animations

## Setup Instructions

### 1. Prerequisites
- Flutter 3.10+
- Dart 3.0+
- Android Studio / Xcode for device testing
- Supabase account
- Google Maps API key

### 2. Environment Setup

1. Clone the repository
2. Copy `.env.example` to `.env` and fill in your credentials:
   ```
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   GOOGLE_MAPS_API_KEY=your_google_maps_api_key
   ```

### 3. Database Setup

1. Go to your Supabase dashboard
2. Navigate to the SQL editor
3. Run the SQL script from `database_setup.sql`

### 4. Google Maps Setup

#### Android
- API key is already configured in `android/app/src/main/AndroidManifest.xml`
- Make sure your API key has Android restrictions enabled

#### iOS
- Add your API key to `ios/Runner/AppDelegate.swift`:
  ```swift
  GMSServices.provideAPIKey("YOUR_API_KEY")
  ```

### 5. Install Dependencies

```bash
flutter pub get
```

### 6. Run the App

```bash
# Debug mode
flutter run

# Release mode
flutter run --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── theme/               # App theming and styling
│   ├── utils/               # Utilities and extensions
│   └── router/              # Navigation setup
├── data/
│   ├── models/              # Data models (Moment)
│   ├── sources/             # Data sources (Supabase)
│   └── repositories/        # Repository pattern implementation
├── features/
│   ├── map/                 # Map interface
│   └── moments/             # Moment creation and details
└── widgets/                 # Reusable UI components
```

## Key Components

### Map Page
- Interactive Google Maps
- Moment markers with preview
- Current location detection
- Floating "New Moment" button

### Moment Creation
- Camera/Gallery photo selection
- Title and location input
- Description (optional)
- GPS location capture

### Moment Details
- Full-screen photo view
- Location information
- Preview functionality
- Hero transitions

## Architecture

- **Clean Architecture**: Separation of concerns with data, domain, and presentation layers
- **Repository Pattern**: Centralized data access
- Local caching with online sync
- **State Management**: StatefulWidget with minimal state

## Design System

### Colors
- Primary Blue: `#306BFF`
- Background Beige: `#FAF8F6`
- Text Dark: `#2D3748`
- Card White: `#FFFFFF`

### Typography
- Headers: Bebas Neue (bold, condensed)
- Body: Inter (readable, modern)

### Animations
- Bouncy button interactions
- Smooth page transitions
- Physics-based motion

## API Integration

### Supabase Features Used
- **Database**: PostgreSQL with PostGIS for geospatial queries
- **Storage**: Image upload and hosting
- **Real-time**: Live updates (future feature)
- **Row Level Security**: Data protection

### Google Maps Features
- Interactive map display
- Marker clustering
- Current location
- Camera controls

## Permissions

### Android
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `CAMERA`
- `READ_EXTERNAL_STORAGE`
- `INTERNET`

### iOS
- `NSLocationWhenInUseUsageDescription`
- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

## Development Guidelines

See `RULES.md` for coding standards and best practices.

## Troubleshooting

### Common Issues

1. **Location not working**
   - Check device location services are enabled
   - Verify app permissions
   - Test on physical device (simulators may not have GPS)

2. **Images not uploading**
   - Check Supabase storage bucket configuration
   - Verify network connectivity
   - Check file size limits (5MB max)

3. **Map not loading**
   - Verify Google Maps API key
   - Check API key restrictions
   - Ensure Maps SDK is enabled

### Debug Commands

```bash
# Check for issues
flutter analyze

# Run tests
flutter test

# Check dependencies
flutter doctor

# Clean build
flutter clean && flutter pub get
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the coding guidelines in `RULES.md`
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
