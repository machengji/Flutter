package com.weixing.maintenance_assistant

import android.os.Build
import android.os.Bundle
import android.view.Display
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestHighestRefreshRate()
    }

    override fun onResume() {
        super.onResume()
        requestHighestRefreshRate()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            requestHighestRefreshRate()
        }
    }

    private fun requestHighestRefreshRate() {
        window.attributes.layoutInDisplayCutoutMode =
            WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.let(::applyPreferredDisplayMode)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            @Suppress("DEPRECATION")
            applyPreferredDisplayMode(windowManager.defaultDisplay)
        }
    }

    private fun applyPreferredDisplayMode(display: Display) {
        val modes = display.supportedModes
        if (modes.isEmpty()) return

        var preferredMode = display.mode
        var maxRefreshRate = preferredMode.refreshRate

        for (mode in modes) {
            if (mode.refreshRate > maxRefreshRate) {
                maxRefreshRate = mode.refreshRate
                preferredMode = mode
            }
        }

        val params = window.attributes
        params.preferredDisplayModeId = preferredMode.modeId
        params.preferredRefreshRate = preferredMode.refreshRate
        window.attributes = params
    }
}
