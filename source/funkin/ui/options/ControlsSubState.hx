package funkin.ui.options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.input.InputFormatter;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialDialog;

typedef ControlsHeaderRef = {
	var rowID:Int;
	var targetY:Int;
	var alpha:Float;
	var text:String;
}

typedef ControlsOptionRef = {
	var rowID:Int;
	var optionIndex:Int;
	var targetY:Int;
	var alpha:Float;
	var text:String;
	var hasBinds:Bool;
}

typedef ControlsBindRef = {
	var optionIndex:Int;
	var bindSlot:Int;
	var targetY:Int;
	var alpha:Float;
	var text:String;
}

class ControlsSubState extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var curAlt:Bool = false;

	// Show on gamepad - Display name - Save file key - Rebind display name
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
		[false],
		[false, 'WINDOW'],
		[false, 'Fullscreen', 'fullscreen', 'Fullscreen Toggel']
	];
	var curOptions:Array<Int>;
	var curOptionsValid:Array<Int>;
	static var defaultKey:String = 'Reset to Default Keys';

	var bg:FlxSprite;
	var grid:FlxBackdrop;
	var visibleRowCards:FlxTypedGroup<FlxSprite>;
	var visibleOptionTexts:FlxTypedGroup<FlxText>;
	var visibleBindCards:FlxTypedGroup<FlxSprite>;
	var visibleBindTexts:FlxTypedGroup<FlxText>;
	var visibleHeaderTexts:FlxTypedGroup<FlxText>;
	var rowCardSelectedStates:Array<Null<Bool>> = [];
	var bindCardSelectedStates:Array<Null<Bool>> = [];
	var headerRefs:Array<ControlsHeaderRef> = [];
	var optionRefs:Array<ControlsOptionRef> = [];
	var bindRefs:Array<ControlsBindRef> = [];

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
	var lastVisibleRowID:Int = 0;

	var binding:Bool = false;
	var holdingEsc:Float = 0;
	var bindingDialog:MaterialDialog;

	var timeForMoving:Float = 0.1;

	public function new()
	{
		controls.isInSubstate = true;

		super();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Controls Menu', null);
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

		var overlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, OptionsMenuTheme.backdropColor());
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
		grid.color = OptionsMenuTheme.gridAccentColor();
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		var panelShadow:FlxSprite = new FlxSprite(panelX + 10, panelY + 12);
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x2A000000);
		add(panelShadow);

		var panelSurface:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, OptionsMenuTheme.panelSurfaceColor());
		add(panelSurface);

		panelHeader = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 106, 34, 34, 0, 0, OptionsMenuTheme.panelHeaderColor());
		add(panelHeader);

		var panelOutline:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, OptionsMenuTheme.neutralOutlineColor());
		add(panelOutline);

		var listSurface:FlxSprite = new FlxSprite(listX, listY);
		MD3ShapeTools.fillAndStrokeRoundRect(listSurface, Std.int(listWidth), Std.int(panelHeight - 164), 28, 2,
			OptionsMenuTheme.previewSurfaceColor(), OptionsMenuTheme.neutralOutlineColor());
		add(listSurface);

		var titleText:FlxText = new FlxText(panelX + 34, panelY + 18, panelWidth - 68, Language.getPhrase('controls_menu', 'Controls'), 30);
		titleText.setFormat(Paths.font('inter-bold.otf'), 30, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		var subtitleText:FlxText = new FlxText(panelX + 34, panelY + 58, panelWidth - 68,
			Language.getPhrase('controls_menu_subtitle', 'Rebind keyboard and gamepad inputs without digging through the whole engine basement.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		var footerText:FlxText = new FlxText(panelX + 34, panelY + panelHeight - 40, panelWidth - 68,
			Language.getPhrase('controls_menu_footer', 'ENTER opens the rebind dialog. LEFT / RIGHT swaps primary and alternate. CTRL or shoulder buttons switch keyboard/gamepad.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), LEFT);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

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
		modeHint.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), RIGHT);
		modeHint.antialiasing = ClientPrefs.data.antialiasing;
		add(modeHint);

		createTexts();

		addTouchPad('NONE', 'B');
	}

	function createTexts():Void
	{
		curOptions = [];
		curOptionsValid = [];
		headerRefs = [];
		optionRefs = [];
		bindRefs = [];
		rowCardSelectedStates = [];
		bindCardSelectedStates = [];
		clearVisibleGroups();

		var rowID:Int = 0;
		for (optionIndex => option in options)
		{
			if (!onKeyboardMode && !option[0])
				continue;

			if (option.length > 1)
			{
				var isCentered:Bool = option.length < 3;
				var isDefaultOption:Bool = option[1] == defaultKey;
				var isHeader:Bool = isCentered && !isDefaultOption;
				var label:String = getOptionLabel(option, isHeader);

				if (isHeader)
				{
					headerRefs.push({
						rowID: rowID,
						targetY: rowID,
						alpha: 0.92,
						text: label
					});

					var headerText = new FlxText(listX + 28, listY, listWidth - 56, label, 20);
					headerText.setFormat(Paths.font('inter-bold.otf'), 20, OptionsMenuTheme.titleColor(), LEFT);
					headerText.antialiasing = ClientPrefs.data.antialiasing;
					visibleHeaderTexts.add(headerText);
				}
				else
				{
					var hasBinds:Bool = !isCentered;
					curOptions.push(optionIndex);
					curOptionsValid.push(rowID);
					optionRefs.push({
						rowID: rowID,
						optionIndex: optionIndex,
						targetY: rowID,
						alpha: 1,
						text: label,
						hasBinds: hasBinds
					});

					var rowCard = new FlxSprite();
					visibleRowCards.add(rowCard);
					rowCardSelectedStates.push(null);

					var labelText = new FlxText(listX + 24, listY, 440, label, 20);
					labelText.setFormat(Paths.font('inter-bold.otf'), 20, OptionsMenuTheme.optionTitleColor(false), LEFT);
					labelText.antialiasing = ClientPrefs.data.antialiasing;
					visibleOptionTexts.add(labelText);

					if (hasBinds)
					{
						for (slot in 0...2)
						{
							bindRefs.push({
								optionIndex: optionIndex,
								bindSlot: slot,
								targetY: rowID,
								alpha: 1,
								text: getBindDisplayText(option[2], slot)
							});

							var bindCard = new FlxSprite();
							visibleBindCards.add(bindCard);
							bindCardSelectedStates.push(null);

							var bindText = new FlxText(panelX + panelWidth - 444 + slot * 212, listY, 184, '', 17);
							bindText.setFormat(Paths.font('inter.otf'), 17, OptionsMenuTheme.optionDescriptionColor(false), CENTER);
							bindText.antialiasing = ClientPrefs.data.antialiasing;
							visibleBindTexts.add(bindText);
						}
					}
				}
			}

			rowID++;
		}

		lastVisibleRowID = Std.int(Math.max(0, rowID - 1));
		updateText(0, true);
		syncVisibleRows(0, true);
	}

	function clearVisibleGroups():Void
	{
		for (card in visibleRowCards.members)
			if (card != null) card.destroy();
		for (text in visibleOptionTexts.members)
			if (text != null) text.destroy();
		for (card in visibleBindCards.members)
			if (card != null) card.destroy();
		for (text in visibleBindTexts.members)
			if (text != null) text.destroy();
		for (text in visibleHeaderTexts.members)
			if (text != null) text.destroy();

		visibleRowCards.clear();
		visibleOptionTexts.clear();
		visibleBindCards.clear();
		visibleBindTexts.clear();
		visibleHeaderTexts.clear();
	}

	function getOptionLabel(option:Array<Dynamic>, isHeader:Bool):String
	{
		var rawLabel:String = option[1];
		if (rawLabel == defaultKey)
			return Language.getPhrase(rawLabel);

		if (isHeader)
			return Language.getPhrase('keygroup_' + rawLabel, rawLabel);

		return Language.getPhrase('key_' + option[2], rawLabel);
	}

	function getBindDisplayText(bindKey:String, slot:Int):String
	{
		if (onKeyboardMode)
		{
			var keys:Array<Null<FlxKey>> = ClientPrefs.keyBinds.get(bindKey);
			if (keys == null) keys = ClientPrefs.defaultKeys.get(bindKey).copy();
			return InputFormatter.getKeyName(keys[slot] != null ? keys[slot] : NONE);
		}

		var buttons:Array<Null<FlxGamepadInputID>> = ClientPrefs.gamepadBinds.get(bindKey);
		if (buttons == null) buttons = ClientPrefs.defaultButtons.get(bindKey).copy();
		return InputFormatter.getGamepadName(buttons[slot] != null ? buttons[slot] : NONE);
	}

	function getOptionRef(optionIndex:Int):ControlsOptionRef
	{
		for (optionRef in optionRefs)
			if (optionRef.optionIndex == optionIndex) return optionRef;

		return null;
	}

	function getBindRefIndex(optionIndex:Int, bindSlot:Int):Int
	{
		for (index in 0...bindRefs.length)
		{
			var bindRef = bindRefs[index];
			if (bindRef.optionIndex == optionIndex && bindRef.bindSlot == bindSlot)
				return index;
		}

		return -1;
	}

	function updateBind(bindIndex:Int, text:String):Void
	{
		if (bindIndex < 0 || bindIndex >= bindRefs.length) return;
		bindRefs[bindIndex].text = text;
		syncVisibleRows(0, true);
	}

	function drawListCard(card:FlxSprite, selected:Bool):Void
	{
		var fill = OptionsMenuTheme.cardFill(selected);
		var stroke = OptionsMenuTheme.cardStroke(selected);
		MD3ShapeTools.fillAndStrokeRoundRect(card, 454, 56, 18, 2, fill, stroke);
	}

	function drawBindCard(card:FlxSprite, selected:Bool):Void
	{
		var fill = OptionsMenuTheme.cardFill(selected);
		var stroke = OptionsMenuTheme.cardStroke(selected);
		MD3ShapeTools.fillAndStrokeRoundRect(card, 188, 56, 16, 2, fill, stroke);
	}

	inline function refreshRowCardVisual(index:Int, card:FlxSprite, selected:Bool, ?force:Bool = false):Void
	{
		if (force || rowCardSelectedStates[index] == null || rowCardSelectedStates[index] != selected)
		{
			drawListCard(card, selected);
			rowCardSelectedStates[index] = selected;
		}
	}

	inline function refreshBindCardVisual(index:Int, card:FlxSprite, selected:Bool, ?force:Bool = false):Void
	{
		if (force || bindCardSelectedStates[index] == null || bindCardSelectedStates[index] != selected)
		{
			drawBindCard(card, selected);
			bindCardSelectedStates[index] = selected;
		}
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
		if (curOptions == null || curOptions.length == 0) return;

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
			field.alpha += (ref.alpha - field.alpha) * follow;

			applyVerticalClip(field, clipTop, clipBottom);
		}

		for (index in 0...optionRefs.length)
		{
			var ref = optionRefs[index];
			var card = visibleRowCards.members[index];
			var field = visibleOptionTexts.members[index];
			if (ref == null || card == null || field == null) continue;

			var selected = ref.optionIndex == curOptions[curSelected];
			var targetCardY = topRowY + (ref.targetY + 3) * rowSpacing;
			card.x = listX + 18;
			if (instant || card.y == 0)
				card.y = targetCardY;
			else
				card.y += (targetCardY - card.y) * follow;
			refreshRowCardVisual(index, card, selected, instant);
			card.alpha += (ref.alpha - card.alpha) * follow;

			field.text = ref.text;
			field.x = card.x + 18;
			field.y = card.y + 15;
			field.alpha += (ref.alpha - field.alpha) * follow;
			field.color = OptionsMenuTheme.optionTitleColor(selected);

			applyVerticalClip(card, clipTop, clipBottom);
			applyVerticalClip(field, clipTop, clipBottom);
		}

		for (index in 0...bindRefs.length)
		{
			var ref = bindRefs[index];
			var card = visibleBindCards.members[index];
			var field = visibleBindTexts.members[index];
			if (ref == null || card == null || field == null) continue;

			var parentRef = getOptionRef(ref.optionIndex);
			if (parentRef == null) continue;

			var selected = ref.optionIndex == curOptions[curSelected] && ref.bindSlot == (curAlt ? 1 : 0);
			var targetCardY = topRowY + (parentRef.targetY + 3) * rowSpacing + 3;
			card.x = panelX + panelWidth - 444 + ref.bindSlot * 212;
			if (instant || card.y == 0)
				card.y = targetCardY;
			else
				card.y += (targetCardY - card.y) * follow;
			refreshBindCardVisual(index, card, selected, instant);
			card.alpha += (ref.alpha - card.alpha) * follow;

			field.text = ref.text;
			field.x = card.x + 12;
			field.y = card.y + 18;
			field.fieldWidth = 164;
			field.alignment = CENTER;
			field.alpha += (ref.alpha - field.alpha) * follow;
			field.color = OptionsMenuTheme.optionDescriptionColor(selected);

			applyVerticalClip(card, clipTop, clipBottom);
			applyVerticalClip(field, clipTop, clipBottom);
		}
	}

	override function update(elapsed:Float):Void
	{
		if (timeForMoving > 0)
		{
			timeForMoving = Math.max(0, timeForMoving - elapsed);
			super.update(elapsed);
			syncVisibleRows(elapsed);
			return;
		}

		if (!binding)
		{
			if (touchPad.buttonB.justPressed || FlxG.keys.justPressed.ESCAPE || FlxG.gamepads.anyJustPressed(B))
			{
				controls.isInSubstate = false;
				close();
				return;
			}

			if (FlxG.keys.justPressed.CONTROL || FlxG.gamepads.anyJustPressed(LEFT_SHOULDER) || FlxG.gamepads.anyJustPressed(RIGHT_SHOULDER))
				swapMode();

			if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT || FlxG.gamepads.anyJustPressed(DPAD_LEFT) || FlxG.gamepads.anyJustPressed(DPAD_RIGHT)
				|| FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_LEFT) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_RIGHT))
				updateAlt(true);

			if (FlxG.keys.justPressed.UP || FlxG.gamepads.anyJustPressed(DPAD_UP) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_UP))
				updateText(-1);
			else if (FlxG.keys.justPressed.DOWN || FlxG.gamepads.anyJustPressed(DPAD_DOWN) || FlxG.gamepads.anyJustPressed(LEFT_STICK_DIGITAL_DOWN))
				updateText(1);

			if (FlxG.keys.justPressed.ENTER || FlxG.gamepads.anyJustPressed(START) || FlxG.gamepads.anyJustPressed(A))
			{
				var selectedOption = options[curOptions[curSelected]];
				if (selectedOption[1] != defaultKey)
				{
					openBindingDialog();
					binding = true;
					holdingEsc = 0;
					ClientPrefs.toggleVolumeKeys(false);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				else
				{
					ClientPrefs.resetKeys(!onKeyboardMode);
					ClientPrefs.reloadVolumeKeys();
					var lastSelection = curSelected;
					createTexts();
					curSelected = FlxMath.wrap(lastSelection, 0, curOptions.length - 1);
					updateText(0, true);
					FlxG.sound.play(Paths.sound('cancelMenu'));
				}
			}
		}
		else
		{
			var altNum = curAlt ? 1 : 0;
			var curOption:Array<Dynamic> = options[curOptions[curSelected]];

			if (FlxG.keys.pressed.ESCAPE || FlxG.gamepads.anyPressed(B))
			{
				holdingEsc += elapsed;
				if (holdingEsc > 0.5)
				{
					FlxG.sound.play(Paths.sound('cancelMenu'));
					cancelBinding();
				}
			}
			else if (FlxG.keys.pressed.BACKSPACE || FlxG.gamepads.anyPressed(BACK))
			{
				holdingEsc += elapsed;
				if (holdingEsc > 0.5)
				{
					clearCurrentBinding();
				}
			}
			else
			{
				holdingEsc = 0;
				var changed:Bool = false;
				var curKeys:Array<FlxKey> = ClientPrefs.keyBinds.get(curOption[2]);
				var curButtons:Array<FlxGamepadInputID> = ClientPrefs.gamepadBinds.get(curOption[2]);

				if (onKeyboardMode)
				{
					if (FlxG.keys.justPressed.ANY || FlxG.keys.justReleased.ANY)
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
				else if (FlxG.gamepads.anyJustPressed(ANY) || FlxG.gamepads.anyJustPressed(LEFT_TRIGGER) || FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER)
					|| FlxG.gamepads.anyJustReleased(ANY))
				{
					var keyPressed:Null<FlxGamepadInputID> = NONE;
					var keyReleased:Null<FlxGamepadInputID> = NONE;
					if (FlxG.gamepads.anyJustPressed(LEFT_TRIGGER))
						keyPressed = LEFT_TRIGGER;
					else if (FlxG.gamepads.anyJustPressed(RIGHT_TRIGGER))
						keyPressed = RIGHT_TRIGGER;
					else
					{
						for (gamepadIndex in 0...FlxG.gamepads.numActiveGamepads)
						{
							var gamepad:FlxGamepad = FlxG.gamepads.getByID(gamepadIndex);
							if (gamepad == null) continue;

							keyPressed = gamepad.firstJustPressedID();
							keyReleased = gamepad.firstJustReleasedID();

							if (keyPressed == null) keyPressed = NONE;
							if (keyReleased == null) keyReleased = NONE;
							if (keyPressed != NONE || keyReleased != NONE) break;
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

				if (changed)
				{
					if (onKeyboardMode)
					{
						if (curKeys[altNum] == curKeys[1 - altNum])
							curKeys[1 - altNum] = FlxKey.NONE;
					}
					else
					{
						if (curButtons[altNum] == curButtons[1 - altNum])
							curButtons[1 - altNum] = FlxGamepadInputID.NONE;
					}

					var optionKey:String = curOption[2];
					ClientPrefs.clearInvalidKeys(optionKey);
					for (slot in 0...2)
						updateBind(getBindRefIndex(curOptions[curSelected], slot), getBindDisplayText(optionKey, slot));

					FlxG.sound.play(Paths.sound('confirmMenu'));
					closeBinding();
				}
			}
		}

		super.update(elapsed);
		syncVisibleRows(elapsed);
	}

	function openBindingDialog():Void
	{
		var selectedOption = options[curOptions[curSelected]];
		var targetInput:String = onKeyboardMode
			? Language.getPhrase('controls_rebinding_keyboard', 'keyboard key')
			: Language.getPhrase('controls_rebinding_gamepad', 'gamepad button');
		var targetSlot:String = curAlt
			? Language.getPhrase('controls_rebinding_alt_slot', 'Alternate slot')
			: Language.getPhrase('controls_rebinding_primary_slot', 'Primary slot');
		var escape:String = controls.mobileC ? 'B' : 'ESC';
		var backspace:String = controls.mobileC ? 'C' : 'Backspace';

		if (bindingDialog != null)
		{
			remove(bindingDialog);
			bindingDialog.destroy();
			bindingDialog = null;
		}

		bindingDialog = new MaterialDialog(
			Language.getPhrase('controls_rebinding', 'Rebinding {1}', [selectedOption[3]]),
			Language.getPhrase('controls_rebinding_dialog_body',
				'Waiting for a {1}.\nTarget: {2}.\n\nPress anything to bind it.\nHold {3} to cancel.\nHold {4} to clear this slot.',
				[targetInput, targetSlot, escape, backspace]),
			Language.getPhrase('controls_rebinding_clear_button', 'Clear bind'),
			Language.getPhrase('controls_rebinding_cancel_button', 'Cancel'),
			function()
			{
				clearCurrentBinding();
			},
			function()
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				cancelBinding();
			}
		);
		add(bindingDialog);
		bindingDialog.open();
	}

	function cancelBinding():Void
	{
		if (!binding) return;
		closeBinding();
	}

	function clearCurrentBinding():Void
	{
		if (!binding) return;

		var altNum = curAlt ? 1 : 0;
		var curOption:Array<Dynamic> = options[curOptions[curSelected]];
		if (onKeyboardMode)
			ClientPrefs.keyBinds.get(curOption[2])[altNum] = NONE;
		else
			ClientPrefs.gamepadBinds.get(curOption[2])[altNum] = NONE;

		ClientPrefs.clearInvalidKeys(curOption[2]);
		updateBind(getBindRefIndex(curOptions[curSelected], altNum), onKeyboardMode ? InputFormatter.getKeyName(NONE) : InputFormatter.getGamepadName(NONE));
		FlxG.sound.play(Paths.sound('cancelMenu'));
		closeBinding();
	}

	function closeBinding():Void
	{
		binding = false;
		holdingEsc = 0;

		if (bindingDialog != null)
		{
			remove(bindingDialog);
			bindingDialog.destroy();
			bindingDialog = null;
		}

		ClientPrefs.reloadVolumeKeys();
	}

	function updateText(?change:Int = 0, ?silent:Bool = false):Void
	{
		if (curOptions == null || curOptions.length == 0) return;

		curSelected = FlxMath.wrap(curSelected + change, 0, curOptions.length - 1);

		var currentRow = curOptionsValid[curSelected];
		var addNum = 0;
		if (currentRow < 3)
			addNum = 3 - currentRow;
		else if (currentRow > lastVisibleRowID - 4)
			addNum = (lastVisibleRowID - 4) - currentRow;

		for (headerRef in headerRefs)
		{
			headerRef.targetY = headerRef.rowID - currentRow - addNum;
			headerRef.alpha = 0.92;
		}

		for (optionRef in optionRefs)
		{
			optionRef.targetY = optionRef.rowID - currentRow - addNum;
			optionRef.alpha = optionRef.optionIndex == curOptions[curSelected] ? 1 : 0.6;
		}

		for (bindRef in bindRefs)
		{
			var parentRef = getOptionRef(bindRef.optionIndex);
			if (parentRef == null) continue;
			bindRef.targetY = parentRef.targetY;
			bindRef.alpha = parentRef.alpha;
		}

		updateAlt();
		if (!silent)
			FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function swapMode():Void
	{
		FlxTween.cancelTweensOf(bg);
		FlxTween.color(bg, 0.5, bg.color, onKeyboardMode ? gamepadColor : keyboardColor, {ease: FlxEase.linear});
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 106, 34, 34, 0, 0, OptionsMenuTheme.panelHeaderColor());
		onKeyboardMode = !onKeyboardMode;

		curSelected = 0;
		curAlt = false;
		controllerSpr.animation.play(onKeyboardMode ? 'keyboard' : 'gamepad');
		createTexts();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function updateAlt(?doSwap:Bool = false):Void
	{
		if (doSwap)
		{
			curAlt = !curAlt;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
	}
}