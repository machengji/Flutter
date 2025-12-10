package com.weixing.maintenance_assistant

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // 启用高刷新率
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Android 11+ 使用新的 API
            window.attributes.layoutInDisplayCutoutMode = 
                WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            
            // 请求最大刷新率
            val display = display
            if (display != null) {
                val modes = display.supportedModes
                var maxRefreshRate = 60f
                var preferredMode = display.mode
                
                for (mode in modes) {
                    if (mode.refreshRate > maxRefreshRate) {
                        maxRefreshRate = mode.refreshRate
                        preferredMode = mode
                    }
                }
                
                val params = window.attributes
                params.preferredDisplayModeId = preferredMode.modeId
                window.attributes = params
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Android 6-10 使用旧 API
            val display = windowManager.defaultDisplay
            val modes = display.supportedModes
            var maxRefreshRate = 60f
            var preferredMode = display.mode
            
            for (mode in modes) {
                if (mode.refreshRate > maxRefreshRate) {
                    maxRefreshRate = mode.refreshRate
                    preferredMode = mode
                }
            }
            
            val params = window.attributes
            params.preferredDisplayModeId = preferredMode.modeId
            window.attributes = params
        }
    }
}
