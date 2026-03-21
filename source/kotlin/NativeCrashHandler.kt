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
import android.util.Log
import android.os.Process
import org.haxe.extension.Extension
import java.io.PrintWriter
import java.io.StringWriter
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.system.exitProcess

/**
 * Captures Java/Kotlin crashes and opens a native crash activity.
 */
object NativeCrashHandler {

    private const val TAG = "NativeCrashHandler"
    private const val CRASH_ACTIVITY_WAIT_MS = 350L
    private val installed = AtomicBoolean(false)

    @JvmStatic
    fun install() {
        if (installed.getAndSet(true)) return

        Thread.setDefaultUncaughtExceptionHandler { thread, throwable ->
            try {
                launchCrashActivity(throwable)
            } catch (handlerError: Throwable) {
                Log.e(TAG, "Failed to open crash activity", handlerError)
            } finally {
                try {
                    Thread.sleep(CRASH_ACTIVITY_WAIT_MS)
                } catch (_: InterruptedException) {
                }

                Process.killProcess(Process.myPid())
                exitProcess(10)
            }
        }
    }

    @JvmStatic
    fun showCrashActivity(throwable: Throwable) {
        launchCrashActivity(throwable)
    }

    private fun launchCrashActivity(throwable: Throwable) {
        val activity = Extension.mainActivity ?: return
        val stackTrace = throwable.toDetailedStackTrace()

        val context = activity.applicationContext
        val intent = Intent(context, NativeCrashActivity::class.java).apply {
            putExtra(NativeCrashActivity.EXTRA_CRASH_TITLE, throwable.javaClass.simpleName)
            putExtra(NativeCrashActivity.EXTRA_CRASH_MESSAGE, throwable.message ?: "No message")
            putExtra(NativeCrashActivity.EXTRA_CRASH_TRACE, stackTrace)
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_CLEAR_TASK
            )
        }

        context.startActivity(intent)
    }

    private fun Throwable.toDetailedStackTrace(): String {
        val writer = StringWriter()
        val printer = PrintWriter(writer)
        this.printStackTrace(printer)
        printer.flush()
        return writer.toString()
    }
}
