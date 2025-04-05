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


import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
  private static final String CHANNEL = "com.hugh/accessibility";



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

    new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
        .setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "isAccessibilityEnabled":
                    boolean enabled = isAccessibilityServiceEnabled(this, AppMonitorService.class);
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
