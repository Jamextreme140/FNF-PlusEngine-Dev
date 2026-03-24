/*
 * Copyright (C) 2026 Lenin
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software.
 *
 * This Software may not be claimed as the original work of any other
 * individual or entity.
 *
 * Attribution to the original author is appreciated, but is not required.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT.
 *
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package com.leninasto.plusengine

import android.content.Intent
import android.os.Bundle
import org.haxe.extension.Extension
import com.leninasto.plusengine.WavyTimebarManager

/**
 * JNI Extension for FNF: Plus Engine
 * Provides native Android functionality accessible from Haxe
 */
class PlusEngineExtension : Extension() {
    
    /**
     * Called when the extension is created
     * Initialize crash handler for Java/Kotlin exceptions
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Install crash handler to catch Java/Kotlin exceptions
        NativeCrashHandler.install()
    }
    
    companion object {
        
        /**
         * Open File Manager Activity from Haxe
         * @param initialPath Optional initial directory path
         */
        @JvmStatic
        fun openFileManager(initialPath: String? = null) {
            val activity = Extension.mainActivity ?: return
            val intent = Intent(activity, FileManagerActivity::class.java)
            
            initialPath?.let {
                intent.putExtra(FileManagerActivity.EXTRA_INITIAL_PATH, it)
            }
            
            activity.startActivity(intent)
        }
        
        /**
         * Open File Manager to a specific location
         * @param location One of: "mods", "saves", "logs", "assets"
         */
        @JvmStatic
        fun openFileManagerLocation(location: String) {
            val activity = Extension.mainActivity ?: return
            val intent = Intent(activity, FileManagerActivity::class.java)
            
            intent.putExtra(FileManagerActivity.EXTRA_START_LOCATION, location)
            
            activity.startActivity(intent)
        }
        
        /**
         * Open mods folder directly
         */
        @JvmStatic
        fun openModsFolder() {
            openFileManagerLocation("mods")
        }
        
        /**
         * Open saves folder directly
         */
        @JvmStatic
        fun openSavesFolder() {
            openFileManagerLocation("saves")
        }
        
        /**
         * Open logs folder directly
         */
        @JvmStatic
        fun openLogsFolder() {
            openFileManagerLocation("logs")
        }
        
        /**
         * Open assets folder directly
         */
        @JvmStatic
        fun openAssetsFolder() {
            openFileManagerLocation("assets")
        }
        
        /**
         * Get app's external files directory path
         */
        @JvmStatic
        fun getExternalFilesPath(): String {
            val activity = Extension.mainActivity ?: return ""
            return activity.getExternalFilesDir(null)?.absolutePath ?: ""
        }
        
        /**
         * Get external storage directory path
         */
        @JvmStatic
        fun getExternalStoragePath(): String {
            return android.os.Environment.getExternalStorageDirectory().absolutePath
        }
        
        /**
         * Check if external storage is writable
         */
        @JvmStatic
        fun isExternalStorageWritable(): Boolean {
            return android.os.Environment.getExternalStorageState() == android.os.Environment.MEDIA_MOUNTED
        }
        
        /**
         * Get free space on external storage (in bytes)
         */
        @JvmStatic
        fun getExternalStorageFreeSpace(): Long {
            val stat = android.os.StatFs(android.os.Environment.getExternalStorageDirectory().path)
            return stat.availableBlocksLong * stat.blockSizeLong
        }

        /**
         * Show a native MD3 message box from Haxe.
         */
        @JvmStatic
        fun showMessageBox(title: String, message: String) {
            val activity = Extension.mainActivity ?: return
            activity.runOnUiThread {
                NativeUI.showDialog(
                    context = activity,
                    title = title,
                    message = message,
                    positiveText = "OK"
                )
            }
        }

        /**
         * Show crash activity with full error details.
         * Called from Haxe CrashHandler when a critical error occurs.
         * @param errorTitle Short error title (e.g., "Null Reference Error")
         * @param errorMessage Brief error message
         * @param stackTrace Full stack trace
         */
        @JvmStatic
        fun showCrashScreen(errorTitle: String, errorMessage: String, stackTrace: String) {
            try {
                val activity = Extension.mainActivity
                if (activity == null || activity.isFinishing) {
                    // Fallback: try to show via application context
                    NativeCrashHandler.showCrashActivityFromContext(errorTitle, errorMessage, stackTrace)
                } else {
                    // Create mock exception for crash display
                    val mockException = Exception("$errorTitle\n$errorMessage\n\n$stackTrace")
                    NativeCrashHandler.showCrashActivity(mockException)
                }
            } catch (e: Exception) {
                android.util.Log.e("PlusEngineExtension", "Failed to show crash screen", e)
            }
        }
        
        // ========== WavyTimebar Methods ==========
        
        /**
         * Initialize the Wavy Timebar overlay
         * Call this once when PlayState is created
         */
        @JvmStatic
        fun initializeTimebar() {
            WavyTimebarManager.initialize()
        }
        
        /**
         * Destroy timebar and free resources
         * Call this when leaving PlayState
         */
        @JvmStatic
        fun destroyTimebar() {
            WavyTimebarManager.destroy()
        }
        
        /**
         * Update timebar progress
         * @param progress Value from 0.0 (start of song) to 1.0 (end of song)
         */
        @JvmStatic
        fun setTimebarProgress(progress: Float) {
            WavyTimebarManager.setProgress(progress)
        }
        
        /**
         * Show timebar
         */
        @JvmStatic
        fun showTimebar() {
            WavyTimebarManager.show()
        }
        
        /**
         * Hide timebar
         */
        @JvmStatic
        fun hideTimebar() {
            WavyTimebarManager.hide()
        }
        
        /**
         * Set timebar visibility alpha
         * @param alpha 0.0 = invisible, 1.0 = fully visible
         */
        @JvmStatic
        fun setTimebarAlpha(alpha: Float) {
            WavyTimebarManager.setVisibility(alpha)
        }
        
        /**
         * Check if timebar is ready to use
         * @return true if initialized and ready
         */
        @JvmStatic
        fun isTimebarReady(): Boolean {
            return WavyTimebarManager.isReady()
        }

        /**
         * Configure native timebar layout.
         * @param widthPercent Relative width in range [0.2, 1.0]
         * @param yPx Top margin in physical pixels
         */
        @JvmStatic
        fun setTimebarLayout(widthPercent: Float, yPx: Float) {
            WavyTimebarManager.setLayout(widthPercent, yPx)
        }
    }
}
