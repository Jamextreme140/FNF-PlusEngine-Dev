package backend;

import openfl.Lib;
import openfl.system.Capabilities;

/**
 * Centralized window mode helper.
 *
 * On Windows, "exclusive fullscreen" can minimize/vanish when the app loses focus.
 * This implements a borderless fullscreen (windowed) alternative so the game behaves
 * like most desktop apps when alt-tabbing.
 *
 * Supports two modes:
 * - Borderless: Windowed fullscreen that won't minimize on alt-tab (recommended)
 * - Exclusive: Traditional exclusive fullscreen (may minimize on focus loss)
 */
class WindowMode
{
	public static var borderlessFullscreen(default, null):Bool = false;
	public static var exclusiveFullscreen(default, null):Bool = false;

	static var lastWindowedX:Int = 0;
	static var lastWindowedY:Int = 0;
	static var lastWindowedW:Int = 0;
	static var lastWindowedH:Int = 0;
	static var hasWindowedState:Bool = false;

	public static function toggleBorderlessFullscreen():Void
	{
		setBorderlessFullscreen(!borderlessFullscreen);
	}

	public static function toggleFullscreen():Void
	{
		#if desktop
		var mode = ClientPrefs.data.fullscreenMode;
		if (mode == 'Exclusive')
			setExclusiveFullscreen(!exclusiveFullscreen);
		else
			setBorderlessFullscreen(!borderlessFullscreen);
		#end
	}

	public static function setExclusiveFullscreen(enable:Bool):Void
	{
		#if desktop
		var window = Lib.current.stage.window;
		if (window == null) return;

		if (enable)
		{
			// Save current windowed state to restore later
			if (!exclusiveFullscreen && !borderlessFullscreen)
			{
				lastWindowedX = window.x;
				lastWindowedY = window.y;
				lastWindowedW = window.width;
				lastWindowedH = window.height;
				hasWindowedState = true;
			}

			// Disable borderless if it was active
			if (borderlessFullscreen)
			{
				window.borderless = false;
				borderlessFullscreen = false;
			}

			// Enable exclusive fullscreen
			try {
				window.fullscreen = true;
			} catch (_:Dynamic) {}
		}
		else
		{
			window.fullscreen = false;

			// Restore previous windowed size/position if we have it
			if (hasWindowedState && lastWindowedW > 0 && lastWindowedH > 0)
			{
				window.resize(lastWindowedW, lastWindowedH);
				window.x = lastWindowedX;
				window.y = lastWindowedY;
			}
		}

		exclusiveFullscreen = enable;
		#end
	}

	public static function setBorderlessFullscreen(enable:Bool):Void
	{
		#if desktop
		var window = Lib.current.stage.window;
		if (window == null) return;

		if (enable)
		{
			// Save current windowed state to restore later
			if (!borderlessFullscreen && !exclusiveFullscreen)
			{
				lastWindowedX = window.x;
				lastWindowedY = window.y;
				lastWindowedW = window.width;
				lastWindowedH = window.height;
				hasWindowedState = true;
			}

			// Disable exclusive fullscreen if it was active
			if (exclusiveFullscreen)
			{
				try {
					window.fullscreen = false;
				} catch (_:Dynamic) {}
				exclusiveFullscreen = false;
			}

			// Avoid exclusive fullscreen where supported.
			// Some platforms treat exclusive fullscreen specially on focus loss.
			try {
				window.fullscreen = false;
			} catch (_:Dynamic) {}
			window.borderless = true;

			var screenW = Std.int(Capabilities.screenResolutionX);
			var screenH = Std.int(Capabilities.screenResolutionY);

			// Move/resize to cover the primary monitor.
			window.x = 0;
			window.y = 0;
			window.resize(screenW, screenH);
		}
		else
		{
			window.borderless = false;

			// Restore previous windowed size/position if we have it.
			if (hasWindowedState && lastWindowedW > 0 && lastWindowedH > 0)
			{
				window.resize(lastWindowedW, lastWindowedH);
				window.x = lastWindowedX;
				window.y = lastWindowedY;
			}
		}

		borderlessFullscreen = enable;
		#end
	}
}
