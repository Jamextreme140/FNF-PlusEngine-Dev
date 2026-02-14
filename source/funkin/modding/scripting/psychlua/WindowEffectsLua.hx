package funkin.modding.scripting.psychlua;

import funkin.util.WindowEffects;

/**
 * Advanced Window Effects Lua API
 * Exposes WindowEffects system to Lua scripts
 * 
 * @author Lenin Asto (Plus Engine)
 */
class WindowEffectsLua
{
	public static function implement(funk:FunkinLua)
	{
		#if WINDOWS_FUNCTIONS_ALLOWED
		var lua = funk.lua;
		
		// === WINDOW SHAKE EFFECTS ===
		
		/**
		 * Shakes the window with customizable parameters
		 * @param intensity Shake intensity in pixels (default: 10)
		 * @param duration Shake duration in seconds (default: 0.5)
		 * @param frequency Shake frequency in Hz (default: 20)
		 * @param dampening Shake dampening factor 0-1 (default: 0.85)
		 */
		Lua_helper.add_callback(lua, "windowShake", function(intensity:Float = 10, duration:Float = 0.5, frequency:Float = 20, dampening:Float = 0.85) {
			WindowEffects.shake(intensity, duration, frequency, dampening);
		});
		
		/**
		 * Stops any active window shake
		 */
		Lua_helper.add_callback(lua, "stopWindowShake", function() {
			WindowEffects.stopShake();
		});
		
		// === WINDOW BOUNCE EFFECTS ===
		
		/**
		 * Bounces the window in a direction
		 * @param direction Direction ("up", "down", "left", "right")
		 * @param distance Bounce distance in pixels (default: 50)
		 * @param duration Bounce duration in seconds (default: 0.3)
		 * @param bounceCount Number of bounces (default: 1)
		 */
		Lua_helper.add_callback(lua, "windowBounce", function(direction:String = "up", distance:Int = 50, duration:Float = 0.3, bounceCount:Int = 1) {
			WindowEffects.bounce(direction, distance, duration, bounceCount);
		});
		
		// === WINDOW ALPHA/TRANSPARENCY ===
		
		/**
		 * Sets window opacity
		 * @param alpha Opacity 0.0 (transparent) to 1.0 (opaque)
		 */
		Lua_helper.add_callback(lua, "setWindowAlpha", function(alpha:Float) {
			WindowEffects.setAlpha(alpha);
		});
		
		/**
		 * Gets current window opacity
		 * @return Current alpha value (0.0 - 1.0)
		 */
		Lua_helper.add_callback(lua, "getWindowAlpha", function():Float {
			return WindowEffects.getAlpha();
		});
		
		/**
		 * Tweens window alpha over time
		 * @param targetAlpha Target opacity (0.0 - 1.0)
		 * @param duration Tween duration in seconds
		 */
		Lua_helper.add_callback(lua, "tweenWindowAlpha", function(targetAlpha:Float, duration:Float) {
			WindowEffects.tweenAlpha(targetAlpha, duration);
		});
		
		/**
		 * Fades window in
		 * @param duration Fade duration in seconds (default: 1.0)
		 */
		Lua_helper.add_callback(lua, "windowFadeIn", function(duration:Float = 1.0) {
			WindowEffects.fadeIn(duration);
		});
		
		/**
		 * Fades window out
		 * @param duration Fade duration in seconds (default: 1.0)
		 */
		Lua_helper.add_callback(lua, "windowFadeOut", function(duration:Float = 1.0) {
			WindowEffects.fadeOut(duration);
		});
		
		/**
		 * Pulses window alpha (fade in/out cycle)
		 * @param minAlpha Minimum alpha (default: 0.3)
		 * @param maxAlpha Maximum alpha (default: 1.0)
		 * @param duration Duration of one cycle in seconds (default: 1.0)
		 * @param loops Number of loops, 0 for infinite (default: 0)
		 */
		Lua_helper.add_callback(lua, "windowPulse", function(minAlpha:Float = 0.3, maxAlpha:Float = 1.0, duration:Float = 1.0, loops:Int = 0) {
			WindowEffects.pulse(minAlpha, maxAlpha, duration, loops);
		});
		
		// === WINDOW MOVEMENT EFFECTS ===
		
		/**
		 * Wiggles the window (figure-8 pattern)
		 * @param intensity Wiggle intensity in pixels (default: 15)
		 * @param duration Wiggle duration in seconds (default: 1.0)
		 * @param speed Wiggle speed multiplier (default: 3.0)
		 */
		Lua_helper.add_callback(lua, "windowWiggle", function(intensity:Float = 15, duration:Float = 1.0, speed:Float = 3.0) {
			WindowEffects.wiggle(intensity, duration, speed);
		});
		
		/**
		 * Spins the window in a circle
		 * @param radius Circle radius in pixels (default: 100)
		 * @param duration Spin duration in seconds (default: 2.0)
		 * @param rotations Number of full rotations (default: 1)
		 */
		Lua_helper.add_callback(lua, "windowSpin", function(radius:Float = 100, duration:Float = 2.0, rotations:Int = 1) {
			WindowEffects.spin(radius, duration, rotations);
		});
		
		// === UTILITY FUNCTIONS ===
		
		/**
		 * Resets all window parameters to default
		 */
		Lua_helper.add_callback(lua, "resetWindowEffects", function() {
			WindowEffects.resetAll();
		});
		
		/**
		 * Checks if any window effect is currently active
		 * @return True if any effect is running
		 */
		Lua_helper.add_callback(lua, "isWindowEffectActive", function():Bool {
			return WindowEffects.isEffectActive();
		});
		
		#end
	}
}
