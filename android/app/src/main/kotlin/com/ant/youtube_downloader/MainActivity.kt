package com.ant.youtube_downloader

import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import io.flutter.embedding.android.FlutterActivity
import com.ant.youtube_downloader.R

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        // Set the theme *before* calling super.onCreate
        if (intent?.action == Intent.ACTION_SEND && intent.type != null) {
            setTheme(R.style.Theme_App_Dialog)
            intent.putExtra("launchedFromShare", true)
        } else {
            setTheme(R.style.Theme_App_Fullscreen)
        }

        super.onCreate(savedInstanceState)

        // Limit size when in dialog mode
        if (intent?.action == Intent.ACTION_SEND && intent.type != null) {
            val params = window.attributes
            // Set width and height for the bottom sheet effect
            params.width = (resources.displayMetrics.widthPixels * 1.0).toInt()  // Full screen width
            params.height = (resources.displayMetrics.heightPixels * 0.5).toInt() // 50% of screen height

            // Set the gravity to the bottom (for bottom sheet effect)
            window.setGravity(Gravity.BOTTOM)

            // Apply the window attributes
            window.attributes = params
            window.setBackgroundDrawableResource(R.drawable.rounded_dialog_background)
        }
    }

    override fun getInitialRoute(): String {
        return if (intent?.action == Intent.ACTION_SEND) "/dialog" else "/home"
    }

}
