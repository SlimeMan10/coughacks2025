package com.hugh.coughacks;

import android.accessibilityservice.AccessibilityService;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.view.accessibility.AccessibilityEvent;
import android.widget.Toast;
import android.net.Uri;
import android.os.Build;
import android.widget.Toast;
import android.content.Intent;


public class DemoAccessibilityService extends AccessibilityService {

    @Override
    public void onAccessibilityEvent(AccessibilityEvent event) {
        // Step 1: Only respond to app window switches
        if (event.getEventType() == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) {

            // Step 2: Get the package name as a string
            CharSequence packageCharSeq = event.getPackageName();
            if (packageCharSeq != null) {
                String packageName = packageCharSeq.toString();

                // Step 3: Print it to logs and show a toast
                System.out.println("Opened package: " + packageName);

                if (packageName.equals("com.android.chrome")) {
                    Intent intent = new Intent(this, SusOverlayActivity.class);
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(intent);
                }

                Toast.makeText(getApplicationContext(),
                    "App Changed: " + packageName,
                    Toast.LENGTH_SHORT).show();
            }
        }
    }


    @Override
    public void onInterrupt() {}

    @Override
    protected void onServiceConnected() {
        System.out.println("DemoAccessibilityService connected");
        super.onServiceConnected();
        AccessibilityServiceInfo config = new AccessibilityServiceInfo();
        config.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED;
        config.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC;

        if (Build.VERSION.SDK_INT >= 16)
            config.flags = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS;

        setServiceInfo(config);
    }

    @Override
    public void onDestroy() {
        System.out.println("DemoAccessibilityService destroy");
        super.onDestroy();
    }
}
