package com.hugh.coughacks;

import android.app.Activity;
import android.os.Bundle;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.LinearLayout;

public class SusOverlayActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Create layout programmatically
        LinearLayout layout = new LinearLayout(this);
        layout.setBackgroundColor(0xFFFFFFFF); // White
        layout.setGravity(Gravity.CENTER);

        TextView text = new TextView(this);
        text.setText("sus");
        text.setTextSize(32);
        text.setGravity(Gravity.CENTER);

        layout.addView(text);
        setContentView(layout);

        // Make it look like an overlay
        getWindow().setType(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY);
        getWindow().setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT);
    }
}
