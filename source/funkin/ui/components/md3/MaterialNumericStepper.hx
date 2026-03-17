package funkin.ui.components.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import funkin.ui.components.md3.MD3Theme;

/**
 * Material Design 3 Numeric Stepper Component
 * Inspired by: https://m3.material.io/components/text-fields and segmented buttons
 *
 * A compact [−] value [+] control inside an outlined pill container.
 * Supports hold-to-repeat, configurable step / range / decimals.
 */
class MaterialNumericStepper extends FlxSpriteGroup
{
	// -----------------------------------------------------------------------
	// Public API
	// -----------------------------------------------------------------------

	/** Current numeric value. Setting this programmatically does NOT fire onChange. */
	public var value(default, set):Float = 0;

	public var min:Float       = 0;
	public var max:Float       = 100;
	public var step:Float      = 1;
	public var decimals:Int    = 0;
	public var enabled:Bool    = true;

	/** Called with the new value only when the user presses − or +. */
	public var onChange:Float->Void = null;

	// -----------------------------------------------------------------------
	// Dimensions
	// -----------------------------------------------------------------------

	public var stepperWidth:Float = 120;

	static inline var HEIGHT:Int         = 40;
	static inline var BTN_AREA:Int       = 36;   // px wide for each −/+ zone
	static inline var CORNER_RADIUS:Int  = 20;   // full pill
	static inline var VALUE_SIZE:Int     = 13;
	static inline var ICON_SIZE:Int      = 18;

	// -----------------------------------------------------------------------
	// Visual components
	// -----------------------------------------------------------------------

	var background:FlxSprite;
	var decrState:FlxSprite;
	var incrState:FlxSprite;
	var divL:FlxSprite;
	var divR:FlxSprite;
	var decrText:FlxText;
	var incrText:FlxText;
	var valueText:FlxText;

	// -----------------------------------------------------------------------
	// Interaction state
	// -----------------------------------------------------------------------

	var hoverDecr:Bool  = false;
	var hoverIncr:Bool  = false;
	var holdDecr:Bool   = false;
	var holdIncr:Bool   = false;
	var holdTimer:Float = 0;
	var holdElapsd:Float = 0;

	static inline var HOLD_DELAY:Float  = 0.45;
	static inline var HOLD_REPEAT:Float = 1 / 12;

	// -----------------------------------------------------------------------
	// Constructor
	// -----------------------------------------------------------------------

	/**
	 * @param x        Group X position.
	 * @param y        Group Y position.
	 * @param step     Amount to add / subtract on each press.
	 * @param value    Initial value.
	 * @param min      Minimum allowed value (inclusive).
	 * @param max      Maximum allowed value (inclusive).
	 * @param decimals Decimal places shown and used for rounding.
	 * @param width    Total pixel width of the stepper.
	 * @param onChange Callback fired after every user-triggered step.
	 */
	public function new(x:Float = 0, y:Float = 0,
	                    step:Float = 1, value:Float = 0,
	                    min:Float = 0, max:Float = 100, decimals:Int = 0,
	                    width:Float = 120, ?onChange:Float->Void)
	{
		super(x, y);

		this.step      = step;
		this.min       = min;
		this.max       = max;
		this.decimals  = decimals;
		this.onChange  = onChange;
		this.stepperWidth = width;

		var w = Std.int(width);

		// Outlined background
		background = new FlxSprite(0, 0);
		background.makeGraphic(w, HEIGHT, FlxColor.TRANSPARENT, true);
		_drawOutlinedPill(background, w, HEIGHT, CORNER_RADIUS);
		add(background);

		// Decrement state layer (hover / press)
		decrState = new FlxSprite(0, 0);
		decrState.makeGraphic(BTN_AREA, HEIGHT, FlxColor.WHITE, true);
		_drawLeftPill(decrState, BTN_AREA, HEIGHT, CORNER_RADIUS);
		decrState.color = MD3Theme.primary;
		decrState.alpha = 0;
		add(decrState);

		// Increment state layer (hover / press)
		incrState = new FlxSprite(w - BTN_AREA, 0);
		incrState.makeGraphic(BTN_AREA, HEIGHT, FlxColor.WHITE, true);
		_drawRightPill(incrState, BTN_AREA, HEIGHT, CORNER_RADIUS);
		incrState.color = MD3Theme.primary;
		incrState.alpha = 0;
		add(incrState);

		// Vertical dividers
		divL = new FlxSprite(BTN_AREA, 7);
		divL.makeGraphic(1, HEIGHT - 14, 0xFFCAC4D0);
		add(divL);

		divR = new FlxSprite(w - BTN_AREA - 1, 7);
		divR.makeGraphic(1, HEIGHT - 14, 0xFFCAC4D0);
		add(divR);

		// Decrement glyph
		decrText = new FlxText(0, 0, BTN_AREA, "\u2212", ICON_SIZE);
		decrText.setFormat(Paths.font("phantom.ttf"), ICON_SIZE, MD3Theme.primary, CENTER);
		decrText.antialiasing = ClientPrefs.data.antialiasing;
		decrText.y = (HEIGHT - decrText.height) / 2 + 1;
		add(decrText);

		// Increment glyph
		incrText = new FlxText(w - BTN_AREA, 0, BTN_AREA, "+", ICON_SIZE);
		incrText.setFormat(Paths.font("phantom.ttf"), ICON_SIZE, MD3Theme.primary, CENTER);
		incrText.antialiasing = ClientPrefs.data.antialiasing;
		incrText.y = (HEIGHT - incrText.height) / 2 + 1;
		add(incrText);

		// Value display
		valueText = new FlxText(BTN_AREA + 2, 0, w - BTN_AREA * 2 - 4, "", VALUE_SIZE);
		valueText.setFormat(Paths.font("phantom.ttf"), VALUE_SIZE, MD3Theme.onSurface, CENTER);
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		valueText.y = (HEIGHT - valueText.height) / 2;
		add(valueText);

		// Assign value after all sprites are ready
		this.value = value;

		MD3Theme.addListener(_onThemeChange);
	}

