package com.example.my_flutter_app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
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
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import java.time.Instant
import java.time.LocalTime
import java.time.ZoneId
import java.util.Collections
import kotlin.concurrent.thread
import kotlin.math.log10
import kotlin.math.sqrt

data class EnvSample(
    val timestampMillis: Long,
    val lux: Float,
    val noiseDb: Float
)

class LightMonitorService : Service(), SensorEventListener {

    companion object {
        val samples = Collections.synchronizedList(mutableListOf<EnvSample>())
        var isRunning = false
        private const val TAG = "LightMonitorService"

        fun getSamplesSnapshotAndClear(): List<EnvSample> {
            synchronized(samples) {
                val copy = samples.toList()
                samples.clear()
                return copy
            }
        }
    }

    private var sensorManager: SensorManager? = null
    private var lightSensor: Sensor? = null

    private val CHANNEL_ID = "light_guide_channel"
    private val NOTIFICATION_ID = 1001

    // noise
    @Volatile private var runningNoise = false
    private var audioRecord: AudioRecord? = null
    @Volatile private var latestNoiseDb = -1f

    private var lastMessage = "Initializing..."

    override fun onCreate() {
        super.onCreate()

        isRunning = true

        // --- 1) Create Notification Channel ---
        createNotificationChannel()

        // --- 2) Start Foreground to prevent crash ---
        try {
            startForeground(
                NOTIFICATION_ID,
                buildNotification("Initializing...")
            )
        } catch (e: Exception) {
            Log.e(TAG, "startForeground failed → stopping service", e)
            stopSelf()
            return
        }

        // --- 3) Register sensor (handle missing sensor gracefully) ---
        try {
            sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
            lightSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_LIGHT)

            if (lightSensor != null) {
                sensorManager?.registerListener(
                    this,
                    lightSensor,
                    SensorManager.SENSOR_DELAY_NORMAL
                )
            } else {
                Log.w(TAG, "No light sensor → lux = -1")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Sensor initialization failed", e)
        }

        // --- 4) Start noise measurement ---
        startNoiseSafe()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false

        try { sensorManager?.unregisterListener(this) } catch (_: Exception) {}
        stopNoiseSafe()
    }

    override fun onBind(intent: Intent?): IBinder? = null
    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type != Sensor.TYPE_LIGHT) return

        val lux = event.values[0]
        val noiseDb = latestNoiseDb
        val now = System.currentTimeMillis()

        samples.add(EnvSample(now, lux, noiseDb))

        // Update recommendation message
        val msg = evaluateRecommendation(
            LocalTime.ofInstant(Instant.ofEpochMilli(now), ZoneId.systemDefault()),
            lux,
            noiseDb
        )

        if (msg != lastMessage) {
            lastMessage = msg
            try {
                val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                nm.notify(NOTIFICATION_ID, buildNotification(msg))
            } catch (e: Exception) {
                Log.e(TAG, "Notification update failed", e)
            }
        }
    }

    private fun evaluateRecommendation(now: LocalTime, lux: Float, noiseDb: Float): String {
        val hour = now.hour

        return if (hour in 6..10) {
            if (lux < 1000f) "It's a good time to get some bright light."
            else "Great! Bright light is helping your circadian rhythm."
        } else {
            "Environment is fine. Focus on maintaining your routine."
        }
    }

    // =======================================================
    // Notification Channel + Foreground Notification
    // =======================================================

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Light Guide Service",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Light/Noise monitoring service"

            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(text: String): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pending = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        )

        // Use safe system icon that exists on all devices
        val safeIcon = android.R.drawable.stat_notify_sync

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Environment Monitor Running")
            .setContentText(text)
            .setSmallIcon(safeIcon)
            .setContentIntent(pending)
            .setOngoing(true)
            .build()
    }

    // =======================================================
    // AudioRecord (Noise Measurement) — crash-safe version
    // =======================================================

    private fun startNoiseSafe() {
        val perm = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO
        )

        if (perm != PackageManager.PERMISSION_GRANTED) {
            Log.w(TAG, "RECORD_AUDIO permission not granted → noise measurement disabled")
            latestNoiseDb = -1f
            return
        }

        try {
            val sampleRate = 44100
            val minBuffer = AudioRecord.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            )

            if (minBuffer <= 0) {
                Log.e(TAG, "AudioRecord buffer error → noise measurement OFF")
                latestNoiseDb = -1f
                return
            }

            audioRecord = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                minBuffer
            )

            if (audioRecord?.state != AudioRecord.STATE_INITIALIZED) {
                Log.e(TAG, "AudioRecord initialization failed → noise measurement OFF")
                audioRecord?.release()
                audioRecord = null
                latestNoiseDb = -1f
                return
            }

            runningNoise = true
            audioRecord?.startRecording()

            thread(start = true) {
                val buffer = ShortArray(minBuffer)

                while (runningNoise) {
                    try {
                        val read = audioRecord?.read(buffer, 0, buffer.size) ?: 0
                        if (read > 0) {
                            var sum = 0.0
                            for (i in 0 until read) sum += buffer[i] * buffer[i].toDouble()
                            val rms = sqrt(sum / read)
                            latestNoiseDb =
                                if (rms > 0) (20 * log10(rms / 32767.0) + 90).toFloat()
                                else -160f
                        }
                    } catch (e: Exception) {
                        Log.e(TAG, "Noise reading failed", e)
                        break
                    }
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "AudioRecord exception", e)
            audioRecord?.release()
            audioRecord = null
            latestNoiseDb = -1f
        }
    }

    private fun stopNoiseSafe() {
        runningNoise = false
        try { audioRecord?.stop() } catch (_: Exception) {}
        try { audioRecord?.release() } catch (_: Exception) {}
        audioRecord = null
    }
}

