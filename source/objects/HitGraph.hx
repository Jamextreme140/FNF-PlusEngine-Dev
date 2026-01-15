package objects;

import flixel.FlxG;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextFieldAutoSize;
import openfl.text.TextFormat;
import flash.display.Graphics;
import flash.display.Shape;
import flash.display.Sprite;
import flash.text.TextField;
import flixel.util.FlxColor;

/**
 * Graph to display hit timing precision
 * Adapted from Kade Engine
 */
class HitGraph extends Sprite
{
	static inline var AXIS_COLOR:FlxColor = 0xffffff;
	static inline var AXIS_ALPHA:Float = 0.5;

	public var graphColor:FlxColor;
	public var history:Array<Dynamic> = [];
	public var bitmap:Bitmap;

	var _axis:Shape;
	var _width:Int;
	var _height:Int;

	public var minValue:Float = -200;
	public var maxValue:Float = 200;

	public function new(X:Int, Y:Int, Width:Int, Height:Int)
	{
		super();
		x = X;
		y = Y;
		_width = Width;
		_height = Height;

		var bm = new BitmapData(Width, Height, true, 0x00000000);
		bm.draw(this);
		bitmap = new Bitmap(bm);

		_axis = new Shape();
		_axis.x = 10;

		addChild(_axis);

		drawAxes();
	}

	function drawAxes():Void
	{
		var gfx = _axis.graphics;
		gfx.clear();
		gfx.lineStyle(1, AXIS_COLOR, AXIS_ALPHA);

		// y-Axis
		gfx.moveTo(0, 0);
		gfx.lineTo(0, _height);

		// x-Axis
		gfx.moveTo(0, _height);
		gfx.lineTo(_width, _height);

		// Center line
		gfx.moveTo(0, _height / 2);
		gfx.lineTo(_width, _height / 2);
	}

	public static function createTextField(X:Float = 0, Y:Float = 0, Color:FlxColor = FlxColor.WHITE, Size:Int = 12):TextField
	{
		var tf = new TextField();
		tf.x = X;
		tf.y = Y;
		tf.multiline = false;
		tf.wordWrap = false;
		tf.embedFonts = true;
		tf.selectable = false;
		tf.defaultTextFormat = new TextFormat("VCR OSD Mono", Size, Color.to24Bit());
		tf.alpha = Color.alphaFloat;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}

	function drawJudgementLine(ms:Float, color:FlxColor):Void
	{
		var gfx:Graphics = graphics;
		gfx.lineStyle(1, color, 0.3);

		// Match NovaFlare's formula: Y = height/2 + (height/2) * (ms / maxValue)
		// Positive ms (late) goes down, negative ms (early) goes up
		var pointY = _axis.y + (_height / 2) + (_height / 2) * (ms / maxValue);
		var graphX = _axis.x + 1;

		gfx.drawRect(graphX, pointY, _width - 12, 1);
	}

	public function addToHistory(ms:Float, judge:String, songTime:Float):Void
	{
		history.push([ms, judge, songTime]);
	}

	public function update():Void
	{
		drawGraph();
	}

	function drawGraph():Void
	{
		var gfx:Graphics = graphics;
		gfx.clear();

		// Draw judgment lines
		drawJudgementLine(45, 0x00FF00);   // Sick threshold
		drawJudgementLine(90, 0xFFFF00);   // Good threshold
		drawJudgementLine(135, 0xFF0000);  // Bad threshold
		drawJudgementLine(-45, 0x00FF00);  // Sick threshold (early)
		drawJudgementLine(-90, 0xFFFF00);  // Good threshold (early)
		drawJudgementLine(-135, 0xFF0000); // Bad threshold (early)

		var range:Float = Math.max(maxValue - minValue, maxValue * 0.1);
		var graphX = _axis.x + 1;

		// Draw hit points
		for (i in 0...history.length)
		{
			var ms = history[i][0];
			var judge = history[i][1];
			var songTime = history[i][2];

			switch (judge)
			{
				case "sick":
					gfx.beginFill(0x00FFFF);
				case "good":
					gfx.beginFill(0x00FF00);
				case "bad":
					gfx.beginFill(0xFF0000);
				case "shit":
					gfx.beginFill(0x8b0000);
				case "miss":
					gfx.beginFill(0x580000);
				default:
					gfx.beginFill(0xFFFFFF);
			}

			// Match NovaFlare's formula: Y = height/2 + (height/2) * 0.8 * (ms / maxValue)
			// The 0.8 factor (MoveSize) prevents hits from reaching graph edges
			// Positive ms (late) goes down, negative ms (early) goes up
			var moveSize = 0.8;
			var pointY = (_height / 2) + (_height / 2) * moveSize * (ms / maxValue);
			var pointX = fitX(songTime);
			
			gfx.drawRect(pointX, pointY, 4, 4);
			gfx.endFill();
		}

		var bm = new BitmapData(_width, _height, true, 0x00000000);
		bm.draw(this);
		bitmap = new Bitmap(bm);
	}

	public function fitX(songTime:Float):Float
	{
		// Fit song time to graph width
		if (history.length == 0) return _axis.x + 1;
		
		var firstTime = history[0][2];
		var lastTime = history[history.length - 1][2];
		var timeRange = lastTime - firstTime;
		
		if (timeRange == 0) return _axis.x + 1;
		
		var normalizedTime = (songTime - firstTime) / timeRange;
		return _axis.x + 1 + (normalizedTime * (_width - 12));
	}
}
