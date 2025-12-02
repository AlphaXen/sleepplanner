package com.example.my_flutter_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager
import android.telephony.TelephonyManager
import android.util.Log
import org.json.JSONArray

class CallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        Log.d("CallReceiver", "state=$state, incoming=$incomingNumber")

        if (state != TelephonyManager.EXTRA_STATE_RINGING || incomingNumber.isNullOrEmpty()) {
            return
        }

        // Flutter SharedPreferences 에서 규칙 JSON 읽기
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE
        )
        val json = prefs.getString("flutter.rulesJson", "[]") ?: "[]"

        try {
            val arr = JSONArray(json)
            val normalizedIncoming = incomingNumber.replace("+82", "0").replace("-", "")

            for (i in 0 until arr.length()) {
                val obj = arr.getJSONObject(i)
                val phone = obj.optString("phone", "")
                val message = obj.optString("message", "")

                if (phone.isEmpty() || message.isEmpty()) continue

                val normalizedTarget = phone.replace("+82", "0").replace("-", "")

                if (normalizedIncoming.endsWith(normalizedTarget)) {
                    // 매칭된 규칙 → 문자 전송
                    try {
                        val sms = SmsManager.getDefault()
                        sms.sendTextMessage(incomingNumber, null, message, null, null)
                        Log.d("CallReceiver", "문자 전송 성공 → $incomingNumber / msg=$message")
                    } catch (e: Exception) {
                        Log.e("CallReceiver", "문자 전송 실패: ${e.message}")
                    }
                    break
                }
            }
        } catch (e: Exception) {
            Log.e("CallReceiver", "JSON 파싱 오류: ${e.message}")
        }
    }
}

