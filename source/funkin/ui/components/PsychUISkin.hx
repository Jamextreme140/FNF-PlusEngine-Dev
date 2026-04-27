package funkin.ui.components;

import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.options.OptionsMenuTheme;

class PsychUISkin
{
	public static inline var PANEL_RADIUS:Float = 18;
	public static inline var TAB_RADIUS:Float = 14;
	public static inline var CONTROL_RADIUS:Float = 12;
	public static inline var SMALL_RADIUS:Float = 9;
	public static inline var PILL_RADIUS:Float = 999;

	public static inline function signature():String
	{
		return OptionsMenuTheme.signature();
	}

	public static inline function textPrimary():Int
	{
		return OptionsMenuTheme.titleColor();
	}

	public static inline function textSecondary():Int
	{
		return OptionsMenuTheme.bodyTextColor();
	}

	public static inline function textTertiary():Int
	{
		return OptionsMenuTheme.footerTextColor();
	}

	public static inline function accent():Int
	{
		return OptionsMenuTheme.current().accent;
	}

	public static inline function accentSoft():Int
	{
		return OptionsMenuTheme.cardAccent(false);
	}

	public static inline function accentOverlay(alpha:Float):Int
	{
		return OptionsMenuTheme.accentOverlay(alpha);
	}

	public static inline function neutralStroke():Int
	{
		return OptionsMenuTheme.neutralOutlineColor();
	}

	public static inline function panelStyle()
	{
		return {
			bgColor: OptionsMenuTheme.panelSurfaceColor(),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: OptionsMenuTheme.panelOutlineColor(),
			radius: PANEL_RADIUS
		};
	}

	public static inline function tabSelectedStyle()
	{
		return {
			bgColor: OptionsMenuTheme.cardFill(true),
			textColor: OptionsMenuTheme.cardTitleColor(true),
			bgAlpha: 1.0,
			strokeColor: OptionsMenuTheme.cardStroke(true),
			radius: TAB_RADIUS
		};
	}

	public static inline function tabHoverStyle()
	{
		return {
			bgColor: blend(OptionsMenuTheme.cardFill(false), accent(), OptionsMenuTheme.isDark() ? 0.12 : 0.09),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: accentSoft(),
			radius: TAB_RADIUS
		};
	}

	public static inline function tabIdleStyle()
	{
		return {
			bgColor: blend(OptionsMenuTheme.panelHeaderColor(), accent(), OptionsMenuTheme.isDark() ? 0.05 : 0.035),
			textColor: textSecondary(),
			bgAlpha: 1.0,
			strokeColor: neutralStroke(),
			radius: TAB_RADIUS
		};
	}

	public static inline function buttonNormalStyle()
	{
		return {
			bgColor: OptionsMenuTheme.cardFill(false),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: neutralStroke(),
			radius: CONTROL_RADIUS
		};
	}

	public static inline function buttonHoverStyle()
	{
		return {
			bgColor: blend(OptionsMenuTheme.cardFill(false), accent(), OptionsMenuTheme.isDark() ? 0.14 : 0.1),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: accentSoft(),
			radius: CONTROL_RADIUS
		};
	}

	public static inline function buttonPressedStyle()
	{
		return {
			bgColor: accent(),
			textColor: contrastText(accent()),
			bgAlpha: 1.0,
			strokeColor: accent(),
			radius: CONTROL_RADIUS
		};
	}

	public static inline function dropdownItemNormalStyle()
	{
		return {
			bgColor: OptionsMenuTheme.previewSurfaceColor(),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: neutralStroke(),
			radius: SMALL_RADIUS
		};
	}

	public static inline function dropdownItemHoverStyle()
	{
		return {
			bgColor: blend(OptionsMenuTheme.previewSurfaceColor(), accent(), OptionsMenuTheme.isDark() ? 0.18 : 0.12),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: accentSoft(),
			radius: SMALL_RADIUS
		};
	}

	public static inline function inputOuterStyle(focused:Bool, hovered:Bool)
	{
		var tintAmount:Float = focused
			? (OptionsMenuTheme.isDark() ? 0.32 : 0.22)
			: (hovered ? (OptionsMenuTheme.isDark() ? 0.18 : 0.13) : (OptionsMenuTheme.isDark() ? 0.11 : 0.08));

		return {
			bgColor: blend(OptionsMenuTheme.panelHeaderColor(), accent(), tintAmount),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: focused ? accent() : (hovered ? accentSoft() : blend(neutralStroke(), accent(), 0.28)),
			radius: CONTROL_RADIUS
		};
	}

