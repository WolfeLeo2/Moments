package com.wolfeleo2.moments

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.wolfeleo2.moments/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            if (call.method == "createNotificationChannel") {
                val id = call.argument<String>("id") ?: "high_importance_channel"
                val name = call.argument<String>("name") ?: "Notifications"
                val description = call.argument<String>("description") ?: "App notifications"
                val importance =
                        call.argument<Int>("importance") ?: NotificationManager.IMPORTANCE_HIGH

                createNotificationChannel(id, name, description, importance)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel(
            id: String,
            name: String,
            description: String,
            importance: Int
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel =
                    NotificationChannel(id, name, importance).apply {
                        this.description = description
                        enableLights(true)
                        enableVibration(true)
                    }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
}
