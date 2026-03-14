package com.leninasto.plusengine

import android.app.Activity
import android.app.AlertDialog
import android.os.Bundle
import android.os.Environment
import android.widget.*
import android.view.ViewGroup
import android.graphics.Color
import java.io.File

/**
 * Native Android File Manager Activity for FNF: Plus Engine
 * Allows users to browse, view and edit game files
 */
class FileManagerActivity : Activity() {
    
    private lateinit var currentPath: File
    private lateinit var listView: ListView
    private lateinit var pathTextView: TextView
    private lateinit var fileAdapter: ArrayAdapter<String>
    private lateinit var searchEdit: EditText
    
    companion object {
        const val EXTRA_INITIAL_PATH = "initial_path"
        const val EXTRA_START_LOCATION = "start_location"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Create UI programmatically (no XML layout needed)
        createUI()
        
        // Get initial path from intent
        val initialPath = when (intent.getStringExtra(EXTRA_START_LOCATION)) {
            "mods" -> File(Environment.getExternalStorageDirectory(), ".PlusEngine/mods")
            "saves" -> File(getExternalFilesDir(null), "saves")
            "logs" -> File(getExternalFilesDir(null), "logs")
            "assets" -> File(getExternalFilesDir(null), "assets")
            else -> {
                val path = intent.getStringExtra(EXTRA_INITIAL_PATH)
                if (path != null) File(path) else getExternalFilesDir(null)
            }
        } ?: getExternalFilesDir(null)!!
        
        currentPath = initialPath
        loadDirectory(currentPath)
    }
    
    private fun createUI() {
        // Main layout
        val layout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            setBackgroundColor(Color.parseColor("#1a1a1a"))
        }
        
        // Top bar
        val topBar = createTopBar()
        layout.addView(topBar)
        
        // Path display
        pathTextView = TextView(this).apply {
            text = "/"
            textSize = 14f
            setTextColor(Color.WHITE)
            setPadding(16, 8, 16, 8)
            setBackgroundColor(Color.parseColor("#2a2a2a"))
        }
        layout.addView(pathTextView)
        
        // Search bar
        searchEdit = EditText(this).apply {
            hint = "Search files..."
            setHintTextColor(Color.GRAY)
            setTextColor(Color.WHITE)
            setPadding(16, 16, 16, 16)
            setSingleLine(true)
            setBackgroundColor(Color.parseColor("#2a2a2a"))
        }
        
