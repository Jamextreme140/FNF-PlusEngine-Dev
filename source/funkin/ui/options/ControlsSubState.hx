package funkin.ui.options;

import funkin.input.InputFormatter;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxRect;
import funkin.play.AttachedSprite;
import funkin.ui.components.md3.MD3ShapeTools;

import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.gamepad.FlxGamepadManager;

class ControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	//Show on gamepad - Display name - Save file key - Rebind display name
	var options:Array<Dynamic> = [
		[true, 'NOTES'],
		[true, 'Left', 'note_left', 'Note Left'],
		[true, 'Down', 'note_down', 'Note Down'],
		[true, 'Up', 'note_up', 'Note Up'],
		[true, 'Right', 'note_right', 'Note Right'],
		[true],
		[true, 'UI'],
		[true, 'Left', 'ui_left', 'UI Left'],
		[true, 'Down', 'ui_down', 'UI Down'],
		[true, 'Up', 'ui_up', 'UI Up'],
		[true, 'Right', 'ui_right', 'UI Right'],
		[true],
		[true, 'Reset', 'reset', 'Reset'],
		[true, 'Accept', 'accept', 'Accept'],
		[true, 'Back', 'back', 'Back'],
		[true, 'Pause', 'pause', 'Pause'],
		[false],
		[false, 'VOLUME'],
		[false, 'Mute', 'volume_mute', 'Volume Mute'],
		[false, 'Up', 'volume_up', 'Volume Up'],
		[false, 'Down', 'volume_down', 'Volume Down'],
		[false],
		[false, 'DEBUG'],
		[false, 'Key 1', 'debug_1', 'Debug Key #1'],
		[false, 'Key 2', 'debug_2', 'Debug Key #2'],
		[false,],
		[false, 'WINDOW'],
		[false, 'Fullscreen', 'fullscreen', 'Fullscreen Toggel']
	];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;
	static var defaultKey:String = 'Reset to Default Keys';

	var bg:FlxSprite;
	var grid:FlxBackdrop;
	var grpDisplay:FlxTypedGroup<Alphabet>;
	var grpBlacks:FlxTypedGroup<AttachedSprite>;
	var grpOptions:FlxTypedGroup<Alphabet>;
	var grpBinds:FlxTypedGroup<Alphabet>;
	var selectSpr:AttachedSprite;
	var visibleRowCards:FlxTypedGroup<FlxSprite>;
	var visibleOptionTexts:FlxTypedGroup<FlxText>;
	var visibleBindCards:FlxTypedGroup<FlxSprite>;
	var visibleBindTexts:FlxTypedGroup<FlxText>;
	var visibleHeaderTexts:FlxTypedGroup<FlxText>;
	var headerRefs:Array<Alphabet> = [];
	var optionRefs:Array<Alphabet> = [];
	var bindRefs:Array<Alphabet> = [];

	var gamepadColor:FlxColor = 0xfffd7194;
	var keyboardColor:FlxColor = 0xff7192fd;
	var onKeyboardMode:Bool = true;
	
	var controllerSpr:FlxSprite;
	var panelHeader:FlxSprite;
	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelWidth:Float = 0;
	var panelHeight:Float = 0;
	var listX:Float = 0;
	var listY:Float = 0;
	var listWidth:Float = 0;
	var listHeight:Float = 0;
	var listVisualOffsetY:Float = 54;
	
	public function new()
	{
		controls.isInSubstate = true;

		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Controls Menu", null);
		#end

		options.push([true]);
		options.push([true]);
		options.push([true, defaultKey]);

		panelWidth = Math.min(1120, FlxG.width - 48);
		panelHeight = Math.min(640, FlxG.height - 44);
		panelX = (FlxG.width - panelWidth) * 0.5;
		panelY = (FlxG.height - panelHeight) * 0.5;
		listX = panelX + 28;
		listY = panelY + 132;
		listWidth = panelWidth - 56;
		listHeight = panelHeight - 196;

		var overlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xC0141020);
		add(overlay);

		OptionsMenuTheme.syncAccent();
		var palette = OptionsMenuTheme.current();

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = keyboardColor;
		bg.alpha = 0.16;
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.screenCenter();
		add(bg);

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		grid.color = 0xFF8D9FFF;
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		var panelShadow:FlxSprite = new FlxSprite(panelX + 10, panelY + 12);
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x2A000000);
		add(panelShadow);

		var panelSurface:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, 0xFFF9F5FC);
		add(panelSurface);

		panelHeader = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 106, 34, 34, 0, 0, 0xFFFFFBFF);
		add(panelHeader);

		var panelOutline:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, 0x22FFFFFF);
		add(panelOutline);

		var listSurface:FlxSprite = new FlxSprite(listX, listY);
		MD3ShapeTools.fillAndStrokeRoundRect(listSurface, Std.int(listWidth), Std.int(panelHeight - 164), 28, 2, 0xFFF8F3FB, 0xFFE5DCEF);
		add(listSurface);

		var titleText:FlxText = new FlxText(panelX + 34, panelY + 18, panelWidth - 68, Language.getPhrase('controls_menu', 'Controls'), 30);
		titleText.setFormat(Paths.font('inter-bold.otf'), 30, palette.strong, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		var subtitleText:FlxText = new FlxText(panelX + 34, panelY + 58, panelWidth - 68,
			Language.getPhrase('controls_menu_subtitle', 'Rebind keyboard and gamepad inputs without digging through the whole engine basement.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, palette.muted, LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		var footerText:FlxText = new FlxText(panelX + 34, panelY + panelHeight - 40, panelWidth - 68,
			Language.getPhrase('controls_menu_footer', 'ENTER rebinds. LEFT / RIGHT swaps primary and alternate. CTRL or shoulder buttons switch keyboard/gamepad.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, 0xFF5E506F, LEFT);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		grpDisplay = new FlxTypedGroup<Alphabet>();
		add(grpDisplay);
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);
		grpBlacks = new FlxTypedGroup<AttachedSprite>();
		add(grpBlacks);
		selectSpr = new AttachedSprite();
		selectSpr.makeGraphic(214, 72, FlxColor.WHITE);
		selectSpr.copyAlpha = false;
		selectSpr.alpha = 0.75;
		add(selectSpr);
		grpBinds = new FlxTypedGroup<Alphabet>();
		add(grpBinds);
		visibleRowCards = new FlxTypedGroup<FlxSprite>();
		add(visibleRowCards);
		visibleOptionTexts = new FlxTypedGroup<FlxText>();
		add(visibleOptionTexts);
		visibleBindCards = new FlxTypedGroup<FlxSprite>();
		add(visibleBindCards);
		visibleBindTexts = new FlxTypedGroup<FlxText>();
		add(visibleBindTexts);
		visibleHeaderTexts = new FlxTypedGroup<FlxText>();
		add(visibleHeaderTexts);

		controllerSpr = new FlxSprite(panelX + panelWidth - 128, panelY + 24).loadGraphic(Paths.image('controllertype'), true, 82, 60);
		controllerSpr.antialiasing = ClientPrefs.data.antialiasing;
		controllerSpr.animation.add('keyboard', [0], 1, false);
		controllerSpr.animation.add('gamepad', [1], 1, false);
		controllerSpr.animation.play('keyboard');
		add(controllerSpr);

		var modeHint:FlxText = new FlxText(panelX + panelWidth - 360, panelY + 44, 220, Language.getPhrase('controls_menu_mode_hint', 'CTRL toggles input mode'), 14);
		modeHint.setFormat(Paths.font('inter.otf'), 14, palette.muted, RIGHT);
		modeHint.antialiasing = ClientPrefs.data.antialiasing;
		add(modeHint);

		createTexts();
		
		addTouchPad('NONE', 'B');
	}

	var lastID:Int = 0;
	function createTexts()
	{
		curOptions = [];
		curOptionsValid = [];
		headerRefs = [];
		optionRefs = [];
		bindRefs = [];
		grpDisplay.forEachAlive(function(text:Alphabet) text.destroy());
		grpBlacks.forEachAlive(function(black:AttachedSprite) black.destroy());
		grpOptions.forEachAlive(function(text:Alphabet) text.destroy());
		grpBinds.forEachAlive(function(text:Alphabet) text.destroy());
		visibleRowCards.forEachAlive(function(card:FlxSprite) card.destroy());
		visibleOptionTexts.forEachAlive(function(text:FlxText) text.destroy());
		visibleBindCards.forEachAlive(function(card:FlxSprite) card.destroy());
		visibleBindTexts.forEachAlive(function(text:FlxText) text.destroy());
		visibleHeaderTexts.forEachAlive(function(text:FlxText) text.destroy());
		grpDisplay.clear();
		grpBlacks.clear();
		grpOptions.clear();
		grpBinds.clear();
		visibleRowCards.clear();
		visibleOptionTexts.clear();
		visibleBindCards.clear();
		visibleBindTexts.clear();
		visibleHeaderTexts.clear();

		var myID:Int = 0;
		for (i => option in options)
		{
			if(onKeyboardMode || option[0])
			{
				if(option.length > 1)
				{
					var isCentered:Bool = (option.length < 3);
					var isDefaultKey:Bool = (option[1] == defaultKey);
					var isDisplayKey:Bool = (isCentered && !isDefaultKey);

					var str:String = option[1];
					var keyStr:String = option[2];
					if(isDefaultKey) str = Language.getPhrase(str);
					var text:Alphabet = new Alphabet(listX + 332, listY + 56, !isDisplayKey ? Language.getPhrase('key_$keyStr', str) : Language.getPhrase('keygroup_$str', str), !isDisplayKey);
					text.isMenuItem = true;
					text.changeX = false;
					text.distancePerItem.y = 60;
					text.targetY = myID;
					text.ID = myID;
					lastID = myID;

					if(!isDisplayKey)
					{
						text.alignment = RIGHT;
						grpOptions.add(text);
						text.visible = false;
						curOptions.push(i);
						curOptionsValid.push(myID);

						var rowCard = new FlxSprite();
						visibleRowCards.add(rowCard);
						var labelText = new FlxText(listX + 24, listY, 440, '', 20);
						labelText.setFormat(Paths.font('inter-bold.otf'), 20, 0xFF2D2140, LEFT);
						labelText.antialiasing = ClientPrefs.data.antialiasing;
						visibleOptionTexts.add(labelText);
						optionRefs.push(text);
					}
					else
					{
						grpDisplay.add(text);
						text.visible = false;
						var headerText = new FlxText(listX + 28, listY, listWidth - 56, text.text, 20);
						headerText.setFormat(Paths.font('inter-bold.otf'), 20, 0xFF5D4B78, LEFT);
						headerText.antialiasing = ClientPrefs.data.antialiasing;
						visibleHeaderTexts.add(headerText);
						headerRefs.push(text);
					}

					if(isCentered) addCenteredText(text, option, myID);
					else addKeyText(text, option, myID);

					text.snapToPosition();
					text.y += FlxG.height * 2;
				}
				myID++;
			}
		}
		updateText();
		syncVisibleRows(0, true);
	}

	function addCenteredText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		text.alignment = LEFT;
		text.x = listX + 28;
		text.startPosition.x = text.x;
		text.y -= 72;
		text.startPosition.y -= 72;
	}
	function addKeyText(text:Alphabet, option:Array<Dynamic>, id:Int)
	{
		var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option[2]);
		if(keys == null && onKeyboardMode)
			keys = ClientPrefs.defaultKeys.get(option[2]).copy();

		var gmpds:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option[2]);
		if(gmpds == null && !onKeyboardMode)
			gmpds = ClientPrefs.defaultButtons.get(option[2]).copy();

		for (n in 0...2)
		{
			var key:String = null;
			if(onKeyboardMode)
				key = InputFormatter.getKeyName((keys[n] != null) ? keys[n] : NONE);
			else
				key = InputFormatter.getGamepadName((gmpds[n] != null) ? gmpds[n] : NONE);

			var attach:Alphabet = new Alphabet(panelX + panelWidth - 444 + n * 212, listY + 4, key, false);
			attach.isMenuItem = true;
			attach.changeX = false;
			attach.distancePerItem.y = 60;
			attach.targetY = text.targetY;
			attach.ID = Math.floor(grpBinds.length / 2);
			attach.snapToPosition();
			attach.y += FlxG.height * 2;
			grpBinds.add(attach);
			attach.visible = false;

			playstationCheck(attach);
			attach.scaleX = Math.min(1, 230 / attach.width);
			//attach.text = key;

			// spawn black bars at the right of the key name
			var black:AttachedSprite = new AttachedSprite();
			black.makeGraphic(214, 72, FlxColor.BLACK);
			black.alphaMult = 0.4;
			black.sprTracker = text;
			black.yAdd = -3;
			black.xAdd = 122 + n * 212;
			black.visible = false;
			grpBlacks.add(black);

			var bindCard = new FlxSprite();
			visibleBindCards.add(bindCard);
			var bindText = new FlxText(panelX + panelWidth - 444 + n * 212, listY, 184, key, 17);
			bindText.setFormat(Paths.font('inter.otf'), 17, 0xFF33254A, CENTER);
			bindText.antialiasing = ClientPrefs.data.antialiasing;
			visibleBindTexts.add(bindText);
			bindRefs.push(attach);
		}
	}

	function playstationCheck(alpha:Alphabet)
	{
		if(onKeyboardMode) return;

		var gamepad:FlxGamepad = FlxG.gamepads.firstActive;
		var model:FlxGamepadModel = gamepad != null ? gamepad.detectedModel : UNKNOWN;
		var letter = alpha.letters[0];
		if(model == PS4)
		{
			switch(alpha.text)
			{
				case '[', ']': //Square and Triangle respectively
					letter.image = 'alphabet_playstation';
					letter.updateHitbox();
					
					letter.offset.x += 4;
					letter.offset.y -= 5;
			}
		}
	}

	function updateBind(num:Int, text:String)
	{
		var bind:Alphabet = grpBinds.members[num];
		var attach:Alphabet = new Alphabet(panelX + panelWidth - 444 + (num % 2) * 212, listY + 4, text, false);
		attach.isMenuItem = true;
		attach.changeX = false;
		attach.distancePerItem.y = 60;
		attach.targetY = bind.targetY;
		attach.ID = bind.ID;
		attach.x = bind.x;
		attach.y = bind.y;
		
		playstationCheck(attach);
		attach.scaleX = Math.min(1, 230 / attach.width);
		//attach.text = text;

		bind.kill();
		grpBinds.remove(bind);
		grpBinds.insert(num, attach);
		bind.destroy();
		bindRefs[num] = attach;
		syncVisibleRows(0, true);
	}

	function drawListCard(card:FlxSprite, selected:Bool):Void
	{
		var fill = selected ? 0xFFE8DEFF : 0xFFF8F2FB;
		var stroke = selected ? 0xFF7A63DA : 0xFFE3D9EF;
		MD3ShapeTools.fillAndStrokeRoundRect(card, 454, 56, 18, 2, fill, stroke);
	}

	function drawBindCard(card:FlxSprite, selected:Bool):Void
	{
		var fill = selected ? 0xFFDCD1FF : 0xFFF1EAF8;
		var stroke = selected ? 0xFF6A53D2 : 0xFFD6CAE6;
		MD3ShapeTools.fillAndStrokeRoundRect(card, 188, 56, 16, 2, fill, stroke);
	}

	function applyVerticalClip(spr:FlxSprite, yMin:Float, yMax:Float):Void
	{
		if (spr == null) return;
		var height:Float = spr.frameHeight;
		if (height <= 0)
		{
			spr.visible = false;
			return;
		}

		var topCut:Float = Math.max(0, yMin - spr.y);
		var bottomCut:Float = Math.max(0, (spr.y + height) - yMax);
		var visibleHeight:Float = height - topCut - bottomCut;
		if (visibleHeight <= 0)
		{
			spr.visible = false;
			spr.clipRect = null;
		}
		else
		{
			spr.visible = true;
			spr.clipRect = new FlxRect(0, topCut, spr.frameWidth, visibleHeight);
		}
	}

	function syncVisibleRows(elapsed:Float = 0, instant:Bool = false):Void
	{
		var clipTop = listY + 14;
		var clipBottom = listY + listHeight - 14;
		var topRowY = listY + 18;
		var rowSpacing = 78;
		var follow = instant ? 1.0 : (1 - Math.exp(-elapsed * 14.0));

		for (index in 0...headerRefs.length)
		{
			var ref = headerRefs[index];
			var field = visibleHeaderTexts.members[index];
			if (ref == null || field == null) continue;
			var targetY = topRowY + (ref.targetY + 3) * rowSpacing + 10;
			field.text = ref.text;
			field.x = listX + 28;
			if (instant || field.y == 0)
				field.y = targetY;
			else
				field.y += (targetY - field.y) * follow;
			field.alpha += (0.92 - field.alpha) * follow;
			applyVerticalClip(field, clipTop, clipBottom);
		}

		for (index in 0...optionRefs.length)
		{
			var ref = optionRefs[index];
			var card = visibleRowCards.members[index];
			var field = visibleOptionTexts.members[index];
			if (ref == null || card == null || field == null) continue;

			var selected = ref.ID == curOptionsValid[curSelected];
			var targetCardY = topRowY + (ref.targetY + 3) * rowSpacing;
			var targetAlpha = ref.alpha;
			card.x = listX + 18;
			if (instant || card.y == 0)
				card.y = targetCardY;
			else
				card.y += (targetCardY - card.y) * follow;
			drawListCard(card, selected);
			card.alpha += (targetAlpha - card.alpha) * follow;

			field.text = ref.text;
			field.x = card.x + 18;
			field.y = card.y + 15;
			field.alpha += (targetAlpha - field.alpha) * follow;
			field.color = selected ? 0xFF24173C : 0xFF4C3B66;

			applyVerticalClip(card, clipTop, clipBottom);
			applyVerticalClip(field, clipTop, clipBottom);
		}

		for (index in 0...bindRefs.length)
		{
			var ref = bindRefs[index];
			var card = visibleBindCards.members[index];
			var field = visibleBindTexts.members[index];
			if (ref == null || card == null || field == null) continue;
			var parentRef = optionRefs[Math.floor(index / 2)];
			if (parentRef == null) continue;

			var selected = ref.ID == curSelected && (index % 2) == (curAlt ? 1 : 0);
			var targetCardY = topRowY + (parentRef.targetY + 3) * rowSpacing + 3;
			var targetAlpha = parentRef.alpha;
			card.x = panelX + panelWidth - 444 + (index % 2) * 212;
			if (instant || card.y == 0)
				card.y = targetCardY;
			else
				card.y += (targetCardY - card.y) * follow;
			drawBindCard(card, selected);
			card.alpha += (targetAlpha - card.alpha) * follow;

			field.text = ref.text;
			field.x = card.x + 12;
			field.y = card.y + 18;
			field.fieldWidth = 164;
			field.alignment = CENTER;
			field.alpha += (targetAlpha - field.alpha) * follow;
			field.color = selected ? 0xFF27184A : 0xFF4D3C69;

			applyVerticalClip(card, clipTop, clipBottom);
			applyVerticalClip(field, clipTop, clipBottom);
		}
	}

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingBlack:FlxSprite;
	var bindingPanel:FlxSprite;
	var bindingText:FlxText;
	var bindingText2:FlxText;

	var timeForMoving:Float = 0.1;
	override function update(elapsed:Float)
	{
		if(timeForMoving > 0) //Fix controller bug
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			syncVisibleRows(elapsed);
			return;
		}

		if(!binding)
		{
			if(touchPad.buttonB.justPressed || FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(B))
			{
				controls.isInSubstate = false;
				close();
				return;
			}
			if(FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER) || FlxG.gamepads.anyJustPressed(RIGHT_SHOULDER)) swapMode();

			if(FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(DPAD_LEFT) || FlxG.gamepads.anyJustPressed(DPAD_RIGHT) ||
				FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_LEFT) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_RIGHT)) updateAlt(true);

			if(FlxG.keys.justPressed.UP || FlxG.gamepads.anyJustPressed(DPAD_UP) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_UP)) updateText(-1);
			else if(FlxG.keys.justPressed.DOWN || FlxG.gamepads.anyJustPressed(DPAD_DOWN) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_DOWN)) updateText(1);

			if(FlxG.keys.justPressed.ENTER || FlxG.gamepads.anyJustPressed(START) || FlxG.gamepads.anyJustPressed(A))
			{
				if(options[curOptions[curSelected]][1] != defaultKey)
				{
					bindingBlack = new FlxSprite().makeGraphic(1, 1, /*FlxColor.BLACK*/ FlxColor.WHITE);
					bindingBlack.scale.set(FlxG.width, FlxG.height);
					bindingBlack.updateHitbox();
					bindingBlack.alpha = 0;
					FlxTween.tween(bindingBlack, {alpha: 0.6}, 0.35, {ease: FlxEase.linear});
					add(bindingBlack);

					bindingPanel = new FlxSprite((FlxG.width - 620) * 0.5, (FlxG.height - 220) * 0.5);
					MD3ShapeTools.fillAndStrokeRoundRect(bindingPanel, 620, 220, 28, 2, 0xFFF8F2FB, 0xFFE0D4EE);
					add(bindingPanel);

					bindingText = new FlxText(bindingPanel.x + 28, bindingPanel.y + 34, 564,
						Language.getPhrase('controls_rebinding', 'Rebinding {1}', [options[curOptions[curSelected]][3]]), 28);
					bindingText.setFormat(Paths.font('inter-bold.otf'), 28, 0xFF281B41, CENTER);
					bindingText.antialiasing = ClientPrefs.data.antialiasing;
					add(bindingText);

					final escape:String = (controls.mobileC) ? "B" : "ESC";
					final backspace:String = (controls.mobileC) ? "C" : "Backspace";
					
					bindingText2 = new FlxText(bindingPanel.x + 36, bindingPanel.y + 104, 548,
						Language.getPhrase('controls_rebinding2', 'Hold {1} to Cancel\nHold {2} to Delete', [escape, backspace]), 20);
					bindingText2.setFormat(Paths.font('inter.otf'), 20, 0xFF5C4B77, CENTER);
					bindingText2.antialiasing = ClientPrefs.data.antialiasing;
					add(bindingText2);

					binding = true;
					holdingEsc = 0;
					ClientPrefs.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else
				{
					// Reset to Default
					ClientPrefs.resetKeys(!onKeyboardMode);
					ClientPrefs.reloadVolumeKeys();
					var lastSel:Int = curSelected;
					createTexts();
					curSelected = lastSel;
					updateText();
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
		else
		{
			var altNum:Int = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];
			if(FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
			{
				holdingEsc += elapsed;
				if(holdingEsc > 0.5)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
			{
				holdingEsc += elapsed;
				if(holdingEsc > 0.5)
				{
					if (onKeyboardMode)
						ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
					else
						ClientPrefs.gamepadBinds.get(curOption[2])[altNum] = NONE;
					ClientPrefs.clearInvalidKeys(curOption[2]);
					updateBind(Math.floor(curSelected * 2) + altNum, onKeyboardMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
					FlxG.sound.play(Paths.sound('cancelMenu'));
					closeBinding();
				}
			}
			else
			{
				holdingEsc = 0;
				var changed:Bool = false;
				var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);
				var curButtons:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(curOption[2]);

				if(onKeyboardMode)
				{
					if(FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
					{
						var keyPressed:Int = FlxG.keys.firstJustPressed();
						var keyReleased:Int = FlxG.keys.firstJustReleased();
						if (keyPressed > -1 && keyPressed != FlxKey.ESCAPE && keyPressed != FlxKey.BACKSPACE)
						{
							curKeys[altNum] = keyPressed;
							changed = true;
						}
						else if (keyReleased > -1 && (keyReleased == FlxKey.ESCAPE || keyReleased == FlxKey.BACKSPACE))
						{
							curKeys[altNum] = keyReleased;
							changed = true;
						}
					}
				}
				else if(FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER) || FlxG.gamepads.anyJustReleased(ANY))
				{
					var keyPressed:Null<FlxGamepadInputID> = NONE;
					var keyReleased:Null<FlxGamepadInputID> = NONE;
					if(FlxG.gamepads.anyJustPressed(LEFT_TRIGGER)) keyPressed = LEFT_TRIGGER; //it wasnt working for some reason
					else if(FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)) keyPressed = RIGHT_TRIGGER; //it wasnt working for some reason
					else
					{
						for (i in 0...FlxG.gamepads.numActiveGamepads)
						{
							var gamepad:FlxGamepad = FlxG.gamepads.getByID(i);
							if(gamepad != null)
							{
								keyPressed = gamepad.firstJustPressedID();
								keyReleased = gamepad.firstJustReleasedID();

								if(keyPressed == null) keyPressed = NONE;
								if(keyReleased == null) keyReleased = NONE;
								if(keyPressed != NONE || keyReleased != NONE) break;
							}
						}
					}

					if (keyPressed != NONE && keyPressed != FlxGamepadInputID.BACK && keyPressed != FlxGamepadInputID.B)
					{
						curButtons[altNum] = keyPressed;
						changed = true;
					}
					else if (keyReleased != NONE && (keyReleased == FlxGamepadInputID.BACK || keyReleased == FlxGamepadInputID.B))
					{
						curButtons[altNum] = keyReleased;
						changed = true;
					}
				}

				if(changed)
				{
					if (onKeyboardMode)
					{
						if(curKeys[altNum] == curKeys[1 - altNum])
							curKeys[1 - altNum] = FlxKey.NONE;
					}
					else
					{
						if(curButtons[altNum] == curButtons[1 - altNum])
							curButtons[1 - altNum] = FlxGamepadInputID.NONE;
					}

					var option:String = options[curOptions[curSelected]][2];
					ClientPrefs.clearInvalidKeys(option);
					for (n in 0...2)
					{
						var key:String = null;
						if(onKeyboardMode)
						{
							var savKey:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(option);
							key = InputFormatter.getKeyName(savKey[n] != null ? savKey[n] : NONE);
						}
						else
						{
							var savKey:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(option);
							key = InputFormatter.getGamepadName(savKey[n] != null ? savKey[n] : NONE);
						}
						updateBind(Math.floor(curSelected * 2) + n, key);
					}
					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
		}
		super.update(elapsed);
		syncVisibleRows(elapsed);
	}

	function closeBinding()
	{
		binding = false;
		bindingBlack.destroy();
		remove(bindingBlack);

		bindingPanel.destroy();
		remove(bindingPanel);

		bindingText.destroy();
		remove(bindingText);

		bindingText2.destroy();
		remove(bindingText2);
		ClientPrefs.reloadVolumeKeys();
	}

	function updateText(?change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, curOptions.length - 1);

		var num:Int = curOptionsValid[curSelected];
		var addNum:Int = 0;
		if(num < 3) addNum = 3 - num;
		else if(num > lastID - 4) addNum = (lastID - 4) - num;

		grpDisplay.forEachAlive(function(item:Alphabet) {
			item.targetY = item.ID - num - addNum;
		});

		grpOptions.forEachAlive(function(item:Alphabet)
		{
			item.targetY = item.ID - num - addNum;
			item.alpha = (item.ID - num == 0) ? 1 : 0.6;
		});
		grpBinds.forEachAlive(function(item:Alphabet)
		{
			var parent:Alphabet = grpOptions.members[item.ID];
			item.targetY = parent.targetY;
			item.alpha = parent.alpha;
		});

		updateAlt();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function swapMode()
	{
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.5, bg.color, onKeyboardMode ? gamepadColor : keyboardColor, {ease: FlxEase.linear});
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 106, 34, 34, 0, 0, 0xFFFFFBFF);
		onKeyboardMode = !onKeyboardMode;

		curSelected = 0;
		curAlt = false;
		controllerSpr.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');
		createTexts();
	}

	function updateAlt(?doSwap:Bool = false)
	{
		if(doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		selectSpr.sprTracker = grpBlacks.members[Math.floor(curSelected * 2) + (curAlt ? 1 : 0)];
		selectSpr.visible = false;
	}
}