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

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.DocumentsContract
import android.view.KeyEvent
import androidx.core.content.FileProvider
import androidx.documentfile.provider.DocumentFile
import org.haxe.extension.Extension
import org.libsdl.app.SDLActivity
import com.leninasto.plusengine.WavyTimebarManager
import java.io.File

/**
 * JNI Extension for FNF: Plus Engine
 * Provides native Android functionality accessible from Haxe
 */
class PlusEngineExtension : Extension() {

    private fun dispatchBackToEngine() {
        android.util.Log.i("PlusEngine", "dispatchBackToEngine() -> forwarding KEYCODE_BACK to SDL")
        SDLActivity.onNativeKeyDown(KeyEvent.KEYCODE_BACK)
        SDLActivity.onNativeKeyUp(KeyEvent.KEYCODE_BACK)
    }
    
    /**
     * Called when the extension is created
     * Initialize crash handler for Java/Kotlin exceptions
     */
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Install crash handler to catch Java/Kotlin exceptions
        NativeCrashHandler.install()

        // Prevent BACK key/gesture from closing the app.
        // GameActivity.onBackPressed() calls extension.onBackPressed() first;
        // returning false here stops super.onBackPressed() (which calls finish()).
        // On Android 13+ (API 33), predictive back uses OnBackInvokedDispatcher instead of
        // onBackPressed(); we register a no-op callback so the engine can keep handling BACK
        // through Lime/SDL without Android finishing or backgrounding the activity.
        val activity = Extension.mainActivity
        if (activity != null && Build.VERSION.SDK_INT >= 33) {
            try {
                android.util.Log.i("PlusEngine", "Registering predictive back callback for API ${Build.VERSION.SDK_INT}")
                val dispatcher = activity.javaClass
                    .getMethod("getOnBackInvokedDispatcher")
                    .invoke(activity)
                val callbackClass = Class.forName("android.window.OnBackInvokedCallback")
                val proxy = java.lang.reflect.Proxy.newProxyInstance(
                    callbackClass.classLoader,
                    arrayOf(callbackClass)
                ) { _, _, _ ->
                    android.util.Log.i("PlusEngine", "Predictive back callback invoked")
                    dispatchBackToEngine()
                    null
                }
                val dispatcherClass = Class.forName("android.window.OnBackInvokedDispatcher")
                dispatcherClass.getMethod("registerOnBackInvokedCallback", Int::class.java, callbackClass)
                    .invoke(dispatcher, 0 /* PRIORITY_DEFAULT */, proxy)
            } catch (e: Exception) {
                android.util.Log.w("PlusEngine", "Could not register OnBackInvokedCallback: ${e.message}")
            }
        }
    }

    // Called by GameActivity.onBackPressed() for API < 33 (hardware back / gesture nav bar).
    // Returning false consumes the event, preventing super.onBackPressed() / finish().
    // Forward the action straight to SDL/Lime so HaxeFlixel can read FlxG.android.BACK.
    override fun onBackPressed(): Boolean {
        android.util.Log.i("PlusEngine", "onBackPressed() intercepted by extension")
        dispatchBackToEngine()
        return false
    }
    
    /**
     * Called when an activity returns a result
     * Used to track when folder browser is closed and to save granted URIs
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        android.util.Log.i("PlusEngine", "onActivityResult requestCode=$requestCode resultCode=$resultCode data=${data != null}")

        // Handle native file picker result
        if (requestCode == REQUEST_CODE_FILE_PICKER) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val activity = Extension.mainActivity
                if (activity != null) {
                    try {
                        val selectedPath = data.getStringExtra(FileManagerActivity.EXTRA_RESULT_PATH)
                        if (!selectedPath.isNullOrEmpty()) {
                            val selectedFile = File(selectedPath)
                            pickedFilePath = selectedFile.name
                            pickedFileContent = selectedFile.readText(Charsets.UTF_8)
                            pickedFileStatus = PICKED_FILE_STATUS_SUCCESS
                            android.util.Log.i("PlusEngine", "File picker selected from FileManagerActivity: $selectedPath (${pickedFileContent.length} chars)")
                        } else if (data.data != null) {
                            val uri = data.data!!

                            // Resolve the display name for reference (used as the "was picked" signal).
                            val cursor = activity.contentResolver.query(uri, null, null, null, null)
                            var displayName = "picked_file.json"
                            cursor?.use {
                                if (it.moveToFirst()) {
                                    val nameIdx = it.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME)
                                    if (nameIdx >= 0) displayName = it.getString(nameIdx)
                                }
                            }

                            // Read the file content directly as a String — no filesystem copy needed.
                            // ACTION_OPEN_DOCUMENT grants temporary read access to the returned URI.
                            val content = activity.contentResolver.openInputStream(uri)
                                ?.bufferedReader(Charsets.UTF_8)
                                ?.use { it.readText() } ?: ""
                            pickedFilePath = displayName
                            pickedFileContent = content
                            pickedFileStatus = PICKED_FILE_STATUS_SUCCESS
                            android.util.Log.i("PlusEngine", "File picker selected from document provider: $displayName (${content.length} chars)")
                        } else {
                            pickedFilePath = ""
                            pickedFileContent = ""
                            pickedFileStatus = PICKED_FILE_STATUS_ERROR
                            android.util.Log.w("PlusEngine", "File picker returned RESULT_OK but no path or URI was provided")
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("PlusEngine", "File picker: failed to read file content", e)
                        pickedFilePath = ""
                        pickedFileContent = ""
                        pickedFileStatus = PICKED_FILE_STATUS_ERROR
                    }
                }
            } else {
                // Cancelled or failed
                pickedFilePath = ""
                pickedFileContent = ""
                pickedFileStatus = PICKED_FILE_STATUS_CANCELLED
                android.util.Log.i("PlusEngine", "File picker cancelled or failed (resultCode=$resultCode)")
            }
            onFolderClosedCallback?.invoke(requestCode)
            return false
        }

        // Check if user granted permission to a folder
        if (resultCode == Activity.RESULT_OK && data != null) {
            val treeUri = data.data
            if (treeUri != null && requestCode in REQUEST_CODE_DATA_FOLDER..REQUEST_CODE_LOGS_FOLDER) {
                // Save the granted URI persistently
                saveGrantedUri(requestCode, treeUri)
            }
        }
        
        // Notify callback that folder was closed
        onFolderClosedCallback?.invoke(requestCode)
        return true
    }
    
    companion object {
        // Request codes for activity results
        const val REQUEST_CODE_DATA_FOLDER = 1001
        const val REQUEST_CODE_MODS_FOLDER = 1002
        const val REQUEST_CODE_SAVES_FOLDER = 1003
        const val REQUEST_CODE_LOGS_FOLDER = 1004
        const val REQUEST_CODE_FILE_PICKER = 2001

        const val PICKED_FILE_STATUS_NONE = 0
        const val PICKED_FILE_STATUS_SUCCESS = 1
        const val PICKED_FILE_STATUS_CANCELLED = -1
        const val PICKED_FILE_STATUS_ERROR = -2

        // Callback for when folder is closed
        private var onFolderClosedCallback: ((Int) -> Unit)? = null

        // Stores the display name of the last file selected via openFilePicker().
        // Non-empty = a file was picked; empty = no pick yet / cancelled.
        private var pickedFilePath: String = ""

        // Stores the raw text content of the last picked file.
        // Populated in onActivityResult by reading directly from the ContentResolver.
        private var pickedFileContent: String = ""

        // Stores the current picker state so Haxe can detect success, cancel, and errors.
        private var pickedFileStatus: Int = PICKED_FILE_STATUS_NONE
        
        // Cache for granted URIs (stores the tree URI after user grants permission)
        private val grantedUris = mutableMapOf<String, Uri>()
        
        /**
         * Set callback to be called when user closes the folder browser
         * First time: Opens picker and asks for permission
         * Subsequent times: Opens directly with cached permission
         * @param folderPath Absolute path to the folder to open
         * @param requestCode Request code to track when folder is closed
         */
        @JvmStatic
        fun openFolderInSystemExplorer(folderPath: String, requestCode: Int = REQUEST_CODE_DATA_FOLDER) {
            val activity = Extension.mainActivity ?: return
            val folder = File(folderPath)
            
            // Ensure folder exists
            if (!folder.exists()) {
                folder.mkdirs()
            }
            
            // Check if we already have permission for this folder
            val cachedUri = getGrantedUri(requestCode)
            if (cachedUri != null && hasUriPermission(activity, cachedUri)) {
                // We already have permission, open directly with VIEW intent
                openFolderWithPermission(activity, cachedUri, requestCode)
                return
            }
            
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // Android 8.0+ (API 26+): Use Storage Access Framework to request permission
                    // This will ask user "Use this folder?" the FIRST time only
                    val initialUri = getDocumentTreeUri(folderPath)
                    
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
                        flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
                        
                        // Set initial location to the app's data folder
                        if (initialUri != null) {
                            putExtra(DocumentsContract.EXTRA_INITIAL_URI, initialUri)
                        }
                    }
                    
                    activity.startActivityForResult(intent, requestCode)
                    
                } else {
                    // Android 7.x and below: Use FileProvider with ACTION_VIEW
                    openFolderLegacy(activity, folder, requestCode)
                }
                
            } catch (e: Exception) {
                android.util.Log.e("PlusEngine", "Failed to open folder with SAF: ${e.message}")
                e.printStackTrace()
                
                // Fallback to legacy method
                openFolderLegacy(activity, folder, requestCode)
            }
        }
        
        /**
         * Open folder directly using a granted URI (no permission prompt)
         * This is called after we already have permission
         */
        @JvmStatic
        private fun openFolderWithPermission(activity: Activity, treeUri: Uri, requestCode: Int) {
            try {
                // Build a VIEW intent to open the folder in the file manager
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(treeUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                    addCategory(Intent.CATEGORY_DEFAULT)
                }
                
                activity.startActivityForResult(intent, requestCode)
                
            } catch (e: Exception) {
                android.util.Log.e("PlusEngine", "Failed to open folder with cached URI: ${e.message}")
                // If this fails, clear the cache and try again with permission request
                clearGrantedUri(requestCode)
                openFolderInSystemExplorer(activity.getExternalFilesDir(null)?.absolutePath ?: "", requestCode)
            }
        }
        
        /**
         * Save granted URI persistently using takePersistableUriPermission
         * This keeps the permission even after app restart
         */
        @JvmStatic
        private fun saveGrantedUri(requestCode: Int, treeUri: Uri) {
            try {
                val activity = Extension.mainActivity ?: return
                val contentResolver = activity.contentResolver
                
                // Take persistable permission so we can use it later
                contentResolver.takePersistableUriPermission(
                    treeUri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                )
                
                // Cache in memory
                val key = "folder_$requestCode"
                grantedUris[key] = treeUri
                
                // Save to SharedPreferences for persistence across app restarts
                activity.getSharedPreferences("FolderPermissions", android.content.Context.MODE_PRIVATE)
                    .edit()
                    .putString(key, treeUri.toString())
                    .apply()
                
                android.util.Log.i("PlusEngine", "Saved permission for folder: $treeUri")
                
            } catch (e: Exception) {
                android.util.Log.e("PlusEngine", "Failed to save granted URI: ${e.message}")
            }
        }
        
        /**
         * Get previously granted URI from cache or SharedPreferences
         */
        @JvmStatic
        private fun getGrantedUri(requestCode: Int): Uri? {
            val activity = Extension.mainActivity ?: return null
            val key = "folder_$requestCode"
            
            // Check memory cache first
            if (grantedUris.containsKey(key)) {
                return grantedUris[key]
            }
            
            // Load from SharedPreferences
            val prefs = activity.getSharedPreferences("FolderPermissions", android.content.Context.MODE_PRIVATE)
            val uriString = prefs.getString(key, null) ?: return null
            
            return try {
                val uri = Uri.parse(uriString)
                grantedUris[key] = uri
                uri
            } catch (e: Exception) {
                android.util.Log.e("PlusEngine", "Failed to parse saved URI: ${e.message}")
                null
            }
        }
        
        /**
         * Check if we still have permission for the given URI
         */
        @JvmStatic
        private fun hasUriPermission(activity: Activity, uri: Uri): Boolean {
            return try {
                val contentResolver = activity.contentResolver
                val persistedUris = contentResolver.persistedUriPermissions
                persistedUris.any { it.uri == uri && it.isReadPermission && it.isWritePermission }
            } catch (e: Exception) {
                false
            }
        }
        
        /**
         * Clear cached permission for a folder (forces new permission request)
         */
        @JvmStatic
        private fun clearGrantedUri(requestCode: Int) {
            val activity = Extension.mainActivity ?: return
            val key = "folder_$requestCode"
            
            grantedUris.remove(key)
            activity.getSharedPreferences("FolderPermissions", android.content.Context.MODE_PRIVATE)
                .edit()
                .remove(key)
                .apply()
        }
        
        /**
         * Get DocumentsContract tree URI for the given folder path
         * This creates a proper URI that the system file picker can understand
         */
        @JvmStatic
        private fun getDocumentTreeUri(folderPath: String): Uri? {
            return try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    // For scoped storage paths (Android/data/package/files/...)
                    // We need to construct the proper tree URI
                    val storageManager = Extension.mainActivity?.getSystemService(android.content.Context.STORAGE_SERVICE) 
                        as? android.os.storage.StorageManager
                    
                    val file = File(folderPath)
                    if (storageManager != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        // Android 10+ (API 29+): Use StorageVolume to get proper URI
                        val volume = storageManager.getStorageVolume(file)
                        volume?.createOpenDocumentTreeIntent()?.data
                    } else {
                        // Android 8-9: Build URI manually
                        // Format: content://com.android.externalstorage.documents/tree/primary:Android/data/package/files
                        val relativePath = folderPath.substringAfter("/storage/emulated/0/")
                        DocumentsContract.buildTreeDocumentUri(
                            "com.android.externalstorage.documents",
                            "primary:$relativePath"
                        )
                    }
                } else {
                    null
                }
            } catch (e: Exception) {
                android.util.Log.w("PlusEngine", "Failed to create document tree URI: ${e.message}")
                null
            }
        }
        
        /**
         * Legacy method for Android 7.x and below, or as fallback
         * Uses FileProvider with ACTION_VIEW
         */
        @JvmStatic
        private fun openFolderLegacy(activity: Activity, folder: File, requestCode: Int) {
            try {
                val uri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    FileProvider.getUriForFile(
                        activity,
                        "${activity.packageName}.provider",
                        folder
                    )
                } else {
                    Uri.fromFile(folder)
                }
                
                val intent = Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(uri, "resource/folder")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                }
                
                activity.startActivityForResult(intent, requestCode)
                
            } catch (e: Exception) {
                android.util.Log.e("PlusEngine", "Legacy folder open failed: ${e.message}")
                // Last resort: show a toast with the path
                activity.runOnUiThread {
                    android.widget.Toast.makeText(
                        activity,
                        "Data folder: ${folder.absolutePath}",
                        android.widget.Toast.LENGTH_LONG
                    ).show()
                }
            }
        }
        
        /**
         * Open data folder (root of external files directory)
         * Opens Android/data/com.leninasto.plusengine/files/
         * This is the main method called from Haxe via JNI
         * @param requestCode Request code for tracking when folder is closed
         */
        @JvmStatic
        fun openDataFolder(requestCode: Int = REQUEST_CODE_DATA_FOLDER) {
            val activity = Extension.mainActivity ?: return
            val dataPath = activity.getExternalFilesDir(null)?.absolutePath ?: return
            openFolderInSystemExplorer(dataPath, requestCode)
        }
        
        /**
         * Open mods folder in system file explorer
         * Opens Android/data/com.leninasto.plusengine/files/mods/
         */
        @JvmStatic
        fun openModsFolder() {
            val activity = Extension.mainActivity ?: return
            val basePath = activity.getExternalFilesDir(null)?.absolutePath ?: return
            openFolderInSystemExplorer("$basePath/mods", REQUEST_CODE_MODS_FOLDER)
        }
        
        /**
         * Open saves folder in system file explorer
         */
        @JvmStatic
        fun openSavesFolder() {
            val activity = Extension.mainActivity ?: return
            val basePath = activity.getExternalFilesDir(null)?.absolutePath ?: return
            openFolderInSystemExplorer("$basePath/saves", REQUEST_CODE_SAVES_FOLDER)
        }
        
        /**
         * Open logs folder in system file explorer
         */
        @JvmStatic
        fun openLogsFolder() {
            val activity = Extension.mainActivity ?: return
            val basePath = activity.getExternalFilesDir(null)?.absolutePath ?: return
            openFolderInSystemExplorer("$basePath/logs", REQUEST_CODE_LOGS_FOLDER)
        }
        
        /**
         * Open a native file picker dialog that allows the user to select
         * a JSON or XML file from device storage.
         * 
         * After the user picks a file (or cancels), the result is stored
         * internally. Call getPickedFilePath() to retrieve the absolute path.
         * An empty string means the picker was cancelled or an error occurred.
         */
        @JvmStatic
        fun openFilePicker() {
            val activity = Extension.mainActivity ?: return
            activity.runOnUiThread {
                val baseDir = activity.getExternalFilesDir(null)
                val intent = Intent(activity, FileManagerActivity::class.java).apply {
                    putExtra(FileManagerActivity.EXTRA_SELECT_FILE, true)
                    if (baseDir != null)
                        putExtra(FileManagerActivity.EXTRA_INITIAL_PATH, baseDir.absolutePath)
                }
                // Reset previous result before opening.
                pickedFilePath = ""
                pickedFileContent = ""
                pickedFileStatus = PICKED_FILE_STATUS_NONE
                android.util.Log.i("PlusEngine", "Opening engine file picker at: ${baseDir?.absolutePath ?: "<null>"}")
                activity.startActivityForResult(intent, REQUEST_CODE_FILE_PICKER)
            }
        }

        /**
         * Returns the display name of the file selected by openFilePicker().
         * Returns an empty string if no file has been picked yet or the picker was cancelled.
         */
        @JvmStatic
        fun getPickedFilePath(): String = pickedFilePath

        /**
         * Returns the raw text content of the file selected by openFilePicker().
         * The content is read directly from the ContentResolver without copying to disk.
         * Returns an empty string if no file has been picked or reading failed.
         */
        @JvmStatic
        fun getPickedFileContent(): String = pickedFileContent

        /**
         * Returns the current picker state.
         * 0 = waiting/no result, 1 = success, -1 = cancelled, -2 = error.
         */
        @JvmStatic
        fun getPickedFileStatus(): Int = pickedFileStatus

        /**
         * Clears both the stored file name and content so subsequent calls return
         * empty strings until the user picks a new file.
         */
        @JvmStatic
        fun clearPickedFile() {
            pickedFilePath = ""
            pickedFileContent = ""
            pickedFileStatus = PICKED_FILE_STATUS_NONE
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