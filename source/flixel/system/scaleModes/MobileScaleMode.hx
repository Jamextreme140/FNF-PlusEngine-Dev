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

package flixel.system.scaleModes;

import flixel.FlxG;
import flixel.math.FlxPoint;
//import funkin.Preferences as ClientPrefs; already added in imports.hx

/**
 * Mobile-optimized scale mode with infinity display support
 * @author: Karim Akra
 */
class MobileScaleMode extends BaseScaleMode
{
	public static var allowInfinityDisplay(default, set):Bool = true;
	
	// Base game resolution for mod compatibility - use these instead of FlxG.width/height for positioning
	public static final BASE_GAME_WIDTH:Int = 1280;
	public static final BASE_GAME_HEIGHT:Int = 720;
	
	// Track screen dimensions for offset calculations
	static var screenWidth:Float = 0;
	static var screenHeight:Float = 0;
	
	/**
	 * Get the safe area width (always 1280 for mod compatibility)
	 * Use this instead of FlxG.width for positioning UI elements
	 */
	public static inline function getSafeWidth():Int
	{
		return BASE_GAME_WIDTH;
	}
	
	/**
	 * Get the safe area height (always 720 for mod compatibility)
	 * Use this instead of FlxG.height for positioning UI elements
	 */
	public static inline function getSafeHeight():Int
	{
		return BASE_GAME_HEIGHT;
	}
	
	/**
	 * Get horizontal offset of the safe area from the left edge
	 * Add this to X positions when using safe area coordinates
	 */
	public static function getHorizontalOffset():Float
	{
		if (!ClientPrefs.data.infinityDisplay || !allowInfinityDisplay)
			return 0;
		
		var screenRatio:Float = screenWidth / screenHeight;
		var baseRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
		
		if (screenRatio <= baseRatio)
		{
			// Screen is taller or equal - no horizontal extension
			return 0;
		}
		
		// Screen is wider - calculate offset
		return Math.max(0, (FlxG.width - BASE_GAME_WIDTH) / 2);
	}
	
	/**
	 * Calculate vertical offset for infinity display mode
	 * Add this to Y positions when using safe area coordinates
	 */
	public static function getVerticalOffset():Float
	{
		if (!ClientPrefs.data.infinityDisplay || !allowInfinityDisplay)
			return 0;
		
		var screenRatio:Float = screenWidth / screenHeight;
		var baseRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
		
		if (screenRatio >= baseRatio)
		{
			// Screen is wider or equal - no vertical extension
			return 0;
		}
		
		// Screen is taller - calculate offset
		return Math.max(0, (FlxG.height - BASE_GAME_HEIGHT) / 2);
	}
	
	/**
	 * Check if infinity display is currently active and affecting dimensions
	 */
	public static inline function isInfinityActive():Bool
	{
		return ClientPrefs.data.infinityDisplay && allowInfinityDisplay;
	}
	
	/**
	 * Get width to use for full-screen backgrounds and elements
	 * Use this for elements that should fill the entire screen
	 */
	public static inline function getScreenWidth():Int
	{
		return FlxG.width;
	}
	
	/**
	 * Get height to use for full-screen backgrounds and elements
	 * Use this for elements that should fill the entire screen
	 */
	public static inline function getScreenHeight():Int
	{
		return FlxG.height;
	}

	override function onMeasure(Width:Int, Height:Int):Void
	{
		screenWidth = Width;
		screenHeight = Height;
		
		if (ClientPrefs.data.infinityDisplay && allowInfinityDisplay)
		{
			// Infinity Display: extend game area to show more content without stretching
			var screenRatio:Float = Width / Height;
			var baseRatio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
			
			if (screenRatio < baseRatio)
			{
				// Screen is taller (mobile) - extend height to show more vertical content
				FlxG.width = BASE_GAME_WIDTH;
				FlxG.height = Math.ceil(BASE_GAME_WIDTH / screenRatio);
			}
			else
			{
				// Screen is wider - extend width to show more horizontal content
				FlxG.height = BASE_GAME_HEIGHT;
				FlxG.width = Math.ceil(BASE_GAME_HEIGHT * screenRatio);
			}
			
			// Use full screen - no black bars
			gameSize.x = Width;
			gameSize.y = Height;
		}
		else
		{
			// Standard 16:9 locked mode
			FlxG.width = BASE_GAME_WIDTH;
			FlxG.height = BASE_GAME_HEIGHT;
			
			var ratio:Float = BASE_GAME_WIDTH / BASE_GAME_HEIGHT;
			var realRatio:Float = Width / Height;
			var scaleY:Bool = realRatio < ratio;

			if (scaleY)
			{
				gameSize.x = Width;
				gameSize.y = Math.floor(gameSize.x / ratio);
			}
			else
			{
				gameSize.y = Height;
				gameSize.x = Math.floor(gameSize.y * ratio);
			}
		}
		
		updateDeviceSize(Width, Height);
		updateScaleOffset();
		updateGamePosition();
	}

	@:noCompletion
	private static function set_allowInfinityDisplay(value:Bool):Bool
	{
		if (allowInfinityDisplay == value)
			return value;
			
		allowInfinityDisplay = value;

		if (Std.isOfType(FlxG.scaleMode, MobileScaleMode))
		{
			if (FlxG.game != null)
			{
				FlxG.resizeGame(FlxG.width, FlxG.height);
			}
		}
		
		return value;
	}
}
