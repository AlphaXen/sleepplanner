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
    // Flutter의 SharedPreferences 플러그인이 자동으로 "flutter." 프리픽스를 관리하므로
    // 네이티브 코드에서는 프리픽스 없이 키를 저장해야 함
    private val PENDING_KEY = "native_pending_sleep_data"

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

            val jsonString = jsonArray.toString()
            val saved = prefs.edit().putString(PENDING_KEY, jsonString).commit()
            Log.d("SleepReceiver", "Data saved to SharedPreferences: $saved")
            Log.d("SleepReceiver", "Key: $PENDING_KEY")
            Log.d("SleepReceiver", "Data length: ${jsonString.length} bytes")
            Log.d("SleepReceiver", "Data preview: ${if (jsonString.length > 100) jsonString.substring(0, 100) else jsonString}...")
        }
    }

    private fun toIso8601(millis: Long): String {
        val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS", java.util.Locale.US)
        return sdf.format(java.util.Date(millis))
    }
}

