package com.hugh.coughacks;

import android.app.Activity;
import android.os.Bundle;
import android.graphics.Color;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.LinearLayout;
import android.view.ViewGroup;
import android.graphics.Typeface;

public class OverlayActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Root layout (fullscreen overlay)
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setBackgroundColor(Color.BLACK);
        layout.setGravity(Gravity.CENTER);
        layout.setLayoutParams(new LinearLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT
        ));

        // "Blocked" Title
        TextView title = new TextView(this);
        title.setText("This app is blocked");
        title.setTextColor(Color.WHITE);
        title.setTextSize(24);
        title.setTypeface(null, Typeface.BOLD);
        title.setGravity(Gravity.CENTER);
        title.setPadding(0, 0, 0, 60);
        layout.addView(title);

        // Motivational Quote
        TextView quote = new TextView(this);
        quote.setText("\"Discipline is choosing between what you want now and what you want most.\"");
        quote.setTextColor(Color.LTGRAY);
        quote.setTextSize(16);
        quote.setGravity(Gravity.CENTER);
        quote.setPadding(40, 0, 40, 0);
        layout.addView(quote);

        setContentView(layout);

        // Overlay settings
        getWindow().setType(WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY);
        getWindow().setLayout(WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.MATCH_PARENT);
    }
}
