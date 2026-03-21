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

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.LinearInterpolator
import android.widget.FrameLayout
import org.haxe.extension.Extension
import java.util.concurrent.atomic.AtomicReference

/**
 * Manager for WavyProgressIndicator used as in-game timebar
 * Provides JNI interface to control Material3 WavyProgressIndicator from Haxe
 */
object WavyTimebarManager {

    private class WavyProgressView(context: Context) : View(context) {
        private val density = resources.displayMetrics.density
        private val wavePath = Path()

        private val trackPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.parseColor("#4D6A5ACD")
            strokeCap = Paint.Cap.ROUND
        }

        private val wavePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            color = Color.parseColor("#6A5ACD")
            strokeCap = Paint.Cap.ROUND
        }

        private var phase = 0f
        private val phaseAnimator = ValueAnimator.ofFloat(0f, (Math.PI * 2).toFloat()).apply {
            duration = 900L
            repeatCount = ValueAnimator.INFINITE
            interpolator = LinearInterpolator()
            addUpdateListener {
                phase = it.animatedValue as Float
                invalidate()
            }
        }

        var progress: Float = 0f
            set(value) {
                field = value.coerceIn(0f, 1f)
                invalidate()
            }

        override fun onAttachedToWindow() {
            super.onAttachedToWindow()
            if (!phaseAnimator.isStarted) {
                phaseAnimator.start()
            } else if (phaseAnimator.isPaused) {
                phaseAnimator.resume()
            }
        }

        override fun onDetachedFromWindow() {
            if (phaseAnimator.isRunning) {
                phaseAnimator.cancel()
            }
            super.onDetachedFromWindow()
        }

        override fun onDraw(canvas: android.graphics.Canvas) {
            super.onDraw(canvas)

            val centerY = height * 0.5f
            val stroke = height * 0.68f
            val amplitude = height * 0.2f
            val waveLength = 36f * density
            val startX = paddingLeft.toFloat() + stroke * 0.5f
            val endX = width - paddingRight.toFloat() - stroke * 0.5f
            val availableWidth = (endX - startX).coerceAtLeast(0f)
            val progressWidth = availableWidth * progress
            val progressEndX = (startX + progressWidth).coerceIn(startX, endX)

            trackPaint.strokeWidth = stroke
            wavePaint.strokeWidth = stroke

            if (progressEndX < endX) {
                canvas.drawLine(progressEndX, centerY, endX, centerY, trackPaint)
            }

            if (progressWidth <= 1f) return

            wavePath.reset()
            var x = startX
            val step = 4f * density
            wavePath.moveTo(x, centerY)
            while (x <= progressEndX) {
                val y = centerY + kotlin.math.sin((x / waveLength) * (Math.PI * 2) + phase).toFloat() * amplitude
                wavePath.lineTo(x, y)
                x += step
            }
            canvas.drawPath(wavePath, wavePaint)
        }
    }

    private var containerView: FrameLayout? = null
    private var progressView: WavyProgressView? = null
    private var currentProgress: Float = 0f
    private var currentAlpha: Float = 0f
    private var barWidthPercent: Float = 0.58f
    private var barTopMarginPx: Int = 0
    private val isInitialized = AtomicReference(false)

    private fun getBarWidthPx(screenWidthPx: Int): Int {
        return (screenWidthPx * barWidthPercent.coerceIn(0.2f, 1f)).toInt()
    }

    private fun applyLayoutOnUiThread(activity: android.app.Activity) {
        val barHeightPx = (8 * activity.resources.displayMetrics.density).toInt()
        val screenWidthPx = activity.resources.displayMetrics.widthPixels
        val barWidthPx = getBarWidthPx(screenWidthPx)

        val view = progressView ?: return
        view.layoutParams = FrameLayout.LayoutParams(
            barWidthPx,
            barHeightPx,
            Gravity.TOP or Gravity.CENTER_HORIZONTAL
        ).apply {
            topMargin = barTopMarginPx
        }
        view.requestLayout()
    }
    
    /**
     * Initialize and add the timebar overlay to the activity
     * Must be called from UI thread
     */
    @JvmStatic
    fun initialize() {
        val activity = Extension.mainActivity ?: return
        
        if (isInitialized.getAndSet(true)) return // Already initialized
        
        activity.runOnUiThread {
            try {
                if (barTopMarginPx <= 0) {
                    barTopMarginPx = (8 * activity.resources.displayMetrics.density).toInt()
                }
                val barHeightPx = (8 * activity.resources.displayMetrics.density).toInt()
                val screenWidthPx = activity.resources.displayMetrics.widthPixels
                val barWidthPx = getBarWidthPx(screenWidthPx)

                containerView = FrameLayout(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    )
                    setBackgroundColor(Color.TRANSPARENT)
                    isClickable = false
                    isFocusable = false
                }

                progressView = WavyProgressView(activity).apply {
                    layoutParams = FrameLayout.LayoutParams(
                        barWidthPx,
                        barHeightPx,
                        Gravity.TOP or Gravity.CENTER_HORIZONTAL
                    ).apply {
                        topMargin = barTopMarginPx
                    }

                    progress = currentProgress.coerceIn(0f, 1f)
                    alpha = currentAlpha.coerceIn(0f, 1f)
                }

                containerView?.addView(progressView)
                
                // Add to activity's content view
                val rootView = activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)
                rootView.addView(containerView)
                
            } catch (e: Exception) {
                e.printStackTrace()
                isInitialized.set(false)
            }
        }
    }
    
    /**
     * Remove timebar from activity
     */
    @JvmStatic
    fun destroy() {
        val activity = Extension.mainActivity ?: return
        
        activity.runOnUiThread {
            containerView?.let { view ->
                val parent = view.parent as? ViewGroup
                parent?.removeView(view)
            }
            progressView = null
            containerView = null
            isInitialized.set(false)
        }
    }
    
    /**
     * Update progress value (0.0 to 1.0)
     * Thread-safe, can be called from any thread
     * @param progress Value between 0.0 (empty) and 1.0 (full)
     */
    @JvmStatic
    fun setProgress(progress: Float) {
        currentProgress = progress.coerceIn(0f, 1f)
        val activity = Extension.mainActivity ?: return
        activity.runOnUiThread {
            progressView?.progress = currentProgress
        }
    }
    
    /**
     * Set visibility alpha (0.0 = invisible, 1.0 = fully visible)
     * @param alpha Value between 0.0 and 1.0
     */
    @JvmStatic
    fun setVisibility(alpha: Float) {
        currentAlpha = alpha.coerceIn(0f, 1f)
        val activity = Extension.mainActivity ?: return
        activity.runOnUiThread {
            progressView?.alpha = currentAlpha
        }
    }
    
    /**
     * Show timebar (fade in)
     */
    @JvmStatic
    fun show() {
        setVisibility(1f)
    }
    
    /**
     * Hide timebar (fade out)
     */
    @JvmStatic
    fun hide() {
        setVisibility(0f)
    }
    
    /**
     * Check if timebar is initialized
     */
    @JvmStatic
    fun isReady(): Boolean {
        return isInitialized.get() && progressView != null
    }

    @JvmStatic
    fun setLayout(widthPercent: Float, yPx: Float) {
        barWidthPercent = widthPercent.coerceIn(0.2f, 1f)
        barTopMarginPx = kotlin.math.max(0, yPx.toInt())

        val activity = Extension.mainActivity ?: return
        activity.runOnUiThread {
            applyLayoutOnUiThread(activity)
        }
    }
}