	// -----------------------------------------------------------------------
	// Value setter — does NOT fire onChange (programmatic use)
	// -----------------------------------------------------------------------

	function set_value(v:Float):Float
	{
		v = FlxMath.bound(v, min, max);
		var factor = Math.pow(10, decimals);
		v = Math.round(v * factor) / factor;
		value = v;
		if (valueText != null)
		{
			valueText.text = decimals > 0
				? Std.string(FlxMath.roundDecimal(v, decimals))
				: Std.string(Std.int(v));
		}
		return value;
	}

	// -----------------------------------------------------------------------
	// Internal step — fires onChange
	// -----------------------------------------------------------------------

	inline function _step(dir:Int):Void
	{
		var prev = value;
		value += dir * step;
		if (value != prev && onChange != null) onChange(value);
	}

	// -----------------------------------------------------------------------
	// Update — hit-testing, hover, and hold-to-repeat
	// -----------------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!enabled) return;

		// Mouse position relative to this group
		var mx:Float = FlxG.mouse.x - x;
		var my:Float = FlxG.mouse.y - y;

		var overDecr = (mx >= 0 && mx < BTN_AREA        && my >= 0 && my < HEIGHT);
		var overIncr = (mx >= stepperWidth - BTN_AREA && mx < stepperWidth && my >= 0 && my < HEIGHT);

		// Hover effect
		if (overDecr != hoverDecr)
		{
			hoverDecr = overDecr;
			FlxTween.cancelTweensOf(decrState);
			FlxTween.tween(decrState, {alpha: hoverDecr ? 0.10 : 0}, 0.1, {ease: FlxEase.sineOut});
		}
		if (overIncr != hoverIncr)
		{
			hoverIncr = overIncr;
			FlxTween.cancelTweensOf(incrState);
			FlxTween.tween(incrState, {alpha: hoverIncr ? 0.10 : 0}, 0.1, {ease: FlxEase.sineOut});
		}

		// Initial click
		if (FlxG.mouse.justPressed)
		{
			if (overDecr) { _step(-1); holdDecr = true; holdTimer = 0; holdElapsd = 0; }
			if (overIncr) { _step( 1); holdIncr = true; holdTimer = 0; holdElapsd = 0; }
		}
		if (FlxG.mouse.justReleased) holdDecr = holdIncr = false;

