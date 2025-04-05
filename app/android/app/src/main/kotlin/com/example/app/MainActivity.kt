package com.hugh.coughacks

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.content.Intent

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.hugh.coughacks/permissions"

    override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getPermissions") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val permissions = getPermissions(packageName)
                    result.success(permissions)
                } else {
                    result.error("INVALID_ARGUMENT", "Package name is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AppMonitorService.CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "monitorApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        AppMonitorService.monitoredApps.add(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "stopMonitoringApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        AppMonitorService.monitoredApps.remove(packageName)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGUMENT", "Package name is required", null)
                    }
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(android.provider.Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    startActivity(intent)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        AppMonitorReceiver.methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, AppMonitorService.CHANNEL)
    }

    private fun getPermissions(packageName: String): List<String> {
        return try {
            val packageInfo = packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            packageInfo.requestedPermissions?.toList() ?: emptyList()
        } catch (e: Exception) {
            emptyList()
        }
    }
}