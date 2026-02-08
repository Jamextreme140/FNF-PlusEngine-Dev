
package funkin.play.stage;

import funkin.play.stage.objects.*;
import funkin.play.notes.Note;
import funkin.play.character.Character;
import funkin.play.notes.StrumNote;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.audio.Conductor;

class Sserafim extends BaseStage
{
	// Stage sprites
	var bg:BGSprite;
	var backTables:BGSprite;
	var floor:BGSprite;
	var backStools:BGSprite;
	var frontStools:BGSprite;
	var truck:BGSprite;
	var door:BGSprite;
	
	// Fog/dust effects
	var blackout:FlxSprite;
	var fogOverlay:FlxSprite;
	var dustBack:FlxSprite;
	var dustMid:FlxSprite;
	var dustFront:FlxSprite;
	var dustTimer:FlxTimer;
	
	// Intro animations
	var kickSprite:FlxSprite;
	var bfGetUp:FlxSprite;
	var gfGetUp:FlxSprite;
	
	// Lights and shaders
	var backLight:FlxSprite;
	var backLight2:FlxSprite;
	var truckLight1:FlxSprite;
	var truckLight2:FlxSprite;
	var lightEnabled:Bool = false;
	var flashStrength:Float = 0.5;
	var presetColors:Array<FlxColor> = [0xFF6F00FF, 0xFFFF00AC];
	var colorIndex:Int = 0;
	var stageShader:funkin.graphics.shaders.AdjustColorShader;
	var shaderedSprites:Array<FlxSprite> = [];

	// Extra characters
	var chaewon:Character;
	var eunchae:Character;
	var kazuha:Character;
	
	// Event system variables
	var currentSinger:String = null; // Who sings all notes (null = default behavior)
	var defaultZoom:Float = 0.5;
	var videoEnded:Bool = false;

	override function create()
	{
		// Store default zoom
		defaultZoom = FlxG.camera.zoom;
		
		// Background elements (layered from back to front)
		bg = new BGSprite('sserafim/bg', -1888, -660, 0.9, 0.9);
		bg.scale.set(2.5, 2.5);
		bg.updateHitbox();
		add(bg);

		backTables = new BGSprite('sserafim/back-tables', -1908, 267, 0.9, 0.9);
		backTables.scale.set(2.5, 2.5);
		backTables.updateHitbox();
		add(backTables);

		floor = new BGSprite('sserafim/floor', -2232, 631, 1.0, 1.0);
		floor.scale.set(2.5, 2.5);
		floor.updateHitbox();
		add(floor);

		backStools = new BGSprite('sserafim/back-stools', -1551, 431, 1.0, 1.0);
		backStools.scale.set(2.5, 2.5);
		backStools.updateHitbox();
		add(backStools);

		frontStools = new BGSprite('sserafim/front-stool', -1551, 431, 1.0, 1.0);
		frontStools.scale.set(1.66, 1.66);
		frontStools.updateHitbox();
		add(frontStools);

		truck = new BGSprite('sserafim/truck-stuff', -983, -707, 1.0, 1.0);
		truck.scale.set(2.0, 2.0);
		truck.updateHitbox();
		add(truck);

		door = new BGSprite('sserafim/truck-door', -980, -173, 1.0, 1.0);
		door.scale.set(1.0, 1.0);
		door.updateHitbox();
		door.alpha = 0; // Hidden at start
		add(door);

		// Intro animation sprites
		kickSprite = new FlxSprite(-1128, -247);
		kickSprite.frames = Paths.getSparrowAtlas('sserafim/kick');
		kickSprite.animation.addByPrefix('kick', 'kick', 12, false);
		kickSprite.animation.addByPrefix('door', 'door', 12, false);
		kickSprite.scale.set(1.375, 1.375);
		kickSprite.updateHitbox();
		kickSprite.alpha = 1;
		add(kickSprite);
		
		// Note: bfGetUp and gfGetUp positions will be set in createPost() based on character positions
		bfGetUp = new FlxSprite(-10, 0);
		bfGetUp.frames = Paths.getSparrowAtlas('sserafim/bfGetUp');
		bfGetUp.animation.addByPrefix('getup', 'getup', 12, false);
		bfGetUp.animation.addByPrefix('static', 'static', 12, false);
		bfGetUp.scale.set(1, 1);
		bfGetUp.updateHitbox();
		bfGetUp.alpha = 1;
		add(bfGetUp);
		
		gfGetUp = new FlxSprite(-10, 0);
		gfGetUp.frames = Paths.getSparrowAtlas('sserafim/gfGetUp');
		gfGetUp.animation.addByPrefix('getup', 'getup', 12, false);
		gfGetUp.animation.addByPrefix('static', 'static', 12, false);
		gfGetUp.scale.set(0.875, 0.875);
		gfGetUp.updateHitbox();
		gfGetUp.alpha = 1;
		add(gfGetUp);

		
		// Start video cutscene if haven't seen it (works in both Story and Freeplay)
		if (!seenCutscene)
		{
			setStartCallback(videoCutscene);
		}
		else
		{
			//XD
		}
	}
	
