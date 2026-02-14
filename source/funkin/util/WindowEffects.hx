package funkin.util;

import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import lime.app.Application;

import funkin.modding.scripting.psychlua.LuaUtils;

#if windows
import lenin.slushithings.windows.WindowsCPP;
import lenin.slushithings.windows.WindowsAPI;
#end

/**
 * Advanced Window Effects System
 * Ported and improved from Slushi Engine
 * 
 * Features:
 * - Window shake/bounce effects
 * - Window alpha/transparency control
 * - Advanced window animations
 * - Window parameter reset
 * - Multi-axis simultaneous tweening
 * 
 * @author Lenin Asto (Plus Engine)
 * @based Slushi Engine window system
 */
class WindowEffects
{
	// Active shake tweens
	private static var shakeTweenX:FlxTween = null;
	private static var shakeTweenY:FlxTween = null;
	
	// Original window position (for shake reset)
	private static var originalX:Int = 0;
	private static var originalY:Int = 0;
	
	// Window state
	private static var isShaking:Bool = false;
	private static var currentAlpha:Float = 1.0;
	
	/**
	 * Shakes the window with customizable intensity and duration
	 * @param intensity Shake intensity in pixels (default: 10)
	 * @param duration Shake duration in seconds (default: 0.5)
	 * @param frequency Shake frequency (oscillations per second, default: 20)
	 * @param dampening Shake dampening factor (0-1, default: 0.85)
	 */
	public static function shake(intensity:Float = 10, duration:Float = 0.5, frequency:Float = 20, dampening:Float = 0.85):Void
	{
		#if desktop
		if (isShaking) stopShake(); // Stop previous shake
		
		var window = Application.current.window;
		originalX = window.x;
		originalY = window.y;
		isShaking = true;
		
		var elapsed:Float = 0;
		var shakeTimer:FlxTimer = new FlxTimer();
		
		shakeTimer.start(1.0 / 60.0, function(timer:FlxTimer) {
			elapsed += 1.0 / 60.0;
			
			if (elapsed >= duration) {
				// Return to original position
				window.x = originalX;
				window.y = originalY;
				isShaking = false;
				timer.cancel();
				return;
			}
			
			// Calculate shake offset with dampening
			var progress:Float = elapsed / duration;
			var dampenedIntensity:Float = intensity * Math.pow(dampening, progress * 10);
			
			var offsetX:Float = Math.sin(elapsed * frequency * Math.PI * 2) * dampenedIntensity;
			var offsetY:Float = Math.cos(elapsed * frequency * Math.PI * 2 * 0.7) * dampenedIntensity * 0.5;
			
			window.x = originalX + Std.int(offsetX);
			window.y = originalY + Std.int(offsetY);
		}, 0); // Loop indefinitely until duration ends
		#end
	}
	
	/**
	 * Stops any active window shake
	 */
	public static function stopShake():Void
	{
		#if desktop
		if (!isShaking) return;
		
		var window = Application.current.window;
		window.x = originalX;
		window.y = originalY;
		isShaking = false;
		#end
	}
	
