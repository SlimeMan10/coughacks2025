package com.hugh.coughacks

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import io.flutter.plugin.common.MethodChannel

class AppMonitorService : AccessibilityService() {
    companion object {
        private const val TAG = "AppMonitorService"
        const val CHANNEL = "com.hugh.coughacks/app_monitor"
        val monitoredApps = mutableSetOf<String>()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            val packageName = event.packageName?.toString() ?: return
            Log.d(TAG, "App opened: $packageName")
            
            if (monitoredApps.contains(packageName)) {
                val intent = Intent("APP_OPENED_ACTION")
                intent.putExtra("package_name", packageName)
                sendBroadcast(intent)
            }
        }
    }

    override fun onInterrupt() {
        Log.d(TAG, "Service interrupted")
    }
}