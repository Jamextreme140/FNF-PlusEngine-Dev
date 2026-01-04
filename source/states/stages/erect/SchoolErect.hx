package states.stages.erect;

import cutscenes.DialogueBoxPsych.DialogueFile;
import cutscenes.DialogueBoxPsych;

class SchoolErect extends BaseStage
{
	override function create()
	{
		var repositionShit:Int = -650;

		var bgSky:BGSprite = new BGSprite('weeb/erect/weebSky', -626, -78, 0.2, 0.2);
		add(bgSky);
		bgSky.antialiasing = false;

		var foliage:BGSprite = new BGSprite('weeb/erect/weebBackTrees', repositionShit, -80, 0.5, 0.5);
		add(foliage);
		foliage.antialiasing = false;

		var bgSchool:BGSprite = new BGSprite('weeb/erect/weebSchool', repositionShit, -38, 0.8, 0.90);
		add(bgSchool);
		bgSchool.antialiasing = false;

		var bgStreet:BGSprite = new BGSprite('weeb/erect/weebStreet', repositionShit, -50, 0.95, 0.95);
		add(bgStreet);
		bgStreet.antialiasing = false;

		var widShit:Int = Std.int(bgSky.width * PlayState.daPixelZoom);

		if(!ClientPrefs.data.lowQuality)
		{
			var fgTrees:BGSprite = new BGSprite('weeb/erect/weebTreesBack', repositionShit + 180, -25, 0.9, 0.9);
			fgTrees.setGraphicSize(Std.int(widShit * 0.9));
			fgTrees.updateHitbox();
			add(fgTrees);
			fgTrees.antialiasing = false;
		}

		var bgTrees:FlxSprite = new FlxSprite(repositionShit - 690, -1490);
		bgTrees.frames = Paths.getPackerAtlas('weeb/erect/weebTrees');
		bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
		bgTrees.animation.play('treeLoop');
		bgTrees.scrollFactor.set(0.85, 0.85);
		add(bgTrees);
		bgTrees.antialiasing = false;

		if(!ClientPrefs.data.lowQuality)
		{
			var treeLeaves:BGSprite = new BGSprite('weeb/erect/petals', repositionShit + 30, -40, 0.85, 0.85, ['PETALS ALL'], true);
			treeLeaves.setGraphicSize(widShit * 0.95);
			treeLeaves.updateHitbox();
			add(treeLeaves);
			treeLeaves.antialiasing = false;
		}

		bgSky.setGraphicSize(widShit);
		foliage.setGraphicSize(widShit);
		bgSchool.setGraphicSize(widShit);
		bgStreet.setGraphicSize(widShit);
		bgTrees.setGraphicSize(Std.int(widShit * 1.5));

		bgSky.updateHitbox();
		foliage.updateHitbox();
		bgSchool.updateHitbox();
		bgStreet.updateHitbox();
		bgTrees.updateHitbox();

		setDefaultGF('gf-pixel');

		if(isStoryMode && !seenCutscene)
		{
			switch(songName)
			{
				case 'senpai-erect':
					setStartCallback(schoolIntro);
				case 'roses-erect':
					FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
					setStartCallback(schoolIntro);
			}
		}
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

		if(songName == 'roses-erect')
		{
			remove(black);
			camHUD.visible = false;
			add(red);
			add(senpaiEvil);
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if(black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				// Try to load dialogue JSON for erect songs
				var dialoguePath:String = Paths.json(PlayState.SONG.song + '/' + PlayState.SONG.song + 'Dialogue');
				if(sys.FileSystem.exists(dialoguePath))
				{
					var dialogueFile:DialogueFile = DialogueBoxPsych.parseDialogue(dialoguePath);
					if(dialogueFile != null)
					{
						PlayState.instance.startDialogue(dialogueFile);
					}
					else
					{
						PlayState.instance.startCountdown();
					}
				}
				else
				{
					PlayState.instance.startCountdown();
				}

				remove(black);
			}
		});
	}
}
