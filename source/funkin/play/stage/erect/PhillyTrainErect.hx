package funkin.play.stage.erect;

import funkin.play.stage.objects.*;
import funkin.play.character.Character;
import funkin.graphics.shaders.AdjustColorShader;

class PhillyTrainErect extends BaseStage
{
	var phillyLightsColors:Array<FlxColor>;
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:PhillyTrain;
	var curLight:Int = -1;
	var colorShader:AdjustColorShader;

	// Philly Glow support
	var blammedLightsBlack:FlxSprite;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;
	var phillyWindowEvent:BGSprite;
	var curLightEvent:Int = -1;

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

	override function eventPushed(event:funkin.play.notes.Note.EventNote)
	{
		switch(event.event)
		{
			case "Philly Glow":
				// Prepare overlay, window duplicate, gradient and particles similar to normal Philly stage
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlowGradient(-400, 225);
				phillyGlowGradient.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);
				if(!ClientPrefs.data.flashing) phillyGlowGradient.intendedAlpha = 0.7;

				Paths.image('philly/particle'); // precache philly glow particle image
				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
		}
	}

	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case 'Change Character':
				if(ClientPrefs.data.shaders && colorShader != null)
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

			case 'Philly Glow':
				if(flValue1 == null || flValue1 <= 0) flValue1 = 0;
				var lightId:Int = Math.round(flValue1);

				var chars:Array<Character> = [boyfriend, gf, dad];
				switch(lightId)
				{
					case 0: // turn off
						if(phillyGlowGradient != null && phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;
							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
							curLightEvent = -1;

							for(who in chars) who.color = FlxColor.WHITE;
							phillyStreet.color = FlxColor.WHITE;
						}

					case 1: // turn on
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if(phillyGlowGradient != null && !phillyGlowGradient.visible)
						{
							doFlash();
							if(ClientPrefs.data.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if(ClientPrefs.data.flashing)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;
							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;
						if(!ClientPrefs.data.flashing) charColor.saturation *= 0.5;
						else charColor.saturation *= 0.75;
						for(who in chars) who.color = charColor;

						if(phillyGlowParticles != null)
						{
							phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
							{
								particle.color = color;
							});
						}
						if(phillyGlowGradient != null) phillyGlowGradient.color = color;
						if(phillyWindowEvent != null) phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;

					case 2: // spawn particles
						if(phillyGlowParticles != null && phillyGlowGradient != null && !ClientPrefs.data.lowQuality)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];
							for(j in 0...3)
							{
								for(i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = phillyGlowParticles.recycle(PhillyGlowParticle);
									particle.x = -400 + width * i + FlxG.random.float(-width / 5, width / 5);
									particle.y = phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40);
									particle.color = color;
									particle.start();
									phillyGlowParticles.add(particle);
								}
							}
						}
						if(phillyGlowGradient != null) phillyGlowGradient.bop();
				}
		}
	}

	override function update(elapsed:Float)
	{
		phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.9;
		if(phillyGlowParticles != null)
		{
			phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle)
			{
				if(particle.alpha <= 0)
					particle.kill();
			});
		}
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

	// Pause and resume train sound when a substate is opened, as in P-Slice.
	override function openSubState(SubState:flixel.FlxSubState)
	{
		if(phillyTrain != null && phillyTrain.sound != null && phillyTrain.sound.playing)
		{
			phillyTrain.sound.pause();
			PlayState.instance.subStateClosed.addOnce(function(sub)
			{
				if(phillyTrain.sound != null) phillyTrain.sound.resume();
			});
		}
		super.openSubState(SubState);
	}

	function doFlash()
	{
		var color:FlxColor = FlxColor.WHITE;
		if(!ClientPrefs.data.flashing)
			color.alphaFloat = 0.5;

		FlxG.camera.flash(color, 0.15, null, true);
	}
}
