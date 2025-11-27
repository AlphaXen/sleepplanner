package com.example.my_flutter_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * A simple foreground service that shows a persistent notification while the
 * auto‑reply feature is active.  Running as a foreground service helps prevent
 * the system from killing our broadcast receivers and ensures the user is
 * informed that automatic SMS replies may be sent.
 */
class ForegroundService : Service() {

    private val channelId = "auto_reply_service"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        // Use the application icon for the notification so it resolves in any
        // package structure without referencing R directly.
        val iconId = applicationContext.applicationInfo.icon
        val notification: Notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle("Auto Reply Service Running")
            .setContentText("Listening for incoming calls to send automatic replies.")
            .setSmallIcon(iconId)
            .setOngoing(true)
            .build()
        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Nothing else to do on each start; return STICKY so the system
        // attempts to recreate the service if it's killed.
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Auto Reply Service",
                NotificationManager.IMPORTANCE_LOW
            )
            channel.description = "Shows a persistent notification when auto reply is enabled."
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
}