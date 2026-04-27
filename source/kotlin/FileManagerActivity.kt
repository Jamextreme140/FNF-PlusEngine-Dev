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
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.NoteAdd
import androidx.compose.material.icons.automirrored.filled.InsertDriveFile
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.core.content.FileProvider
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.google.android.material.bottomsheet.BottomSheetDialog
import com.google.android.material.button.MaterialButton
import com.google.android.material.card.MaterialCardView
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
import java.util.Locale

class FileManagerActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_INITIAL_PATH = "initial_path"
        const val EXTRA_START_LOCATION = "start_location"
        const val EXTRA_SELECT_FILE = "select_file"
        const val EXTRA_RESULT_PATH = "result_path"
        private const val REQUEST_STORAGE_PERMISSION = 1001
        private const val REQUEST_MANAGE_STORAGE = 1002
    }

    private val textExtensions  = setOf("txt", "json", "xml", "lua", "hx", "hxs", "log", "md", "ini", "cfg", "yaml", "yml")
    private val imageExtensions = setOf("png", "jpg", "jpeg", "webp", "gif")
    private val audioExtensions = setOf("ogg", "mp3", "wav", "flac")
    private val videoExtensions = setOf("mp4", "mkv", "mov", "3gp", "webm")

    private lateinit var currentPath: File
    private lateinit var recyclerView: RecyclerView
    private lateinit var pathText: TextView
    private lateinit var searchEdit: EditText
    private lateinit var actionLayout: LinearLayout
    private lateinit var lang: Language

    private var fileList = mutableListOf<File?>()
    private var searchQuery = ""
    private var selectFileMode = false

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

        selectFileMode = intent.getBooleanExtra(EXTRA_SELECT_FILE, false)

        setupLanguage()
        buildUI()

        val initial = resolveInitialPath()
        loadDirectory(initial)
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
            setViewTreeLifecycleOwner(this@FileManagerActivity)
            setViewTreeViewModelStoreOwner(this@FileManagerActivity)
            setViewTreeSavedStateRegistryOwner(this@FileManagerActivity)
        }

        root.addView(buildTopBarCompose())
        root.addView(buildPathBar())
        root.addView(buildSearchBar())
        root.addView(divider())

        recyclerView = RecyclerView(this).apply {
            layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 0, 1f)
            layoutManager = LinearLayoutManager(this@FileManagerActivity)
        }
        root.addView(recyclerView)

        root.addView(divider())

        actionLayout = buildActionBar()
        root.addView(actionLayout)
        setContentView(root)
    }

    @OptIn(ExperimentalMaterial3Api::class)
    private fun buildTopBarCompose() = ComposeView(this).apply {
        layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
        setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
        setContent {
            var showMenu by remember { mutableStateOf(false) }

            Surface(color = androidx.compose.ui.graphics.Color(colorSurfaceContainer)) {
                TopAppBar(
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = androidx.compose.ui.graphics.Color.Transparent,
                        titleContentColor = androidx.compose.ui.graphics.Color(colorOnSurface),
                    ),
                    title = {
                        androidx.compose.material3.Text(
                            "Plus Explorer",
                            style = androidx.compose.ui.text.TextStyle(
                                fontWeight = FontWeight.Bold,
                                fontSize = 20.sp
                            )
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = {
                            goBack()
                        }) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                contentDescription = lang.back,
                                tint = androidx.compose.ui.graphics.Color(colorPrimary)
                            )
                        }
                    },
                    actions = {
                        IconButton(onClick = { searchQuery = ""; searchEdit.setText(""); searchEdit.requestFocus() }) {
                            Icon(Icons.Default.Search, contentDescription = null, tint = androidx.compose.ui.graphics.Color(colorOnSurface))
                        }

                        IconButton(onClick = { showMenu = true }) {
                            Icon(Icons.Default.MoreVert, contentDescription = "Menu", tint = androidx.compose.ui.graphics.Color(colorOnSurface))
                        }

                        DropdownMenu(
                            expanded = showMenu,
                            onDismissRequest = { showMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { androidx.compose.material3.Text(lang.mods) },
                                leadingIcon = { Icon(Icons.Default.Extension, contentDescription = null) },
                                onClick = { showMenu = false; navigateTo("mods") }
                            )
                            DropdownMenuItem(
                                text = { androidx.compose.material3.Text(lang.assets) },
                                leadingIcon = { Icon(Icons.Default.FolderZip, contentDescription = null) },
                                onClick = { showMenu = false; navigateTo("assets") }
                            )
                            DropdownMenuItem(
                                text = { androidx.compose.material3.Text(lang.saves) },
                                leadingIcon = { Icon(Icons.Default.Save, contentDescription = null) },
                                onClick = { showMenu = false; navigateTo("saves") }
                            )
                            HorizontalDivider()
                            DropdownMenuItem(
                                text = { androidx.compose.material3.Text(lang.newFolder) },
                                leadingIcon = { Icon(Icons.Default.CreateNewFolder, contentDescription = null) },
                                onClick = { showMenu = false; promptCreate(true) }
                            )
                            DropdownMenuItem(
                                text = { androidx.compose.material3.Text(lang.newFile) },
                                leadingIcon = { Icon(Icons.AutoMirrored.Filled.NoteAdd, contentDescription = null) },
                                onClick = { showMenu = false; promptCreate(false) }
                            )
                        }
                    }
                )
            }
        }
    }

    private fun goBack() {
        if (currentPath.parentFile != null && currentPath.absolutePath != Environment.getExternalStorageDirectory().absolutePath) {
            loadDirectory(currentPath.parentFile!!)
        } else {
            finish()
        }
    }

    private fun buildPathBar() = TextView(this).apply {
        pathText = this
        textSize = 12f
        setTextColor(colorPrimary)
        setPadding(dp(20), dp(8), dp(20), dp(8))
        typeface = Typeface.MONOSPACE
        isSingleLine = true
        alpha = 0.8f
        ellipsize = android.text.TextUtils.TruncateAt.START
    }

    private fun buildSearchBar() = EditText(this).apply {
        searchEdit = this
        hint = lang.searchHint
        setPadding(dp(16), dp(12), dp(16), dp(12))
        background = MaterialShapeDrawable(ShapeAppearanceModel.builder().setAllCorners(CornerFamily.ROUNDED, dp(12).toFloat()).build()).apply {
            fillColor = ColorStateList.valueOf(colorSurfaceContainer)
        }
        layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT).apply { setMargins(dp(16), dp(4), dp(16), dp(8)) }
        addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) { searchQuery = s?.toString() ?: ""; refreshDisplay() }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })
    }

    private fun buildActionBar() = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        setPadding(dp(16), dp(8), dp(16), dp(8))
        setBackgroundColor(colorSurfaceContainer)
        visibility = View.GONE
        updateActionButtons(this)
    }

    private fun updateActionButtons(layout: LinearLayout) {
        layout.removeAllViews()
        if (clipboardFile != null) {
            layout.visibility = View.VISIBLE
            layout.addView(filledBtn("${lang.paste} (${clipboardFile?.name})", colorPrimary, colorSurface) { pasteFile() }.apply {
                layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, WRAP_CONTENT)
            })
        } else {
            layout.visibility = View.GONE
        }
    }

    private fun refreshDisplay() {
        val files = currentPath.listFiles()?.sortedWith(compareBy<File> { !it.isDirectory }.thenBy { it.name.lowercase() }) ?: emptyList()
        val filtered = files.filter { it.name.contains(searchQuery, true) }

        fileList.clear()
        if (searchQuery.isEmpty() && currentPath.parentFile != null && currentPath.absolutePath != Environment.getExternalStorageDirectory().absolutePath) {
            fileList.add(null) // Representa ".."
        }
        fileList.addAll(filtered)

        recyclerView.adapter = FileAdapter(fileList)
    }

    private inner class FileAdapter(val items: List<File?>) : RecyclerView.Adapter<FileAdapter.ViewHolder>() {
        inner class ViewHolder(view: View) : RecyclerView.ViewHolder(view) {
            val card = view as MaterialCardView
            val iconView = view.findViewById<ComposeView>(android.R.id.icon)
            val nameText = view.findViewById<TextView>(android.R.id.text1)
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
            val card = MaterialCardView(this@FileManagerActivity).apply {
                layoutParams = ViewGroup.MarginLayoutParams(MATCH_PARENT, WRAP_CONTENT).apply {
                    setMargins(dp(12), dp(4), dp(12), dp(4))
                }
                radius = dp(12).toFloat()
                setCardBackgroundColor(Color.TRANSPARENT)
                strokeWidth = 0
                rippleColor = ColorStateList.valueOf(colorPrimary).withAlpha(30)
                isClickable = true
                isFocusable = true

                val layout = LinearLayout(context).apply {
                    orientation = LinearLayout.HORIZONTAL
                    setPadding(dp(12), dp(12), dp(12), dp(12))
                    gravity = Gravity.CENTER_VERTICAL

                    val composeIcon = ComposeView(context).apply {
                        id = android.R.id.icon
                        layoutParams = LinearLayout.LayoutParams(dp(40), dp(40))
                        setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
                    }

                    val textView = TextView(context).apply {
                        id = android.R.id.text1
                        textSize = 16f
                        setPadding(dp(16), 0, 0, 0)
                        layoutParams = LinearLayout.LayoutParams(0, WRAP_CONTENT, 1f)
                    }

                    addView(composeIcon)
                    addView(textView)
                }
                addView(layout)
            }
            return ViewHolder(card)
        }

        override fun onBindViewHolder(holder: ViewHolder, position: Int) {
            val file = items[position]
            val isParent = file == null

            holder.nameText.text = if (isParent) ".." else file?.name
            holder.nameText.setTextColor(if (isParent || file?.isDirectory == true) colorPrimary else colorOnSurface)
            holder.nameText.typeface = if (isParent || file?.isDirectory == true) Typeface.DEFAULT_BOLD else Typeface.DEFAULT

            holder.iconView.setContent {
                val vector = when {
                    isParent -> Icons.Default.SubdirectoryArrowLeft
                    file?.isDirectory == true -> Icons.Default.Folder
                    else -> getFileIconVector(file!!)
                }
                val color = if (isParent || file?.isDirectory == true) colorPrimary else colorOnSurface
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Icon(vector, null, tint = androidx.compose.ui.graphics.Color(color), modifier = Modifier.size(24.dp))
                }
            }

            holder.card.setOnClickListener { handleItemClick(position) }
            holder.card.setOnLongClickListener { if (!isParent) showFileOptions(position); true }
        }

        override fun getItemCount() = items.size
    }

    private fun getFileIconVector(file: File): ImageVector {
        val ext = file.extension.lowercase()
        return when {
            ext in imageExtensions -> Icons.Default.Image
            ext in videoExtensions -> Icons.Default.Movie
            ext in audioExtensions -> Icons.Default.MusicNote
            ext in textExtensions -> Icons.Default.Description
            else -> Icons.AutoMirrored.Filled.InsertDriveFile
        }
    }

    private fun handleItemClick(pos: Int) {
        val f = fileList.getOrNull(pos)
        if (f == null) {
            goBack()
        } else if (f.isDirectory) {
            loadDirectory(f)
        } else if (selectFileMode) {
            returnSelectedFile(f)
        } else {
            openFile(f)
        }
    }

    private fun returnSelectedFile(file: File) {
        setResult(Activity.RESULT_OK, Intent().apply {
            putExtra(EXTRA_RESULT_PATH, file.absolutePath)
        })
        finish()
    }

    private fun loadDirectory(dir: File) {
        if (!dir.exists()) dir.mkdirs()
        currentPath = dir
        pathText.text = dir.absolutePath.replace(Environment.getExternalStorageDirectory().absolutePath, "STORAGE")
        refreshDisplay()
    }

    private fun resolveInitialPath(): File {
        val startLoc = intent.getStringExtra(EXTRA_START_LOCATION)
        return when (startLoc) {
            "mods" -> File(getExternalFilesDir(null), "mods").also { it.mkdirs() }
            "assets" -> File(getExternalFilesDir(null), "assets").also { it.mkdirs() }
            "saves" -> File(getExternalFilesDir(null), "saves").also { it.mkdirs() }
            else -> intent.getStringExtra(EXTRA_INITIAL_PATH)?.let { File(it) } ?: getExternalFilesDir(null)!!
        }
    }

    private fun navigateTo(location: String) {
        val target = when(location) {
            "mods" -> File(getExternalFilesDir(null), "mods")
            "assets" -> File(getExternalFilesDir(null), "assets")
            "saves" -> File(getExternalFilesDir(null), "saves")
            else -> getExternalFilesDir(null)!!
        }
        target.mkdirs()
        loadDirectory(target)
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
                    isAllCaps = false
                })
            }
        }
        sheet.setContentView(content)
        sheet.show()
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
        val editor = EditText(this).apply {
            setText(file.readText())
            typeface = Typeface.MONOSPACE
            textSize = 14f
            setTextColor(Color.WHITE)
            setBackgroundColor(Color.parseColor("#1E1E1E"))
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
                val newName = input.text.toString()
                if (newName.isNotEmpty()) {
                    val newFile = File(file.parentFile, newName)
                    if (file.renameTo(newFile)) refreshDisplay()
                }
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

    private fun filledBtn(l: String, bg: Int, fg: Int, onClick: () -> Unit) = MaterialButton(this).apply {
        text = l; setTextColor(fg); backgroundTintList = ColorStateList.valueOf(bg); cornerRadius = dp(12); setOnClickListener { onClick() }; isAllCaps = false
    }

    private fun divider() = View(this).apply { layoutParams = LinearLayout.LayoutParams(MATCH_PARENT, 1); setBackgroundColor(colorOnSurface); alpha = 0.08f }
}
