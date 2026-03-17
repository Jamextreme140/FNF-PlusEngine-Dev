package funkin.ui.components.md3;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;

/**
 * Material Design 3 Loading Indicator
 * Based on: https://m3.material.io/components/loading-indicator/guidelines
 *
 * A solid shape that morphs through the 7 M3 shape keyframes while gently
 * rotating.  Designed for short indeterminate waits (200 ms – 5 s).
 *
 * For longer or detectable-progress waits, use MaterialProgressIndicator instead.
 *
 * Usage:
 *   var indicator = new MaterialLoadingIndicator(x, y);          // default 48 px
 *   var big       = new MaterialLoadingIndicator(x, y, 64);      // custom size
 *   var onSurface = new MaterialLoadingIndicator(x, y, 48, true); // with container bg
 */
class MaterialLoadingIndicator extends FlxSpriteGroup
{
	/** Side length of the indicator in pixels (24–240). Default 48. */
	public var indicatorSize(default, null):Int;

	/** When true, a circular container is rendered behind the indicator. */
	public var showContainer(default, null):Bool;

	// M3 color tokens
	static inline var ACTIVE_COLOR:FlxColor        = 0xFF6750A4; // primary
	static inline var CONTAINER_COLOR:FlxColor     = 0xFFECE6F0; // primary-container
	static inline var ON_CONTAINER_COLOR:FlxColor  = 0xFF21005D; // on-primary-container

	var _container:FlxSprite;
	var _indicator:FlxSprite;

	// Animation state
	var _morphTimer:Float = 0;
	var _spinAngle:Float  = 0;
	var _lastCorner:Float = -1;

	/**
	 * 5-entry shape keyframes (entry[4] == entry[0] to close the loop).
	 *
	 * CORNERS  corner radius fraction of indicatorSize/2 (0.5=circle, 0.08=near-square)
	 * SCALE_X  horizontal stretch via sprite scale
	 * SCALE_Y  vertical stretch via sprite scale
	 * ROT_OFF  extra rotation on top of base spin (degrees)
	 *
	 * Moderate scale values (max 1.30) keep the morph organic without
	 * reading as a distracting "squash and stretch".
	 */
	static var CORNERS:Array<Float> = [0.50, 0.50, 0.50, 0.50, 0.50];
	static var SCALE_X:Array<Float>  = [1.00, 1.28, 1.00, 0.78, 1.00];
	static var SCALE_Y:Array<Float>  = [1.00, 0.78, 1.00, 1.28, 1.00];
	static var ROT_OFF:Array<Float>  = [0.0,  10.0, 25.0, -10.0, 0.0];

	// 0.72 cycles/s → each transition lasts ~0.35 s; four distinct shapes per loop
	static inline var MORPH_SPEED:Float = 0.72;
	static inline var SPIN_SPEED:Float  = 90.0; // base continuous rotation (degrees/s)

	public function new(x:Float = 0, y:Float = 0, size:Int = 48, showContainer:Bool = false)
	{
		super(x, y);

		this.indicatorSize  = size;
		this.showContainer  = showContainer;

		if (showContainer)
		{
			// Container: circle ~1.67× the indicator, centred behind it
			var cs:Int     = Std.int(size * 1.667);
			var offset:Int = Std.int((cs - size) / 2);
			_container = new FlxSprite(-offset, -offset);
			_container.makeGraphic(cs, cs, FlxColor.TRANSPARENT, true);
			_drawFilledCircle(_container, cs, CONTAINER_COLOR);
			add(_container);
		}

		_indicator = new FlxSprite(0, 0);
		_indicator.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		_redrawShape(size * 0.5); // start as circle
		add(_indicator);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		_morphTimer += elapsed;
		_spinAngle   = (_spinAngle + elapsed * SPIN_SPEED) % 360;

		var steps:Int    = CORNERS.length - 1; // 7 transitions
		var cycleT:Float = (_morphTimer * MORPH_SPEED) % 1.0;
		var pos:Float    = cycleT * steps;
		var idx:Int      = Std.int(pos);
		if (idx >= steps) idx = steps - 1;
		var t:Float = _smoothstep(pos - idx);

		var corner:Float = _lerp(CORNERS[idx], CORNERS[idx + 1], t) * indicatorSize * 0.5;
		var sx:Float     = _lerp(SCALE_X[idx],  SCALE_X[idx + 1],  t);
		var sy:Float     = _lerp(SCALE_Y[idx],  SCALE_Y[idx + 1],  t);
		var rotOff:Float = _lerp(ROT_OFF[idx],  ROT_OFF[idx + 1],  t);

		// Only redraw the BitmapData when the corner radius changes visibly
		if (Math.abs(corner - _lastCorner) > 0.5)
		{
			_lastCorner = corner;
			_redrawShape(corner);
		}

		// Scale and angle are cheap — update every frame.
		// Flixel rotates/scales around the sprite's frame center, so the
		// visual center stays fixed regardless of scale values.
		_indicator.scale.x = sx;
		_indicator.scale.y = sy;
		_indicator.angle   = _spinAngle + rotOff;
	}

	// -----------------------------------------------------------------------
	// Private helpers
	// -----------------------------------------------------------------------

	function _redrawShape(cornerRadius:Float):Void
	{
		var s:Int        = indicatorSize;
		var col:FlxColor = showContainer ? ON_CONTAINER_COLOR : ACTIVE_COLOR;
		var bmp          = _indicator.pixels;
		bmp.fillRect(bmp.rect, FlxColor.TRANSPARENT);
		_drawFilledRoundedRect(_indicator, s, s, Std.int(cornerRadius), col);
		_indicator.dirty = true;
	}

	function _drawFilledCircle(sprite:FlxSprite, size:Int, color:FlxColor):Void
	{
		var bmp = sprite.pixels;
		var cx:Float = size * 0.5;
		var cy:Float = size * 0.5;
		var r:Float  = cx;
		for (py in 0...size)
			for (px in 0...size)
			{
				var dx:Float = px - cx + 0.5;
				var dy:Float = py - cy + 0.5;
				if (dx * dx + dy * dy <= r * r)
					bmp.setPixel32(px, py, color);
			}
		sprite.dirty = true;
	}

	function _drawFilledRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Int, color:FlxColor):Void
	{
		var bmp      = sprite.pixels;
		var r:Int    = Std.int(Math.min(radius, Math.min(width, height) / 2));
		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var inShape:Bool = true;
				var dx:Float;
				var dy:Float;
				if (px < r && py < r)
				{
					dx = r - px - 0.5; dy = r - py - 0.5;
					inShape = (dx * dx + dy * dy) <= r * r;
				}
				else if (px >= width - r && py < r)
				{
					dx = px - (width - r) + 0.5; dy = r - py - 0.5;
					inShape = (dx * dx + dy * dy) <= r * r;
				}
				else if (px < r && py >= height - r)
				{
					dx = r - px - 0.5; dy = py - (height - r) + 0.5;
					inShape = (dx * dx + dy * dy) <= r * r;
				}
				else if (px >= width - r && py >= height - r)
				{
					dx = px - (width - r) + 0.5; dy = py - (height - r) + 0.5;
					inShape = (dx * dx + dy * dy) <= r * r;
				}
				if (inShape)
					bmp.setPixel32(px, py, color);
			}
		}
		sprite.dirty = true;
	}

	static inline function _lerp(a:Float, b:Float, t:Float):Float
		return a + (b - a) * t;

	static inline function _smoothstep(t:Float):Float
	{
		var c:Float = t < 0 ? 0.0 : (t > 1 ? 1.0 : t);
		return c * c * (3.0 - 2.0 * c);
	}
}
