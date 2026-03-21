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

package com.leninasto.plusengine.components

import android.text.Editable
import android.text.TextWatcher
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.LinearLayout
import android.widget.ListView
import androidx.appcompat.app.AlertDialog
import com.leninasto.plusengine.NativeCrashHandler
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.textfield.TextInputEditText
import com.google.android.material.textfield.TextInputLayout
import org.haxe.extension.Extension
import org.json.JSONArray
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * Native Android MD3 dropdown helper.
 *
 * This class exposes static methods for JNI so Haxe can open
 * a native single-choice popup and poll the selected item index.
 */
object DropDown {

	const val NO_SELECTION: Int = -1
	const val CANCELED: Int = -2

	private val pendingSelection: AtomicInteger = AtomicInteger(NO_SELECTION)
	private val dialogVisible: AtomicBoolean = AtomicBoolean(false)

	@JvmStatic
	fun showDropDown(title: String?, itemsJson: String, selectedIndex: Int): Boolean {
		val activity = Extension.mainActivity ?: return false
		val items = parseItems(itemsJson)
		if (items.isEmpty()) return false

		activity.runOnUiThread {
			try {
			if (dialogVisible.get()) return@runOnUiThread

			dialogVisible.set(true)
			val safeSelectedIndex = selectedIndex.coerceIn(0, items.lastIndex)
			val displayTitle = if (title.isNullOrBlank()) "Select option" else title
			val filteredItems = items.toMutableList()
			val filteredIndices = items.indices.toMutableList()

			val listView = ListView(activity).apply {
				choiceMode = ListView.CHOICE_MODE_SINGLE
			}
			val adapter = ArrayAdapter(activity, android.R.layout.simple_list_item_single_choice, filteredItems)
			listView.adapter = adapter

			val searchInput = TextInputEditText(activity)
			val searchLayout = TextInputLayout(activity).apply {
				hint = "Search"
				addView(
					searchInput,
					LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
				)
			}

			val container = LinearLayout(activity).apply {
				orientation = LinearLayout.VERTICAL
				setPadding(dp(20), dp(8), dp(20), dp(0))
				addView(searchLayout, ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
				addView(
					listView,
					LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(280))
				)
			}

			var dialogRef: AlertDialog? = null

			fun refreshList(query: String?) {
				val trimmed = query?.trim()?.lowercase() ?: ""
				filteredItems.clear()
				filteredIndices.clear()

				for (index in items.indices) {
					val item = items[index]
					if (trimmed.isEmpty() || item.lowercase().contains(trimmed)) {
						filteredItems.add(item)
						filteredIndices.add(index)
					}
				}

				adapter.notifyDataSetChanged()
				val selectedFilteredIndex = filteredIndices.indexOf(safeSelectedIndex)
				if (selectedFilteredIndex >= 0) {
					listView.setItemChecked(selectedFilteredIndex, true)
					listView.setSelection(selectedFilteredIndex)
				} else {
					listView.clearChoices()
				}
			}

			searchInput.addTextChangedListener(object : TextWatcher {
				override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
				override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {
					refreshList(s?.toString())
				}
				override fun afterTextChanged(s: Editable?) {}
			})

			listView.setOnItemClickListener { _, _, position, _ ->
				if (position >= 0 && position < filteredIndices.size) {
					pendingSelection.set(filteredIndices[position])
					dialogRef?.dismiss()
				}
			}

			dialogRef = MaterialAlertDialogBuilder(activity)
				.setTitle(displayTitle)
				.setView(container)
				.setNegativeButton(android.R.string.cancel) { _, _ ->
					pendingSelection.set(CANCELED)
				}
				.setOnCancelListener {
					pendingSelection.set(CANCELED)
				}
				.setOnDismissListener {
					dialogVisible.set(false)
				}
				.show()

			refreshList(null)
			} catch (throwable: Throwable) {
				dialogVisible.set(false)
				pendingSelection.set(CANCELED)
				NativeCrashHandler.showCrashActivity(throwable)
			}
		}

		return true
	}

	@JvmStatic
	fun pollSelection(): Int {
		val currentValue = pendingSelection.get()
		if (currentValue == NO_SELECTION) return NO_SELECTION

		pendingSelection.set(NO_SELECTION)
		return currentValue
	}

	@JvmStatic
	fun isDialogVisible(): Boolean {
		return dialogVisible.get()
	}

	private fun parseItems(itemsJson: String): List<String> {
		return try {
			val json = JSONArray(itemsJson)
			buildList(json.length()) {
				for (index in 0 until json.length()) {
					add(json.optString(index, ""))
				}
			}
		} catch (_: Throwable) {
			emptyList()
		}
	}

	private fun dp(value: Int): Int {
		val activity = Extension.mainActivity ?: return value
		return (value * activity.resources.displayMetrics.density).toInt()
	}
}
