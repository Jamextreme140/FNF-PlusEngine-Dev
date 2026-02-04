package funkin.play.stage.erect;

import funkin.play.stage.objects.*;
import funkin.play.character.Character;
import funkin.graphics.shaders.AdjustColorShader;
	
class MainStageErect extends BaseStage
{
	var peeps:BGSprite;
	
	override function create()
	{
		var bg:BGSprite = new BGSprite(null, -500, -1000);
		bg.makeGraphic(2400, 2000, 0xFF222026);
		add(bg);

		if(!ClientPrefs.data.lowQuality)
		{
			peeps = new BGSprite('erect/crowd', 682, 290, 0.8, 0.8, ['idle'], true);
			peeps.animation.curAnim.frameRate = 12;
			add(peeps);

			var lightSmol:BGSprite = new BGSprite('erect/brightLightSmall', 967, -103, 1.2, 1.2);
			lightSmol.blend = ADD;
			add(lightSmol);
		}

		var stageFront:BGSprite = new BGSprite('erect/bg', -765, -247);
		add(stageFront);

		var server:BGSprite = new BGSprite('erect/server', -991, 205);
		add(server);

		if(!ClientPrefs.data.lowQuality)
		{
			var greenLight:BGSprite = new BGSprite('erect/lightgreen', -171, 242);
			greenLight.blend = ADD;
			add(greenLight);

			var redLight:BGSprite = new BGSprite('erect/lightred', -101, 560);
			redLight.blend = ADD;
			add(redLight);

			var orangeLight:BGSprite = new BGSprite('erect/orangeLight', 189, -500);
			orangeLight.blend = ADD;
			add(orangeLight);
		}

		var beamLol:BGSprite = new BGSprite('erect/lights', -847, -245, 1.2, 1.2);
		add(beamLol);

		if(!ClientPrefs.data.lowQuality)
		{
			var TheOneAbove:BGSprite = new BGSprite('erect/lightAbove', 804, -117);
			TheOneAbove.blend = ADD;
			add(TheOneAbove);
		}
	}

	override function createPost()
	{
		super.createPost();
		if(ClientPrefs.data.shaders)
		{
			gf.shader = makeCoolShader(-9, 0, -30, -4);
			dad.shader = makeCoolShader(-32, 0, -33, -23);
			boyfriend.shader = makeCoolShader(12, 0, -23, 7);
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if(!ClientPrefs.data.lowQuality && peeps != null)
		{
			peeps.dance(true);
		}
	}

	// Generic event handler for playing animations on stage or characters
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case 'Play Animation':
				var target:String = value2.toLowerCase().trim();
				switch(target)
				{
					case 'peeps' | 'crowd':
						if(peeps != null)
						{
							peeps.animation.play(value1, true);
						}
					case 'bf' | 'boyfriend' | '0':
						boyfriend.playAnim(value1, true);
						boyfriend.specialAnim = true;
					case 'gf' | 'girlfriend' | '2':
						if(gf != null)
						{
							gf.playAnim(value1, true);
							gf.specialAnim = true;
						}
					default: // dad/opponent or unspecified
						dad.playAnim(value1, true);
						dad.specialAnim = true;
				}
		}
	}

	function makeCoolShader(hue:Float, sat:Float, bright:Float, contrast:Float):AdjustColorShader
	{
		var coolShader:AdjustColorShader = new AdjustColorShader();
		coolShader.hue = hue;
		coolShader.saturation = sat;
		coolShader.brightness = bright;
		coolShader.contrast = contrast;
		return coolShader;
	}
}