	/**
	 * Bounces the window in a direction
	 * @param direction Direction to bounce ("up", "down", "left", "right")
	 * @param distance Bounce distance in pixels (default: 50)
	 * @param duration Bounce duration in seconds (default: 0.3)
	 * @param bounceCount Number of bounces (default: 1)
	 */
	public static function bounce(direction:String = "up", distance:Int = 50, duration:Float = 0.3, bounceCount:Int = 1):Void
	{
		#if desktop
		var window = Application.current.window;
		var startX:Int = window.x;
		var startY:Int = window.y;
		
		var targetX:Int = startX;
		var targetY:Int = startY;
		
		switch (direction.toLowerCase()) {
			case "up":
				targetY -= distance;
			case "down":
				targetY += distance;
			case "left":
				targetX -= distance;
			case "right":
				targetX += distance;
		}
		
		// Create bounce tween
		var bounceTween:FlxTween = null;
		
		if (direction == "up" || direction == "down") {
			// Vertical bounce
			bounceTween = FlxTween.tween(window, {y: targetY}, duration / 2, {
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					FlxTween.tween(window, {y: startY}, duration / 2, {
						ease: FlxEase.bounceOut,
						onComplete: function(_) {
							if (bounceCount > 1) {
								// Recursive bounce with reduced intensity
								bounce(direction, Std.int(distance * 0.6), duration * 0.8, bounceCount - 1);
							}
						}
					});
				}
			});
		} else {
			// Horizontal bounce
			bounceTween = FlxTween.tween(window, {x: targetX}, duration / 2, {
				ease: FlxEase.quadOut,
				onComplete: function(_) {
					FlxTween.tween(window, {x: startX}, duration / 2, {
						ease: FlxEase.bounceOut,
						onComplete: function(_) {
							if (bounceCount > 1) {
								// Recursive bounce with reduced intensity
								bounce(direction, Std.int(distance * 0.6), duration * 0.8, bounceCount - 1);
							}
						}
					});
				}
			});
		}
		#end
	}
	
	/**
	 * Sets window alpha/transparency
	 * @param alpha Alpha value (0.0 - 1.0)
	 */
	public static function setAlpha(alpha:Float):Void
	{
		#if windows
		currentAlpha = FlxMath.bound(alpha, 0.0, 1.0);
		WindowsCPP.setWindowOpacity(currentAlpha);
		#end
	}
	
	/**
	 * Gets current window alpha
	 * @return Current alpha value (0.0 - 1.0)
	 */
	public static function getAlpha():Float
	{
		#if windows
		return WindowsCPP.getWindowOpacity();
		#else
		return 1.0;
		#end
	}
	
	/**
	 * Tweens window alpha over time
	 * @param targetAlpha Target alpha value (0.0 - 1.0)
	 * @param duration Tween duration in seconds
	 * @param ease Easing function (default: FlxEase.linear)
	 */
	public static function tweenAlpha(targetAlpha:Float, duration:Float, ?ease:EaseFunction):Void
	{
		#if windows
		if (ease == null) ease = FlxEase.linear;
		
		var startAlpha:Float = getAlpha();
		targetAlpha = FlxMath.bound(targetAlpha, 0.0, 1.0);
		
		var numTween:NumTween = FlxTween.num(startAlpha, targetAlpha, duration, {
			ease: ease
		});
		
		numTween.onUpdate = function(_) {
			setAlpha(numTween.value);
		};
		#end
	}
	
	/**
	 * Makes window fade in
	 * @param duration Fade duration in seconds (default: 1.0)
	 */
	public static function fadeIn(duration:Float = 1.0):Void
	{
		tweenAlpha(1.0, duration, FlxEase.sineOut);
	}
	
	/**
	 * Makes window fade out
	 * @param duration Fade duration in seconds (default: 1.0)
	 */
	public static function fadeOut(duration:Float = 1.0):Void
	{
		tweenAlpha(0.0, duration, FlxEase.sineIn);
	}
	
	/**
	 * Pulses window alpha (fade in/out cycle)
	 * @param minAlpha Minimum alpha value (default: 0.3)
	 * @param maxAlpha Maximum alpha value (default: 1.0)
	 * @param duration Duration of one pulse cycle (default: 1.0)
	 * @param loops Number of loops (0 = infinite, default: 0)
	 */
	public static function pulse(minAlpha:Float = 0.3, maxAlpha:Float = 1.0, duration:Float = 1.0, loops:Int = 0):Void
	{
		#if windows
		var currentLoop:Int = 0;
		
		function doPulse() {
			tweenAlpha(minAlpha, duration / 2, FlxEase.sineInOut);
			
			new FlxTimer().start(duration / 2, function(_) {
				tweenAlpha(maxAlpha, duration / 2, FlxEase.sineInOut);
				
				currentLoop++;
				if (loops == 0 || currentLoop < loops) {
					new FlxTimer().start(duration / 2, function(_) {
						doPulse();
					});
				}
			});
		}
		
		doPulse();
		#end
	}
	
	/**
	 * Wiggles the window (figure-8 pattern)
	 * @param intensity Wiggle intensity in pixels (default: 15)
	 * @param duration Wiggle duration in seconds (default: 1.0)
	 * @param speed Wiggle speed multiplier (default: 3.0)
	 */
	public static function wiggle(intensity:Float = 15, duration:Float = 1.0, speed:Float = 3.0):Void
	{
		#if desktop
		var window = Application.current.window;
		var startX:Int = window.x;
		var startY:Int = window.y;
		
		var elapsed:Float = 0;
		var wiggleTimer:FlxTimer = new FlxTimer();
		
		wiggleTimer.start(1.0 / 60.0, function(timer:FlxTimer) {
			elapsed += 1.0 / 60.0;
			
			if (elapsed >= duration) {
				window.x = startX;
				window.y = startY;
				timer.cancel();
				return;
			}
			
			// Figure-8 pattern (Lissajous curve)
			var t:Float = elapsed * speed;
			var offsetX:Float = Math.sin(t) * intensity;
			var offsetY:Float = Math.sin(t * 2) * intensity * 0.5;
			
			window.x = startX + Std.int(offsetX);
			window.y = startY + Std.int(offsetY);
		}, 0);
		#end
	}
	
	/**
	 * Spins the window in a circle
	 * @param radius Circle radius in pixels (default: 100)
	 * @param duration Spin duration in seconds (default: 2.0)
	 * @param rotations Number of full rotations (default: 1)
	 */
	public static function spin(radius:Float = 100, duration:Float = 2.0, rotations:Int = 1):Void
	{
		#if desktop
		var window = Application.current.window;
		var centerX:Int = window.x;
		var centerY:Int = window.y;
		
		var elapsed:Float = 0;
		var totalAngle:Float = rotations * Math.PI * 2;
		
		var spinTimer:FlxTimer = new FlxTimer();
		
		spinTimer.start(1.0 / 60.0, function(timer:FlxTimer) {
			elapsed += 1.0 / 60.0;
			
			if (elapsed >= duration) {
				window.x = centerX;
				window.y = centerY;
				timer.cancel();
				return;
			}
			
			var progress:Float = elapsed / duration;
			var angle:Float = progress * totalAngle;
			
			var offsetX:Float = Math.cos(angle) * radius;
			var offsetY:Float = Math.sin(angle) * radius;
			
			window.x = centerX + Std.int(offsetX);
			window.y = centerY + Std.int(offsetY);
		}, 0);
		#end
	}
	
	/**
	 * Resets all window parameters to default
	 * Position, size, alpha, borderless, etc.
	 */
	public static function resetAll():Void
	{
		#if desktop
		var window = Application.current.window;
		
		// Stop any active effects
		stopShake();
		
		// Reset alpha
		setAlpha(1.0);
		
		// Reset borderless
		window.borderless = false;
		
		// Reset resizable
		window.resizable = true;
		
		// Reset title
		window.title = Application.current.meta.get('name');
		
		// Center window
		#if windows
		var screenWidth:Int = WindowsCPP.getScreenWidth();
		var screenHeight:Int = WindowsCPP.getScreenHeight();
		window.x = Std.int((screenWidth - window.width) / 2);
		window.y = Std.int((screenHeight - window.height) / 2);
		#else
		// Fallback centering
		window.x = Std.int((FlxG.stage.stageWidth - window.width) / 2);
		window.y = Std.int((FlxG.stage.stageHeight - window.height) / 2);
		#end
		
		trace('Window parameters reset to default');
		#end
	}
	
	/**
	 * Checks if any window effect is currently active
	 * @return True if any effect is running
	 */
	public static function isEffectActive():Bool
	{
		return isShaking;
	}
}
