package funkin.ui.components.md3;

import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Theme System
 * Central source-of-truth for color roles and motion tokens.
 *
 * Usage:
 *   MD3Theme.setAccent(0xFF006494); // Blue
 *   MD3Theme.setAccent(0xFF6750A4); // Default purple
 *
 * Components register via addListener() so they refresh automatically
 * when the accent changes.
 */
class MD3Theme
{
	// -----------------------------------------------------------------------
	// Light-scheme color roles (M3 baseline — default = purple 40 palette)
	// -----------------------------------------------------------------------

	public static var primary:FlxColor              = 0xFF6750A4;
	public static var onPrimary:FlxColor            = 0xFFFFFFFF;
	public static var primaryContainer:FlxColor     = 0xFFEADDFF;
	public static var onPrimaryContainer:FlxColor   = 0xFF21005D;

	public static var secondary:FlxColor            = 0xFF625B71;
	public static var onSecondary:FlxColor          = 0xFFFFFFFF;
	public static var secondaryContainer:FlxColor   = 0xFFE8DEF8;
	public static var onSecondaryContainer:FlxColor = 0xFF1D192B;

	public static var tertiary:FlxColor             = 0xFF7D5260;
	public static var onTertiary:FlxColor           = 0xFFFFFFFF;
	public static var tertiaryContainer:FlxColor    = 0xFFFFD8E4;
	public static var onTertiaryContainer:FlxColor  = 0xFF31111D;

	public static var error:FlxColor                = 0xFFB3261E;
	public static var onError:FlxColor              = 0xFFFFFFFF;
	public static var errorContainer:FlxColor       = 0xFFF9DEDC;
	public static var onErrorContainer:FlxColor     = 0xFF410E0B;

	public static var background:FlxColor           = 0xFFFEF7FF;
	public static var onBackground:FlxColor         = 0xFF1C1B1F;

	public static var surface:FlxColor              = 0xFFFEF7FF;
	public static var onSurface:FlxColor            = 0xFF1C1B1F;
	public static var surfaceVariant:FlxColor       = 0xFFE7E0EC;
	public static var onSurfaceVariant:FlxColor     = 0xFF49454F;

	public static var surfaceContainerLowest:FlxColor = 0xFFFFFBFE;
	public static var surfaceContainerLow:FlxColor    = 0xFFF7F2FA;
	public static var surfaceContainer:FlxColor       = 0xFFF3EDF7;
	public static var surfaceContainerHigh:FlxColor   = 0xFFECE6F0;
	public static var surfaceContainerHighest:FlxColor= 0xFFE6E0E9;

	public static var outline:FlxColor              = 0xFF79747E;
	public static var outlineVariant:FlxColor       = 0xFFCAC4D0;

	public static var inverseSurface:FlxColor       = 0xFF313033;
	public static var inverseOnSurface:FlxColor     = 0xFFF4EFF4;
	public static var inversePrimary:FlxColor       = 0xFFD0BCFF;

	// -----------------------------------------------------------------------
	// Motion — M3 Easing tokens
	// https://m3.material.io/styles/motion/easing-and-duration/applying-easing-and-duration
	//
	// Emphasized       → on-screen transitions, soft landing (500 ms)
	// EmphasizedDec    → enter screen, begins at peak velocity (400 ms)
	// EmphasizedAcc    → exit screen permanently, ends at peak velocity (200 ms)
	// Standard         → small utility transitions (300 ms)
	// StandardDec      → enter small component (250 ms)
	// StandardAcc      → exit small component (200 ms)
	// -----------------------------------------------------------------------

	/** M3 Emphasized: expressive on-screen motion. Snappy start, very soft landing. */
	public static var emphasized:Float->Float           = FlxEase.expoOut;

	/** M3 Emphasized Decelerate: enters the screen at peak velocity then settles. */
	public static var emphasizedDecelerate:Float->Float = FlxEase.quintOut;