        searchEdit.addTextChangedListener(object : android.text.TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                filterFiles(s.toString())
            }
            override fun afterTextChanged(s: android.text.Editable?) {}
        })
        
        layout.addView(searchEdit)
        
        // File list
        listView = ListView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
            setBackgroundColor(Color.parseColor("#1a1a1a"))
            divider = android.graphics.drawable.ColorDrawable(Color.parseColor("#3a3a3a"))
            dividerHeight = 1
        }
        
        fileAdapter = ArrayAdapter(
            this,
            android.R.layout.simple_list_item_1,
            mutableListOf<String>()
        )
        listView.adapter = fileAdapter
        
        listView.setOnItemClickListener { _, _, position, _ ->
            handleItemClick(position)
        }
        
        listView.setOnItemLongClickListener { _, _, position, _ ->
            handleItemLongClick(position)
            true
        }
        
        layout.addView(listView)
        
        // Bottom action bar
        val actionBar = createActionBar()
        layout.addView(actionBar)
        
        setContentView(layout)
    }
    
    private fun createTopBar(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(8, 8, 8, 8)
            setBackgroundColor(Color.parseColor("#2a2a2a"))
            
            // Back to game button
            addView(Button(this@FileManagerActivity).apply {
                text = "← Back to Game"
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#4a4a4a"))
                setOnClickListener { finish() }
            })
            
            // Quick navigation buttons
            addView(createQuickNavButton("Mods", "mods"))
            addView(createQuickNavButton("Saves", "saves"))
            addView(createQuickNavButton("Logs", "logs"))
        }
    }
    
    private fun createQuickNavButton(label: String, location: String): Button {
        return Button(this).apply {
            text = label
            textSize = 12f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#3a3a3a"))
            setPadding(16, 8, 16, 8)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                leftMargin = 8
            }
            
            setOnClickListener {
                val path = when (location) {
                    "mods" -> File(Environment.getExternalStorageDirectory(), ".PlusEngine/mods")
                    "saves" -> File(getExternalFilesDir(null), "saves")
                    "logs" -> File(getExternalFilesDir(null), "logs")
                    else -> getExternalFilesDir(null)!!
                }
                loadDirectory(path)
            }
        }
    }
    
    private fun createActionBar(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(8, 8, 8, 8)
            setBackgroundColor(Color.parseColor("#2a2a2a"))
            
            addView(Button(this@FileManagerActivity).apply {
                text = "New Folder"
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#4a4a4a"))
                setOnClickListener { createNewFolder() }
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply { rightMargin = 4 }
            })
            
            addView(Button(this@FileManagerActivity).apply {
                text = "New File"
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#4a4a4a"))
                setOnClickListener { createNewFile() }
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    1f
                ).apply { leftMargin = 4 }
            })
        }
    }
    
    private fun loadDirectory(dir: File) {
        if (!dir.exists()) {
            try {
                dir.mkdirs()
            } catch (e: Exception) {
                Toast.makeText(this, "Cannot create directory: ${e.message}", Toast.LENGTH_SHORT).show()
                return
            }
        }
        
        if (!dir.canRead()) {
            Toast.makeText(this, "Cannot access directory: Permission denied", Toast.LENGTH_SHORT).show()
            return
        }
        
        currentPath = dir
        pathTextView.text = dir.absolutePath
        searchEdit.setText("") // Clear search
        
        refreshFileList()
    }
    
    private fun refreshFileList() {
        val files = currentPath.listFiles()?.sortedWith(
            compareBy<File> { !it.isDirectory }.thenBy { it.name.lowercase() }
        ) ?: emptyList()
        
        fileAdapter.clear()
        
        // Add parent directory option
        if (currentPath.parent != null) {
            fileAdapter.add("📁 ..")
        }
        
        // Add files and directories
        files.forEach { file ->
            val icon = when {
                file.isDirectory -> "📁"
                file.extension.lowercase() in listOf("json", "txt", "xml", "lua", "hx") -> "📄"
                file.extension.lowercase() in listOf("png", "jpg", "jpeg") -> "🖼️"
                file.extension.lowercase() in listOf("ogg", "mp3", "wav") -> "🎵"
                else -> "📄"
            }
            fileAdapter.add("$icon ${file.name}")
        }
        
        fileAdapter.notifyDataSetChanged()
    }
    
    private fun filterFiles(query: String) {
        if (query.isEmpty()) {
            refreshFileList()
            return
        }
        
        val files = currentPath.listFiles()?.filter { file ->
            file.name.lowercase().contains(query.lowercase())
        }?.sortedWith(
            compareBy<File> { !it.isDirectory }.thenBy { it.name.lowercase() }
        ) ?: emptyList()
        
        fileAdapter.clear()
        
        files.forEach { file ->
            val icon = if (file.isDirectory) "📁" else "📄"
            fileAdapter.add("$icon ${file.name}")
        }
        
        fileAdapter.notifyDataSetChanged()
    }
    
    private fun handleItemClick(position: Int) {
        val item = fileAdapter.getItem(position) ?: return
        val fileName = item.substring(2) // Remove emoji
        
        if (fileName == "..") {
            currentPath.parentFile?.let { loadDirectory(it) }
            return
        }
        
        val file = File(currentPath, fileName)
        
        if (file.isDirectory) {
            loadDirectory(file)
        } else {
            openFile(file)
        }
    }
    
    private fun handleItemLongClick(position: Int) {
        val item = fileAdapter.getItem(position) ?: return
        val fileName = item.substring(2)
        
        if (fileName == "..") return
        
        val file = File(currentPath, fileName)
        
        AlertDialog.Builder(this)
            .setTitle(file.name)
            .setItems(arrayOf("Open", "Rename", "Delete", "Info")) { _, which ->
                when (which) {
                    0 -> if (file.isFile) openFile(file) else loadDirectory(file)
                    1 -> renameFile(file)
                    2 -> deleteFile(file)
                    3 -> showFileInfo(file)
                }
            }
            .show()
    }
    
    private fun openFile(file: File) {
        val extension = file.extension.lowercase()
        
        // Only open text files for editing
        if (extension in listOf("txt", "json", "xml", "lua", "hx", "hxs", "log", "md", "ini")) {
            if (file.length() > 1024 * 1024) { // 1MB limit
                Toast.makeText(this, "File too large to edit (max 1MB)", Toast.LENGTH_SHORT).show()
                return
            }
            
            try {
                val content = file.readText()
                showTextEditor(file, content)
            } catch (e: Exception) {
                Toast.makeText(this, "Error reading file: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        } else {
            Toast.makeText(this, "Cannot edit ${extension.uppercase()} files", Toast.LENGTH_SHORT).show()
        }
    }
    
    private fun showTextEditor(file: File, content: String) {
        val editText = EditText(this).apply {
            setText(content)
            setSingleLine(false)
            minLines = 20
            setTextColor(Color.BLACK)
            setBackgroundColor(Color.WHITE)
            setPadding(16, 16, 16, 16)
            setHorizontallyScrolling(true)
        }
        
        val scrollView = ScrollView(this).apply {
            addView(editText)
        }
        
        AlertDialog.Builder(this)
            .setTitle("Edit: ${file.name}")
            .setView(scrollView)
            .setPositiveButton("Save") { _, _ ->
                try {
                    file.writeText(editText.text.toString())
                    Toast.makeText(this, "File saved!", Toast.LENGTH_SHORT).show()
                } catch (e: Exception) {
                    Toast.makeText(this, "Error saving: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .setNeutralButton("Info") { _, _ ->
                showFileInfo(file)
            }
            .show()
    }
    
    private fun createNewFolder() {
        val input = EditText(this).apply {
            hint = "Folder name"
            setTextColor(Color.BLACK)
        }
        
        AlertDialog.Builder(this)
            .setTitle("Create New Folder")
            .setView(input)
            .setPositiveButton("Create") { _, _ ->
                val name = input.text.toString().trim()
                if (name.isEmpty()) {
                    Toast.makeText(this, "Folder name cannot be empty", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                
                val newFolder = File(currentPath, name)
                try {
                    if (newFolder.mkdir()) {
                        Toast.makeText(this, "Folder created!", Toast.LENGTH_SHORT).show()
                        refreshFileList()
                    } else {
                        Toast.makeText(this, "Failed to create folder", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
    
    private fun createNewFile() {
        val input = EditText(this).apply {
            hint = "File name (e.g., config.json)"
            setTextColor(Color.BLACK)
        }
        
        AlertDialog.Builder(this)
            .setTitle("Create New File")
            .setView(input)
            .setPositiveButton("Create") { _, _ ->
                val name = input.text.toString().trim()
                if (name.isEmpty()) {
                    Toast.makeText(this, "File name cannot be empty", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                
                val newFile = File(currentPath, name)
                try {
                    if (newFile.createNewFile()) {
                        Toast.makeText(this, "File created!", Toast.LENGTH_SHORT).show()
                        refreshFileList()
                        openFile(newFile)
                    } else {
                        Toast.makeText(this, "File already exists", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
    
    private fun renameFile(file: File) {
        val input = EditText(this).apply {
            setText(file.name)
            setTextColor(Color.BLACK)
        }
        
        AlertDialog.Builder(this)
            .setTitle("Rename")
            .setView(input)
            .setPositiveButton("Rename") { _, _ ->
                val newName = input.text.toString().trim()
                if (newName.isEmpty()) {
                    Toast.makeText(this, "Name cannot be empty", Toast.LENGTH_SHORT).show()
                    return@setPositiveButton
                }
                
                val newFile = File(currentPath, newName)
                try {
                    if (file.renameTo(newFile)) {
                        Toast.makeText(this, "Renamed successfully!", Toast.LENGTH_SHORT).show()
                        refreshFileList()
                    } else {
                        Toast.makeText(this, "Failed to rename", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
    
    private fun deleteFile(file: File) {
        AlertDialog.Builder(this)
            .setTitle("Delete")
            .setMessage("Are you sure you want to delete ${file.name}?")
            .setPositiveButton("Delete") { _, _ ->
                try {
                    if (file.deleteRecursively()) {
                        Toast.makeText(this, "Deleted successfully!", Toast.LENGTH_SHORT).show()
                        refreshFileList()
                    } else {
                        Toast.makeText(this, "Failed to delete", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }
    
    private fun showFileInfo(file: File) {
        val size = if (file.isDirectory) {
            "${file.listFiles()?.size ?: 0} items"
        } else {
            formatFileSize(file.length())
        }
        
        val info = """
            Name: ${file.name}
            Path: ${file.absolutePath}
            Type: ${if (file.isDirectory) "Directory" else "File"}
            Size: $size
            Last Modified: ${java.text.SimpleDateFormat("yyyy-MM-dd HH:mm:ss").format(file.lastModified())}
            Readable: ${file.canRead()}
            Writable: ${file.canWrite()}
        """.trimIndent()
        
        AlertDialog.Builder(this)
            .setTitle("File Information")
            .setMessage(info)
            .setPositiveButton("OK", null)
            .show()
    }
    
    private fun formatFileSize(size: Long): String {
        return when {
            size < 1024 -> "$size B"
            size < 1024 * 1024 -> "${size / 1024} KB"
            size < 1024 * 1024 * 1024 -> "${size / (1024 * 1024)} MB"
            else -> "${size / (1024 * 1024 * 1024)} GB"
        }
    }
    
    override fun onBackPressed() {
        // Go up one directory or exit
        if (currentPath.parent != null) {
            currentPath.parentFile?.let { loadDirectory(it) }
        } else {
            super.onBackPressed()
        }
    }
}
