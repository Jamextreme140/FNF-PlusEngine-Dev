package funkin.ui.components.md3;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.display.CapsStyle;
import openfl.display.JointStyle;
import openfl.display.Shape;

/**
 * Material-inspired progress indicator with a soft animated wave.
 * Supports linear and circular variants in determinate and indeterminate modes.
 */
class MaterialWavyProgressIndicator extends FlxSpriteGroup
{
	static inline var TAU:Float = 6.283185307179586;

	public var value(default, set):Float = 0;
	public var indeterminate(default, set):Bool = false;
	public var indicatorType:WavyProgressType = LINEAR;
	public var indicatorExtent:Float = 240;
	public var animationSpeed:Float = 2.6;
	public var waveUsesGradient(default, null):Bool = false;

	var linearTrack:FlxSprite;
	var linearWave:FlxSprite;
	var circularTrack:FlxSprite;
	var circularWave:FlxSprite;
	var trackColor:FlxColor = 0x00000000;
	var waveStartColor:FlxColor = 0x00000000;
	var waveEndColor:FlxColor = 0x00000000;
	var useThemeTrackColor:Bool = true;
	var useThemeWaveColor:Bool = true;

	var phase:Float = 0;
	var sweepPhase:Float = 0;
	var redrawAccumulator:Float = 0;

	static inline var REDRAW_INTERVAL:Float = 1 / 30;

	inline function linearHeight():Int return MD3Metrics.size(8);
	inline function linearCorner():Int return MD3Metrics.corner(4, indicatorExtent, linearHeight());
	inline function circularSize():Int return Std.int(indicatorExtent > 0 ? indicatorExtent : MD3Metrics.size(56));
	inline function circularThickness():Float return MD3Metrics.size(6);

	public function new(x:Float = 0, y:Float = 0, ?indicatorType:WavyProgressType = LINEAR, ?extent:Float = 240)
	{
		super(x, y);

		this.indicatorType = indicatorType;
		this.indicatorExtent = extent;

		switch (indicatorType)
		{
			case LINEAR:
				buildLinear();
			case CIRCULAR:
				buildCircular();
		}

		MD3Theme.addListener(_onThemeChange);
		applyResolvedColors();
		redrawDynamic();
	}

	public function setWaveColor(color:FlxColor):Void
	{
		useThemeWaveColor = false;
		waveUsesGradient = false;
		waveStartColor = color;
		waveEndColor = color;
		redrawDynamic();
	}

	public function setWaveGradient(startColor:FlxColor, endColor:FlxColor):Void
	{
		useThemeWaveColor = false;
		waveUsesGradient = true;
		waveStartColor = startColor;
		waveEndColor = endColor;
		redrawDynamic();
	}

	public function setTrackColor(color:FlxColor):Void
	{
		useThemeTrackColor = false;
		trackColor = color;
		applyResolvedColors();
		redrawDynamic();
	}

	public function resetThemeColors():Void
	{
		useThemeTrackColor = true;
		useThemeWaveColor = true;
		waveUsesGradient = false;
		applyResolvedColors();
		redrawDynamic();
	}

	public function getIndicatorHeight():Float
	{
		return indicatorType == LINEAR ? linearHeight() : circularSize();
	}

	function buildLinear():Void
	{
		var width = Std.int(indicatorExtent);
		var height = linearHeight();

		linearTrack = new FlxSprite(0, 0);
		linearTrack.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(linearTrack, width, height, linearCorner());
		linearTrack.color = MD3Theme.surfaceVariant;
		add(linearTrack);

		linearWave = new FlxSprite(0, 0);
		linearWave.antialiasing = ClientPrefs.data.antialiasing;
		linearWave.makeGraphic(width, height, FlxColor.TRANSPARENT, true);
		add(linearWave);
	}

	function buildCircular():Void
	{
		var size = circularSize();

		circularTrack = new FlxSprite(0, 0);
		circularTrack.antialiasing = ClientPrefs.data.antialiasing;
		circularTrack.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		add(circularTrack);

		circularWave = new FlxSprite(0, 0);
		circularWave.antialiasing = ClientPrefs.data.antialiasing;
		circularWave.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		add(circularWave);

		drawCircularTrack();
	}

	function set_value(nextValue:Float):Float
	{
		value = FlxMath.bound(nextValue, 0, 1);
		redrawDynamic();
		return value;
	}

	function set_indeterminate(nextValue:Bool):Bool
	{
		indeterminate = nextValue;
		redrawDynamic();
		return indeterminate;
	}

	function _onThemeChange():Void
	{
		applyResolvedColors();
		redrawDynamic();
	}

	function applyResolvedColors():Void
	{
		if (useThemeTrackColor)
			trackColor = MD3Theme.surfaceVariant;

		if (useThemeWaveColor)
		{
			waveStartColor = MD3Theme.primary;
			waveEndColor = MD3Theme.primary;
			waveUsesGradient = false;
		}

		if (linearTrack != null)
		{
			linearTrack.color = stripAlpha(trackColor);
			linearTrack.alpha = colorAlpha(trackColor);
		}

		if (circularTrack != null)
			drawCircularTrack();
	}

	inline function stripAlpha(color:FlxColor):FlxColor
	{
		return color & 0x00FFFFFF;
	}

	inline function colorAlpha(color:FlxColor):Float
	{
		return ((color >> 24) & 0xFF) / 255;
	}