	/** M3 Emphasized Accelerate: exits the screen, starts slow then peaks. */
	public static var emphasizedAccelerate:Float->Float = FlxEase.quintIn;

	/** M3 Standard: compact utility transition. */
	public static var standard:Float->Float             = FlxEase.cubeInOut;

	/** M3 Standard Decelerate: small component entering. */
	public static var standardDecelerate:Float->Float   = FlxEase.cubeOut;

	/** M3 Standard Accelerate: small component exiting. */
	public static var standardAccelerate:Float->Float   = FlxEase.cubeIn;

	// -----------------------------------------------------------------------
	// Motion — M3 Duration tokens (seconds)
	// -----------------------------------------------------------------------
	/** Short 1: 50 ms */  public static inline var DUR_S1:Float = 0.050;
	/** Short 2: 100 ms */ public static inline var DUR_S2:Float = 0.100;
	/** Short 3: 150 ms */ public static inline var DUR_S3:Float = 0.150;
	/** Short 4: 200 ms */ public static inline var DUR_S4:Float = 0.200;
	/** Medium 1: 250 ms */public static inline var DUR_M1:Float = 0.250;
	/** Medium 2: 300 ms */public static inline var DUR_M2:Float = 0.300;
	/** Medium 3: 350 ms */public static inline var DUR_M3:Float = 0.350;
	/** Medium 4: 400 ms */public static inline var DUR_M4:Float = 0.400;
	/** Long 1: 450 ms */  public static inline var DUR_L1:Float = 0.450;
	/** Long 2: 500 ms */  public static inline var DUR_L2:Float = 0.500;

	// Convenience aliases for the most common M3 durations
	/** 500 ms — enter a full-screen element. */
	public static inline var DUR_ENTER:Float = DUR_L2;
	/** 200 ms — exit any element. */
	public static inline var DUR_EXIT:Float  = DUR_S4;

	// -----------------------------------------------------------------------
	// Predefined accent palettes
	// -----------------------------------------------------------------------

	/** Default Material purple. */
	public static inline var ACCENT_PURPLE:Int = 0xFF6750A4;
	/** Vibrant teal / cyan. */
	public static inline var ACCENT_TEAL:Int   = 0xFF006494;
	/** Warm coral / red. */
	public static inline var ACCENT_RED:Int    = 0xFFC00600;
	/** Green / nature. */
	public static inline var ACCENT_GREEN:Int  = 0xFF006E1C;
	/** Warm amber / orange. */
	public static inline var ACCENT_AMBER:Int  = 0xFF7B4F00;
	/** Deep indigo / navy. */
	public static inline var ACCENT_INDIGO:Int = 0xFF00305B;
	/** Rose / pink. */
	public static inline var ACCENT_PINK:Int   = 0xFF8C0044;

	// -----------------------------------------------------------------------
	// Listener / change-notification system
	// -----------------------------------------------------------------------
	static var _listeners:Array<Void->Void> = [];

	/**
	 * Register a callback that fires whenever the theme changes.
	 * Call from a component's constructor and remove in destroy().
	 */
	public static function addListener(fn:Void->Void):Void
	{
		if (!_listeners.contains(fn))
			_listeners.push(fn);
	}

	/** Remove a previously registered listener. */
	public static function removeListener(fn:Void->Void):Void
		_listeners.remove(fn);

	// -----------------------------------------------------------------------
	// Theme generation
	// -----------------------------------------------------------------------

