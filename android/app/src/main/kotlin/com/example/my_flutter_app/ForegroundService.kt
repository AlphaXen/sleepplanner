package com.example.my_flutter_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class ForegroundService : Service() {

    private val channelId = "autoreply_service"

    override fun onCreate() {
        super.onCreate()
        Log.d("ForegroundService", "Service created")
        createNotificationChannel()

        val notification: Notification =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(this, channelId)
                    .setContentTitle("자동응답 서비스 실행 중")
                    .setContentText("전화 감지 및 자동 문자 전송 활성화")
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .build()
            } else {
                Notification.Builder(this)
                    .setContentTitle("자동응답 서비스 실행 중")
                    .setContentText("전화 감지 및 자동 문자 전송 활성화")
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .build()
            }

        startForeground(1, notification)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("ForegroundService", "Service started")
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                channelId,
                "자동응답 서비스 채널",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}

