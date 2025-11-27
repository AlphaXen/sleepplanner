package com.example.my_flutter_app

import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity acts as the entrypoint for the Flutter portion of the SleepPlanner app.
 *
 * In addition to the default FlutterActivity behaviour, this class exposes a
 * MethodChannel that allows the Dart side to communicate auto‑reply settings to
 * the native Android side.  When the user enables or disables auto reply, or
 * updates the reply message or allowed contacts list, Flutter invokes methods on
 * this channel.  The native code stores the values in SharedPreferences and
 * starts or stops the foreground service accordingly.
 */
class MainActivity : FlutterActivity() {

    private val channelName = "auto_reply_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Enable or disable auto reply.  Expects a map with keys
                    // "enabled" (bool), "message" (String) and "contacts" (List<String>).
                    "enableAutoReply" -> {
                        val enabled = call.argument<Boolean>("enabled") ?: false
                        val message = call.argument<String>("message") ?: ""
                        val contacts = call.argument<List<String>>("contacts") ?: emptyList()
                        updatePreferences(enabled = enabled, message = message, contacts = contacts)
                        if (enabled) startAutoReplyService() else stopAutoReplyService()
                        result.success(null)
                    }
                    // Update only the reply message in SharedPreferences.
                    "updateMessage" -> {
                        val message = call.argument<String>("message") ?: ""
                        updatePreferences(message = message)
                        result.success(null)
                    }
                    // Update only the allowed contacts list in SharedPreferences.
                    "updateContacts" -> {
                        val contacts = call.argument<List<String>>("contacts") ?: emptyList()
                        updatePreferences(contacts = contacts)
                        result.success(null)
                    }
                    // Explicitly start or stop the service from Dart without
                    // touching preferences.
                    "startService" -> {
                        startAutoReplyService()
                        result.success(null)
                    }
                    "stopService" -> {
                        stopAutoReplyService()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /**
     * Persist auto‑reply preferences to SharedPreferences.  Any parameter not
     * provided will keep its existing value.
     */
    private fun updatePreferences(
        enabled: Boolean? = null,
        message: String? = null,
        contacts: List<String>? = null
    ) {
        val prefs: SharedPreferences = getSharedPreferences("auto_reply_prefs", MODE_PRIVATE)
        val editor = prefs.edit()
        enabled?.let { editor.putBoolean("enabled", it) }
        message?.let { editor.putString("message", it) }
        contacts?.let { editor.putString("contacts", it.joinToString(",")) }
        editor.apply()
    }

    /**
     * Start the foreground service responsible for displaying a persistent
     * notification.  Uses startForegroundService on API 26+ and startService
     * on earlier versions.
     */
    private fun startAutoReplyService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }
    }

    /**
     * Stop the foreground auto reply service if it is running.
     */
    private fun stopAutoReplyService() {
        val serviceIntent = Intent(this, ForegroundService::class.java)
        stopService(serviceIntent)
    }
}