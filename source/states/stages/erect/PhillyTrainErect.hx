package states.stages.erect;

import states.stages.objects.*;
import objects.Character;
import shaders.AdjustColorShader;

class PhillyTrainErect extends BaseStage
{
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;
	var colorShader:AdjustColorShader;

	override function create()
	{
		if(!ClientPrefs.data.lowQuality)
		{
			var bg:BGSprite = new BGSprite('philly/erect/sky', -50, 0, 0.1, 0.1);
			add(bg);
		}

		var city:BGSprite = new BGSprite('philly/erect/city', -255, 45, 0.3, 0.3);
		city.setGraphicSize(Std.int(city.width * 0.85));
		city.updateHitbox();
		add(city);

		phillyLightsColors = [0x502d64, 0x2663ac, 0x932c28, 0x329a6d, 0xb66f43];
		phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
		phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
		phillyWindow.updateHitbox();
		add(phillyWindow);
		phillyWindow.alpha = 0;

		if(!ClientPrefs.data.lowQuality)
		{
			var streetBehind:BGSprite = new BGSprite('philly/erect/behindTrain', 178, 148);
			add(streetBehind);
		}

		phillyTrain = new PhillyTrain(2000, 360);
		add(phillyTrain);

		phillyStreet = new BGSprite('philly/erect/street', -299, 144);
		add(phillyStreet);

		if(ClientPrefs.data.shaders)
		{
			colorShader = new AdjustColorShader();
			colorShader.hue = -26;
			colorShader.saturation = -16;
			colorShader.contrast = 0;
			colorShader.brightness = -5;
		}
	}

	override function createPost()
	{
		super.createPost();

		if(ClientPrefs.data.shaders && colorShader != null)
		{
			boyfriend.shader = colorShader;
			dad.shader = colorShader;
			gf.shader = colorShader;
			phillyTrain.shader = colorShader;
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		if(eventName == 'Change Character' && ClientPrefs.data.shaders && colorShader != null)
		{
			switch(value1.toLowerCase().trim())
			{
				case 'gf' | 'girlfriend' | '2':
					gf.shader = colorShader;
				case 'dad' | 'opponent' | '1':
					dad.shader = colorShader;
				default:
					boyfriend.shader = colorShader;
			}
		}
	}

	override function update(elapsed:Float)
	{
		phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.9;
		super.update(elapsed);
	}

	override function beatHit()
	{
		phillyTrain.beatHit(curBeat);
		if(curBeat % 4 == 0)
		{
			curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
			phillyWindow.color = phillyLightsColors[curLight];
			phillyWindow.alpha = 1;
		}
	}
}