	inline function resolveWaveColor(t:Float):FlxColor
	{
		return waveUsesGradient ? FlxColor.interpolate(waveStartColor, waveEndColor, FlxMath.bound(t, 0, 1)) : waveStartColor;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!visible || alpha <= 0) return;

		phase += elapsed * animationSpeed * TAU;
		sweepPhase += elapsed * 1.15;
		if (phase > TAU) phase -= TAU;
		if (sweepPhase > 1000) sweepPhase = 0;
		redrawAccumulator += elapsed;
		if (redrawAccumulator < REDRAW_INTERVAL) return;
		redrawAccumulator = 0;

		redrawDynamic();
	}

	function redrawDynamic():Void
	{
		switch (indicatorType)
		{
			case LINEAR:
				drawLinearWave();
			case CIRCULAR:
				drawCircularWave();
		}
	}

	function drawLinearWave():Void
	{
		if (linearWave == null) return;

		var bitmap = linearWave.pixels;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var width = indicatorExtent;
		var height = linearHeight();
		var stroke = height * 0.72;
		var centerY = height * 0.5;
		var amplitude = Math.max(1.0, height * 0.18);
		var waveLength = Math.max(MD3Metrics.size(36), height * 3.0);
		var availableWidth = Math.max(0.0, width - stroke);

		var startOffset = 0.0;
		var endOffset = availableWidth * value;
		if (indeterminate)
		{
			var segmentWidth = availableWidth * 0.34;
			var travel = availableWidth + segmentWidth;
			var segmentT = (sweepPhase % 1.1) / 1.1;
			var head = segmentT * travel - segmentWidth;
			startOffset = Math.max(0.0, head);
			endOffset = Math.min(availableWidth, head + segmentWidth);
		}

		var startX = stroke * 0.5 + startOffset;
		var endX = stroke * 0.5 + endOffset;
		if (endX - startX <= 0.5)
		{
			linearWave.dirty = true;
			return;
		}

		var shape = new Shape();
		var graphics = shape.graphics;
		var steps = Std.int(Math.max(16, Math.ceil((endX - startX) / 4.0)));
		var previousX:Null<Float> = null;
		var previousY:Null<Float> = null;

		for (i in 0...steps + 1)
		{
			var t = i / steps;
			var px = FlxMath.lerp(startX, endX, t);
			var py = centerY + Math.sin((px / waveLength) * TAU + phase) * amplitude;
			if (previousX != null && previousY != null)
			{
				var color = resolveWaveColor((i - 0.5) / steps);
				graphics.lineStyle(stroke, stripAlpha(color), colorAlpha(color), false, null, ROUND, ROUND);
				graphics.moveTo(previousX, previousY);
				graphics.lineTo(px, py);
			}
			previousX = px;
			previousY = py;
		}

		bitmap.draw(shape);
		linearWave.dirty = true;
	}

	function drawCircularTrack():Void
	{
		if (circularTrack == null) return;

		var bitmap = circularTrack.pixels;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var size = circularSize();
		var thickness = circularThickness();
		var radius = (size - thickness) * 0.5 - 1;
		var center = size * 0.5;

		var shape = new Shape();
		shape.graphics.lineStyle(thickness, stripAlpha(trackColor), colorAlpha(trackColor), false, null, ROUND, ROUND);
		shape.graphics.drawCircle(center, center, radius);

		bitmap.draw(shape);
		circularTrack.dirty = true;
	}

	function drawCircularWave():Void
	{
		if (circularWave == null) return;

		var bitmap = circularWave.pixels;
		bitmap.fillRect(bitmap.rect, FlxColor.TRANSPARENT);

		var size = circularSize();
		var thickness = circularThickness();
		var center = size * 0.5;
		var baseRadius = (size - thickness) * 0.5 - 1;
		var amplitude = Math.max(1.0, thickness * 0.35);
		var waveTurns = 6.0;

		var startAngle = -Math.PI / 2;
		var sweep = TAU * value;
		if (indeterminate)
		{
			startAngle += sweepPhase * 2.4;
			var pulse = (Math.sin(sweepPhase * 1.9) + 1) * 0.5;
			sweep = TAU * FlxMath.lerp(0.18, 0.34, pulse);
		}

		if (sweep <= 0.01)
		{
			circularWave.dirty = true;
			return;
		}

		var shape = new Shape();
		var graphics = shape.graphics;

		var steps = Std.int(Math.max(36, Math.ceil((sweep * baseRadius) / 3.0)));
		var previousX:Null<Float> = null;
		var previousY:Null<Float> = null;
		for (i in 0...steps + 1)
		{
			var t = i / steps;
			var angle = startAngle + sweep * t;
			var radius = baseRadius + Math.sin(angle * waveTurns + phase) * amplitude;
			var px = center + Math.cos(angle) * radius;
			var py = center + Math.sin(angle) * radius;
			if (previousX != null && previousY != null)
			{
				var color = resolveWaveColor((i - 0.5) / steps);
				graphics.lineStyle(thickness, stripAlpha(color), colorAlpha(color), false, null, ROUND, ROUND);
				graphics.moveTo(previousX, previousY);
				graphics.lineTo(px, py);
			}
			previousX = px;
			previousY = py;
		}

		bitmap.draw(shape);
		circularWave.dirty = true;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		super.destroy();
	}
}

enum WavyProgressType
{
	LINEAR;
	CIRCULAR;
}