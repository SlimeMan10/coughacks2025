package com.hugh.coughacks

import android.util.Log

object RuleManager {
    private val TAG = "RuleManager"
    private val blockedApps = mutableSetOf<String>()
    
    fun isAppBlocked(packageName: String): Boolean {
        Log.d(TAG, "🔍 Checking if app is blocked: $packageName")
        val isInBlockedSet = blockedApps.contains(packageName)
        val isChrome = packageName == "com.android.chrome"
        val isBlocked = isInBlockedSet || isChrome
        
        if (isBlocked) {
            if (isInBlockedSet) {
                Log.d(TAG, "🚫 App $packageName is in blocked list")
            }
            if (isChrome) {
                Log.d(TAG, "🚫 Chrome is hardcoded to be blocked")
            }
        } else {
            Log.d(TAG, "✅ App $packageName is not blocked")
        }
        
        return isBlocked
    }
    
    fun blockApp(packageName: String) {
        Log.d(TAG, "➕ Adding app to blocked list: $packageName")
        blockedApps.add(packageName)
        Log.d(TAG, "📋 Current blocked apps: $blockedApps")
    }
    
    fun unblockApp(packageName: String) {
        Log.d(TAG, "➖ Removing app from blocked list: $packageName")
        blockedApps.remove(packageName)
        Log.d(TAG, "📋 Current blocked apps: $blockedApps")
    }
}