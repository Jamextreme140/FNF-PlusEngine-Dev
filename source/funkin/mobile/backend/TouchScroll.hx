/*
 * Copyright (C) 2026 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package funkin.mobile.backend;

import flixel.input.touch.FlxTouch;
import flixel.math.FlxPoint;

/**
 * Touch scroll/swipe handler with tap detection
 * Differentiates between tap (quick touch) and scroll/swipe (drag gesture)
 * 
 * Based on implementations from NovaFlare Engine and Psych-Slice
 * @author Lenin
 */
class TouchScroll
{
    // Swipe detection thresholds
    public static inline var TAP_DISTANCE_THRESHOLD:Float = 15.0; // Pixels - if movement < this, it's a tap
    public static inline var TAP_TIME_THRESHOLD:Float = 0.3; // Seconds - max duration for a tap
    public static inline var SWIPE_VELOCITY_THRESHOLD:Float = 50.0; // Pixels/second - minimum for swipe
    
    // Momentum/inertia settings
    public static inline var MOMENTUM_FRICTION:Float = 0.92; // Deceleration multiplier (0-1)
    public static inline var MOMENTUM_MIN_VELOCITY:Float = 5.0; // Stop momentum below this velocity
    
    // Touch tracking
    private var touchStartPos:FlxPoint;
    private var touchCurrentPos:FlxPoint;
    private var touchStartTime:Float;
    private var lastTouchPos:FlxPoint;
    private var lastMoveTime:Float;
    
    // State
    public var isScrolling(default, null):Bool = false;
    public var isTap(default, null):Bool = false;
    public var scrollVelocity:Float = 0;
    public var totalDelta:Float = 0;
    
    // Axis (vertical or horizontal)
    public var vertical:Bool = true;
    
    private var activeTouch:FlxTouch = null;
    
    public function new(vertical:Bool = true)
    {
        this.vertical = vertical;
        touchStartPos = FlxPoint.get();
        touchCurrentPos = FlxPoint.get();
        lastTouchPos = FlxPoint.get();
        reset();
    }
    
    public function reset():Void
    {
        isScrolling = false;
        isTap = false;
        scrollVelocity = 0;
        totalDelta = 0;
        activeTouch = null;
        touchStartTime = 0;
        lastMoveTime = 0;
    }
    
    /**
     * Update scroll state - call this every frame
     * @return The scroll delta for this frame
     */
    public function update():Float
    {
        var currentTouch:FlxTouch = null;
        
        // Find active touch
        for (touch in FlxG.touches.list)
        {
            if (touch != null && (touch.justPressed || touch.pressed))
            {
                currentTouch = touch;
                break;
            }
        }
        
        // Touch just started
        if (currentTouch != null && currentTouch.justPressed)
        {
            touchStartPos.set(currentTouch.screenX, currentTouch.screenY);
            touchCurrentPos.set(currentTouch.screenX, currentTouch.screenY);
            lastTouchPos.set(currentTouch.screenX, currentTouch.screenY);
            touchStartTime = FlxG.game.ticks / 1000.0;
            lastMoveTime = touchStartTime;
            activeTouch = currentTouch;
            isScrolling = false;
            isTap = false;
            scrollVelocity = 0;
            totalDelta = 0;
        }
        // Touch is moving
        else if (currentTouch != null && currentTouch.pressed && activeTouch == currentTouch)
        {
            touchCurrentPos.set(currentTouch.screenX, currentTouch.screenY);
            
            var distance = getDistance();
            var duration = (FlxG.game.ticks / 1000.0) - touchStartTime;
            
            // Determine if this is a scroll or still could be a tap
            if (distance > TAP_DISTANCE_THRESHOLD)
            {
                isScrolling = true;
                isTap = false;
                
                // Calculate velocity for momentum
                var currentTime = FlxG.game.ticks / 1000.0;
                var deltaTime = currentTime - lastMoveTime;
                
                if (deltaTime > 0)
                {
                    var delta = vertical ? 
                        (touchCurrentPos.y - lastTouchPos.y) : 
                        (touchCurrentPos.x - lastTouchPos.x);
                    
                    scrollVelocity = delta / deltaTime;
                    totalDelta += delta;
                    
                    lastTouchPos.set(touchCurrentPos.x, touchCurrentPos.y);
                    lastMoveTime = currentTime;
                    
                    return delta;
                }
            }
        }
        // Touch ended
        else if (activeTouch != null && activeTouch.justReleased)
        {
            var distance = getDistance();
            var duration = (FlxG.game.ticks / 1000.0) - touchStartTime;
            
            // Determine if it was a tap
            if (distance < TAP_DISTANCE_THRESHOLD && duration < TAP_TIME_THRESHOLD)
            {
                isTap = true;
                isScrolling = false;
                scrollVelocity = 0;
            }
            else
            {
                isScrolling = false;
                isTap = false;
                // Keep velocity for momentum
            }
            
            activeTouch = null;
        }
        // No touch - apply momentum if scrolling ended
        else if (activeTouch == null && Math.abs(scrollVelocity) > MOMENTUM_MIN_VELOCITY)
        {
            scrollVelocity *= MOMENTUM_FRICTION;
            
            if (Math.abs(scrollVelocity) < MOMENTUM_MIN_VELOCITY)
            {
                scrollVelocity = 0;
            }
            
            var delta = scrollVelocity * FlxG.elapsed;
            totalDelta += delta;
            return delta;
        }
        else
        {
            scrollVelocity = 0;
        }
        
        return 0;
    }
    
    /**
     * Get distance from touch start to current position
     */
    private function getDistance():Float
    {
        if (vertical)
        {
            return Math.abs(touchCurrentPos.y - touchStartPos.y);
        }
        else
        {
            return Math.abs(touchCurrentPos.x - touchStartPos.x);
        }
    }
    
    /**
     * Get the touch position for tap detection
     * This consumes the tap event, returning the position once and then null
     */
    public function getTapPosition():FlxPoint
    {
        if (isTap)
        {
            isTap = false; // Consume the tap event - only return position once
            return touchStartPos;
        }
        return null;
    }
    
    /**
     * Check if a specific point was tapped (not scrolled)
     */
    public function wasTapped():Bool
    {
        return isTap;
    }
    
    /**
     * Check if currently scrolling
     */
    public function isCurrentlyScrolling():Bool
    {
        return isScrolling || Math.abs(scrollVelocity) > MOMENTUM_MIN_VELOCITY;
    }
    
    /**
     * Force stop scrolling and momentum
     */
    public function stopScroll():Void
    {
        scrollVelocity = 0;
        isScrolling = false;
    }
    
    public function destroy():Void
    {
        touchStartPos.put();
        touchCurrentPos.put();
        lastTouchPos.put();
        touchStartPos = null;
        touchCurrentPos = null;
        lastTouchPos = null;
        activeTouch = null;
    }
}
