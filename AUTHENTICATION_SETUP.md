# Authentication Setup Guide

## ✅ Current Status
- ✅ Google Sign In package installed (`google_sign_in: ^6.3.0`)
- ✅ AuthService created with Google & Email authentication
- ✅ LoginPage created with neubrutalism design
- ✅ Router configured with authentication redirect logic
- ✅ Environment variables configured (.env file)

## 🔐 Google Sign-In Configuration

### Environment Variables (Already Set)
Your `.env` file contains:
```
SUPABASE_GOOGLE_WEB_CLIENT_ID=837716303354-icka1slhlp723lekmsumg8ep4n310ni8.apps.googleusercontent.com
SUPABASE_GOOGLE_ANDROID_CLIENT_ID=837716303354-v1d1sqarke414sa7b80csbipjhdgrptt.apps.googleusercontent.com
```

### Android Configuration Steps

1. **SHA-1 Certificate Fingerprint** (Required for Google Sign-In)
   
   Run this command to get your SHA-1:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   
   Look for the SHA-1 under `Variant: debug` and `Config: debug`

2. **Add SHA-1 to Firebase Console**
   
   - Go to [Firebase Console](https://console.firebase.google.com)
   - Select your project
   - Go to Project Settings > General
   - Scroll to "Your apps" > Android app
   - Add your SHA-1 fingerprint
   - Download the updated `google-services.json`
   - Place it in `android/app/google-services.json`

3. **Supabase Configuration**
   
   Your Google OAuth credentials are already configured in Supabase:
   - Web Client ID: `837716303354-icka1slhlp723lekmsumg8ep4n310ni8.apps.googleusercontent.com`
   - Android Client ID: `837716303354-v1d1sqarke414sa7b80csbipjhdgrptt.apps.googleusercontent.com`

### iOS Configuration (Optional)

Add to `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.837716303354-icka1slhlp723lekmsumg8ep4n310ni8</string>
    </array>
  </dict>
</array>
```

## 🎨 Features Implemented

### 1. AuthService (`lib/core/services/auth_service.dart`)
**Capabilities:**
- ✅ Google Sign In with Supabase integration
- ✅ Email/Password sign in and sign up
- ✅ Auto-create/update user profile in `profiles` table
- ✅ Sign out (clears Google and Supabase sessions)
- ✅ Password reset
- ✅ Auth state stream
- ✅ User metadata (photo URL, display name, email)

**Methods:**
```dart
// Properties
bool get isSignedIn
String? get currentUserPhotoUrl
String? get currentUserDisplayName
String? get currentUserEmail
Stream<AuthState> get authStateChanges

// Methods
Future<AuthResponse> signInWithGoogle()
Future<AuthResponse> signInWithEmail(email, password)
Future<AuthResponse> signUpWithEmail(email, password, {displayName})
Future<void> signOut()
Future<void> resetPassword(email)
```

### 2. LoginPage (`lib/features/auth/presentation/login_page.dart`)
**Features:**
- ✅ Neubrutalism design matching app aesthetic
- ✅ Google Sign In button (primary method)
- ✅ Email/Password toggle (optional)
- ✅ Sign Up / Sign In toggle
- ✅ Large "MOMENTS" title with cutout effect
- ✅ Spring animations on buttons
- ✅ Error handling with SnackBars

**UI Elements:**
- Large branded header with cutout text effect
- Google Sign In button (white with Google logo)
- Email/Password fields (expandable)
- Sign Up/Sign In toggle
- All styled with brutal borders and hard shadows

### 3. Router Updates (`lib/core/router/app_router.dart`)
**Features:**
- ✅ `/login` route added
- ✅ Authentication redirect logic
- ✅ Auto-redirect to map when signed in
- ✅ Auto-redirect to login when signed out
- ✅ Initial route set to `/login`

### 4. Map Page Integration
**Features:**
- ✅ Profile avatar in app bar (shows Google photo)
- ✅ Profile dialog with user info and sign out
- ✅ Uses AuthService to get current user data

## 📊 Database Schema

The `profiles` table should have:
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
  ON profiles FOR SELECT
  USING (true);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  WITH CHECK (auth.uid() = id);
```

## 🚀 Testing Authentication

### 1. First Launch
1. App starts on Login page
2. Click "CONTINUE WITH GOOGLE"
3. Select Google account
4. Redirects to Map page
5. Profile avatar appears in app bar

### 2. Avatar Display
- App bar shows Google profile photo
- Click avatar to see profile dialog
- Dialog shows name, email, and sign out button

### 3. Sign Out Flow
1. Click profile avatar
2. Click "Sign Out"
3. Redirects back to Login page
4. Google session cleared

## 🎯 Next Steps

1. **Run the app** - Authentication should work immediately
2. **Test Google Sign In** - Verify profile photo appears
3. **Check database** - Verify profile created in Supabase
4. **Add Google logo asset** (optional):
   - Download Google logo PNG
   - Save to `assets/images/google_logo.png`
   - Update `pubspec.yaml` assets section

## 🐛 Troubleshooting

### "Sign in failed" Error
- Verify SHA-1 fingerprint added to Firebase
- Check `google-services.json` is in `android/app/`
- Ensure Supabase Google OAuth is configured
- Check `.env` file has correct client IDs

### Avatar doesn't show
- Check Supabase profiles table exists
- Verify RLS policies allow SELECT
- Check AuthService is creating profile correctly

### "PlatformException" on Android
- Verify SHA-1 certificate registered
- Check package name matches Firebase
- Rebuild app: `flutter clean && flutter run`

## 📱 Platform Requirements

### Android
- ✅ Minimum SDK: 21 (Android 5.0)
- ✅ Google Play Services
- ⚠️ SHA-1 fingerprint required
- ⚠️ google-services.json required

### iOS
- ✅ iOS 12.0+
- ⚠️ Info.plist URL scheme configuration
- ⚠️ May need iOS client ID from Google Console

## 🔗 Useful Links

- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Google Sign-In Flutter](https://pub.dev/packages/google_sign_in)
- [Firebase Console](https://console.firebase.google.com)
- [Supabase Dashboard](https://supabase.com/dashboard)
