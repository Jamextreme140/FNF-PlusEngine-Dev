package states.stages.erect;

import states.stages.objects.*;
import shaders.AdjustColorShader;

class PhillyStreetsErect extends BaseStage
{
	var phillyCars:BGSprite;
	var darkenable:Array<FlxSprite> = [];
	var colorShader:AdjustColorShader;

	override function create()
	{
		if(!ClientPrefs.data.lowQuality)
		{
			var skyImage:String = 'phillyStreets/erect/phillySkybox';
			var scrollingSky:BGSprite = new BGSprite(skyImage, -650, -375, 0.1, 0.1);
			scrollingSky.scale.set(0.65, 0.65);
			add(scrollingSky);
			darkenable.push(scrollingSky);

			var phillySkyline:BGSprite = new BGSprite('phillyStreets/erect/phillySkyline', -545, -273, 0.2, 0.2);
			add(phillySkyline);
			darkenable.push(phillySkyline);

			var phillyForegroundCity:BGSprite = new BGSprite('phillyStreets/erect/phillyForegroundCity', 600, 69, 0.3, 0.3);
			add(phillyForegroundCity);
			darkenable.push(phillyForegroundCity);

			var phillyForegroundCity2:BGSprite = new BGSprite('phillyStreets/erect/phillyForegroundCity', 1860, 185, 0.3, 0.3);
			phillyForegroundCity2.angle = 5;
			add(phillyForegroundCity2);
			darkenable.push(phillyForegroundCity2);
		}

		var phillyConstruction:BGSprite = new BGSprite('phillyStreets/erect/phillyConstruction', 1795, 360, 0.7, 1);
		add(phillyConstruction);
		darkenable.push(phillyConstruction);

		var phillyHighwayLights:BGSprite = new BGSprite('phillyStreets/erect/phillyHighwayLights', 122, 201, 1, 1);
		add(phillyHighwayLights);
		darkenable.push(phillyHighwayLights);

		if(!ClientPrefs.data.lowQuality)
		{
			var phillyHighwayLightsLightmap:BGSprite = new BGSprite('phillyStreets/phillyHighwayLights_lightmap', 122, 201, 1, 1);
			phillyHighwayLightsLightmap.blend = ADD;
			phillyHighwayLightsLightmap.alpha = 0.6;
			add(phillyHighwayLightsLightmap);
			darkenable.push(phillyHighwayLightsLightmap);
		}

		var phillyHighway:BGSprite = new BGSprite('phillyStreets/erect/phillyHighway', 139, 209, 1, 1);
		add(phillyHighway);
		darkenable.push(phillyHighway);

		if(!ClientPrefs.data.lowQuality)
		{
			var phillySmog:BGSprite = new BGSprite('phillyStreets/phillySmog', -6, 245, 0.8, 1);
			add(phillySmog);
			darkenable.push(phillySmog);

			phillyCars = new BGSprite('phillyStreets/erect/phillyCars', 1200, 818, 0.9, 1, ['car1'], false);
			add(phillyCars);
			darkenable.push(phillyCars);
		}

		var phillyForeground:BGSprite = new BGSprite('phillyStreets/erect/phillyForeground', 88, 317, 1, 1);
		add(phillyForeground);
		darkenable.push(phillyForeground);

		var spraycanPile:BGSprite = new BGSprite('phillyStreets/erect/SpraycanPile', 920, 1045, 1, 1);
		add(spraycanPile);
		darkenable.push(spraycanPile);

		if(ClientPrefs.data.shaders)
		{
			colorShader = new AdjustColorShader();
			colorShader.hue = 0;
			colorShader.saturation = 0;
			colorShader.brightness = 0;
			colorShader.contrast = 0;
		}

		setDefaultGF('nene');
	}

	override function createPost()
	{
		super.createPost();
		if(ClientPrefs.data.shaders && colorShader != null)
		{
			dad.shader = colorShader;
			boyfriend.shader = colorShader;
			gf.shader = colorShader;
		}
	}

	override function beatHit()
	{
		super.beatHit();
		if(!ClientPrefs.data.lowQuality && phillyCars != null)
		{
			if(FlxG.random.bool(10))
				phillyCars.animation.play('car' + FlxG.random.int(1, 4), true);
		}
	}
}
