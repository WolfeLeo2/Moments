# Notifications System Documentation

## 🚀 Next Steps (Required Manual Setup)

To fully enable push notifications, you must complete the following configuration steps:

### 1. Firebase Configuration (Completed via FlutterFire)

- **Android**: `google-services.json` is already present in `android/app/` (managed by FlutterFire).
- **iOS**: `GoogleService-Info.plist` is managed by FlutterFire.
  - _Note: iOS Push Notifications require a paid Apple Developer Account to upload an APNs Key to Firebase Console. Until then, notifications will only work on Android._

### 2. Service Account for Edge Function (Completed)

- `supabase/functions/service-account.json` is present.

### 3. Deploy Backend

Run the following command in your terminal to deploy the Edge Function:

```bash
supabase functions deploy push-notification --no-verify-jwt
```

### 4. Configure Database Webhook

Tell Supabase to trigger the function when a new notification is created.

1.  Go to the **Supabase Dashboard** > **Database** > **Webhooks**.
2.  Create a new webhook:
    - **Name**: `push-notification`
    - **Table**: `notifications`
    - **Events**: `INSERT`
    - **Type**: `HTTP Request`
    - **URL**: `https://<your-project-ref>.supabase.co/functions/v1/push-notification`
    - **Method**: `POST`
    - **Headers**: Add `Authorization: Bearer <your-anon-key>` (Find this in Project Settings > API).

---

## ✅ Implementation Summary

### 1. Push Notifications (FCM)

- **Flutter Infrastructure**:
  - Added `firebase_messaging` and `firebase_core` dependencies.
  - Created `FirebaseMessagingService` (`lib/core/services/firebase_messaging_service.dart`) to handle:
    - Permission requests (iOS/Android).
    - FCM Token retrieval and monitoring.
    - Background message handling (`_firebaseMessagingBackgroundHandler`).
    - Saving tokens to Supabase `user_devices` table.
    - **Foreground "Pill" Notifications**: Enabled via `setForegroundNotificationPresentationOptions()` - no need for `flutter_local_notifications`.
  - Updated `main.dart` to initialize Firebase and the messaging service on app start.
  - Updated `ios/Runner/Info.plist` to enable `remote-notification` background mode.
- **Android Heads-Up Notifications**:
  - Created high-importance notification channel (`high_importance_channel`) in `AndroidManifest.xml`.
  - Added native Kotlin code in `MainActivity.kt` to create the channel programmatically.
  - Added `colors.xml` for notification accent color.
- **Backend (Supabase)**:
  - **`user_devices` Table**: Created a table to map `user_id` to `fcm_token` and `platform` (Android/iOS). Includes RLS policies for security.
  - **Edge Function**: Created `push-notification` (`supabase/functions/push-notification`) to:
    - Listen for webhooks (payload from `notifications` table).
    - Check user notification preferences before sending.
    - Fetch target user's active devices.
    - Send FCM messages with rich notification support (images).
    - **Auto-cleanup invalid tokens** (UNREGISTERED, INVALID_ARGUMENT errors).

### 2. Rich Notifications (Images)

- **How it works**: FCM natively supports an `image` field in the notification payload.
- **No `flutter_local_notifications` needed** for basic rich notifications.
- The Edge Function:
  - Checks for `image_url` in the notification record.
  - Falls back to fetching the actor's `avatar_url` from `profiles` if no image provided.
  - Sends the image URL in the FCM payload for both Android and iOS.
- **When you WOULD need `flutter_local_notifications`**:
  - Data-only payloads (no `notification` field - app must display manually).
  - Advanced customization (action buttons, custom sounds, scheduled notifications).
  - Local reminders that don't come from the server.

### 3. Token Cleanup (Maintenance)

- The Edge Function automatically detects invalid FCM tokens from error responses:
  - `UNREGISTERED` - App was uninstalled.
  - `INVALID_ARGUMENT` - Malformed token.
- Invalid tokens are immediately deleted from the `user_devices` table.
- This keeps the database clean and prevents wasted API calls.

### 4. Notification Settings

- Created `NotificationSettingsPage` (`lib/features/profile/notification_settings_page.dart`).
- **User can toggle**:
  - **Master switch**: Enable/disable all push notifications.
  - **Friend Requests**: Notifications for new friend requests.
  - **New Messages**: Chat message notifications.
  - **Moment Invites**: Collaboration invitations.
  - **System Updates**: Important app announcements.
  - **Promotions & Tips**: Marketing and helpful tips.
- Preferences stored in `notification_preferences` table with RLS.
- Auto-created for new users via database trigger.
- Edge Function checks preferences before sending push.

### 5. Deep Linking & Navigation

- Created `NotificationNavigator` (`lib/core/services/notification_navigator.dart`) to handle notification taps:
  - **App Terminated**: Uses `getInitialMessage()` to check for pending notification.
  - **App in Background**: Uses `onMessageOpenedApp` listener.
  - Routes to appropriate page based on notification `type`:
    - `friend_request` -> Notifications Page
    - `new_message` -> Chat Page (with friend lookup)
    - `moment_invite` -> Notifications Page
    - `system` / `promo` -> Notifications Page
- Updated `AppRouter` to use a global `navigatorKey` for navigation from outside widget tree.

### 6. In-App Notifications & Badges

- **Simplified FriendsPage**:
  - **Removed the "Requests" tab** from `FriendsPage` - all friend requests are now handled in `NotificationsPage`.
  - FriendsPage now only shows the list of accepted friends.
  - **Removed `friendRequestCount` badge** from the Friends icon in the app bar.
- **Unified Notification Badge**:
  - The notification bell icon badge now shows a **combined count** of:
    - Pending friend requests
    - Pending collaboration invites
    - Unread system notifications
- **Friend Requests in NotificationsPage**: Show Accept/Decline buttons directly.

### 7. Database Schema

| Table                      | Purpose                                                            |
| -------------------------- | ------------------------------------------------------------------ |
| `notifications`            | Stores notification data (title, body, type, image_url, is_read)   |
| `user_devices`             | Stores FCM tokens per device (fcm_token, platform, last_active_at) |
| `notification_preferences` | Stores user toggle settings for each notification type             |

All tables have RLS policies to ensure users can only access their own data.

---

## 📖 Understanding Data vs Notification Payloads

FCM messages can have two parts:

| Part           | Purpose                                                      | Display                                     |
| -------------- | ------------------------------------------------------------ | ------------------------------------------- |
| `notification` | Contains `title`, `body`, `image`                            | System automatically shows the notification |
| `data`         | Contains custom key-value pairs (e.g., `type`, `related_id`) | App receives this for navigation/logic      |

**When the app is in the foreground**:

- iOS: With `setForegroundNotificationPresentationOptions(alert: true)`, the system shows the "pill" notification.
- Android: With a high-importance channel, the system shows the heads-up notification.

**Data-only payloads** (no `notification` field):

- The system does NOT display anything automatically.
- The app receives the data silently.
- You MUST use `flutter_local_notifications` to show a notification manually.

Our implementation uses **both** `notification` AND `data` in every FCM message, so the system handles display and the app handles navigation.
