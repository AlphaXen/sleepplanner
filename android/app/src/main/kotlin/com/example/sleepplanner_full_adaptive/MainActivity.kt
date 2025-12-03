package com.example.sleepplanner_full_adaptive

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "light_guide_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLightService" -> {
                        val intent = Intent(this, LightMonitorService::class.java)
                        ContextCompat.startForegroundService(this, intent)
                        result.success(null)
                    }
                    "stopLightService" -> {
                        stopService(Intent(this, LightMonitorService::class.java))
                        result.success(null)
                    }
                    "getEnvSamples" -> {
                        val copy = LightMonitorService.getSamplesSnapshotAndClear()
                        val list = copy.map {
                            mapOf(
                                "timestampMillis" to it.timestampMillis,
                                "lux" to it.lux,
                                "noiseDb" to it.noiseDb
                            )
                        }
                        result.success(list)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
