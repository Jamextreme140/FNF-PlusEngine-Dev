package funkin.ui.components.md3;

import flixel.FlxSprite;
import flixel.util.FlxColor;

/**
 * Material Design 3 Divider Component
 * Based on: https://m3.material.io/components/divider/guidelines
 *
 * A simple 1dp horizontal or vertical hairline separator.
 * Full-width or inset (indented) variants.
 */
class MaterialDivider extends FlxSprite
{
	// Colors (MD3)
	static inline var DIVIDER_COLOR:FlxColor = 0xFFCAC4D0;

	/**
	 * @param x          Position X.
	 * @param y          Position Y.
	 * @param length     Length of the divider in pixels.
	 * @param vertical   If true, draws a vertical divider instead of horizontal.
	 * @param insetStart Left/top inset in pixels (default 0 = full-width).
	 * @param insetEnd   Right/bottom inset in pixels (default 0).
	 */
	public function new(x:Float = 0, y:Float = 0, length:Float = 240, ?vertical:Bool = false, ?insetStart:Float = 0, ?insetEnd:Float = 0)
	{
		super(x, y);

		var totalLength = Std.int(length);
		var insetedLength = Std.int(length - insetStart - insetEnd);
		if (insetedLength < 1) insetedLength = 1;

		if (!vertical)
		{
			// Horizontal divider — 1px tall
			makeGraphic(totalLength, 1, FlxColor.TRANSPARENT, true);
			for (px in Std.int(insetStart)...Std.int(insetStart + insetedLength))
				pixels.setPixel32(px, 0, DIVIDER_COLOR);
		}
		else
		{
			// Vertical divider — 1px wide
			makeGraphic(1, totalLength, FlxColor.TRANSPARENT, true);
			for (py in Std.int(insetStart)...Std.int(insetStart + insetedLength))
				pixels.setPixel32(0, py, DIVIDER_COLOR);
		}

		dirty = true;
		antialiasing = false; // hairline lines should never be anti-aliased
	}
}
