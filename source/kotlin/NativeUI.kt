package com.leninasto.plusengine

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.Toast
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import com.google.android.material.color.MaterialColors

/**
 * Native UI utilities for FNF: Plus Engine
 * MD3 Alert Dialogs and system notifications
 */
object NativeUI {

    fun showDialog(
        context: Context,
        title: String,
        message: String,
        positiveText: String = "OK",
        onPositive: (() -> Unit)? = null,
        negativeText: String? = null,
        onNegative: (() -> Unit)? = null
    ) {
        val builder = MaterialAlertDialogBuilder(context)
            .setTitle(title)
            .setMessage(message)
            .setPositiveButton(positiveText) { _, _ -> onPositive?.invoke() }
        
        negativeText?.let {
            builder.setNegativeButton(it) { _, _ -> onNegative?.invoke() }
        }
        
        builder.show()
    }

    fun showToast(context: Context, message: String) {
        Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
    }

    fun showSnackbar(view: android.view.View, message: String, actionText: String? = null, onAction: (() -> Unit)? = null) {
        val snack = Snackbar.make(view, message, Snackbar.LENGTH_LONG)
        actionText?.let {
            snack.setAction(it) { onAction?.invoke() }
        }
        snack.show()
    }
}