	override function createPost()
	{
		// Position intro animation sprites based on character positions
		if (bfGetUp != null && game.boyfriend != null)
		{
			bfGetUp.setPosition(game.boyfriend.x, game.boyfriend.y + 100);
		}
		
		if (gfGetUp != null && game.gf != null)
		{
			gfGetUp.setPosition(game.gf.x, game.gf.y);
		}
		
		// Create extra characters (hidden at start)
		chaewon = new Character(200, -240, 'chaewon');
		add(chaewon);
		chaewon.scrollFactor.set(1.0, 1.0);
		chaewon.alpha = 0; // Hidden until step 167

		eunchae = new Character(250, 290, 'eunchae');
		insert(members.indexOf(game.gfGroup), eunchae); // Add behind GF
		eunchae.scrollFactor.set(1.0, 1.0);
		eunchae.alpha = 0; // Hidden until step 227

		kazuha = new Character(-500, 100, 'kazuha');
		insert(members.indexOf(game.gfGroup), kazuha); // Add behind GF
		kazuha.scrollFactor.set(1.0, 1.0);
		kazuha.alpha = 0; // Hidden until step 101
		
		// Add fog and dust effects (above characters)
		if (!ClientPrefs.data.lowQuality)
		{
			// Fog overlay (starts visible, fades out) - positioned lower
			fogOverlay = new FlxSprite(-1500, -500).makeGraphic(1280, 720, 0xFF6B6345);
			fogOverlay.scrollFactor.set(0, 0);
			fogOverlay.alpha = 0.8;
			fogOverlay.scale.set(5, 5);
			add(fogOverlay);

			// Dust particles
			dustBack = new FlxSprite(-2000, -300);
			dustBack.loadGraphic(Paths.image('sserafim/dust/dustBack'));
			dustBack.scale.set(6.25, 1.875);
			dustBack.updateHitbox();
			dustBack.alpha = 1;
			add(dustBack);

			dustMid = new FlxSprite(-2000, 300);
			dustMid.loadGraphic(Paths.image('sserafim/dust/dustMid'));
			dustMid.scale.set(6.25, 1.875);
			dustMid.updateHitbox();
			dustMid.alpha = 1;
			add(dustMid);

			dustFront = new FlxSprite(-2000, -300);
			dustFront.loadGraphic(Paths.image('sserafim/dust/dustFront'));
			dustFront.scale.set(6.25, 1.875);
			dustFront.updateHitbox();
			dustFront.alpha = 1;
			add(dustFront);

			// Start dust movement timer
			dustTimer = new FlxTimer();
			dustTimer.start(0.1, function(tmr:FlxTimer) {
				moveDust(1);
			});
		}
		
		// Blackout overlay (above fog, used for flash effects)
		blackout = new FlxSprite(0, 0).makeGraphic(1920, 1080, 0xFF000000);
		blackout.scrollFactor.set(0, 0);
		blackout.alpha = 0;
		blackout.cameras = [game.camHUD];
		add(blackout);
		
		// Hide characters at start (shown at step 18/38)
		if (game.boyfriend != null)
		{
			game.boyfriend.alpha = 0;
		}
		if (game.gf != null)
		{
			game.gf.alpha = 0;
		}
		if (game.dad != null)
		{
			game.dad.alpha = 0;
		}
		
		// Hide opponent strums and notes (from sserafim notes.lua)
		var oppStrums:FlxTypedGroup<StrumNote> = cast game.opponentStrums;
		if (oppStrums != null)
		{
			oppStrums.forEach(function(strum:StrumNote)
			{
				if (strum != null) strum.alpha = 0;
			});
		}
	}

