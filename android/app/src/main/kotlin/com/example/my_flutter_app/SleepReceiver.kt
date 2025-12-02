package com.example.my_flutter_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.SleepSegmentEvent
import org.json.JSONArray
import org.json.JSONObject

class SleepReceiver : BroadcastReceiver() {
    
    private val PREF_NAME = "FlutterSharedPreferences"
    private val PENDING_KEY = "flutter.native_pending_sleep_data"

    override fun onReceive(context: Context, intent: Intent) {
        if (SleepSegmentEvent.hasEvents(intent)) {
            val events = SleepSegmentEvent.extractEvents(intent)
            Log.d("SleepReceiver", "Sleep events received: ${events.size}")
            
            val prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
            
            val pendingJsonStr = prefs.getString(PENDING_KEY, "[]")
            val jsonArray = JSONArray(pendingJsonStr)

            for (event in events) {
                val session = JSONObject()
                
                val startStr = toIso8601(event.startTimeMillis)
                val endStr = toIso8601(event.endTimeMillis)
                
                session.put("sleepTime", startStr)
                session.put("wakeTime", endStr)
                
                jsonArray.put(session)
                Log.d("SleepReceiver", "Saved session: $startStr ~ $endStr")
            }

            prefs.edit().putString(PENDING_KEY, jsonArray.toString()).apply()
        }
    }

    private fun toIso8601(millis: Long): String {
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", java.util.Locale.US)
        return sdf.format(java.util.Date(millis))
    }
}

