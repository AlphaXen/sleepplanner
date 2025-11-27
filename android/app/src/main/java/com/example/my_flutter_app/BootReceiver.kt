package com.example.my_flutter_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

/**
 * BootReceiver listens for BOOT_COMPLETED so the app can restart its
 * foreground service after the device boots.  The receiver checks the
 * persisted auto‑reply preference and only starts the service if auto reply
 * was enabled prior to reboot.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Intent.ACTION_BOOT_COMPLETED != intent.action) return
        val prefs = context.getSharedPreferences("auto_reply_prefs", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("enabled", false)
        if (enabled) {
            val serviceIntent = Intent(context, ForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }
        }
    }
}