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

import flixel.FlxObject;
import flixel.input.touch.FlxTouch;

/**
 * Utility class for handling touch input within the FlxG context.
 * Based on Funkin base implementation by FunkinCrew
 * @author: Karim Akra (rework by Lenin)
 */
class TouchUtil
{
	public static var pressed(get, never):Bool;
	public static var justPressed(get, never):Bool;
	public static var justReleased(get, never):Bool;
	public static var released(get, never):Bool;
	public static var touch(get, never):FlxTouch;

	/**
	 * Checks if an object was touched/pressed
	 * @param object The FlxObject to check for touch
	 * @param camera The camera to use for checking (optional, uses object's camera if null)
	 * @param justPressed If true, only returns true on justPressed. If false, returns true on both pressed and justPressed
	 * @return Whether the object was touched
	 */
	public static function pressAction(object:FlxObject, ?camera:FlxCamera, justPressed:Bool = true):Bool
	{
		if (object == null) return false;
		
		if (camera == null)
			camera = object.camera;
		
		for (touch in FlxG.touches.list)
		{
			if (touch == null) continue;
			
			// Check if touch is pressed or just pressed based on parameter
			var touchCondition = justPressed ? touch.justPressed : (touch.justPressed || touch.pressed);
			
			if (touchCondition && object.overlapsPoint(touch.getWorldPosition(camera), true, camera))
			{
				return true;
			}
		}
		
		return false;
	}

	public static function overlaps(object:FlxObject, ?camera:FlxCamera):Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.overlaps(object, camera ?? object.camera))
				return true;

		return false;
	}

	public static function overlapsComplex(object:FlxObject, ?camera:FlxCamera):Bool
	{
		if (camera == null)
			for (camera in object.cameras)
				for (touch in FlxG.touches.list)
					@:privateAccess
					if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera))
						return true;
		else
			@:privateAccess
			if (object.overlapsPoint(touch.getWorldPosition(camera, object._point), true, camera))
				return true;

		return false;
	}

	@:noCompletion
	private static function get_pressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.pressed)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_justPressed():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_justReleased():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.justReleased)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_released():Bool
	{
		for (touch in FlxG.touches.list)
			if (touch.released)
				return true;

		return false;
	}

	@:noCompletion
	private static function get_touch():FlxTouch
	{
		for (touch in FlxG.touches.list)
			if (touch != null)
				return touch;

		return FlxG.touches.getFirst();
	}
}