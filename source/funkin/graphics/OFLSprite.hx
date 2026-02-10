package funkin.graphics;

import flixel.util.FlxColor;
import openfl.display.Sprite;
import flixel.FlxSprite;

/**
 * Designed to draw an OpenFL Sprite as a FlxSprite
 * Allows layering and auto sizing for HaxeFlixel cameras
 * Adapted from Kade Engine
 */
class OFLSprite extends FlxSprite
{
	public var flSprite:Sprite;

	public function new(x:Float, y:Float, width:Int, height:Int, sprite:Sprite)
	{
		super(x, y);

		makeGraphic(width, height, FlxColor.TRANSPARENT);

		flSprite = sprite;
		pixels.draw(flSprite);
	}

	private var _frameCount:Int = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (_frameCount < 2)
		{
			pixels.draw(flSprite);
			_frameCount++;
		}
	}

	public function updateDisplay():Void
	{
		pixels.draw(flSprite);
	}
}
