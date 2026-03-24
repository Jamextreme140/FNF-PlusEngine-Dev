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

import android.content.Context
import android.content.res.ColorStateList
import android.graphics.Color
import android.view.Gravity
import android.widget.FrameLayout
import android.widget.Toast
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import com.google.android.material.snackbar.Snackbar
import com.google.android.material.color.MaterialColors
import android.util.Log

/**
 * Native UI utilities for FNF: Plus Engine
 * MD3 Alert Dialogs and system notifications
 */
object NativeUI {

    private const val TAG = "NativeUI"

    fun showDialog(
        context: Context,
        title: String,
        message: String,
        positiveText: String = "OK",
        onPositive: (() -> Unit)? = null,
        negativeText: String? = null,
        onNegative: (() -> Unit)? = null
    ) {
        try {
            // Check if context is valid (activity not destroyed)
            if (context is android.app.Activity && context.isFinishing) {
                Log.w(TAG, "Activity is finishing, falling back to Toast")
                showToast(context, "$title: $message")
                return
            }

            val builder = MaterialAlertDialogBuilder(context)
                .setTitle(title)
                .setMessage(message)
                .setPositiveButton(positiveText) { _, _ -> 
                    try {
                        onPositive?.invoke()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error in positive button callback", e)
                    }
                }
            
            negativeText?.let {
                builder.setNegativeButton(it) { _, _ -> 
                    try {
                        onNegative?.invoke()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error in negative button callback", e)
                    }
                }
            }
            
            // Prevent dialog from being cancelable during crashes
            builder.setCancelable(false)
            
            builder.show()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show dialog", e)
            // Fallback to Toast if dialog fails
            try {
                showToast(context, "$title: $message")
            } catch (te: Exception) {
                Log.e(TAG, "Even Toast failed", te)
            }
        }
    }

    fun showToast(context: Context, message: String) {
        try {
            Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show toast: $message", e)
        }
    }

    fun showSnackbar(view: android.view.View, message: String, actionText: String? = null, onAction: (() -> Unit)? = null) {
        try {
            val snack = Snackbar.make(view, message, Snackbar.LENGTH_LONG)
            actionText?.let {
                snack.setAction(it) { 
                    try {
                        onAction?.invoke()
                    } catch (e: Exception) {
                        Log.e(TAG, "Error in snackbar action", e)
                    }
                }
            }
            snack.show()
        } catch (e: Exception) {
            Log.e(TAG, "Failed to show snackbar", e)
        }
    }
}
