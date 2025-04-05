package com.hugh.coughacks

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.content.Intent

// Renamed to avoid collision with Java MainActivity
class KotlinMainActivity: FlutterActivity() {
    private val CHANNEL = "com.hugh.coughacks/permissions"
    private val RULE_CHANNEL = "com.hugh.coughacks/rule_check"



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

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RULE_CHANNEL).setMethodCallHandler(object : MethodChannel.MethodCallHandler {
            override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
                if (call.method == "isAppBlocked") {
                    val app = call.argument<String>("app")
                    if (app != null) {
                        println("📲 Flutter → Native: Checking if app is blocked: $app")
                        val blocked = RuleManager.isAppBlocked(app)
                        println("📲 Native → Flutter: Result for $app is ${if (blocked) "BLOCKED ❌" else "ALLOWED ✅"}")
                        result.success(blocked)
                    } else {
                        println("⚠️ Flutter → Native: Missing app package name")
                        result.error("INVALID_ARGUMENT", "App package name is required", null)
                    }
                } else if (call.method == "isAppCurrentlyBlocked") {
                    val app = call.argument<String>("app")
                    if (app != null) {
                        println("📲 Flutter → Native: Checking if app is currently blocked: $app")
                        val blocked = RuleManager.isAppBlocked(app)
                        println("📲 Native → Flutter: Current status for $app is ${if (blocked) "BLOCKED ❌" else "ALLOWED ✅"}")
                        result.success(blocked)
                    } else {
                        println("⚠️ Flutter → Native: Missing app package name")
                        result.error("INVALID_ARGUMENT", "App package name is required", null)
                    }
                } else {
                    println("⚠️ Flutter → Native: Unknown method called: ${call.method}")
                    result.notImplemented()
                }
            }
        })
    
        
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