		// Hold-to-repeat
		if (holdDecr || holdIncr)
		{
			holdTimer += elapsed;
			if (holdTimer >= HOLD_DELAY)
			{
				holdElapsd += elapsed;
				while (holdElapsd >= HOLD_REPEAT)
				{
					_step(holdDecr ? -1 : 1);
					holdElapsd -= HOLD_REPEAT;
				}
			}
		}
	}

	// -----------------------------------------------------------------------
	// Theme listener
	// -----------------------------------------------------------------------

	function _onThemeChange():Void
	{
		if (decrText  != null) decrText.color  = MD3Theme.primary;
		if (incrText  != null) incrText.color  = MD3Theme.primary;
		if (valueText != null) valueText.color = MD3Theme.onSurface;
		if (decrState != null) decrState.color = MD3Theme.primary;
		if (incrState != null) incrState.color = MD3Theme.primary;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		super.destroy();
	}

	// -----------------------------------------------------------------------
	// Pixel-drawing helpers
	// -----------------------------------------------------------------------

	function _drawOutlinedPill(spr:FlxSprite, w:Int, h:Int, r:Int):Void
	{
		var gfx = spr.pixels;
		gfx.fillRect(gfx.rect, FlxColor.TRANSPARENT);
		var outline:Int = MD3Theme.outline;
		var fill:Int    = MD3Theme.surface;
		for (py in 0...h)
			for (px in 0...w)
			{
				if (!_inRR(px, py, w, h, r)) continue;
				gfx.setPixel32(px, py, _inRR(px, py, w, h, r, 1) ? fill : outline);
			}
	}

	function _drawLeftPill(spr:FlxSprite, w:Int, h:Int, r:Int):Void
	{
		var gfx = spr.pixels;
		gfx.fillRect(gfx.rect, FlxColor.TRANSPARENT);
		for (py in 0...h)
			for (px in 0...w)
				if (_inLeftRR(px, py, w, h, r)) gfx.setPixel32(px, py, 0xFFFFFFFF);
	}

	function _drawRightPill(spr:FlxSprite, w:Int, h:Int, r:Int):Void
	{
		var gfx = spr.pixels;
		gfx.fillRect(gfx.rect, FlxColor.TRANSPARENT);
		for (py in 0...h)
			for (px in 0...w)
				if (_inRightRR(px, py, w, h, r)) gfx.setPixel32(px, py, 0xFFFFFFFF);
	}

	/** True if (px, py) is inside a rounded rectangle with uniform corner radius r,
	 *  optionally shrunk inward by `shrink` pixels. */
	inline function _inRR(px:Int, py:Int, w:Int, h:Int, r:Int, shrink:Int = 0):Bool
	{
		var rs = r - shrink;
		if (rs <= 0) return true;
		var x1 = rs; var x2 = w - rs;
		var y1 = rs; var y2 = h - rs;
		if (px >= x1 && px < x2) return (py >= shrink && py < h - shrink);
		if (py >= y1 && py < y2) return (px >= shrink && px < w - shrink);
		var cx = (px < r) ? rs : w - rs;
		var cy = (py < r) ? rs : h - rs;
		var dx = px - cx + 0.5;
		var dy = py - cy + 0.5;
		return dx * dx + dy * dy <= rs * rs;
	}

	/** Rounded on the left side only (right edge is straight). */
	inline function _inLeftRR(px:Int, py:Int, w:Int, h:Int, r:Int):Bool
	{
		if (px >= r) return (py >= 0 && py < h);
		if (py >= r && py < h - r) return _circleX(px, r, r);
		var cy = (py < r) ? r : h - r;
		var dx = px - r + 0.5; var dy = py - cy + 0.5;
		return dx * dx + dy * dy <= r * r;
	}

	/** Rounded on the right side only (left edge is straight). */
	inline function _inRightRR(px:Int, py:Int, w:Int, h:Int, r:Int):Bool
	{
		var cx2 = w - r;
		if (px < cx2) return (py >= 0 && py < h);
		if (py >= r && py < h - r) return _circleX(px - cx2, 0, r);
		var cy = (py < r) ? r : h - r;
		var dx = px - cx2 + 0.5; var dy = py - cy + 0.5;
		return dx * dx + dy * dy <= r * r;
	}

	inline function _circleX(dx:Int, cx:Int, r:Int):Bool
	{
		var d = dx - cx + 0.5;
		return d * d <= r * r;
	}
}
