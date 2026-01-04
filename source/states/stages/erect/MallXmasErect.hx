package states.stages.erect;

import states.stages.objects.*;
import shaders.AdjustColorShader;

class MallXmasErect extends BaseStage
{
	var upperBoppers:BGSprite;
	var bottomBoppers:MallCrowd;
	var santa:BGSprite;

	override function create()
	{
		var bg:BGSprite = new BGSprite('christmas/erect/bgWalls', -726, -566, 0.2, 0.2);
		bg.setGraphicSize(Std.int(bg.width * 0.9));
		bg.updateHitbox();
		add(bg);

		if(!ClientPrefs.data.lowQuality)
		{
			upperBoppers = new BGSprite('christmas/erect/upperBop', -374, -98, 0.28, 0.28, ['upperBop']);
			upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
			upperBoppers.updateHitbox();
			add(upperBoppers);

			var bgEscalator:BGSprite = new BGSprite('christmas/erect/bgEscalator', -909, -204, 0.3, 0.3);
			bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
			bgEscalator.updateHitbox();
			add(bgEscalator);
		}

		var tree:BGSprite = new BGSprite('christmas/erect/christmasTree', 370, -250, 0.40, 0.40);
		add(tree);

		var fog:BGSprite = new BGSprite('christmas/erect/white', -1000, 100, 0.85, 0.85);
		fog.scale.set(0.9, 0.9);
		add(fog);

		bottomBoppers = new MallCrowd(-300, 140, 'christmas/erect/bottomBop', 'bottomBop');
		add(bottomBoppers);

		var fgSnow:BGSprite = new BGSprite('christmas/erect/fgSnow', -880, 700);
		add(fgSnow);

		santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
		add(santa);
		
		setDefaultGF('gf-christmas');
	}

	override function createPost()
	{
		super.createPost();
		if(ClientPrefs.data.shaders)
		{
			var colorShader:AdjustColorShader = new AdjustColorShader();
			colorShader.hue = 5;
			colorShader.saturation = 20;

			boyfriend.shader = colorShader;
			gf.shader = colorShader;
			dad.shader = colorShader;
			santa.shader = colorShader;
		}
	}

	override function countdownTick(count:Countdown, num:Int) everyoneDance();
	override function beatHit()
	{
		super.beatHit();
		everyoneDance();
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case 'Hey!':
				switch(value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						return;
				}
				bottomBoppers.animation.play('hey', true);
				bottomBoppers.heyTimer = flValue2;
		}
	}

	function everyoneDance():Void
	{
		if(!ClientPrefs.data.lowQuality)
			upperBoppers.dance(true);

		bottomBoppers.dance(true);
		santa.dance(true);
	}
}
