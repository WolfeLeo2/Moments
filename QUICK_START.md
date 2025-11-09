# 🚀 Moments App - Quick Start Guide

**Welcome!** This guide will get you from zero to running app in under 30 minutes.

---

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [ ] Flutter SDK 3.10+ installed (`flutter --version`)
- [ ] Dart SDK 3.10+ installed (comes with Flutter)
- [ ] Android Studio (for Android development)
- [ ] Xcode (for iOS development - Mac only)
- [ ] Git installed
- [ ] A code editor (VS Code or Android Studio recommended)
- [ ] A Supabase account (free at [supabase.com](https://supabase.com))
- [ ] A Google Cloud account (for Maps API)

---

## ⚡ 5-Minute Setup (Before Coding)

### Step 1: Clone/Navigate to Project
```bash
cd /Users/app/AndroidStudioProjects/Moments
```

### Step 2: Read Key Documents (10 mins)
1. Open [CLARIFICATIONS.md](CLARIFICATIONS.md) - **Critical updates**
2. Skim [PROJECT_SUMMARY.md](PROJECT_SUMMARY.md) - Big picture
3. Keep [CHECKLIST.md](CHECKLIST.md) handy - Your task list

---

## 🔧 Environment Setup (15 minutes)

### 1. Create Supabase Project

**Go to:** [supabase.com/dashboard](https://supabase.com/dashboard)

1. Click "New Project"
2. Name: `moments-mvp`
3. Database Password: (save this!)
4. Region: Choose closest to you
5. Click "Create new project"
6. **Wait 2 minutes** for provisioning

**Get Your Credentials:**
- Go to Settings → API
- Copy `Project URL`
- Copy `anon/public` key

### 2. Set Up Database

**In Supabase Dashboard:**
1. Go to SQL Editor
2. Create new query
3. Paste and run:

```sql
-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "earthdistance" CASCADE;

-- Create moments table (MVP - no auth)
CREATE TABLE moments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL CHECK (char_length(title) >= 3 AND char_length(title) <= 100),
  location TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL CHECK (latitude >= -90 AND latitude <= 90),
  longitude DOUBLE PRECISION NOT NULL CHECK (longitude >= -180 AND longitude <= 180),
  image_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for location clustering
CREATE INDEX idx_moments_location ON moments USING GIST (
  ll_to_earth(latitude, longitude)
);

-- Enable RLS (but allow all for MVP)
ALTER TABLE moments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view moments"
  ON moments FOR SELECT
  USING (true);

CREATE POLICY "Anyone can create moments (MVP)"
  ON moments FOR INSERT
  WITH CHECK (true);
```

### 3. Create Storage Bucket

**In Supabase Dashboard:**
1. Go to Storage
2. Click "New bucket"
3. Name: `moments`
4. Public bucket: **YES** ✅
5. Click "Create bucket"
6. Click on bucket → Click "Policies"
7. Add policy:
   - Name: "Public upload (MVP)"
   - INSERT: Allow all
   - SELECT: Allow all

### 4. Get Google Maps API Keys

**Go to:** [console.cloud.google.com](https://console.cloud.google.com)

1. Create new project: "Moments App"
2. Go to APIs & Services → Library
3. Enable: "Maps SDK for Android"
4. Enable: "Maps SDK for iOS"
5. Go to Credentials → Create Credentials → API Key
6. Create **two separate keys**:
   - One for Android
   - One for iOS
7. Restrict each key to respective platform
8. **Copy both keys**

### 5. Create Environment File

**In project root:**
```bash
cd /Users/app/AndroidStudioProjects/Moments
touch .env
```

**Edit `.env`:**
```env
# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here

# Google Maps
GOOGLE_MAPS_API_KEY_ANDROID=your-android-key
GOOGLE_MAPS_API_KEY_IOS=your-ios-key
```

**Add to `.gitignore`:**
```bash
echo ".env" >> .gitignore
```

---

## 📦 Install Dependencies (5 minutes)

### 1. Update `pubspec.yaml`

Replace the dependencies section with:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Backend & Offline-First
  supabase_flutter: ^2.5.0
  brick_offline_first_with_supabase: ^4.0.0
  
  # Maps & Location
  google_maps_flutter: ^2.5.0
  geolocator: ^11.0.0
  
  # UI & Design
  google_fonts: ^6.1.0
  cached_network_image: ^3.3.0
  
  # Animation
  motor: ^0.2.0
  flutter_animate: ^4.5.0
  
  # Navigation & State
  go_router: ^13.0.0
  provider: ^6.1.0
  
  # Media
  image_picker: ^1.0.7
  image: ^4.1.0
  
  # Utilities
  flutter_dotenv: ^5.1.0
  permission_handler: ^11.2.0
  logger: ^2.0.0
  uuid: ^4.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  brick_offline_first_with_supabase_generator: ^4.0.0
  flutter_lints: ^6.0.0
```

### 2. Install Packages

```bash
flutter pub get
```

---

## 🤖 Configure Android (3 minutes)

### 1. Add Google Maps Key

**File:** `android/app/src/main/AndroidManifest.xml`
