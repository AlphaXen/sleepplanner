package com.example.my_flutter_app

import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.location.ActivityRecognition
import com.google.android.gms.location.SleepSegmentRequest

class MainActivity : FlutterActivity() {

    private val CHANNEL_AUTOREPLY = "com.example.call/autoreply"
    private val CHANNEL_SLEEP = "com.example.sleep_tracker/sleep"
    private val CHANNEL_LIGHT = "light_guide_channel"
    private val REQUEST_CODE = 100

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Auto Reply 채널
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_AUTOREPLY)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startService" -> {
                        val intent = Intent(this, ForegroundService::class.java)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            startForegroundService(intent)
                        } else {
                            startService(intent)
                        }
                        result.success("Service started")
                    }
                    "stopService" -> {
                        val intent = Intent(this, ForegroundService::class.java)
                        stopService(intent)
                        result.success("Service stopped")
                    }
                    else -> result.notImplemented()
                }
            }

        // Sleep API 채널
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_SLEEP)
            .setMethodCallHandler { call, result ->
                if (call.method == "requestSleepUpdates") {
                    if (hasActivityRecognitionPermission()) {
                        subscribeToSleepUpdates()
                        result.success(true)
                    } else {
                        result.error("PERMISSION_DENIED", "Activity Recognition permission needed", null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // Environment Checker (Light/Noise) 채널
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_LIGHT)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLightService" -> {
                        try {
                            val intent = Intent(this, LightMonitorService::class.java)
                            ContextCompat.startForegroundService(this, intent)
                            result.success(null)
                        } catch (e: Exception) {
                            android.util.Log.e("MainActivity", "Failed to start LightMonitorService", e)
                            result.error("SERVICE_ERROR", e.message, null)
                        }
                    }
                    "stopLightService" -> {
                        try {
                            stopService(Intent(this, LightMonitorService::class.java))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("SERVICE_ERROR", e.message, null)
                        }
                    }
                    "getEnvSamples" -> {
                        try {
                            val copy = LightMonitorService.getSamplesSnapshotAndClear()
                            val list = copy.map {
                                mapOf(
                                    "timestampMillis" to it.timestampMillis,
                                    "lux" to it.lux,
                                    "noiseDb" to it.noiseDb
                                )
                            }
                            result.success(list)
                        } catch (e: Exception) {
                            result.error("DATA_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasActivityRecognitionPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return checkSelfPermission(android.Manifest.permission.ACTIVITY_RECOGNITION) == PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun subscribeToSleepUpdates() {
        val intent = Intent(this, SleepReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            REQUEST_CODE,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )

        val request = SleepSegmentRequest.getDefaultSleepSegmentRequest()
        
        ActivityRecognition.getClient(this)
            .requestSleepSegmentUpdates(pendingIntent, request)
            .addOnSuccessListener {
                android.util.Log.d("MainActivity", "Successfully subscribed to sleep updates")
            }
            .addOnFailureListener { e ->
                android.util.Log.e("MainActivity", "Failed to subscribe to sleep updates", e)
            }
    }
}
