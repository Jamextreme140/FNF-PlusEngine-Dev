package com.leninasto.plusengine

import android.content.Intent
import org.haxe.extension.Extension

/**
 * JNI Extension for FNF: Plus Engine
 * Provides native Android functionality accessible from Haxe
 */
class PlusEngineExtension : Extension() {
    
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
    }
}
