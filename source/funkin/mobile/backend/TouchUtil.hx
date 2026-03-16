package funkin.mobile.backend;

import flixel.FlxObject;
import flixel.input.touch.FlxTouch;

/**
 * Utility class for handling touch input within the FlxG context.
 * Based on Funkin base implementation by FunkinCrew
 * @author: Karim Akra
 * @author: Lenin
 */
class TouchUtil
{
	public static var pressed(get, never):Bool;
	public static var justPressed(get, never):Bool;
	public static var justReleased(get, never):Bool;
	public static var released(get, never):Bool;
	public static var touch(get, never):FlxTouch;

	// Reference to active scroll handler to prevent taps during scroll
	private static var activeScrollHandler:TouchScroll = null;

	/**
	 * Register a scroll handler to prevent tap conflicts
	 */
	public static function setScrollHandler(handler:TouchScroll):Void
	{
		activeScrollHandler = handler;
	}

	/**
	 * Clear scroll handler reference
	 */
	public static function clearScrollHandler():Void
	{
		activeScrollHandler = null;
	}

	/**
	 * Checks if an object was touched/pressed
	 * @param object The FlxObject to check for touch
	 * @param camera The camera to use for checking (optional, uses object's camera if null)
	 * @param justPressed If true, only returns true on justPressed. If false, returns true on both pressed and justPressed
	 * @param ignoreScroll If false, will return false if scroll is active (prevents accidental taps during scroll)
	 * @return Whether the object was touched
	 */
	public static function pressAction(object:FlxObject, ?camera:FlxCamera, justPressed:Bool = true, ignoreScroll:Bool = false):Bool
	{
		if (object == null) return false;
		
		// Don't register taps if scroll is active (unless explicitly ignored)
		if (!ignoreScroll && activeScrollHandler != null && activeScrollHandler.isCurrentlyScrolling())
		{
			return false;
		}
		
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