	/**
	 * Generate a complete M3 light-scheme from a single source/accent color.
	 * All color roles are derived from the hue and saturation of `accentColor`.
	 * Notifies all registered component listeners so the UI updates immediately.
	 */
	public static function setAccent(accentColor:FlxColor):Void
	{
		var h:Float = accentColor.hue;
		// Ensure the source color is vivid enough to generate a usable palette
		var s:Float = Math.max(0.30, accentColor.saturation);

		// Primary palette
		primary            = colorFromHSL(h, s * 0.82, 0.40);
		onPrimary          = 0xFFFFFFFF;
		primaryContainer   = colorFromHSL(h, s * 0.48, 0.90);
		onPrimaryContainer = colorFromHSL(h, s * 0.95, 0.10);

		// Secondary — same hue family, lower chroma
		secondary            = colorFromHSL((h + 10) % 360, s * 0.30, 0.40);
		onSecondary          = 0xFFFFFFFF;
		secondaryContainer   = colorFromHSL((h + 10) % 360, s * 0.20, 0.88);
		onSecondaryContainer = colorFromHSL((h + 10) % 360, s * 0.55, 0.12);

		// Tertiary — offset hue (analogous / complementary)
		tertiary             = colorFromHSL((h + 60) % 360, s * 0.30, 0.43);
		onTertiary           = 0xFFFFFFFF;
		tertiaryContainer    = colorFromHSL((h + 60) % 360, s * 0.25, 0.88);
		onTertiaryContainer  = colorFromHSL((h + 60) % 360, s * 0.55, 0.12);

		// Neutral / surface — very low chroma, same hue
		surface              = colorFromHSL(h, s * 0.04, 0.98);
		onSurface            = colorFromHSL(h, s * 0.08, 0.11);
		surfaceVariant       = colorFromHSL(h, s * 0.14, 0.91);
		onSurfaceVariant     = colorFromHSL(h, s * 0.10, 0.31);
		background           = surface;
		onBackground         = onSurface;

		// Surface containers (elevation tiers)
		surfaceContainerLowest  = colorFromHSL(h, s * 0.02, 0.99);
		surfaceContainerLow     = colorFromHSL(h, s * 0.06, 0.96);
		surfaceContainer        = colorFromHSL(h, s * 0.09, 0.93);
		surfaceContainerHigh    = colorFromHSL(h, s * 0.12, 0.90);
		surfaceContainerHighest = colorFromHSL(h, s * 0.16, 0.87);

		// Outline
		outline              = colorFromHSL(h, s * 0.12, 0.50);
		outlineVariant       = colorFromHSL(h, s * 0.15, 0.80);

		// Inverse (dark panel on light background)
		inverseSurface       = colorFromHSL(h, s * 0.06, 0.19);
		inverseOnSurface     = colorFromHSL(h, s * 0.04, 0.95);
		inversePrimary       = colorFromHSL(h, s * 0.55, 0.80);

		// Notify all registered component listeners
		for (fn in _listeners) fn();
	}

	// -----------------------------------------------------------------------
	// Color utilities
	// -----------------------------------------------------------------------

	/**
	 * Build a FlxColor from HSL values.
	 * @param h  Hue 0 – 360
	 * @param s  Saturation 0 – 1
	 * @param l  Lightness 0 – 1
	 */
	public static function colorFromHSL(h:Float, s:Float, l:Float):FlxColor
	{
		s = Math.max(0.0, Math.min(1.0, s));
		l = Math.max(0.0, Math.min(1.0, l));

		var c:Float = (1.0 - Math.abs(2.0 * l - 1.0)) * s;
		var x:Float = c * (1.0 - Math.abs((h / 60.0) % 2.0 - 1.0));
		var m:Float = l - c / 2.0;
		var r:Float; var g:Float; var b:Float;

		if      (h < 60.0)  { r = c; g = x; b = 0.0; }
		else if (h < 120.0) { r = x; g = c; b = 0.0; }
		else if (h < 180.0) { r = 0.0; g = c; b = x; }
		else if (h < 240.0) { r = 0.0; g = x; b = c; }
		else if (h < 300.0) { r = x; g = 0.0; b = c; }
		else                { r = c; g = 0.0; b = x; }

		return FlxColor.fromRGB(
			Std.int((r + m) * 255),
			Std.int((g + m) * 255),
			Std.int((b + m) * 255)
		);
	}
}
