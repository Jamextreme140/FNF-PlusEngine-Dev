package states.stages.erect;

import states.stages.objects.*;
import objects.Character;

class TankErect extends BaseStage
{
	var sniper:FlxSprite;
	var guy:FlxSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	override function create()
	{
		var bg:BGSprite = new BGSprite('erect/bg', -985, -805, 1, 1);
		bg.scale.set(1.15, 1.15);
		add(bg);

		sniper = new FlxSprite(-346, 245);
		sniper.frames = Paths.getSparrowAtlas('erect/sniper');
		sniper.animation.addByPrefix('idle', 'Tankmanidlebaked instance 1', 24);
		sniper.animation.addByPrefix('sip', 'tanksippingBaked instance 1', 24);
		sniper.scale.set(1.15, 1.15);
		add(sniper);

		guy = new FlxSprite(1175, 270);
		guy.frames = Paths.getSparrowAtlas('erect/guy');
		guy.animation.addByPrefix('idle', 'BLTank2 instance 1', 24);
		guy.scale.set(1.15, 1.15);
		add(guy);

		tankmanRun = new FlxTypedGroup<TankmenBG>();
		add(tankmanRun);

		foregroundSprites = new FlxTypedGroup<BGSprite>();
		foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
		if(!ClientPrefs.data.lowQuality)
			foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
		foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
		if(!ClientPrefs.data.lowQuality)
			foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
		foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
		if(!ClientPrefs.data.lowQuality)
			foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));

		setDefaultGF('gf-tankmen');

		if(isStoryMode && !seenCutscene)
		{
			switch(songName)
			{
				case 'ugh-erect':
					setStartCallback(tankIntro);
			}
		}
	}

	override function createPost()
	{
		add(foregroundSprites);
	}

	override function beatHit()
	{
		super.beatHit();
		if(curBeat % 2 == 0)
		{
			sniper.animation.play('idle', true);
			guy.animation.play('idle', true);
		}
		if(FlxG.random.bool(2))
			sniper.animation.play('sip', true);
	}

	// Ugh cutscene
	function tankIntro()
	{
		inCutscene = true;
		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/ugh');
		tankman.antialiasing = ClientPrefs.data.antialiasing;
		tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
		tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
		tankman.animation.play('wellWell', true);
		tankman.animation.finishCallback = function(name:String)
		{
			if(name == 'wellWell')
			{
				tankman.animation.play('killYou', true);
			}
			else
			{
				remove(tankman);
				startCountdown();
			}
		};
		add(tankman);
	}

	// For events
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case 'Tankman Run':
				spawnTankman();
		}
	}

	function spawnTankman():Void
	{
		if(!ClientPrefs.data.lowQuality)
		{
			var tankman:TankmenBG = tankmanRun.recycle(TankmenBG);
			tankman.resetShit(FlxG.random.int(630, 730), 255, FlxG.random.bool(50));
			tankmanRun.add(tankman);
		}
	}
}
