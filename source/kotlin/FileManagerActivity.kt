package com.leninasto.plusengine

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.content.res.ColorStateList
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import android.text.Editable
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.LayoutParams.MATCH_PARENT
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale

/**
 * Native Android File Manager Activity for FNF: Plus Engine
 * Material Design 3 implementation with proper runtime permission handling
 */
class FileManagerActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_INITIAL_PATH = "initial_path"
        const val EXTRA_START_LOCATION = "start_location"
        private const val REQUEST_STORAGE_PERMISSION = 1001
        private const val REQUEST_MANAGE_STORAGE = 1002
    }

    // MD3 Dark color tokens
    private val colorBackground              = Color.parseColor("#1C1B1F")
    private val colorSurface                 = Color.parseColor("#1C1B1F")
    private val colorSurfaceContainer        = Color.parseColor("#211F26")
    private val colorSurfaceContainerHigh    = Color.parseColor("#2B2930")
    private val colorSurfaceContainerHighest = Color.parseColor("#36343B")
    private val colorOnSurface               = Color.parseColor("#E6E1E5")
    private val colorOnSurfaceVariant        = Color.parseColor("#CAC4D0")
    private val colorPrimary                 = Color.parseColor("#D0BCFF")
    private val colorPrimaryContainer        = Color.parseColor("#4F378B")
    private val colorSecondaryContainer      = Color.parseColor("#4A4458")
    private val colorOnSecondaryContainer    = Color.parseColor("#E8DEF8")
    private val colorOutline                 = Color.parseColor("#938F99")
    private val colorOutlineVariant          = Color.parseColor("#49454F")

    private val textExtensions  = setOf("txt", "json", "xml", "lua", "hx", "hxs", "log", "md", "ini", "cfg", "yaml", "yml")
    private val imageExtensions = setOf("png", "jpg", "jpeg", "webp", "gif")
    private val audioExtensions = setOf("ogg", "mp3", "wav", "flac")

    private lateinit var currentPath: File
    private lateinit var listView: ListView
    private lateinit var pathText: TextView
    private lateinit var searchEdit: EditText
    private lateinit var fileAdapter: ArrayAdapter<String>

    // Parallel list to the adapter - avoids ALL emoji string-parsing bugs
    private val fileList = mutableListOf<File?>() // null = parent ".." entry
    private var searchQuery = ""

    private fun dp(v: Int): Int = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics
    ).toInt()

    // ── Lifecycle ──────────────────────────────────────────────────────────

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            window.statusBarColor = colorSurfaceContainerHigh
            window.navigationBarColor = colorBackground
        }

        buildUI()

        val initial = resolveInitialPath()
        currentPath = initial

        if (needsPermission(initial)) {
            requestStorageAccess { loadDirectory(currentPath) }
        } else {
            loadDirectory(currentPath)
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        val parent = currentPath.parentFile
        val scoped = getExternalFilesDir(null)

        val atScopedRoot = scoped != null &&
            try { currentPath.canonicalPath == scoped.canonicalPath } catch (e: Exception) { false }

        when {
            // Still inside accessible dirs - go up
            parent != null && parent.canRead() && !atScopedRoot -> loadDirectory(parent)
            // At scoped root but have full permission - allow going up
            parent != null && parent.canRead() && hasStoragePermission() -> loadDirectory(parent)
            // Nowhere to go - exit to game
            else -> {
                @Suppress("DEPRECATION")
                super.onBackPressed()
            }
        }
    }

    // ── Permissions ────────────────────────────────────────────────────────

    private fun needsPermission(file: File): Boolean {
        val scoped = getExternalFilesDir(null) ?: return false
        return try {
            !file.canonicalPath.startsWith(scoped.canonicalPath)
        } catch (e: Exception) { false }
    }

    private fun hasStoragePermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            return Environment.isExternalStorageManager()
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            return checkSelfPermission(Manifest.permission.READ_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
        return true
    }

    private fun requestStorageAccess(onGranted: () -> Unit) {
        if (hasStoragePermission()) { onGranted(); return }

        MaterialAlertDialogBuilder(this)
            .setTitle("Storage Access Required")
            .setMessage(
                "To browse external storage (e.g. the mods folder), this app needs full storage access permission."
            )
            .setPositiveButton("Grant Permission") { _, _ ->
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    try {
                        startActivityForResult(
                            Intent(
                                Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                                Uri.parse("package:$packageName")
                            ),
                            REQUEST_MANAGE_STORAGE
                        )
                    } catch (e: Exception) {
                        startActivityForResult(
                            Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION),
                            REQUEST_MANAGE_STORAGE
                        )
                    }
                } else {
                    requestPermissions(
                        arrayOf(
                            Manifest.permission.READ_EXTERNAL_STORAGE,
                            Manifest.permission.WRITE_EXTERNAL_STORAGE
                        ),
                        REQUEST_STORAGE_PERMISSION
                    )
                }
            }
            .setNegativeButton("Use App Folder") { _, _ ->
                currentPath = getExternalFilesDir(null)!!
                loadDirectory(currentPath)
            }
            .setCancelable(false)
            .show()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_STORAGE_PERMISSION) {
            if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
                loadDirectory(currentPath)
            } else {
                currentPath = getExternalFilesDir(null)!!
                loadDirectory(currentPath)
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_MANAGE_STORAGE) {
            val granted = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                Environment.isExternalStorageManager()
            if (!granted) {
                currentPath = getExternalFilesDir(null)!!
            }
            loadDirectory(currentPath)
        }
    }

    // ── UI construction ────────────────────────────────────────────────────

    private fun buildUI() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(MATCH_PARENT, MATCH_PARENT)
            setBackgroundColor(colorBackground)
        }

        root.addView(buildTopBar())
        root.addView(buildPathBar())
        root.addView(buildSearchBar())
        root.addView(divider())
        root.addView(buildFileList())
        root.addView(divider())
        root.addView(buildActionBar())

        setContentView(root)
    }

    private fun buildTopBar(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dp(8), dp(8), dp(8), dp(8))
            setBackgroundColor(colorSurfaceContainerHigh)
            gravity = Gravity.CENTER_VERTICAL
            minimumHeight = dp(56)

            addView(outlinedBtn("← Back") { finish() }.apply {
                setTextColor(colorPrimary)
                strokeColor = ColorStateList.valueOf(colorPrimaryContainer)
            })

            addView(View(this@FileManagerActivity).apply {
                layoutParams = LinearLayout.LayoutParams(0, 1, 1f)
            })

            addView(chipBtn("Mods")  { navigateTo("mods")  })
            addView(chipBtn("Saves") { navigateTo("saves") })
            addView(chipBtn("Logs")  { navigateTo("logs")  })
        }
    }

    private fun buildPathBar(): TextView {
        pathText = TextView(this).apply {
            textSize = 11f
            setTextColor(colorOnSurfaceVariant)
            setPadding(dp(16), dp(6), dp(16), dp(6))
            setBackgroundColor(colorSurfaceContainer)
            typeface = Typeface.MONOSPACE
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
            isSingleLine = true
            ellipsize = android.text.TextUtils.TruncateAt.START
        }
        return pathText
    }

    private fun buildSearchBar(): EditText {
        searchEdit = EditText(this).apply {
            hint = "Search files..."
            setHintTextColor(colorOutline)
            setTextColor(colorOnSurface)
            setPadding(dp(16), dp(10), dp(16), dp(10))
            setSingleLine(true)
            background = null
            setBackgroundColor(colorSurfaceContainerHigh)
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)

            addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
                    searchQuery = s?.toString() ?: ""
                    refreshDisplay()
                }
                override fun afterTextChanged(s: Editable?) {}
            })
        }
        return searchEdit
    }

    private fun buildFileList(): ListView {
        fileAdapter = object : ArrayAdapter<String>(this, 0, mutableListOf()) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val tv = (convertView as? TextView) ?: TextView(context).apply {
                    setPadding(dp(16), dp(14), dp(16), dp(14))
                    textSize = 15f
                    layoutParams = AbsListView.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
                }
                val file = fileList.getOrNull(position)
                tv.text = getItem(position) ?: ""
                tv.setBackgroundColor(colorSurface)
                tv.setTextColor(when {
                    file == null        -> colorOnSurfaceVariant  // ".." icon
                    file.isDirectory    -> colorPrimary
                    else                -> colorOnSurface
                })
                return tv
            }
        }

        listView = ListView(this).apply {
            adapter = fileAdapter
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
            setBackgroundColor(colorSurface)
            divider = android.graphics.drawable.ColorDrawable(Color.argb(50, 147, 143, 153))
            dividerHeight = 1
            setOnItemClickListener { _, _, pos, _ -> handleItemClick(pos) }
            setOnItemLongClickListener { _, _, pos, _ -> handleItemLongClick(pos); true }
        }
        return listView
    }

    private fun buildActionBar(): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(dp(12), dp(8), dp(12), dp(8))
            setBackgroundColor(colorSurfaceContainer)

            addView(filledBtn("📁  New Folder", colorSecondaryContainer, colorOnSecondaryContainer) {
                promptCreate(isDir = true)
            }.apply { layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f).apply { rightMargin = dp(6) } })

            addView(filledBtn("📄  New File", colorSurfaceContainerHighest, colorOnSurface) {
                promptCreate(isDir = false)
            }.apply { layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f).apply { leftMargin = dp(6) } })
        }
    }

    // ── Button factories ───────────────────────────────────────────────────

    private fun outlinedBtn(label: String, onClick: () -> Unit) =
        MaterialButton(this, null, com.google.android.material.R.attr.materialButtonOutlinedStyle).apply {
            text = label
            cornerRadius = dp(8)
            setOnClickListener { onClick() }
        }

    private fun chipBtn(label: String, onClick: () -> Unit) =
        MaterialButton(this, null, com.google.android.material.R.attr.materialButtonOutlinedStyle).apply {
            text = label
            textSize = 12f
            setTextColor(colorOnSurfaceVariant)
            strokeColor = ColorStateList.valueOf(colorOutlineVariant)
            cornerRadius = dp(20)
            setPadding(dp(10), 0, dp(10), 0)
            layoutParams = LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { leftMargin = dp(6) }
            setOnClickListener { onClick() }
        }

    private fun filledBtn(label: String, bg: Int, fg: Int, onClick: () -> Unit) =
        MaterialButton(this).apply {
            text = label
            setTextColor(fg)
            backgroundTintList = ColorStateList.valueOf(bg)
            cornerRadius = dp(8)
            setOnClickListener { onClick() }
        }

    private fun divider() = View(this).apply {
        layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 1)
        setBackgroundColor(colorOutlineVariant)
    }

    private fun inputField(hint: String, prefill: String = "") = EditText(this).apply {
        this.hint = hint
        setText(prefill)
        setHintTextColor(colorOutline)
        setTextColor(colorOnSurface)
        setBackgroundColor(colorSurfaceContainerHigh)
        setPadding(dp(16), dp(12), dp(16), dp(12))
    }

    // ── Navigation ─────────────────────────────────────────────────────────

    private fun resolveInitialPath(): File {
        return when (intent.getStringExtra(EXTRA_START_LOCATION)) {
            "mods"  -> File(Environment.getExternalStorageDirectory(), ".PlusEngine/mods")
            "saves" -> File(getExternalFilesDir(null), "saves")
            "logs"  -> File(getExternalFilesDir(null), "logs")
            else    -> intent.getStringExtra(EXTRA_INITIAL_PATH)
                            ?.let { File(it) }
                            ?: getExternalFilesDir(null)!!
        } ?: getExternalFilesDir(null)!!
    }

    private fun navigateTo(location: String) {
        val target = when (location) {
            "mods"  -> File(Environment.getExternalStorageDirectory(), ".PlusEngine/mods")
            "saves" -> File(getExternalFilesDir(null), "saves")
            "logs"  -> File(getExternalFilesDir(null), "logs")
            else    -> getExternalFilesDir(null)!!
        }
        if (needsPermission(target) && !hasStoragePermission()) {
            currentPath = target
            requestStorageAccess { loadDirectory(currentPath) }
        } else {
            target.mkdirs()
            loadDirectory(target)
        }
    }

    private fun loadDirectory(dir: File) {
        if (!dir.exists()) {
            try { dir.mkdirs() } catch (e: Exception) {
                Toast.makeText(this, "Cannot create directory: ${e.message}", Toast.LENGTH_SHORT).show()
                return
            }
        }

        if (!dir.canRead()) {
            Toast.makeText(this, "Access denied: ${dir.name}", Toast.LENGTH_LONG).show()
            val fallback = getExternalFilesDir(null)!!
            if (!dir.canonicalPath.equals(fallback.canonicalPath)) {
                currentPath = fallback
                loadDirectory(fallback)
            }
            return
        }

        currentPath = dir
        pathText.text = dir.absolutePath
        searchEdit.setText("")
        searchQuery = ""
        refreshDisplay()
    }

    private fun refreshDisplay() {
        val all = currentPath.listFiles()
            ?.sortedWith(compareBy<File> { !it.isDirectory }.thenBy { it.name.lowercase() })
            ?: emptyList()

        val shown = if (searchQuery.isBlank()) all
                    else all.filter { it.name.lowercase().contains(searchQuery.lowercase()) }

        fileAdapter.clear()
        fileList.clear()

        if (searchQuery.isBlank() && currentPath.parentFile != null) {
            fileAdapter.add("⬆   ..")
            fileList.add(null)
        }

        shown.forEach { file ->
            val icon = when {
                file.isDirectory -> "📁  "
                file.extension.lowercase() in textExtensions  -> "📝  "
                file.extension.lowercase() in imageExtensions -> "🖼   "
                file.extension.lowercase() in audioExtensions -> "🎵  "
                else -> "📄  "
            }
            fileAdapter.add("$icon${file.name}")
            fileList.add(file)
        }

        fileAdapter.notifyDataSetChanged()
    }

    // ── Item handlers ──────────────────────────────────────────────────────

    private fun handleItemClick(position: Int) {
        val file = fileList.getOrNull(position)
        when {
            file == null       -> currentPath.parentFile?.let { loadDirectory(it) }
            file.isDirectory   -> loadDirectory(file)
            else               -> openFile(file)
        }
    }

    private fun handleItemLongClick(position: Int) {
        val file = fileList.getOrNull(position) ?: return // ".." – ignore

        MaterialAlertDialogBuilder(this)
            .setTitle(file.name)
            .setItems(arrayOf("Open", "Rename", "Delete", "Info")) { _, which ->
                when (which) {
                    0 -> if (file.isFile) openFile(file) else loadDirectory(file)
                    1 -> promptRename(file)
                    2 -> confirmDelete(file)
                    3 -> showFileInfo(file)
                }
            }
            .show()
    }

    // ── File operations ────────────────────────────────────────────────────

    private fun openFile(file: File) {
        if (file.extension.lowercase() !in textExtensions) {
            Toast.makeText(this, "Cannot edit .${file.extension} files", Toast.LENGTH_SHORT).show()
            return
        }
        if (file.length() > 1024 * 1024) {
            Toast.makeText(this, "File too large (max 1 MB)", Toast.LENGTH_SHORT).show()
            return
        }
        try {
            val edit = inputField("").apply {
                setText(file.readText())
                typeface = Typeface.MONOSPACE
                textSize = 13f
            }

            MaterialAlertDialogBuilder(this)
                .setTitle("✏️  ${file.name}")
                .setView(ScrollView(this).apply { addView(edit) })
                .setPositiveButton("Save") { _, _ ->
                    try {
                        file.writeText(edit.text.toString())
                        Toast.makeText(this, "Saved!", Toast.LENGTH_SHORT).show()
                    } catch (e: Exception) {
                        Toast.makeText(this, "Save error: ${e.message}", Toast.LENGTH_SHORT).show()
                    }
                }
                .setNegativeButton("Cancel", null)
                .show()
        } catch (e: Exception) {
            Toast.makeText(this, "Error reading file: ${e.message}", Toast.LENGTH_SHORT).show()
        }
    }

    private fun promptCreate(isDir: Boolean) {
        val hint = if (isDir) "Folder name" else "e.g. config.json"
        val title = if (isDir) "📁  New Folder" else "📄  New File"
        val input = inputField(hint)

        MaterialAlertDialogBuilder(this)
            .setTitle(title)
            .setView(input)
            .setPositiveButton("Create") { _, _ ->
                val name = input.text.toString().trim()
                if (name.isEmpty()) return@setPositiveButton
                val target = File(currentPath, name)
                try {
                    val ok = if (isDir) target.mkdirs() else target.createNewFile()
                    if (ok) {
                        Toast.makeText(this, if (isDir) "Folder created" else "File created", Toast.LENGTH_SHORT).show()
                        refreshDisplay()
                        if (!isDir) openFile(target)
                    } else {
                        Toast.makeText(this, "Already exists", Toast.LENGTH_SHORT).show()
                    }
                } catch (e: Exception) {
                    Toast.makeText(this, "Error: ${e.message}", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun promptRename(file: File) {
        val input = inputField(file.name, file.name)

        MaterialAlertDialogBuilder(this)
            .setTitle("✏️  Rename")
            .setView(input)
            .setPositiveButton("Rename") { _, _ ->
                val name = input.text.toString().trim()
                if (name.isEmpty()) return@setPositiveButton
                if (file.renameTo(File(currentPath, name))) {
                    Toast.makeText(this, "Renamed", Toast.LENGTH_SHORT).show()
                    refreshDisplay()
                } else {
                    Toast.makeText(this, "Failed to rename", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun confirmDelete(file: File) {
        MaterialAlertDialogBuilder(this)
            .setTitle("🗑️  Delete?")
            .setMessage(
                "\"${file.name}\"\n" +
                if (file.isDirectory) "This will delete the folder and all its contents." else "This action cannot be undone."
            )
            .setPositiveButton("Delete") { _, _ ->
                if (file.deleteRecursively()) {
                    Toast.makeText(this, "Deleted", Toast.LENGTH_SHORT).show()
                    refreshDisplay()
                } else {
                    Toast.makeText(this, "Failed to delete", Toast.LENGTH_SHORT).show()
                }
            }
            .setNegativeButton("Cancel", null)
            .show()
    }

    private fun showFileInfo(file: File) {
        val size = if (file.isDirectory) "${file.listFiles()?.size ?: 0} items" else formatSize(file.length())
        val date = SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault()).format(file.lastModified())

        MaterialAlertDialogBuilder(this)
            .setTitle("ℹ️  ${file.name}")
            .setMessage(
                "Path:\n${file.absolutePath}\n\n" +
                "Size: $size\n" +
                "Modified: $date\n" +
                "Readable: ${file.canRead()}   Writable: ${file.canWrite()}"
            )
            .setPositiveButton("OK", null)
            .show()
    }

    private fun formatSize(bytes: Long): String = when {
        bytes < 1024L            -> "$bytes B"
        bytes < 1024L * 1024     -> "${bytes / 1024} KB"
        bytes < 1024L * 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
        else                     -> "${bytes / (1024L * 1024 * 1024)} GB"
    }
}