	public static inline function inputInnerColor(focused:Bool):Int
	{
		return focused
			? blend(OptionsMenuTheme.previewSurfaceColor(), accent(), OptionsMenuTheme.isDark() ? 0.24 : 0.18)
			: blend(OptionsMenuTheme.previewSurfaceColor(), accent(), OptionsMenuTheme.isDark() ? 0.16 : 0.12);
	}

	public static inline function inputInnerStrokeColor(focused:Bool, hovered:Bool):Int
	{
		return focused ? accentSoft() : (hovered ? blend(accentSoft(), accent(), 0.45) : blend(neutralStroke(), accent(), 0.32));
	}

	public static inline function inputSelectionColor():Int
	{
		return withAlpha(accent(), OptionsMenuTheme.isDark() ? 0.34 : 0.24);
	}

	public static inline function inputSelectedTextColor():Int
	{
		return textPrimary();
	}

	public static inline function inputCaretColor():Int
	{
		return accent();
	}

	public static inline function sliderTrackColor():Int
	{
		return blend(OptionsMenuTheme.previewSurfaceColor(), accent(), OptionsMenuTheme.isDark() ? 0.08 : 0.04);
	}

	public static inline function sliderFillColor():Int
	{
		return accent();
	}

	public static inline function sliderHandleColor():Int
	{
		return accent();
	}

	public static inline function navButtonStyle(pressed:Bool, enabled:Bool = true)
	{
		if (!enabled)
		{
			return {
				bgColor: blend(OptionsMenuTheme.cardFill(false), neutralStroke(), 0.12),
				textColor: textTertiary(),
				bgAlpha: 1.0,
				strokeColor: neutralStroke(),
				radius: SMALL_RADIUS
			};
		}

		return pressed ? buttonPressedStyle() : buttonNormalStyle();
	}

	public static inline function toggleStyle(checked:Bool, hovered:Bool)
	{
		if (checked)
		{
			return {
				bgColor: accent(),
				textColor: contrastText(accent()),
				bgAlpha: 1.0,
				strokeColor: accent(),
				radius: SMALL_RADIUS
			};
		}

		return {
			bgColor: hovered ? blend(OptionsMenuTheme.previewSurfaceColor(), accent(), OptionsMenuTheme.isDark() ? 0.14 : 0.09) : OptionsMenuTheme.previewSurfaceColor(),
			textColor: textPrimary(),
			bgAlpha: 1.0,
			strokeColor: hovered ? accentSoft() : neutralStroke(),
			radius: SMALL_RADIUS
		};
	}

	public static function drawStyledRect(sprite:FlxSprite, width:Int, height:Int, style:Dynamic):Void
	{
		if (sprite == null)
			return;

		width = Std.int(Math.max(1, width));
		height = Std.int(Math.max(1, height));

		var bgColor:Int = getInt(style, "bgColor", FlxColor.WHITE);
		var bgAlpha:Float = getFloat(style, "bgAlpha", 1.0);
		var strokeColor:Int = getInt(style, "strokeColor", FlxColor.TRANSPARENT);
		var radius:Float = getFloat(style, "radius", CONTROL_RADIUS);
		var fillColor:Int = withAlpha(bgColor, bgAlpha);

		if (((strokeColor >> 24) & 0xFF) == 0)
			MD3ShapeTools.fillRoundRect(sprite, width, height, radius, fillColor);
		else
			MD3ShapeTools.fillAndStrokeRoundRect(sprite, width, height, radius, 1, fillColor, strokeColor);
	}

	public static inline function withAlpha(color:Int, alpha:Float):Int
	{
		var a:Int = Std.int(Math.max(0, Math.min(1, alpha)) * 255);
		return (a << 24) | (color & 0x00FFFFFF);
	}

	public static inline function blend(base:Int, tint:Int, amount:Float):Int
	{
		return FlxColor.interpolate(base, tint, Math.max(0, Math.min(1, amount)));
	}

	public static function contrastText(color:Int):Int
	{
		var red:Float = (color >> 16) & 0xFF;
		var green:Float = (color >> 8) & 0xFF;
		var blue:Float = color & 0xFF;
		var luminance:Float = (red * 0.299) + (green * 0.587) + (blue * 0.114);
		return luminance >= 160 ? 0xFF111317 : FlxColor.WHITE;
	}

	static inline function getInt(style:Dynamic, field:String, fallback:Int):Int
	{
		var value:Dynamic = Reflect.field(style, field);
		return value == null ? fallback : Std.int(value);
	}

	static inline function getFloat(style:Dynamic, field:String, fallback:Float):Float
	{
		var value:Dynamic = Reflect.field(style, field);
		return value == null ? fallback : value;
	}
}