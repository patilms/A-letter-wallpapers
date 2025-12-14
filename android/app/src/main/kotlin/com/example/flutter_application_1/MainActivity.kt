package com.example.flutter_application_1

import android.app.WallpaperManager
import android.graphics.BitmapFactory
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.flutter_application_1/wallpaper"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "setWallpaper") {
                val filePath = call.argument<String>("filePath")
                val location = call.argument<Int>("location") // 1 for Home, 2 for Lock, 3 for Both

                if (filePath != null) {
                    val success = setWallpaper(filePath, location ?: 1)
                    if (success) {
                        result.success(true)
                    } else {
                        result.error("UNAVAILABLE", "Could not set wallpaper.", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "File path is null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun setWallpaper(filePath: String, location: Int): Boolean {
        val wallpaperManager = WallpaperManager.getInstance(applicationContext)
        val bitmap = BitmapFactory.decodeFile(filePath)
        
        return try {
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                // Determine flags based on location
                // This is a simple implementation. You can map 'location' to specific flags.
                // For simplicity in this demo, we'll try to set it for the System (Home Screen) mostly, 
                // or both if requested.
                
                // Note: WallpaperManager.FLAG_SYSTEM = 1
                // Note: WallpaperManager.FLAG_LOCK = 2
                
                var flags = WallpaperManager.FLAG_SYSTEM
                if (location == 2) flags = WallpaperManager.FLAG_LOCK
                if (location == 3) flags = WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                
                wallpaperManager.setBitmap(bitmap, null, true, flags)
            } else {
                wallpaperManager.setBitmap(bitmap)
            }
            true
        } catch (e: IOException) {
            e.printStackTrace()
            false
        }
    }
}
