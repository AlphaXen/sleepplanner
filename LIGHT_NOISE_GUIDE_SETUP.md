# Light & Noise Guide - Native Android Implementation Guide

## Overview

The Light & Noise Guide feature has been successfully integrated into your Sleep Planner app. However, to enable the light sensor and microphone functionality, you need to add the native Android code.

## Required Android Implementation

### 1. Create MainActivity.kt

In `android/app/src/main/kotlin/com/example/sleepplanner_full_adaptive/MainActivity.kt`, add:

```kotlin
package com.example.sleepplanner_full_adaptive

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.log10

class MainActivity : FlutterActivity() {
    private val CHANNEL = "light_guide_channel"
    private var sensorManager: SensorManager? = null
    private var lightSensor: Sensor? = null
    private var isRunning = false
    private val samples = mutableListOf<Map<String, Any>>()

    private var audioRecord: AudioRecord? = null
    private var recordingThread: Thread? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLightService" -> {
                        startService()
                        result.success(null)
                    }
                    "stopLightService" -> {
                        stopService()
                        result.success(null)
                    }
                    "getEnvSamples" -> {
                        val copy = samples.toList()
                        samples.clear()
                        result.success(copy)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private val sensorListener = object : SensorEventListener {
        override fun onSensorChanged(event: SensorEvent?) {
            if (event?.sensor?.type == Sensor.TYPE_LIGHT && isRunning) {
                val lux = event.values[0]
                val db = getCurrentNoiseLevel()
                samples.add(
                    mapOf(
                        "timestampMillis" to System.currentTimeMillis(),
                        "lux" to lux,
                        "noiseDb" to db
                    )
                )
            }
        }

        override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
    }

    private fun startService() {
        if (!isRunning) {
            isRunning = true
            sensorManager?.registerListener(
                sensorListener,
                lightSensor,
                SensorManager.SENSOR_DELAY_NORMAL
            )
            startNoiseRecording()
        }
    }

    private fun stopService() {
        isRunning = false
        sensorManager?.unregisterListener(sensorListener)
        stopNoiseRecording()
        samples.clear()
    }

    private fun startNoiseRecording() {
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO)
            != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val bufferSize = AudioRecord.getMinBufferSize(
            44100,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )

        audioRecord = AudioRecord(
            MediaRecorder.AudioSource.MIC,
            44100,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            bufferSize
        )

        audioRecord?.startRecording()
    }

    private fun stopNoiseRecording() {
        audioRecord?.stop()
        audioRecord?.release()
        audioRecord = null
    }

    private fun getCurrentNoiseLevel(): Double {
        val audioRecord = this.audioRecord ?: return 30.0
        val bufferSize = AudioRecord.getMinBufferSize(
            44100,
            AudioFormat.CHANNEL_IN_MONO,
            AudioFormat.ENCODING_PCM_16BIT
        )
        val buffer = ShortArray(bufferSize)

        val read = audioRecord.read(buffer, 0, bufferSize)
        if (read <= 0) return 30.0

        var sum = 0.0
        for (i in 0 until read) {
            sum += buffer[i] * buffer[i]
        }
        val rms = Math.sqrt(sum / read)
        val db = 20 * log10(rms / 32768.0) + 90
        return db.coerceIn(0.0, 120.0)
    }

    override fun onDestroy() {
        stopService()
        super.onDestroy()
    }
}
```

### 2. Update AndroidManifest.xml

Add these permissions in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

### 3. Request Permissions at Runtime

The app already requests microphone permission via `permission_handler` package, which is included in your `pubspec.yaml`.

## Features Integrated

✅ **Real-time Light & Noise Monitoring**: Measures ambient light (lux) and noise (dB) every 5 seconds
✅ **Environment Analysis**: Categorizes environment as Good, Warning, or Disturbing based on sleep quality criteria
✅ **10-Minute Live Graph**: Shows recent light and noise trends
✅ **24-Hour Statistics**: Tracks daily averages, peaks, and environment quality distribution
✅ **Local Storage**: Saves measurements using SharedPreferences
✅ **Provider Integration**: Uses Flutter Provider pattern for state management
✅ **Home Screen Integration**: New "Light & Noise" card added to feature grid

## Testing

1. Run the app on an Android device (not emulator for accurate sensor data)
2. Navigate to Home Screen → Light & Noise
3. Toggle "가이드 활성화" (Activate Guide)
4. Grant microphone permission when prompted
5. View real-time measurements and statistics

## Notes

- Light sensor readings depend on device hardware
- Noise measurements require RECORD_AUDIO permission
- Data is stored locally and cleared manually or after 24 hours
- The feature complements the existing sleep tracking functionality

## Environment Thresholds

- **Good**: Light ≤ 50 lux, Noise ≤ 40 dB (Ideal for sleep)
- **Warning**: Light 50-80 lux, Noise 40-50 dB (Acceptable but not optimal)
- **Disturbing**: Light ≥ 80 lux, Noise ≥ 50 dB (May interfere with sleep quality)
