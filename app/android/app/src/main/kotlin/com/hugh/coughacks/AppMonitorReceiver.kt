package com.hugh.coughacks

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.MethodChannel

class AppMonitorReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "AppMonitorReceiver"
        var methodChannel: MethodChannel? = null
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "APP_OPENED_ACTION") {
            val packageName = intent.getStringExtra("package_name") ?: return
            Log.d(TAG, "Broadcast received: $packageName")
            
            methodChannel?.invokeMethod("onAppOpened", packageName)
        }
    }
}