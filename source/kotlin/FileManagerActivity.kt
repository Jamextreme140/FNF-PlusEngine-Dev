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
import androidx.core.content.FileProvider
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.button.MaterialButton
import com.google.android.material.color.DynamicColors
import com.google.android.material.color.MaterialColors
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.shape.CornerFamily
import com.google.android.material.shape.MaterialShapeDrawable
import com.google.android.material.shape.ShapeAppearanceModel
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import com.leninasto.plusengine.languages.*
import java.io.File
import java.text.SimpleDateFormat
import java.util.Locale

class FileManagerActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_INITIAL_PATH = "initial_path"
        const val EXTRA_START_LOCATION = "start_location"
        private const val REQUEST_STORAGE_PERMISSION = 1001
        private const val REQUEST_MANAGE_STORAGE = 1002
    }

    private val textExtensions  = setOf("txt", "json", "xml", "lua", "hx", "hxs", "log", "md", "ini", "cfg", "yaml", "yml")
    private val imageExtensions = setOf("png", "jpg", "jpeg", "webp", "gif")
    private val audioExtensions = setOf("ogg", "mp3", "wav", "flac")
    private val videoExtensions = setOf("mp4", "mkv", "mov", "3gp", "webm")

    private lateinit var currentPath: File
    private lateinit var listView: ListView
    private lateinit var pathText: TextView
    private lateinit var searchEdit: EditText
    private lateinit var fileAdapter: ArrayAdapter<String>
    private lateinit var actionLayout: LinearLayout
    private lateinit var lang: Language

    private val fileList = mutableListOf<File?>()
    private var searchQuery = ""

    private var clipboardFile: File? = null
    private var isCutOperation: Boolean = false

    // MD3 Colors
    private val colorSurface get() = MaterialColors.getColor(this, com.google.android.material.R.attr.colorSurface, Color.BLACK)
    private val colorPrimary get() = MaterialColors.getColor(this, com.google.android.material.R.attr.colorPrimary, Color.BLUE)
    private val colorOnSurface get() = MaterialColors.getColor(this, com.google.android.material.R.attr.colorOnSurface, Color.WHITE)
    private val colorSurfaceContainer get() = MaterialColors.getColor(this, com.google.android.material.R.attr.colorSurfaceContainer, Color.DKGRAY)

    private fun dp(v: Int): Int = TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, v.toFloat(), resources.displayMetrics).toInt()

    override fun onCreate(savedInstanceState: Bundle?) {
        DynamicColors.applyToActivityIfAvailable(this)
        super.onCreate(savedInstanceState)
        
        setupLanguage()
        buildUI()
        
        val initial = resolveInitialPath()
        currentPath = initial
        
        if (needsPermission(initial)) requestStorageAccess { loadDirectory(currentPath) }
        else loadDirectory(currentPath)
    }

    private fun setupLanguage() {
        val currentLocale = Locale.getDefault().language
        lang = if (currentLocale == "es") Spanish() else English()
    }

    private fun buildUI() {
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = ViewGroup.LayoutParams(MATCH_PARENT, MATCH_PARENT)
            setBackgroundColor(colorSurface)
        }

        root.addView(buildTopBar())
        root.addView(buildPathBar())
        root.addView(buildSearchBar())
        root.addView(divider())
        root.addView(buildFileList())
        root.addView(divider())

        actionLayout = buildActionBar()
        root.addView(actionLayout)
        setContentView(root)
    }

    private fun buildTopBar() = LinearLayout(this).apply {
        setPadding(dp(12), dp(12), dp(12), dp(12))
        setBackgroundColor(colorSurfaceContainer)
        gravity = Gravity.CENTER_VERTICAL
        addView(outlinedBtn(lang.back) { finish() }.apply { 
            layoutParams = LinearLayout.LayoutParams(WRAP_CONTENT, dp(48))
            setIconResource(android.R.drawable.ic_menu_revert)
        })
        addView(View(context).apply { layoutParams = LinearLayout.LayoutParams(0, 1, 1f) })
        addView(chipBtn(lang.mods) { navigateTo("mods") })
        addView(chipBtn(lang.saves) { navigateTo("saves") })
    }

    private fun buildPathBar() = TextView(this).apply {
        pathText = this
        textSize = 13f
        setTextColor(colorPrimary)
        setPadding(dp(20), dp(12), dp(20), dp(12))
        typeface = Typeface.create("sans-serif-medium", Typeface.NORMAL)
        isSingleLine = true
        ellipsize = android.text.TextUtils.TruncateAt.START
    }

    private fun buildSearchBar() = EditText(this).apply {
        searchEdit = this
        hint = lang.searchHint
        setPadding(dp(16), dp(14), dp(16), dp(14))
        background = MaterialShapeDrawable(ShapeAppearanceModel.builder().setAllCorners(CornerFamily.ROUNDED, dp(28).toFloat()).build()).apply {
            fillColor = ColorStateList.valueOf(colorSurfaceContainer)
        }
        layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { setMargins(dp(16), dp(8), dp(16), dp(8)) }
        addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) { searchQuery = s?.toString() ?: ""; refreshDisplay() }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })
    }

    private fun buildFileList() = ListView(this).apply {
        listView = this
        layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
        divider = null
        fileAdapter = object : ArrayAdapter<String>(this@FileManagerActivity, 0, mutableListOf()) {
            override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
                val item = (convertView as? LinearLayout) ?: LinearLayout(context).apply {
                    setPadding(dp(16), dp(12), dp(16), dp(12))
                    gravity = Gravity.CENTER_VERTICAL
                }
                item.removeAllViews()
                val file = fileList.getOrNull(position)
                
                val iconView = ImageView(context).apply {
                    setImageResource(if (file == null) android.R.drawable.ic_menu_up_indicator else getFileIconResource(file))
                    setPadding(0, 0, dp(16), 0)
                    layoutParams = LinearLayout.LayoutParams(dp(24), dp(24))
                }
                
                val nameView = TextView(context).apply {
                    text = getItem(position)?.substringAfter("  ") ?: ""
                    textSize = 16f
                    setTextColor(if (file?.isDirectory == true) colorPrimary else colorOnSurface)
                    layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f)
                }
                
                item.addView(iconView)
                item.addView(nameView)
                return item
            }
        }
        adapter = fileAdapter
        setOnItemClickListener { _, _, pos, _ -> handleItemClick(pos) }
        setOnItemLongClickListener { _, _, pos, _ -> showFileOptions(pos); true }
    }

    private fun getFileIconResource(file: File): Int {
        val ext = file.extension.lowercase()
        return when {
            file.isDirectory -> android.R.drawable.ic_menu_archive
            ext in imageExtensions -> android.R.drawable.ic_menu_gallery
            ext in videoExtensions -> android.R.drawable.ic_menu_slideshow
            ext in audioExtensions -> android.R.drawable.ic_lock_silent_mode_off
            else -> android.R.drawable.ic_menu_file
        }
    }

    private fun buildActionBar() = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        setPadding(dp(16), dp(16), dp(16), dp(16))
        setBackgroundColor(colorSurfaceContainer)
        updateActionButtons(this)
    }

    private fun updateActionButtons(layout: LinearLayout) {
        layout.removeAllViews()
        layout.addView(filledBtn(lang.newFolder, colorPrimary, colorSurface) { promptCreate(true) }.apply { 
            layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f).apply { rightMargin = dp(8) }
        })
        layout.addView(filledBtn(lang.newFile, colorPrimary, colorSurface) { promptCreate(false) }.apply { 
            layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f)
        })
        if (clipboardFile != null) {
            layout.addView(filledBtn(lang.paste, colorOnSurface, colorSurface) { pasteFile() }.apply { 
                layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f).apply { leftMargin = dp(8) }
            })
        }
    }

    private fun showFileOptions(position: Int) {
        val file = fileList.getOrNull(position) ?: return
        val sheet = BottomSheetDialog(this)
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(32))
            setBackgroundColor(colorSurface)

            addView(TextView(context).apply {
                text = file.name
                textSize = 18f
                typeface = Typeface.DEFAULT_BOLD
                setPadding(dp(16), dp(8), dp(16), dp(16))
                setTextColor(colorOnSurface)
            })

            val options = listOf(
                lang.open to { openFile(file) },
                lang.cut to { clipboardFile = file; isCutOperation = true; updateActionButtons(actionLayout); NativeUI.showToast(context, "Cut") },
                lang.copy to { clipboardFile = file; isCutOperation = false; updateActionButtons(actionLayout); NativeUI.showToast(context, "Copied") },
                lang.rename to { promptRename(file) },
                lang.delete to { confirmDelete(file) }
            )

            options.forEach { (label, action) ->
                addView(MaterialButton(context, null, com.google.android.material.R.attr.borderlessButtonStyle).apply {
                    text = label
                    setPadding(dp(16), dp(12), dp(16), dp(12))
                    gravity = Gravity.START or Gravity.CENTER_VERTICAL
                    setTextColor(colorOnSurface)
                    setOnClickListener { action(); sheet.dismiss() }
                    textAllCaps = false
                })
            }
        }
        sheet.setContentView(content)
        sheet.show()
    }

    private fun handleItemClick(pos: Int) {
        val f = fileList.getOrNull(pos)
        if (f == null) loadDirectory(currentPath.parentFile!!) else if (f.isDirectory) loadDirectory(f) else openFile(f)
    }

    private fun openFile(file: File) {
        val ext = file.extension.lowercase()
        when {
            ext in textExtensions -> openCodeEditor(file)
            ext in imageExtensions -> showImagePreview(file)
            ext in videoExtensions -> openVideoPlayer(file)
            else -> openWithSystem(file)
        }
    }

    private fun openCodeEditor(file: File) {
        val ext = file.extension.lowercase()
        val editor = EditText(this).apply {
            setText(file.readText())
            typeface = Typeface.MONOSPACE
            textSize = 14f
            // Syntax coloring simple simulation
            val textColor = when(ext) {
                "lua" -> "#569CD6" // Blue
                "hx", "hxs" -> "#DCDCAA" // Yellowish
                "xml", "json" -> "#9CDCFE" // Light Blue
                else -> "#CE9178" // Orange-ish
            }
            setTextColor(Color.parseColor(textColor))
            setBackgroundColor(Color.parseColor("#1E1E1E")) // VSCode Dark
            setPadding(dp(16), dp(16), dp(16), dp(16))
            gravity = Gravity.TOP
        }

        MaterialAlertDialogBuilder(this)
            .setTitle(file.name)
            .setView(ScrollView(this).apply { addView(editor) })
            .setPositiveButton(lang.save) { _, _ ->
                file.writeText(editor.text.toString())
                NativeUI.showToast(this, "Saved")
            }
            .setNegativeButton(lang.cancel, null)
            .show()
    }

    private fun showImagePreview(file: File) {
        val img = ImageView(this).apply { 
            setImageURI(Uri.fromFile(file))
            adjustViewBounds = true
            setPadding(dp(16), dp(16), dp(16), dp(16))
        }
        MaterialAlertDialogBuilder(this).setTitle(file.name).setView(img).setPositiveButton(lang.back, null).show()
    }

    private fun openVideoPlayer(file: File) {
        val videoView = VideoView(this).apply {
            setVideoURI(Uri.fromFile(file))
            val mc = MediaController(this@FileManagerActivity)
            mc.setAnchorView(this)
            setMediaController(mc)
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, dp(300))
        }
        
        MaterialAlertDialogBuilder(this)
            .setTitle(file.name)
            .setView(videoView)
            .setPositiveButton(lang.back) { _, _ -> videoView.stopPlayback() }
            .setOnDismissListener { videoView.stopPlayback() }
            .show()
        
        videoView.start()
    }

    private fun openWithSystem(file: File) {
        try {
            val uri = FileProvider.getUriForFile(this, "$packageName.provider", file)
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, contentResolver.getType(uri) ?: "*/*")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, lang.open))
        } catch (e: Exception) {
            NativeUI.showToast(this, "No app found")
        }
    }

    private fun promptCreate(isDir: Boolean) {
        val input = TextInputEditText(this)
        val container = TextInputLayout(this).apply {
            setPadding(dp(24), dp(8), dp(24), dp(8))
            hint = if (isDir) lang.folderName else lang.fileName
            addView(input)
        }

        MaterialAlertDialogBuilder(this)
            .setTitle(if (isDir) lang.newFolder else lang.newFile)
            .setView(container)
            .setPositiveButton(lang.create) { _, _ ->
                val name = input.text.toString()
                if (name.isNotEmpty()) {
                    val f = File(currentPath, name)
                    if (isDir) f.mkdirs() else f.createNewFile()
                    refreshDisplay()
                }
            }.setNegativeButton(lang.cancel, null).show()
    }

    private fun promptRename(file: File) {
        val input = TextInputEditText(this).apply { setText(file.name) }
        val container = TextInputLayout(this).apply {
            setPadding(dp(24), dp(8), dp(24), dp(8))
            hint = lang.rename
            addView(input)
        }
        MaterialAlertDialogBuilder(this)
            .setTitle(lang.rename)
            .setView(container)
            .setPositiveButton("OK") { _, _ ->
                val newFile = File(file.parentFile, input.text.toString())
                if (file.renameTo(newFile)) refreshDisplay()
            }.setNegativeButton(lang.cancel, null).show()
    }

    private fun confirmDelete(file: File) {
        MaterialAlertDialogBuilder(this)
            .setTitle(lang.delete)
            .setMessage(file.name)
            .setPositiveButton(lang.delete) { _, _ ->
                if (file.deleteRecursively()) refreshDisplay()
            }.setNegativeButton(lang.cancel, null).show()
    }

    private fun pasteFile() {
        val source = clipboardFile ?: return
        val target = File(currentPath, source.name)
        if (isCutOperation) {
            if (source.renameTo(target)) {
                clipboardFile = null
                isCutOperation = false
            }
        } else {
            source.copyRecursively(target, overwrite = true)
        }
        updateActionButtons(actionLayout)
        refreshDisplay()
    }

    private fun loadDirectory(dir: File) {
        currentPath = dir
        pathText.text = "📂  ${dir.absolutePath}"
        refreshDisplay()
    }

    private fun refreshDisplay() {
        val files = currentPath.listFiles()?.sortedWith(compareBy<File> { !it.isDirectory }.thenBy { it.name.lowercase() }) ?: emptyList()
        val filtered = files.filter { it.name.contains(searchQuery, true) }
        fileAdapter.clear()
        fileList.clear()
        if (searchQuery.isEmpty() && currentPath.parentFile != null) { 
            fileAdapter.add("  ..") 
            fileList.add(null) 
        }
        filtered.forEach { 
            fileAdapter.add("  ${it.name}")
            fileList.add(it) 
        }
    }

    private fun resolveInitialPath(): File {
        val startLoc = intent.getStringExtra(EXTRA_START_LOCATION)
        return when (startLoc) {
            "mods" -> File(Environment.getExternalStorageDirectory(), ".PlusEngine/mods")
            "saves" -> File(getExternalFilesDir(null), "saves")
            else -> intent.getStringExtra(EXTRA_INITIAL_PATH)?.let { File(it) } ?: getExternalFilesDir(null)!!
        }
    }

    private fun navigateTo(location: String) {
        val target = if (location == "mods") File(Environment.getExternalStorageDirectory(), ".PlusEngine/mods") else getExternalFilesDir(null)!!
        target.mkdirs()
        loadDirectory(target)
    }

    private fun needsPermission(file: File) = Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && !Environment.isExternalStorageManager()

    private fun requestStorageAccess(onGranted: () -> Unit) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            startActivityForResult(Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:$packageName")), REQUEST_MANAGE_STORAGE)
        }
    }

    private fun filledBtn(l: String, bg: Int, fg: Int, onClick: () -> Unit) = MaterialButton(this).apply {
        text = l; setTextColor(fg); backgroundTintList = ColorStateList.valueOf(bg); cornerRadius = dp(16); setOnClickListener { onClick() }; textAllCaps = false
    }
    
    private fun chipBtn(l: String, onClick: () -> Unit) = MaterialButton(this, null, com.google.android.material.R.attr.materialButtonOutlinedStyle).apply {
        text = l; cornerRadius = dp(20); setOnClickListener { onClick() }; layoutParams = LinearLayout.LayoutParams(WRAP_CONTENT, WRAP_CONTENT).apply { leftMargin = dp(8) }
    }
    
    private fun outlinedBtn(l: String, onClick: () -> Unit) = MaterialButton(this, null, com.google.android.material.R.attr.materialButtonOutlinedStyle).apply {
        text = l; cornerRadius = dp(12); setOnClickListener { onClick() }
    }
    
    private fun divider() = View(this).apply { layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 1); setBackgroundColor(colorOnSurface); alpha = 0.1f }
}
