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
import android.content.pm.PackageManager;
import java.util.ArrayList;
import java.util.List;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterEngineCache;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

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
        
    // Add permissions method channel
    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), PERMISSIONS_CHANNEL)
        .setMethodCallHandler((call, result) -> {
            if (call.method.equals("getPermissions")) {
                String packageName = call.argument("packageName");
                if (packageName != null) {
                    Log.d(TAG, "🔍 Querying permissions for: " + packageName);
                    List<String> permissions = getPermissions(packageName);
                    Log.d(TAG, "✅ Found " + permissions.size() + " permissions for " + packageName);
                    result.success(permissions);
                } else {
                    Log.d(TAG, "❌ Error: Package name is null");
                    result.error("INVALID_ARGUMENT", "Package name is null", null);
                }
            } else {
                result.notImplemented();
            }
        });
  }

  private List<String> getPermissions(String packageName) {
    try {
        PackageManager pm = getPackageManager();
        android.content.pm.PackageInfo packageInfo = pm.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS);
        String[] requestedPermissions = packageInfo.requestedPermissions;
        
        List<String> permissions = new ArrayList<>();
        if (requestedPermissions != null) {
            for (String permission : requestedPermissions) {
                permissions.add(permission);
            }
        }
        
        return permissions;
    } catch (Exception e) {
        Log.e(TAG, "❌ Error getting permissions for " + packageName + ": " + e.getMessage());
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