	override function update(elapsed:Float)
	{
		// Hide opponent notes during gameplay (from sserafim notes.lua)
		var noteGroup:FlxTypedGroup<Note> = cast game.notes;
		if (noteGroup != null)
		{
			noteGroup.forEachAlive(function(note:Note)
			{
				if (!note.mustPress)
				{
					note.alpha = 0;
				}
			});
		}
		
		// Keep opponent strums hidden
		var oppStrums:FlxTypedGroup<StrumNote> = cast game.opponentStrums;
		if (oppStrums != null)
		{
			oppStrums.forEach(function(strum:StrumNote)
			{
				if (strum != null) strum.alpha = 0;
			});
		}
	}

	override function beatHit()
	{
		// Make extra characters dance every 2 beats
		if (curBeat % 2 == 0)
		{
			danceIfNotSinging(chaewon);
			danceIfNotSinging(eunchae);
			danceIfNotSinging(kazuha);
		}
		
		// Light flashing effects
		if (lightEnabled && backLight != null)
		{
			// Flash backLight with color change
			if (game.modchartTweens.exists('backLightFlash'))
			{
				game.modchartTweens.get('backLightFlash').cancel();
			}
			
			backLight.alpha = flashStrength;
			FlxTween.tween(backLight, {alpha: 0}, 0.4, {
				ease: FlxEase.quadIn,
				onComplete: function(_) {
					if (game.modchartTweens.exists('backLightFlash'))
						game.modchartTweens.remove('backLightFlash');
				}
			});
			backLight.color = presetColors[colorIndex];
			
			// Flash backLight2 (no color change)
			if (backLight2 != null)
			{
				backLight2.alpha = flashStrength;
				FlxTween.tween(backLight2, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
			}
			
			// Flash truckLight1 with full alpha
			if (truckLight1 != null)
			{
				truckLight1.alpha = 1;
				FlxTween.tween(truckLight1, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
			}
			
			// Flash truckLight2
			if (truckLight2 != null)
			{
				truckLight2.alpha = flashStrength;
				FlxTween.tween(truckLight2, {alpha: 0}, 0.4, {ease: FlxEase.quadIn});
			}
			
			// Cycle colors
			colorIndex = (colorIndex + 1) % presetColors.length;
		}
	}
	
	override function stepHit()
	{
		// Fade out fog and dust at step 1
		if (curStep == 1)
		{
			if (!ClientPrefs.data.lowQuality && fogOverlay != null)
			{
				FlxTween.tween(fogOverlay, {alpha: 0}, 15, {ease: FlxEase.linear});
			}
			if (!ClientPrefs.data.lowQuality && dustBack != null)
			{
				FlxTween.tween(dustBack, {alpha: 0}, 15, {ease: FlxEase.linear});
				FlxTween.tween(dustMid, {alpha: 0}, 15, {ease: FlxEase.linear});
				FlxTween.tween(dustFront, {alpha: 0}, 15, {ease: FlxEase.linear});
			}
		}
		
		// Kick animation and show BF/GF at step 18
		if (curStep == 18)
		{
			if (kickSprite != null)
			{
				kickSprite.animation.play('kick', true);
			}
			if (game.boyfriend != null)
			{
				game.boyfriend.alpha = 1;
			}
			if (game.gf != null)
			{
				game.gf.alpha = 1;
			}
			if (bfGetUp != null)
			{
				bfGetUp.alpha = 0;
			}
			if (gfGetUp != null)
			{
				gfGetUp.alpha = 0;
			}
		}
		
		// Show door at step 27
		if (curStep == 27)
		{
			door.alpha = 1;
		}
		
		// Show dad and hide kick sprite at step 38
		if (curStep == 38)
		{
			if (game.dad != null)
			{
				game.dad.alpha = 1;
			}
			if (kickSprite != null)
			{
				kickSprite.alpha = 0;
			}
		}
		
		// Show kazuha at step 101
		if (curStep == 101)
		{
			if (kazuha != null)
			{
				kazuha.alpha = 1;
			}
		}
		
		// Show chaewon at step 167
		if (curStep == 167)
		{
			if (chaewon != null)
			{
				chaewon.alpha = 1;
			}
		}
		
		// Show eunchae at step 227
		if (curStep == 227)
		{
			if (eunchae != null)
			{
				eunchae.alpha = 1;
			}
		}
		
		// Blackout flash effects
		if (curStep == 463)
		{
			if (blackout != null)
			{
				blackout.visible = true;
				blackout.alpha = 1;
			}
		}
		if (curStep == 465)
		{
			if (blackout != null)
			{
				blackout.alpha = 0;
			}
		}
		if (curStep == 476)
		{
			if (blackout != null)
			{
				blackout.alpha = 1;
			}
		}
		if (curStep == 479)
		{
			if (blackout != null)
			{
				blackout.alpha = 0;
			}
		}
	}
	
	// Dust particle movement
	function moveDust(phase:Int)
	{
		if (ClientPrefs.data.lowQuality || dustBack == null) return;
		
		if (phase == 1)
		{
			dustBack.velocity.x = 200;
			dustFront.velocity.x = 200;
			dustMid.velocity.x = -200;
			dustTimer.start(2, function(tmr:FlxTimer) {
				moveDust(2);
			});
		}
		else
		{
			dustBack.velocity.x = -200;
			dustFront.velocity.x = -200;
			dustMid.velocity.x = 200;
			dustTimer.start(2, function(tmr:FlxTimer) {
				moveDust(1);
			});
		}
	}
	
	// Update health icon based on who is singing
	function updateHealthIcon(character:String)
	{
		if (game.iconP2 == null) return;
		
		var iconName:String = 'yunjin'; // Default
		
		switch(character)
		{
			case 'chaewon': iconName = 'chaewon';
			case 'eunchae': iconName = 'eunchae';
			case 'kazuha': iconName = 'kazuha';
			case 'dad' | 'yunjin': iconName = 'yunjin';
			case 'gf': iconName = game.gf != null ? game.gf.healthIcon : 'nene';
			case 'bf' | 'boyfriend': iconName = game.boyfriend != null ? game.boyfriend.healthIcon : 'bf';
		}
		
		game.iconP2.changeIcon(iconName);
	}

	// Helper function to make character dance only if not singing
	function danceIfNotSinging(char:Character)
	{
		if (char == null) return;
		
		var anim = char.animation.name;
		if (anim != null && !anim.startsWith('sing'))
		{
			char.dance();
		}
	}

	// Video cutscene before countdown
	function videoCutscene()
	{
		inCutscene = true;
		if(!videoEnded)
		{
			#if VIDEOS_ALLOWED
			game.startVideo('sserafim-cutscene');
			game.videoCutscene.finishCallback = game.videoCutscene.onSkip = function()
			{
				videoEnded = true;
				game.videoCutscene = null;
				videoCutscene();
			};
			#else
			new FlxTimer().start(0.0, function(tmr:FlxTimer)
			{
				videoEnded = true;
				videoCutscene();
			});
			#end
			return;
		}
		
		game.skipCountdown = true;
		
		// Play intro animations when countdown starts
		if (bfGetUp != null)
		{
			bfGetUp.animation.play('getup', true);
		}
		if (gfGetUp != null)
		{
			gfGetUp.animation.play('getup', true);
		}
		if (kickSprite != null)
		{
			kickSprite.animation.play('door', true);
		}
		
		startCountdown();
	}

	// Helper function to make character sing
	function singCharacter(char:Character, noteData:Int)
	{
		if (char == null) return;

		var animToPlay:String = '';
		switch (noteData % 4)
		{
			case 0: animToPlay = 'singLEFT';
			case 1: animToPlay = 'singDOWN';
			case 2: animToPlay = 'singUP';
			case 3: animToPlay = 'singRIGHT';
		}

		if (char.animOffsets.exists(animToPlay))
		{
			char.playAnim(animToPlay, true);
		}
	}

	override function goodNoteHit(note:Note)
	{
		// If currentSinger is set, that character sings ALL notes
		if (currentSinger != null)
		{
			if (currentSinger == 'all')
			{
				// All characters sing together
				singCharacter(game.boyfriend, note.noteData);
				singCharacter(game.dad, note.noteData);
				singCharacter(game.gf, note.noteData);
				singCharacter(chaewon, note.noteData);
				singCharacter(eunchae, note.noteData);
				singCharacter(kazuha, note.noteData);
			}
			else
			{
				// Specific character sings
				switch (currentSinger)
				{
					case 'chaewon': singCharacter(chaewon, note.noteData);
					case 'eunchae': singCharacter(eunchae, note.noteData);
					case 'kazuha': singCharacter(kazuha, note.noteData);
					case 'dad' | 'yunjin': singCharacter(game.dad, note.noteData);
					case 'bf' | 'boyfriend': singCharacter(game.boyfriend, note.noteData);
					case 'gf' | 'girlfriend': singCharacter(game.gf, note.noteData);
				}
			}
			return;
		}
		
		// Default behavior: handle custom note types
		switch (note.noteType)
		{
			case 'ChaewonNote':
				singCharacter(chaewon, note.noteData);
			case 'EunchaeNote':
				singCharacter(eunchae, note.noteData);
			case 'YunjinNote':
				singCharacter(game.dad, note.noteData);
			case 'KazuhaNote':
				singCharacter(kazuha, note.noteData);
			case 'sakura-joint' | 'AllSingNote':
				// All characters sing together
				singCharacter(chaewon, note.noteData);
				singCharacter(eunchae, note.noteData);
				singCharacter(kazuha, note.noteData);
				singCharacter(game.dad, note.noteData);
		}
	}

	// For events
	override function eventCalled(eventName:String, value1:String, value2:String, flValue1:Null<Float>, flValue2:Null<Float>, strumTime:Float)
	{
		switch(eventName)
		{
			case 'sserafimSing':
				// Change who sings all notes
				// Special logic for bf
				if (value1 == 'bf' || value1 == 'all')
				{
					game.triggerEvent('Change Character', 'bf', 'bf-truck', strumTime);
				}
				else
				{
					game.triggerEvent('Change Character', 'bf', 'bf (idle only)', strumTime);
				}
				
				// Update currentSinger
				if (value1 == 'chaewon' || value1 == 'eunchae' || value1 == 'kazuha' || 
				    value1 == 'dad' || value1 == 'gf' || value1 == 'bf')
				{
					currentSinger = value1;
					// Only change icon if not BF
					if (value1 != 'bf' && value1 != 'boyfriend')
					{
						updateHealthIcon(value1);
					}
				}
				else if (value1 == 'all')
				{
					currentSinger = 'all';
					updateHealthIcon('yunjin'); // Default to yunjin for 'all'
				}
				else if (value1 == 'none')
				{
					currentSinger = null;
					updateHealthIcon(game.dad.healthIcon); // Restore dad's icon
				}
				
			case 'sserafimBeautiful':
				// Similar to sserafimSing but GF also sings
				if (value1 == 'chaewon' || value1 == 'eunchae' || value1 == 'kazuha' || 
				    value1 == 'bf' || value1 == 'dad')
				{
					currentSinger = value1;
					// GF will sing too (handled in goodNoteHit)
				}
				else if (value1 == 'all')
				{
					currentSinger = 'all';
				}
				else if (value1 == 'none')
				{
					currentSinger = null;
				}
				
			case 'sserafimShow':
				// Lighting effects with shaders
				if (!ClientPrefs.data.shaders) return;
				
				var stageBrightness:Float = flValue2 != null ? flValue2 : 0;
				
				// Create light sprites if they don't exist
				if (backLight == null)
				{
					backLight = new FlxSprite(-1200, -850);
					backLight.loadGraphic(Paths.image('sserafim/lights/back-light-color'));
					backLight.scrollFactor.set(1, 1);
					backLight.scale.set(1.3, 1.3);
					backLight.updateHitbox();
					backLight.alpha = 0;
					insert(members.indexOf(truck), backLight); // Behind truck
				}
				
				if (backLight2 == null)
				{
					backLight2 = new FlxSprite(-200, -600);
					backLight2.loadGraphic(Paths.image('sserafim/lights/back-light-color'));
					backLight2.scrollFactor.set(1, 1);
					backLight2.scale.set(0.9, 0.9);
					backLight2.updateHitbox();
					backLight2.alpha = 0;
					insert(members.indexOf(backLight) + 1, backLight2);
				}
				
				if (truckLight1 == null)
				{
					truckLight1 = new FlxSprite(-910, -620);
					truckLight1.loadGraphic(Paths.image('sserafim/lights/truck-light1'));
					truckLight1.scrollFactor.set(1, 1);
					truckLight1.scale.set(1.4, 1.4);
					truckLight1.updateHitbox();
					truckLight1.alpha = 0;
					insert(members.indexOf(truck) + 1, truckLight1);
				}
				
				if (truckLight2 == null)
				{
					truckLight2 = new FlxSprite(-780, -465);
					truckLight2.loadGraphic(Paths.image('sserafim/lights/truck-light2'));
					truckLight2.scrollFactor.set(1, 1);
					truckLight2.scale.set(1.25, 1.25);
					truckLight2.updateHitbox();
					truckLight2.alpha = 0;
					insert(members.indexOf(truck) + 2, truckLight2);
				}
				
				// Initialize shader if needed
				if (stageShader == null)
				{
					stageShader = new funkin.graphics.shaders.AdjustColorShader();
					shaderedSprites = [];
					
					// Apply shader to stage sprites
					var stageSprites:Array<FlxSprite> = [bg, backTables, floor, backStools, frontStools, truck, door];
					for (sprite in stageSprites)
					{
						if (sprite != null)
						{
							sprite.shader = stageShader;
							shaderedSprites.push(sprite);
						}
					}
					
					// Apply shader to characters
					var charSprites:Array<FlxSprite> = [game.boyfriend, game.dad, game.gf, chaewon, eunchae, kazuha];
					for (sprite in charSprites)
					{
						if (sprite != null)
						{
							sprite.shader = stageShader;
							shaderedSprites.push(sprite);
						}
					}
				}
				
				// Set shader values based on mode
				if (value1 == 'dark')
				{
					lightEnabled = false;
					stageShader.brightness = stageBrightness;
				}
				else if (value1 == 'light')
				{
					lightEnabled = true;
					var brightness:Float = flValue2 != null ? flValue2 : -80;
					stageShader.brightness = brightness;
					if (backLight != null) backLight.alpha = 0;
				}
				
				stageShader.hue = 0;
				stageShader.contrast = -20;
				stageShader.saturation = -10;
				
			case 'SserafimCamera':
				// Camera effects (can use existing Camera Follow Pos event)
				
			case 'Set Cam Speed':
				// Set camera speed
				if (value1 != null && value1.length > 0)
				{
					game.cameraSpeed = Std.parseFloat(value1);
				}
				else
				{
					game.cameraSpeed = 1;
				}
				
			case 'Zoom':
				// Custom zoom event
				var zoom:Float = flValue1 != null ? flValue1 : defaultZoom;
				var durSteps:Float = 1;
				var ease:String = 'CLASSIC';
				
				if (value2 != null && value2.length > 0)
				{
					var params = value2.split(',');
					if (params.length > 0)
					{
						durSteps = Std.parseFloat(params[0].trim());
					}
					if (params.length > 1)
					{
						ease = params[1].trim().toUpperCase();
					}
				}
				
				var duration:Float = 0;
				if (durSteps > 0)
				{
					duration = (Conductor.stepCrochet / 1000) * durSteps;
				}
				
				if (game.camZoomTween != null)
				{
					game.camZoomTween.cancel();
				}
				
				if (ease == 'INSTANT' || duration <= 0)
				{
					game.camGame.zoom = zoom;
					game.defaultCamZoom = zoom;
				}
				else
				{
					game.camZoomTween = FlxTween.tween(game.camGame, {zoom: zoom}, duration / game.playbackRate, {
						ease: FlxEase.linear,
						onComplete: function(_) {
							game.defaultCamZoom = zoom;
						}
					});
				}
		}
	}
}
