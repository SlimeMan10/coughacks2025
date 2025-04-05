package com.hugh.coughacks;  // <-- your package

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.provider.Settings;
import android.text.TextUtils;
import android.net.Uri;
import android.os.Build;
import android.widget.Toast;
import android.content.Intent;
import android.util.Log;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

import java.util.ArrayList;
import java.util.List;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "com.hugh/accessibility";
  private static final String RULE_CHANNEL = "com.hugh.coughacks/rule_check";
  private static final String PERMISSIONS_CHANNEL = "com.hugh.coughacks/permissions";
  private static final String TAG = "MainActivity";

  private void requestOverlayPermission() {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
          if (!Settings.canDrawOverlays(this)) {
              Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                  Uri.parse("package:" + getPackageName()));
              intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
              startActivity(intent);
          } else {
              Toast.makeText(this, "Overlay permission already granted", Toast.LENGTH_SHORT).show();
          }
      }
  }

  private boolean hasOverlayPermission() {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        return Settings.canDrawOverlays(this);
    }
    return true; // Overlay permission not required pre-Marshmallow
  }

  @Override
  public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
    
    // Cache the Flutter engine for DemoAccessibilityService to use
    FlutterEngineCache.getInstance().put("engine_id", flutterEngine);
    Log.d(TAG, "🔄 Flutter engine cached for accessibility service");

    // Main accessibility channel
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "isAccessibilityEnabled":
                    boolean enabled = isAccessibilityServiceEnabled(this, DemoAccessibilityService.class);
                    result.success(enabled);
                    break;
                case "openAccessibilitySettings":
                    Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(intent);
                    result.success(null);
                    break;
                case "requestOverlayPermission":
                    requestOverlayPermission();
                    result.success(true);
                    break;
                case "hasOverlayPermission":
                    result.success(hasOverlayPermission());
                    break;
                default:
                    result.notImplemented();
            }
        });
    
    // Add rule checking channel
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), RULE_CHANNEL)
        .setMethodCallHandler((call, result) -> {
            if (call.method.equals("isAppCurrentlyBlocked")) {
                String app = call.argument("app");
                if (app != null) {
                    Log.d(TAG, "📲 Flutter → Native: Checking if app is currently blocked: " + app);
                    boolean blocked = RuleManager.INSTANCE.isAppBlocked(app);
                    Log.d(TAG, "📲 Native → Flutter: Current status for " + app + " is " + 
                          (blocked ? "BLOCKED ❌" : "ALLOWED ✅"));
                    result.success(blocked);
                } else {
                    Log.d(TAG, "⚠️ Flutter → Native: Missing app package name");
                    result.error("INVALID_ARGUMENT", "App package name is required", null);
                }
            } else {
                Log.d(TAG, "⚠️ Flutter → Native: Unknown method called: " + call.method);
                result.notImplemented();
            }
        });
        
    // Add permissions channel for getting app permissions
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PERMISSIONS_CHANNEL)
        .setMethodCallHandler((call, result) -> {
            if (call.method.equals("getPermissions")) {
                String packageName = call.argument("packageName");
                Log.d(TAG, "📲 Request permissions for app: " + packageName);
                
                if (packageName != null) {
                    try {
                        List<String> permissions = getPermissions(packageName);
                        Log.d(TAG, "📲 Found " + permissions.size() + " permissions for " + packageName);
                        result.success(permissions);
                    } catch (Exception e) {
                        Log.e(TAG, "⚠️ Error getting permissions: " + e.getMessage());
                        result.error("PERMISSIONS_ERROR", e.getMessage(), null);
                    }
                } else {
                    Log.e(TAG, "⚠️ Package name is null");
                    result.error("INVALID_ARGUMENT", "Package name is required", null);
                }
            } else {
                Log.d(TAG, "⚠️ Unknown method called: " + call.method);
                result.notImplemented();
            }
        });
  }

  private List<String> getPermissions(String packageName) {
    try {
        PackageInfo packageInfo = getPackageManager().getPackageInfo(packageName, PackageManager.GET_PERMISSIONS);
        
        if (packageInfo.requestedPermissions == null) {
            Log.d(TAG, "No permissions found for " + packageName);
            return new ArrayList<>();
        }
        
        List<String> permissions = new ArrayList<>();
        for (String permission : packageInfo.requestedPermissions) {
            permissions.add(permission);
        }
        
        return permissions;
    } catch (Exception e) {
        Log.e(TAG, "Error fetching permissions: " + e.getMessage());
        return new ArrayList<>();
    }
  }

  public static boolean isAccessibilityServiceEnabled(Context context, Class<?> service) {
    ComponentName expectedComponentName = new ComponentName(context, service);
    String enabledServices = Settings.Secure.getString(
      context.getContentResolver(),
      Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
    );

    if (enabledServices == null) return false;

    TextUtils.SimpleStringSplitter splitter = new TextUtils.SimpleStringSplitter(':');
    splitter.setString(enabledServices);

    while (splitter.hasNext()) {
      ComponentName enabledComponent = ComponentName.unflattenFromString(splitter.next());
      if (enabledComponent != null && enabledComponent.equals(expectedComponentName)) {
        return true;
      }
    }

    return false;
  }
}
