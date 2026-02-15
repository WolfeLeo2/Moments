#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.google.firebase.** { *; }

# Prevent obfuscating Async/Await
-keep class **.Async** { *; }

# Retain generic type information for use by reflection by converters and adapters.
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Exception overrides
-keep public class * extends java.lang.Exception

# Mapbox (if kept)
-keep class com.mapbox.** { *; }

# Supabase / Ktor (if needed for underlying libs)
-keep class io.ktor.** { *; }

# Flutter Map & Tile Caching (Drift/SQLite)
# Although flutter_map is Dart, its plugins (like tile caching) might use native libs
-keep class org.sqlite.** { *; }
-keep interface org.sqlite.** { *; }

# Flutter Play Store Split / Deferred Components
# These are referenced by the Flutter Engine but often not present unless using Play Feature Delivery
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
