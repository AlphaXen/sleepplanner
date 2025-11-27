package com.example.my_flutter_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager
import android.telephony.TelephonyManager

/**
 * CallReceiver listens for incoming phone state changes.  When a device is
 * ringing, it checks the auto‑reply preferences stored in SharedPreferences.
 * If auto reply is enabled and the incoming number matches either an empty
 * allowed list (i.e. reply to anyone) or one of the configured allowed
 * contacts, the receiver sends a text message via the default SmsManager.
 */
class CallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        // Only handle phone state changes.
        if (TelephonyManager.ACTION_PHONE_STATE_CHANGED != intent.action) return

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        // Only proceed when the phone is ringing and we have a number.
        if (state != TelephonyManager.EXTRA_STATE_RINGING || incomingNumber.isNullOrEmpty()) {
            return
        }
        val prefs = context.getSharedPreferences("auto_reply_prefs", Context.MODE_PRIVATE)
        val enabled = prefs.getBoolean("enabled", false)
        if (!enabled) return

        val message = prefs.getString("message", "") ?: ""
        if (message.isBlank()) return
        val contactsString = prefs.getString("contacts", "") ?: ""
        val allowedContacts = if (contactsString.isBlank()) {
            emptyList<String>()
        } else {
            contactsString.split(",").map { it.trim() }.filter { it.isNotEmpty() }
        }
        // Normalize numbers by stripping country codes (+82 → 0, + → nothing) and hyphens.
        val normalizedIncoming = incomingNumber.replace("+82", "0").replace("+", "").replace("-", "")
        val shouldReply = allowedContacts.isEmpty() || allowedContacts.any { target ->
            val normalizedTarget = target.replace("+82", "0").replace("+", "").replace("-", "")
            // Allow partial matching at the end for numbers missing area codes.
            normalizedIncoming.endsWith(normalizedTarget)
        }
        if (shouldReply) {
            try {
                val smsManager = SmsManager.getDefault()
                smsManager.sendTextMessage(incomingNumber, null, message, null, null)
            } catch (_: Exception) {
                // Swallow any exceptions silently.  Failures here should not crash the app.
            }
        }
    }
}