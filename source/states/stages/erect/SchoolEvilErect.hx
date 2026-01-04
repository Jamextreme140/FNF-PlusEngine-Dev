package states.stages.erect;

import flixel.addons.effects.FlxTrail;
import shaders.WiggleEffect;
import shaders.WiggleEffect.WiggleEffectType;
import cutscenes.DialogueBox;
import cutscenes.DialogueBoxPsych;
import cutscenes.DialogueBoxPsych.DialogueFile;

class SchoolEvilErect extends BaseStage
{
	var bgGhouls:BGSprite;
	var wiggleShit:WiggleEffect;

	override function create()
	{
		var posX:Int = 400;
		var posY:Int = 200;
		
		if(!ClientPrefs.data.lowQuality)
		{
			var bg:BGSprite = new BGSprite('weeb/erect/evil/weebBackSpikes', posX - 1062, posY - 260, 0.5, 0.5);
			bg.setGraphicSize(Std.int(bg.width * PlayState.daPixelZoom));
			bg.updateHitbox();
			bg.antialiasing = false;
			add(bg);
		}

		var school:BGSprite = new BGSprite('weeb/erect/evil/weebSchool', posX - 1216, posY - 238, 0.75, 0.75);
		school.setGraphicSize(Std.int(school.width * PlayState.daPixelZoom));
		school.updateHitbox();
		school.antialiasing = false;
		add(school);

		var spike:BGSprite = new BGSprite('weeb/erect/evil/backSpike', posX + 1016, posY + 264, 0.85, 0.85);
		spike.setGraphicSize(Std.int(spike.width * PlayState.daPixelZoom));
		spike.updateHitbox();
		spike.antialiasing = false;
		add(spike);

		var blackBg:BGSprite = new BGSprite(null, -500, 660);
		blackBg.makeGraphic(2400, 2000, FlxColor.BLACK);
		add(blackBg);

		var street:BGSprite = new BGSprite('weeb/erect/evil/weebStreet', posX - 1062, posY + 6);
		street.setGraphicSize(Std.int(street.width * PlayState.daPixelZoom));
		street.updateHitbox();
		street.antialiasing = false;
		add(street);

		if(ClientPrefs.data.shaders)
		{
			wiggleShit = new WiggleEffect();
			wiggleShit.effectType = WiggleEffectType.DREAMY;
			wiggleShit.waveAmplitude = 0.01;
			wiggleShit.waveFrequency = 60;
			wiggleShit.waveSpeed = 0.8;
		}

		setDefaultGF('gf-pixel');

		// Dialogue starts
		if(isStoryMode && !seenCutscene)
		{
			initDoof();
		}
	}

	override function createPost()
	{
		var trail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
		addBehindDad(trail);

		if(ClientPrefs.data.shaders && wiggleShit != null)
		{
			dad.shader = wiggleShit.shader;
		}
	}

	var doof:DialogueBox = null;
	function initDoof()
	{
		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		#if MODS_ALLOWED
		if(!FileSystem.exists(file))
		#else
		if(!Assets.exists(file))
		#end
		{
			startCountdown();
			return;
		}

		setStartCallback(schoolIntro);
	}

	function schoolIntro():Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		remove(black);

		if(songName == 'thorns-erect')
		{
			camHUD.visible = false;
			add(red);
			add(senpaiEvil);
			senpaiEvil.alpha = 0;
			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				senpaiEvil.alpha += 0.15;
				if(senpaiEvil.alpha < 1)
				{
					tmr.reset();
				}
				else
				{
					senpaiEvil.animation.play('idle');
					FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
					{
						remove(senpaiEvil);
						remove(red);
						FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
						{
							add(black);
							FlxG.camera.fade(FlxColor.WHITE, 1, false);
						}, true);
					});
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						PlayState.instance.startCountdown();
						remove(black);
					});
				}
			});
		}
		else
		{
			add(black);
			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				black.alpha -= 0.15;

				if(black.alpha > 0)
				{
					tmr.reset(0.3);
				}
				else
				{
					PlayState.instance.startCountdown();
					remove(black);
				}
			});
		}
	}

	// Ghouls event
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case 'Trigger BG Ghouls':
				if(bgGhouls != null && !ClientPrefs.data.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
		}
	}

	override function eventPushed(event:objects.Note.EventNote)
	{
		switch(event.event)
		{
			case 'Trigger BG Ghouls':
				if(!ClientPrefs.data.lowQuality)
				{
					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * PlayState.daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if(name == 'BG freaks glitch instance')
							bgGhouls.visible = false;
					}
					addBehindGF(bgGhouls);
				}
		}
	}
}
