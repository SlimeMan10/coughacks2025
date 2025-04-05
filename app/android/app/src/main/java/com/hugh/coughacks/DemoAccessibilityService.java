package com.hugh.coughacks;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.view.accessibility.AccessibilityEvent;
import android.widget.Toast;
import android.content.Intent;
import android.util.Log;

import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.Result;

import java.util.Map;
import java.util.HashMap;

public class DemoAccessibilityService extends AccessibilityService {
    private static final String TAG = "DemoAccessService";
    private static final String RULE_CHANNEL = "com.hugh.coughacks/rule_check";
    private static final String EXTRA_RULE_NAME = "rule_name";
    private Handler mainHandler = new Handler(Looper.getMainLooper());

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // Step 1: Only respond to app window switches
        if (event.getEventType() == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {
            Log.d(TAG, "📱 Window state changed event detected");

            // Step 2: Get the package name as a string
            CharSequence packageCharSeq = event.getPackageName();
            if (packageCharSeq != null) {
                String packageName = packageCharSeq.toString();

                // Step 3: Print it to logs
                Log.d(TAG, "👀 Detected app opened: " + packageName);
                System.out.println("Opened package: " + packageName);

                // Step 4: Check with Flutter code if this app should be blocked
                checkWithFlutterIfAppShouldBeBlocked(packageName);
            } else {
                Log.d(TAG, "⚠️ Package name is null for window state change event");
            }
        }
    }

    private void checkWithFlutterIfAppShouldBeBlocked(String packageName) {
        Log.d(TAG, "🔍 Checking with Flutter if app should be blocked: " + packageName);
        
        // Get FlutterEngine from cache
        FlutterEngine engine = FlutterEngineCache.getInstance().get("engine_id");
        
        if (engine == null) {
            Log.e(TAG, "⚠️ FlutterEngine not found in cache. Falling back to RuleManager check");
            // Fall back to native check
            checkNativeIfAppShouldBeBlocked(packageName);
            return;
        }
        
        // Use the main thread for communicating with Flutter
        mainHandler.post(() -> {
            MethodChannel channel = new MethodChannel(engine.getDartExecutor().getBinaryMessenger(), RULE_CHANNEL);
            
            // Call the Flutter method
            Log.d(TAG, "📲 Calling Flutter method to check if app should be blocked: " + packageName);
            channel.invokeMethod("checkAppAgainstRules", packageName, new Result() {
                @Override
                public void success(Object result) {
                    if (result instanceof Map) {
                        // Parse result as Map
                        @SuppressWarnings("unchecked")
                        Map<String, Object> resultMap = (Map<String, Object>) result;
                        boolean shouldBlock = (Boolean) resultMap.get("blocked");
                        String ruleName = (String) resultMap.get("ruleName");
                        
                        Log.d(TAG, "📱 Flutter responded: App " + packageName + " should " + 
                            (shouldBlock ? "be blocked ❌ by rule " + ruleName : "not be blocked ✅"));
                        
                        if (shouldBlock) {
                            Log.d(TAG, "🚫 Launching overlay to block: " + packageName);
                            showBlockOverlay(ruleName);
                        }
                        
                        Toast.makeText(getApplicationContext(),
                            "App: " + packageName + (shouldBlock ? " (BLOCKED by Flutter)" : " (Allowed)"),
                            Toast.LENGTH_SHORT).show();
                    } else if (result instanceof Boolean) {
                        // For backward compatibility with older implementation
                        boolean shouldBlock = (Boolean) result;
                        Log.d(TAG, "📱 Flutter responded (legacy format): App " + packageName + 
                            " should " + (shouldBlock ? "be blocked ❌" : "not be blocked ✅"));
                        
                        if (shouldBlock) {
                            Log.d(TAG, "🚫 Launching overlay to block: " + packageName);
                            showBlockOverlay(null);
                        }
                        
                        Toast.makeText(getApplicationContext(),
                            "App: " + packageName + (shouldBlock ? " (BLOCKED by Flutter)" : " (Allowed)"),
                            Toast.LENGTH_SHORT).show();
                    }
                }
                
                @Override
                public void error(String errorCode, String errorMessage, Object errorDetails) {
                    Log.e(TAG, "❌ Error calling Flutter: " + errorMessage);
                    // Fall back to native check
                    checkNativeIfAppShouldBeBlocked(packageName);
                }
                
                @Override
                public void notImplemented() {
                    Log.e(TAG, "⚠️ Flutter method not implemented. Falling back to native check");
                    // Fall back to native check
                    checkNativeIfAppShouldBeBlocked(packageName);
                }
            });
        });
    }
    
    private void checkNativeIfAppShouldBeBlocked(String packageName) {
        Log.d(TAG, "🔍 Checking if app should be blocked via RuleManager: " + packageName);
        boolean shouldBlock = RuleManager.INSTANCE.isAppBlocked(packageName);
        Log.d(TAG, shouldBlock ? "🚫 App should be blocked: " + packageName : "✅ App is allowed: " + packageName);
        
        if (shouldBlock) {
            Log.d(TAG, "🚫 Launching overlay to block app: " + packageName);
            showBlockOverlay("System Rule"); // Default rule name for native blocking
        }
        
        Toast.makeText(getApplicationContext(),
            "App: " + packageName + (shouldBlock ? " (BLOCKED by Native)" : " (Allowed)"),
            Toast.LENGTH_SHORT).show();
    }
    
    private void showBlockOverlay(String ruleName) {
        Intent intent = new Intent(this, OverlayActivity.class);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        if (ruleName != null) {
            intent.putExtra(EXTRA_RULE_NAME, ruleName);
        }
        startActivity(intent);
        Log.d(TAG, "⚡ Overlay activity started" + (ruleName != null ? " with rule: " + ruleName : ""));
    }

    @Override
    public void onInterrupt() {
        Log.d(TAG, "⚠️ Accessibility service interrupted");
    }

    @Override
    protected void onServiceConnected() {
        Log.d(TAG, "🔌 DemoAccessibilityService connected");
        System.out.println("DemoAccessibilityService connected");
        super.onServiceConnected();
        AccessibilityServiceInfo config = new AccessibilityServiceInfo();
        config.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED;
        config.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC;

        if (Build.VERSION.SDK_INT >= 16)
            config.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS;

        setServiceInfo(config);
        Log.d(TAG, "⚙️ Accessibility service configured");
    }

    @Override
    public void onDestroy() {
        Log.d(TAG, "💀 DemoAccessibilityService destroy");
        System.out.println("DemoAccessibilityService destroy");
        super.onDestroy();
    }
}