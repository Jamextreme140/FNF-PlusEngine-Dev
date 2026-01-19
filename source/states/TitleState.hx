package states;

import backend.ClientPrefs;

import flixel.input.keyboard.FlxKey;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;


import shaders.ColorSwap;

import states.StoryMenuState;
import states.MainMenuState;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#end

#if mobile
import mobile.backend.TouchUtil;
#end

typedef TitleData =
{
	var titlex:Float;
	var titley:Float;
	var startx:Float;
	var starty:Float;
	var gfx:Float;
	var gfy:Float;
	var backgroundSprite:String;
	var bpm:Float;
	
	@:optional var animation:String;
	@:optional var dance_left:Array<Int>;
	@:optional var dance_right:Array<Int>;
	@:optional var idle:Bool;
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;
	public static var fromSubstate:Bool = false; // Flag to detect if coming from a substate
	
	var forceShowIntro:Bool = false; // Whether to force showing the intro

	var credGroup:FlxGroup = new FlxGroup();
	var textGroup:FlxGroup = new FlxGroup();
	var blackScreen:FlxSprite;
	var credTextShit:Alphabet;
	var ngSpr:FlxSprite;
	var updateNotificationText:FlxText;
	
	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	#if TITLE_SCREEN_EASTER_EGG
	final easterEggKeys:Array<String> = [
		'SHADOW', 'RIVEREN', 'BBPANZU', 'PESSY'
	];
	final allowedKeys:String = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
	var easterEggKeysBuffer:String = '';
	#end

	#if VIDEOS_ALLOWED
	var introVideo:FlxVideoSprite;
	#end
	var showingIntro:Bool = false;
	var introFinished:Bool = false;
	var skipTimer:Float = 0;
	var canSkip:Bool = true;

	override public function create():Void
	{
		Paths.clearStoredMemory();
		super.create();
		Paths.clearUnusedMemory();

		if(!initialized)
		{
			// Language phrases are reloaded in InitialState; only update colorblind filter here.
			shaders.ColorblindFilter.UpdateColors();
		}

		if(FlxG.save.data.introFinished == null) FlxG.save.data.introFinished = false;

		curWacky = FlxG.random.getObject(getIntroTextShit());

		if(!initialized || forceShowIntro)
		{
			if(FlxG.save.data != null && FlxG.save.data.fullscreen)
			{
				backend.WindowMode.setBorderlessFullscreen(FlxG.save.data.fullscreen);
				//trace('LOADED FULLSCREEN SETTING!!');
			}
			persistentUpdate = true;
			persistentDraw = true;
		}

		if (FlxG.save.data.weekCompleted != null)
		{
			StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;
		}

		FlxG.mouse.visible = false;

		var shouldShowIntro:Bool = (!initialized || forceShowIntro) && ClientPrefs.data.showIntroVideo && !FlxG.save.data.introFinished;
		
		if(shouldShowIntro)
		{
			showIntroVideo();
		}
		else
		{
			#if FREEPLAY
			MusicBeatState.switchState(new FreeplayState());
			#elseif CHARTING
			MusicBeatState.switchState(new ChartingState());
			#else
			if(FlxG.save.data.flashing == null && !FlashingState.leftState)
			{
				controls.isInSubstate = false; //idfk what's wrong
				FlxTransitionableState.skipNextTransIn = true;
				FlxTransitionableState.skipNextTransOut = true;
				MusicBeatState.switchState(new FlashingState());
			}
			else
				startIntro();
			#end
		}
	}

	function showIntroVideo():Void
	{
		showingIntro = true;

		var blackBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackBG);

		#if VIDEOS_ALLOWED
		introVideo = new FlxVideoSprite();
		introVideo.bitmap.onEndReached.add(function() {
			onIntroFinished();
		});

		var videoPath:String = Paths.video('titleIntro');
		if(videoPath != null)
		{
			introVideo.load(videoPath);
			introVideo.play();
			add(introVideo);
		}
		else
		{
			trace('Intro video not found, skipping to normal intro');
			onIntroFinished();
		}
		#end
	}
	
	function onIntroFinished():Void
	{
		if (!showingIntro) return;
		
		showingIntro = false;
		introFinished = true;
		FlxG.save.data.introFinished = true;
		FlxG.save.flush();

		#if VIDEOS_ALLOWED
		if (introVideo != null)
		{
			introVideo.destroy();
			introVideo = null;
		}
		#end

		#if FREEPLAY
		MusicBeatState.switchState(new FreeplayState());
		#elseif CHARTING
		MusicBeatState.switchState(new ChartingState());
		#else
		if(FlxG.save.data.flashing == null && !FlashingState.leftState)
		{
			controls.isInSubstate = false;
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new FlashingState());
		}
		else
			startIntro();
		#end
	}
	
	function skipIntroVideo():Void
	{
		if (!showingIntro || !canSkip) return;

		FlxG.sound.play(Paths.sound('cancelMenu'), 0.7);

		#if VIDEOS_ALLOWED
		if (introVideo != null)
		{
			introVideo.stop();
		}
		#end
		
		onIntroFinished();
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	#if mobile
	var titleTextMobile:FlxSprite;
	#else
	var titleText:FlxSprite;
	#end
	var swagShader:ColorSwap = null;

	function startIntro()
	{
		persistentUpdate = true;
		
		// Reproducir música si no está inicializado o si no hay música
		if (!initialized && FlxG.sound.music == null)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}
		// Si viene del substate y la música existe pero no está sonando, reiniciarla
		else if (!initialized && FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
			FlxG.sound.music.fadeIn(4, 0, 0.7);
		}

		loadJsonData();
		#if TITLE_SCREEN_EASTER_EGG easterEggData(); #end
		Conductor.bpm = musicBPM;

		logoBl = new FlxSprite(logoPosition.x, logoPosition.y);
		logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
		logoBl.antialiasing = ClientPrefs.data.antialiasing;

		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();

		gfDance = new FlxSprite(gfPosition.x, gfPosition.y);
		gfDance.antialiasing = ClientPrefs.data.antialiasing;
		
		if(ClientPrefs.data.shaders)
		{
			swagShader = new ColorSwap();
			gfDance.shader = swagShader.shader;
			logoBl.shader = swagShader.shader;
		}
		
		gfDance.frames = Paths.getSparrowAtlas(characterImage);
		if(!useIdle)
		{
			gfDance.animation.addByIndices('danceLeft', animationName, danceLeftFrames, "", 24, false);
			gfDance.animation.addByIndices('danceRight', animationName, danceRightFrames, "", 24, false);
			gfDance.animation.play('danceRight');
		}
		else
		{
			gfDance.animation.addByPrefix('idle', animationName, 24, false);
			gfDance.animation.play('idle');
		}


		var animFrames:Array<FlxFrame> = [];
		#if mobile
		titleTextMobile = new FlxSprite(enterPositionMobile.x, enterPositionMobile.y);
		titleTextMobile.frames = Paths.getSparrowAtlas('titleEnterMobile');
		#else
		titleText = new FlxSprite(enterPosition.x, enterPosition.y);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		#end

		#if mobile
		@:privateAccess
		{
			titleTextMobile.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleTextMobile.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (newTitle = animFrames.length > 0)
		{
			titleTextMobile.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleTextMobile.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			titleTextMobile.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleTextMobile.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleTextMobile.animation.play('idle');
		titleTextMobile.updateHitbox();
		#else
		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (newTitle = animFrames.length > 0)
		{
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}
		titleText.animation.play('idle');
		titleText.updateHitbox();
		#end

		blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		blackScreen.scale.set(FlxG.width, FlxG.height);
		blackScreen.updateHitbox();
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "", true);
		credTextShit.screenCenter();
		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('newgrounds_logo'));
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = ClientPrefs.data.antialiasing;

		add(gfDance);
		add(logoBl); //FNF Logo
		#if mobile
		add(titleTextMobile);
		#else
		add(titleText); //"Press Enter to Begin" text
		#end
		add(credGroup);
		add(ngSpr);

		// Create update notification text
		updateNotificationText = new FlxText(0, 10, 0, "Checking Updates...", 20);
		updateNotificationText.setFormat("VCR OSD Mono", 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		updateNotificationText.borderSize = 2;
		updateNotificationText.scrollFactor.set();
		updateNotificationText.x = FlxG.width + 50; // Start off-screen to the right
		updateNotificationText.cameras = [FlxG.camera];
		add(updateNotificationText);

		#if CHECK_FOR_UPDATES
		if (ClientPrefs.data.checkForUpdates) {
			// Show the text immediately with animation (from right to left)
			FlxTween.tween(updateNotificationText, {x: FlxG.width - updateNotificationText.width - 10}, 0.5, {ease: FlxEase.backOut});
			
			// Start checking for updates in background (non-blocking)
			try {
				CoolUtil.checkForUpdates(null, function() {
					// When done, change text to "Done!" (this callback runs on main thread)
					if(updateNotificationText != null) {
						updateNotificationText.text = "Done!";
						// Wait a bit and then hide (slide back to the right)
						new FlxTimer().start(1.0, function(tmr:FlxTimer) {
							if(updateNotificationText != null) {
								FlxTween.tween(updateNotificationText, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn, onComplete: function(twn:FlxTween) {
									if(updateNotificationText != null)
										updateNotificationText.visible = false;
								}});
							}
						});
					}
				});
			} catch (e:Dynamic) {
				trace('Error checking for updates: ' + e);
				if(updateNotificationText != null) {
					updateNotificationText.text = "Error!";
					new FlxTimer().start(1.0, function(tmr:FlxTimer) {
						if(updateNotificationText != null) {
							FlxTween.tween(updateNotificationText, {x: FlxG.width + 50}, 0.5, {ease: FlxEase.backIn, onComplete: function(twn:FlxTween) {
								if(updateNotificationText != null)
									updateNotificationText.visible = false;
							}});
						}
					});
				}
			}
		} else {
			updateNotificationText.visible = false;
		}
		#else
		updateNotificationText.visible = false;
		#end

		if (initialized && !forceShowIntro)
			skipIntro();
		else
		{
			initialized = true;
			forceShowIntro = false; // Resetear después de usarla
		}

		// credGroup.add(credTextShit);
	}

	// JSON data
	var characterImage:String = 'gfDanceTitle';
	var animationName:String = 'gfDance';

	var gfPosition:FlxPoint = FlxPoint.get(512, 40);
	var logoPosition:FlxPoint = FlxPoint.get(-150, -100);
	#if mobile
	var enterPositionMobile:FlxPoint = FlxPoint.get(50, 590);
	#else
	var enterPosition:FlxPoint = FlxPoint.get(100, 576);
	#end
	
	var useIdle:Bool = false;
	var musicBPM:Float = 102;
	var danceLeftFrames:Array<Int> = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29];
	var danceRightFrames:Array<Int> = [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

	function loadJsonData()
	{
		if(Paths.fileExists('images/gfDanceTitle.json', TEXT))
		{
			var titleRaw:String = Paths.getTextFromFile('images/gfDanceTitle.json');
			if(titleRaw != null && titleRaw.length > 0)
			{
				try
				{
					var titleJSON:TitleData = tjson.TJSON.parse(titleRaw);
					gfPosition.set(titleJSON.gfx, titleJSON.gfy);
					logoPosition.set(titleJSON.titlex, titleJSON.titley);
					#if mobile
					enterPositionMobile.set(titleJSON.startx, titleJSON.starty);
					#else
					enterPosition.set(titleJSON.startx, titleJSON.starty);
					#end
					musicBPM = titleJSON.bpm;
					
					if(titleJSON.animation != null && titleJSON.animation.length > 0) animationName = titleJSON.animation;
					if(titleJSON.dance_left != null && titleJSON.dance_left.length > 0) danceLeftFrames = titleJSON.dance_left;
					if(titleJSON.dance_right != null && titleJSON.dance_right.length > 0) danceRightFrames = titleJSON.dance_right;
					useIdle = (titleJSON.idle == true);
	
					if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0)
					{
						var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image(titleJSON.backgroundSprite));
						bg.antialiasing = ClientPrefs.data.antialiasing;
						add(bg);
					}
				}
				catch(e:haxe.Exception)
				{
					trace('[WARN] Title JSON might broken, ignoring issue...\n${e.details()}');
				}
			}
			else trace('[WARN] No Title JSON detected, using default values.');
		}
		//else trace('[WARN] No Title JSON detected, using default values.');
	}

	function easterEggData()
	{
		if (FlxG.save.data.psychDevsEasterEgg == null) FlxG.save.data.psychDevsEasterEgg = ''; //Crash prevention
		var easterEgg:String = FlxG.save.data.psychDevsEasterEgg;
		switch(easterEgg.toUpperCase())
		{
			case 'SHADOW':
				characterImage = 'ShadowBump';
				animationName = 'Shadow Title Bump';
				gfPosition.x += 210;
				gfPosition.y += 40;
				useIdle = true;
			case 'RIVEREN':
				characterImage = 'ZRiverBump';
				animationName = 'River Title Bump';
				gfPosition.x += 180;
				gfPosition.y += 40;
				useIdle = true;
			case 'BBPANZU':
				characterImage = 'BBBump';
				animationName = 'BB Title Bump';
				danceLeftFrames = [14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27];
				danceRightFrames = [27, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
				gfPosition.x += 45;
				gfPosition.y += 100;
			case 'PESSY':
				characterImage = 'PessyBump';
				animationName = 'Pessy Title Bump';
				gfPosition.x += 165;
				gfPosition.y += 60;
				danceLeftFrames = [29, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];
				danceRightFrames = [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28];
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		// Intentar obtener introTexts localizados primero
		#if TRANSLATIONS_ALLOWED
		var localizedIntros:Array<Array<String>> = Language.getLocalizedIntroTexts();
		if (localizedIntros != null && localizedIntros.length > 0)
		{
			return localizedIntros;
		}
		#end
		
		// Fallback: usar archivo introText.txt
		#if MODS_ALLOWED
		var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
		#else
		var fullText:String = Assets.getText(Paths.txt('introText'));
		var firstArray:Array<String> = fullText.split('\n');
		#end
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	private static var playJingle:Bool = false;
	
	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	override function update(elapsed:Float)
	{
		// Execute any pending update check callbacks on the main thread
		CoolUtil.executeUpdateCallback();

		if (showingIntro && canSkip)
		{
			var pressedSkip:Bool = false;
			
			#if mobile
			pressedSkip = TouchUtil.justPressed || controls.ACCEPT;
			#else
			pressedSkip = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
			
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
			if (gamepad != null && gamepad.justPressed.START)
			{
				pressedSkip = true;
			}
			#end
			
			if (pressedSkip)
			{
				skipIntroVideo();
				return;
			}
		}

		if (!showingIntro)
		{
			if (FlxG.sound.music != null)
				Conductor.songPosition = FlxG.sound.music.time;
			// FlxG.watch.addQuick('amp', FlxG.sound.music.amplitude);

			var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT || TouchUtil.justPressed;

			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			if (gamepad != null)
			{
				if (gamepad.justPressed.START)
					pressedEnter = true;

				#if switch
				if (gamepad.justPressed.B)
					pressedEnter = true;
				#end
			}
			
			if (newTitle) {
				titleTimer += FlxMath.bound(elapsed, 0, 1);
				if (titleTimer > 2) titleTimer -= 2;
			}

			// EASTER EGG

			if (initialized && !transitioning && skippedIntro)
			{
				if (newTitle && !pressedEnter)
				{
					var timer:Float = titleTimer;
					if (timer >= 1)
						timer = (-timer) + 2;
					
					timer = FlxEase.quadInOut(timer);
					#if mobile
					titleTextMobile.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
					titleTextMobile.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
					#else
					titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
					titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
					#end
				}
				
				if(pressedEnter)
				{
					#if mobile
					titleTextMobile.color = FlxColor.WHITE;
					titleTextMobile.alpha = 1;
					
					if(titleTextMobile != null) titleTextMobile.animation.play('press');
					#else
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
					
					if(titleText != null) titleText.animation.play('press');
					#end

					FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
					FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

					transitioning = true;
					// FlxG.sound.music.stop();

					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						MusicBeatState.switchState(new MainMenuState());
						closedState = true;
					});
					// FlxG.sound.play(Paths.music('titleShoot'), 0.7);
				}
				#if TITLE_SCREEN_EASTER_EGG
				else if (FlxG.keys.firstJustPressed() != FlxKey.NONE)
				{
					var keyPressed:FlxKey = FlxG.keys.firstJustPressed();
					var keyName:String = Std.string(keyPressed);
					if(allowedKeys.contains(keyName)) {
						easterEggKeysBuffer += keyName;
						if(easterEggKeysBuffer.length >= 32) easterEggKeysBuffer = easterEggKeysBuffer.substring(1);
						//trace('Test! Allowed Key pressed!!! Buffer: ' + easterEggKeysBuffer);

						for (wordRaw in easterEggKeys)
						{
							var word:String = wordRaw.toUpperCase(); //just for being sure you're doing it right
							if (easterEggKeysBuffer.contains(word))
							{
								//trace('YOOO! ' + word);
								if (FlxG.save.data.psychDevsEasterEgg == word)
									FlxG.save.data.psychDevsEasterEgg = '';
								else
									FlxG.save.data.psychDevsEasterEgg = word;
								FlxG.save.flush();

								FlxG.sound.play(Paths.sound('secret'));

								var black:FlxSprite = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.BLACK);
								black.scale.set(FlxG.width, FlxG.height);
								black.updateHitbox();
								black.alpha = 0;
								add(black);

								FlxTween.tween(black, {alpha: 1}, 1, {onComplete:
									function(twn:FlxTween) {
										FlxTransitionableState.skipNextTransIn = true;
										FlxTransitionableState.skipNextTransOut = true;
										MusicBeatState.switchState(new TitleState());
									}
								});
								FlxG.sound.music.fadeOut();
								if(FreeplayState.vocals != null)
								{
									FreeplayState.vocals.fadeOut();
								}
								closedState = true;
								transitioning = true;
								playJingle = true;
								easterEggKeysBuffer = '';
								break;
							}
						}
					}
				}
				#end
			}

			if (initialized && pressedEnter && !skippedIntro)
			{
				skipIntro();
			}

			if(swagShader != null)
			{
				if(controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
				if(controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
			}
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if(credGroup != null && textGroup != null)
			{
				credGroup.add(money);
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if(textGroup != null && credGroup != null) {
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			credGroup.add(coolText);
			textGroup.add(coolText);
		}
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	private var sickBeats:Int = 0; //Basically curBeat but won't be skipped if you hold the tab or resize the screen
	public static var closedState:Bool = false;
	override function beatHit()
	{
		super.beatHit();

		if(logoBl != null)
			logoBl.animation.play('bump', true);

		if(gfDance != null)
		{
			danceLeft = !danceLeft;
			if(!useIdle)
			{
				if (danceLeft)
					gfDance.animation.play('danceRight');
				else
					gfDance.animation.play('danceLeft');
			}
			else if(curBeat % 2 == 0) gfDance.animation.play('idle', true);
		}

		if(!closedState && !showingIntro)
		{
			sickBeats++;
			switch (sickBeats)
			{
				case 1:
					//FlxG.sound.music.stop();
					FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
					FlxG.sound.music.fadeIn(4, 0, 0.7);
				case 2:
					createCoolText(['Psych Engine by\n Shadow Mario'], -30);
				case 4:
					addMoreText('Plus Engine by\n   Lenin Asto', 130);
				case 5:
					deleteCoolText();
				case 6:
					createCoolText(['Not associated', 'with'], -40);
				case 8:
					addMoreText('newgrounds', -40);
					ngSpr.visible = true;
				case 9:
					deleteCoolText();
					ngSpr.visible = false;
				case 10:
					createCoolText([curWacky[0]]);
				case 12:
					addMoreText(curWacky[1]);
				case 13:
					deleteCoolText();
				case 14:
					addMoreText('Friday');
				case 15:
					addMoreText('Night');
				case 16:
					addMoreText('Funkin'); // credTextShit.text += '\nFunkin';

				case 17:
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;
	var increaseVolume:Bool = false;
	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			#if TITLE_SCREEN_EASTER_EGG
			if (playJingle) //Ignore deez
			{
				playJingle = false;
				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();

				var sound:FlxSound = null;
				switch(easteregg)
				{
					case 'RIVEREN':
						sound = FlxG.sound.play(Paths.sound('JingleRiver'));
					case 'SHADOW':
						FlxG.sound.play(Paths.sound('JingleShadow'));
					case 'BBPANZU':
						sound = FlxG.sound.play(Paths.sound('JingleBB'));
					case 'PESSY':
						sound = FlxG.sound.play(Paths.sound('JinglePessy'));

					default: //Go back to normal ugly ass boring GF
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 2);
						skippedIntro = true;

						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						return;
				}

				transitioning = true;
				if(easteregg == 'SHADOW')
				{
					new FlxTimer().start(3.2, function(tmr:FlxTimer)
					{
						remove(ngSpr);
						remove(credGroup);
						FlxG.camera.flash(FlxColor.WHITE, 0.6);
						transitioning = false;
					});
				}
				else
				{
					remove(ngSpr);
					remove(credGroup);
					FlxG.camera.flash(FlxColor.WHITE, 3);
					sound.onComplete = function() {
						FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
						FlxG.sound.music.fadeIn(4, 0, 0.7);
						transitioning = false;
						#if ACHIEVEMENTS_ALLOWED
						if(easteregg == 'PESSY') Achievements.unlock('pessy_easter_egg');
						#end
					};
				}
			}
			else #end //Default! Edit this one!!
			{
				remove(ngSpr);
				remove(credGroup);
				FlxG.camera.flash(FlxColor.WHITE, 4);

				var easteregg:String = FlxG.save.data.psychDevsEasterEgg;
				if (easteregg == null) easteregg = '';
				easteregg = easteregg.toUpperCase();
				#if TITLE_SCREEN_EASTER_EGG
				if(easteregg == 'SHADOW')
				{
					FlxG.sound.music.fadeOut();
					if(FreeplayState.vocals != null)
					{
						FreeplayState.vocals.fadeOut();
					}
				}
				#end
			}
			skippedIntro = true;
		}
	}
}
