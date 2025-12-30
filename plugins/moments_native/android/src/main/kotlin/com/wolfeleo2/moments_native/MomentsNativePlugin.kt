package com.wolfeleo2.moments_native

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** MomentsNativePlugin */
class MomentsNativePlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context: Context

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "com.wolfeleo2.moments/notifications")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    when (call.method) {
      "createNotificationChannel" -> {
        val id = call.argument<String>("id") ?: "high_importance_channel"
        val name = call.argument<String>("name") ?: "Notifications"
        val description = call.argument<String>("description") ?: "App notifications"
        val importance = call.argument<Int>("importance") ?: NotificationManager.IMPORTANCE_HIGH
        createNotificationChannel(id, name, description, importance)
        result.success(null)
      }
      "createConversationChannel" -> {
        val id = call.argument<String>("id") ?: return
        val name = call.argument<String>("name") ?: "Chat"
        val description = call.argument<String>("description") ?: "Chat notifications"
        val importance = call.argument<Int>("importance") ?: NotificationManager.IMPORTANCE_HIGH
        val conversationId = call.argument<String>("conversationId")
        createConversationChannel(id, name, description, importance, conversationId)
        result.success(null)
      }
      "pushConversationShortcut" -> {
        val shortcutId = call.argument<String>("shortcutId") ?: return result.error("MISSING_ID", "shortcutId is required", null)
        val personName = call.argument<String>("personName") ?: "Unknown"
        val personIconBytes = call.argument<ByteArray>("personIconBytes")
        
        try {
          pushConversationShortcut(shortcutId, personName, personIconBytes)
          result.success(null)
        } catch (e: Exception) {
          result.error("SHORTCUT_ERROR", e.message, null)
        }
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun pushConversationShortcut(
    shortcutId: String,
    personName: String,
    personIconBytes: ByteArray?
  ) {
      android.util.Log.d("MomentsNative", "pushConversationShortcut called for: $personName, bytes: ${personIconBytes?.size}")
      
      // Decode bitmap from bytes
      var personIcon: IconCompat? = null
      if (personIconBytes != null && personIconBytes.isNotEmpty()) {
          val bitmap = BitmapFactory.decodeByteArray(personIconBytes, 0, personIconBytes.size)
          if (bitmap != null) {
              android.util.Log.d("MomentsNative", "Bitmap decoded: ${bitmap.width}x${bitmap.height}")
              // Use adaptive bitmap for proper rendering on Android 8+
              personIcon = IconCompat.createWithAdaptiveBitmap(bitmap)
          } else {
              android.util.Log.e("MomentsNative", "Failed to decode bitmap from bytes")
          }
      }

      // 1. Create Person for the shortcut
      val personBuilder = Person.Builder()
          .setName(personName)
          .setKey(shortcutId)
          .setImportant(true)

      if (personIcon != null) {
          personBuilder.setIcon(personIcon)
      }

      val person = personBuilder.build()

      // 2. Create Intent that opens the chat when shortcut is tapped
      val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
      if (launchIntent == null) {
          android.util.Log.e("MomentsNative", "Failed to get launch intent")
          return
      }

      val intent = launchIntent.apply {
          action = Intent.ACTION_VIEW
          putExtra("conversation_id", shortcutId)
          addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
      }

      // 3. Build the shortcut with icon
      val shortcutBuilder = ShortcutInfoCompat.Builder(context, shortcutId)
          .setLongLived(true)
          .setIntent(intent)
          .setShortLabel(personName.take(10))
          .setLongLabel(personName)
          .setPerson(person)

      if (personIcon != null) {
          shortcutBuilder.setIcon(personIcon)
      }

      val shortcut = shortcutBuilder.build()

      // 4. Push the shortcut
      ShortcutManagerCompat.pushDynamicShortcut(context, shortcut)
      android.util.Log.d("MomentsNative", "Shortcut pushed successfully for: $shortcutId")
  }

  private fun createNotificationChannel(
      id: String,
      name: String,
      description: String,
      importance: Int
  ) {
      createConversationChannel(id, name, description, importance, null)
  }

  private fun createConversationChannel(
      id: String,
      name: String,
      description: String,
      importance: Int,
      conversationId: String?
  ) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
          val channel = NotificationChannel(id, name, importance).apply {
              this.description = description
              enableLights(true)
              enableVibration(true)
              
              if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && conversationId != null) {
                  setConversationId("high_importance_channel", conversationId)
              }
          }
          val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
          notificationManager.createNotificationChannel(channel)
      }
  }
}
