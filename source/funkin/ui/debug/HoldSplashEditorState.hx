package funkin.ui.debug;

import funkin.play.notes.Note;
import funkin.play.notes.SustainSplash;
import funkin.play.notes.StrumNote;
import funkin.graphics.shaders.RGBPalette;

import openfl.net.FileFilter;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.input.keyboard.FlxKey;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import haxe.Json;

@:access(funkin.play.notes.SustainSplash)
class HoldSplashEditorState extends MusicBeatState
{
	var strums:FlxTypedSpriteGroup<StrumNote> = new FlxTypedSpriteGroup();
	var holdSplashes:FlxTypedSpriteGroup<SustainSplash> = new FlxTypedSpriteGroup();
	var config = SustainSplash.createConfig();

	var tipText:FlxText;
	var errorText:FlxText;
	var curText:FlxText;

	static var imageSkin:String = null;
	var holdSplash:SustainSplash;

	var UI:PsychUIBox;
	var properUI:PsychUIBox;
	var shaderUI:PsychUIBox;

	override function create()
	{
		if (imageSkin == null)
			imageSkin = SustainSplash.defaultHoldSplash + SustainSplash.getHoldSplashPostfix();

		Cursor.show();

		FlxG.sound.volumeUpKeys = [];
		FlxG.sound.volumeDownKeys = [];
		FlxG.sound.muteKeys = [];

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Hold Splash Editor');
		#end

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF505050;
		add(bg);

		UI = new PsychUIBox(0, 0, 0, 0, ["Animation"]);
		UI.canMove = UI.canMinimize = false;
		UI.y += 20;
		UI.x = FlxG.width - 300;
		UI.resize(290, 240);

		properUI = new PsychUIBox(0, 0, 0, 0, ["Properties"]);
		properUI.canMove = properUI.canMinimize = false;
		properUI.resize(280, 210);
		properUI.y += 20;
		properUI.x = UI.x - properUI.width - 5;
		add(properUI);
		add(UI);

		shaderUI = new PsychUIBox(0, 0, 0, 0, ["Shader"]);
		shaderUI.canMove = shaderUI.canMinimize = false;
		shaderUI.resize(160, 180);
		shaderUI.x = FlxG.width - shaderUI.width - 10;
		shaderUI.y = UI.y + UI.height + 10;
		add(shaderUI);

		final buttonF1:String = (controls.mobileC) ? "F" : "F1";

		var tipText:FlxText = new FlxText();
		tipText.setFormat(null, 24);
		tipText.text = 'Press $buttonF1 for Help';
		tipText.setPosition(properUI.x - properUI.width + 15, UI.y);
		add(tipText);

		for (i in 0...4)
		{
			var babyArrow:StrumNote = new StrumNote(-273, 50, i % 4, 1);
			babyArrow.playerPosition();
			babyArrow.screenCenter(Y);
			babyArrow.ID = i;
			strums.add(babyArrow);
		}

		add(strums);
		add(holdSplashes);

		holdSplash = new SustainSplash(imageSkin);
		holdSplash.alpha = .0;
		holdSplashes.add(holdSplash);

		if (holdSplash.config != null)
			config = holdSplash.config;

		parseRGB();

		addPropertiesTab();
		addAnimTab();
		addShadersTab();

		errorText = new FlxText();
		errorText.setFormat(null, 16, FlxColor.RED);
		errorText.text = "ERROR!";
		errorText.y = FlxG.height - errorText.height;
		errorText.alpha = .0;
		add(errorText);

		curText = new FlxText();
		curText.setFormat(null, 24, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		curText.text = 'Copied Offsets: [0, 0]\nCurrent Animation: NONE';
		curText.y = FlxG.height - curText.height;
		curText.x += 5;
		add(curText);

		addTouchPad('LEFT_FULL', 'NOTE_SPLASH_EDITOR'); // Reusing same touchpad layout

		super.create();
	}

	var animDropDown:PsychUIDropDownMenu;
	var curAnim:String = "hold";
	var addButton:PsychUIButton;
	var curAnimText = null;
	var templateButton:PsychUIButton;
	
	function addAnimTab()
	{
		var UI = UI.getTab("Animation").menu;

		UI.add(new FlxText(20, 20, 0, "Animation Name:", 8));
		var name_input:PsychUIInputText = new PsychUIInputText(20, 37.5, 100, "", 8);
		name_input.name = "name_input";
		curAnimText = name_input;
		UI.add(name_input);

		UI.add(new FlxText(name_input.x, name_input.y + 30, 0, "Animation Prefix:", 8));
		var prefix_input:PsychUIInputText = new PsychUIInputText(20, name_input.y + 47.5, 100, "", 8);
		UI.add(prefix_input);

		UI.add(new FlxText(150, 20, 0, "FPS:", 8));
		var fpsNumericStepper = new PsychUINumericStepper(150, 37.5, 1, 24, 1, 120, 0);
		UI.add(fpsNumericStepper);

		UI.add(new FlxText(150, name_input.y + 30, 0, "Looped:", 8));
		var loopedCheckbox:PsychUICheckBox = new PsychUICheckBox(150, name_input.y + 50, "", 1);
		UI.add(loopedCheckbox);

		animDropDown = new PsychUIDropDownMenu(-155, 57, [""], function(id:Int, name:String)
		{
			if (config != null && name.length > 0)
			{
				var i = config.animations.get(name);
				if (i != null)
				{
					name_input.text = name;
					prefix_input.text = i.prefix;
					fpsNumericStepper.value = i.fps;
					loopedCheckbox.checked = i.looped;
					curAnim = name;

					playHoldSplash(curAnim);
				}
			}
		});

		function setAnimDropDown()
		{
			var anims:Array<String> = [];
			if (config != null && config.animations != null)
				for (i in config.animations.keys())
				{
					anims.push(i);
				}

			if (anims.length < 1)
				anims.push("");

			if (curAnim == null && anims[0].length > 0)
				curAnim = anims[0];

			animDropDown.list = anims;
			animDropDown.selectedLabel = curAnim;
		}

		setAnimDropDown();

		templateButton.onClick = function()
		{
			SustainSplash.configs.clear();
			config = SustainSplash.createConfig();

			curAnim = "hold";
			name_input.text = "";
			prefix_input.text = "";
			fpsNumericStepper.value = 24;
			loopedCheckbox.checked = true;
			setAnimDropDown();
			parseRGB();
			changeShader.selectedLabel = "Red";
			changeShader.onSelect(0, "Red");
		}

		addButton = new PsychUIButton(20, 185, "Add/Update", function()
		{
			var offsets:Array<Float> = [0, 0];
			var conf = config.animations.get(name_input.text);

			if (conf != null)
				offsets = conf.offsets;

			if (offsets == null)
				offsets = [0, 0];
			else
				offsets = offsets.copy();

			config = SustainSplash.addAnimationToConfig(
				config,
				name_input.text,
				prefix_input.text,
				Std.int(fpsNumericStepper.value),
				loopedCheckbox.checked,
				offsets
			);
			curAnim = name_input.text;
			playHoldSplash(curAnim);
			setAnimDropDown();
		});
		UI.add(addButton);

		var removeButton:PsychUIButton = new PsychUIButton(185, 185, "Remove", function()
		{
			if (config != null)
			{
				if (config.animations.exists(curAnim))
				{
					config.animations.remove(curAnim);

					curAnim = "hold";
					name_input.text = "";
					prefix_input.text = "";
					fpsNumericStepper.value = 24;
					loopedCheckbox.checked = true;
					setAnimDropDown();
				}
			}
		});
		UI.add(removeButton);
		UI.add(animDropDown);

		reloadImage = function()
		{
			imageSkin = imageInputText.text;

			errorText.color = FlxColor.RED;
			FlxTween.cancelTweensOf(errorText);

			var image = Paths.image(imageSkin);
			if (image == null)
			{
				errorText.text = 'ERROR! Couldn\'t find $imageSkin.png';
				errorText.alpha = 1;
				return;
			}
			else
			{
				errorText.color = FlxColor.GREEN;
				errorText.alpha = 1;
				errorText.text = 'Successfully loaded $imageSkin.png';
			}

			SustainSplash.configs.clear();

			FlxTween.tween(errorText, {alpha: 0}, 1, {
				startDelay: 1, 
				onComplete: (twn) -> {
					errorText.color = FlxColor.RED;
				}
			});

			holdSplash.loadHoldSplash(imageSkin);
			holdSplash.alpha = 0.0001;

			if (holdSplash.config != null) config = holdSplash.config;
			else config = SustainSplash.createConfig();

			curAnim = "hold";
			name_input.text = "";
			prefix_input.text = "";
			fpsNumericStepper.value = 24;
			loopedCheckbox.checked = true;
			setAnimDropDown();
			parseRGB();
			changeShader.selectedLabel = "Red";
			changeShader.onSelect(0, "Red");
		}
	}

	var imageInputText:PsychUIInputText;
	var scaleNumericStepper:PsychUINumericStepper;
	
	function addPropertiesTab()
	{
		var ui = properUI.getTab("Properties").menu;

		ui.add(new FlxText(20, 10, 0, "Image:"));
		imageInputText = new PsychUIInputText(60, 10, 120, imageSkin, 8);
		ui.add(imageInputText);

		var reloadButton:PsychUIButton = new PsychUIButton(185, 6.8, "Reload Image", function()
		{
			reloadImage();
		});
		ui.add(reloadButton);

		ui.add(new FlxText(20, 40, "Scale:"));
		scaleNumericStepper = new PsychUINumericStepper(20, 57.5, 0.1, 1, 0, 4, 2, 60);
		ui.add(scaleNumericStepper);

		scaleNumericStepper.value = config != null ? config.scale : 1;

		ui.add(new FlxText(130, 40, "Animations:"));
		var animCount:FlxText = new FlxText(130, 57.5, 100, "Hold + End");
		ui.add(animCount);

		var saveButton:PsychUIButton = new PsychUIButton(20, 130, "Save", saveHoldSplash);
		ui.add(saveButton);

		templateButton = new PsychUIButton(20, 155, "Template");
		ui.add(templateButton);

		var allowRGBCheck:PsychUICheckBox = new PsychUICheckBox(20, 105, "", 1);
		function check()
		{
			if (config != null)
				config.allowRGB = allowRGBCheck.checked;
			refreshPreviewShader();
		}
		allowRGBCheck.onClick = check;
		allowRGBCheck.checked = config != null && cast(config.allowRGB, Null<Bool>) != null ? config.allowRGB : false;

		var rgbText = new FlxText(allowRGBCheck.x + 20, 0);
		rgbText.text = "Allow RGB?";
		rgbText.y = allowRGBCheck.y + 2.5;
		ui.add(rgbText);

		ui.add(allowRGBCheck);

		var allowPixelCheck:PsychUICheckBox = new PsychUICheckBox(allowRGBCheck.x + 110, allowRGBCheck.y, "", 1);
		function check()
		{
			if (config != null)
				config.allowPixel = allowPixelCheck.checked;
		}
		allowPixelCheck.onClick = check;
		allowPixelCheck.checked = config != null && cast(config.allowPixel, Null<Bool>) != null ? config.allowPixel : false;

		var pixelText = new FlxText(allowPixelCheck.x + 20, 0);
		pixelText.text = "Allow Pixel?";
		pixelText.y = allowPixelCheck.y + 2.5;
		ui.add(pixelText);

		ui.add(allowPixelCheck);
	}

	var redEnabled:Bool = true;
	var blueEnabled:Bool = true;
	var greenEnabled:Bool = true;
	var redShader:Array<Int> = [0, 0, 0];
	var greenShader:Array<Int> = [0, 0, 0];
	var blueShader:Array<Int> = [0, 0, 0];
	var changeShader:PsychUIDropDownMenu;
	var defaultButton:PsychUICheckBox;
	
	function addShadersTab()
	{
		var tab = shaderUI.getTab("Shader").menu;

		tab.add(new FlxText(40, 10, "Replacing Color:"));
		tab.add(new FlxText(25, 30, "Red:"));
		tab.add(new FlxText(25, 50, "Green:"));
		tab.add(new FlxText(25, 70, "Blue:"));

		var red = new PsychUINumericStepper(60, 30, 1, redShader[0], 0, 255, 0);
		red.onValueChange = () -> {
			var shader = switch (changeShader.selectedLabel)
			{
				case "Red": redShader[0] = Std.int(red.value);
				case "Green": greenShader[0] = Std.int(red.value);
				case _: blueShader[0] = Std.int(red.value);
			}
			setConfigRGB();
		};
		tab.add(red);

		var green = new PsychUINumericStepper(60, 50, 1, redShader[1], 0, 255, 0);
		green.onValueChange = () -> {
			var shader = switch (changeShader.selectedLabel)
			{
				case "Red": redShader[1] = Std.int(green.value);
				case "Green": greenShader[1] = Std.int(green.value);
				case _: blueShader[1] = Std.int(green.value);
			}
			setConfigRGB();
		};
		tab.add(green);

		var blue = new PsychUINumericStepper(60, 70, 1, redShader[2], 0, 255, 0);
		blue.onValueChange = () -> {
			var shader = switch (changeShader.selectedLabel)
			{
				case "Red": redShader[2] = Std.int(blue.value);
				case "Green": greenShader[2] = Std.int(blue.value);
				case _: blueShader[2] = Std.int(blue.value);
			}
			setConfigRGB();
		};
		tab.add(blue);

		function onCheck(change:Bool = true)
		{
			if (!defaultButton.checked)
				shaderUI.alpha = 1;
			else
				shaderUI.alpha = 0.6;

			if (change)
				switch (changeShader.selectedLabel)
				{
					case "Red": redEnabled = !defaultButton.checked;
					case "Green": greenEnabled = !defaultButton.checked;
					case "Blue": blueEnabled = !defaultButton.checked;
				}

			setConfigRGB();
		}

		add(new FlxText(shaderUI.x + 20, shaderUI.y + 135, 0, "Color to Replace:"));
		changeShader = new PsychUIDropDownMenu(shaderUI.x + 20, shaderUI.y + 150, ["Red", "Green", "Blue"], function(id:Int, name:String)
		{
			var shader = switch (name)
			{
				case "Red": redShader;
				case "Green": greenShader;
				case _: blueShader;
			}

			red.value = shader[0];
			green.value = shader[1];
			blue.value = shader[2];

			// changing checked doesn't initiate onCheck!!
			defaultButton.checked = switch (name) {
				case "Red": !redEnabled;
				case "Green": !greenEnabled;
				case _: !blueEnabled;
			}
			onCheck(false);
		});
		add(changeShader);

		defaultButton = new PsychUICheckBox(shaderUI.x + 30, shaderUI.y + 115, "Do not replace", 100, () -> onCheck());
		defaultButton.text.y += 2.5;
		add(defaultButton);

		changeShader.selectedLabel = "Red";
		changeShader.onSelect(0, "Red");
	}

	dynamic function reloadImage() // Dynamic because needs to be changed later
	{
		//
	}

	var holdingArrowsTime:Float = 0;
	var holdingArrowsElapsed:Float = 0;
	var copiedOffset:Array<Float> = [0, 0];
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		errorText.x = FlxG.width - errorText.width - 5;

		curText.text = 'Copied Offsets: ${Std.string(copiedOffset).replace(',', ', ')}\n';
		curText.text += 'Current Animation: ${curAnim == null || curAnim.length < 1 ? "NONE" : curAnim}';

		if (config != null && !curText.text.contains('NONE'))
		{
			var offsets:Array<Float> = try config.animations.get(curAnim).offsets catch (e) [0, 0];
			curText.text += ' ($offsets)'.replace(',', ', ');
		}

		if (config != null)
		{
			var currentAnim:String = curAnimText.text;
			if (config.animations.exists(currentAnim) && config.animations.get(currentAnim) != null)
				addButton.label = 'Update';
			else
				addButton.label = 'Add';

			config.scale = scaleNumericStepper.value;
		}

		var blockInput:Bool = PsychUIInputText.focusOn != null;
		if (!blockInput && config != null && config.animations != null && config.animations.exists(curAnim) && curAnim != null && curAnim.length > 0)
		{
			function splash()
			{
				if (config.animations.get(curAnim) != null)
				{
					playHoldSplash(curAnim);
					FlxTween.cancelTweensOf(errorText);
					errorText.alpha = 0;
				}
			}

			var changedOffset = false;
			if (controls.mobileC || FlxG.keys.pressed.CONTROL && config.animations.get(curAnim) != null)
			{
				if (touchPad.buttonC.justPressed || FlxG.keys.justPressed.C)
				{
					copiedOffset = config.animations.get(curAnim).offsets.copy();
				}
				else if (touchPad.buttonV.justPressed || FlxG.keys.justPressed.V)
				{
					var conf = config.animations.get(curAnim);
					conf.offsets = copiedOffset.copy();
					config.animations.set(curAnim, conf);
					changedOffset = true;
				}
				else if (FlxG.keys.justPressed.R)
				{
					var conf = config.animations.get(curAnim);
					conf.offsets = [0, 0];
					config.animations.set(curAnim, conf);
					changedOffset = true;
				}
			}

			var multiplier:Int = (touchPad.buttonZ.pressed || FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER)) ? 10 : 1;

			var moveKeysP = [
				touchPad.buttonLeft.justPressed || FlxG.keys.justPressed.LEFT,
				touchPad.buttonRight.justPressed || FlxG.keys.justPressed.RIGHT,
				touchPad.buttonUp.justPressed || FlxG.keys.justPressed.UP,
				touchPad.buttonDown.justPressed || FlxG.keys.justPressed.DOWN
			];
			if (moveKeysP.contains(true))
			{
				config.animations[curAnim].offsets[0] += ((moveKeysP[0] ? 1 : 0) - (moveKeysP[1] ? 1 : 0)) * multiplier;
				config.animations[curAnim].offsets[1] += ((moveKeysP[2] ? 1 : 0) - (moveKeysP[3] ? 1 : 0)) * multiplier;
				changedOffset = true;
			}

			var moveKeys = [
				touchPad.buttonLeft.pressed || FlxG.keys.pressed.LEFT,
				touchPad.buttonRight.pressed || FlxG.keys.pressed.RIGHT,
				touchPad.buttonUp.pressed || FlxG.keys.pressed.UP,
				touchPad.buttonDown.pressed || FlxG.keys.pressed.DOWN
			];
			if (moveKeys.contains(true))
			{
				holdingArrowsTime += elapsed;
				if (holdingArrowsTime > 0.6)
				{
					holdingArrowsElapsed += elapsed;
					while (holdingArrowsElapsed > (1 / 60))
					{
						config.animations[curAnim].offsets[0] += ((moveKeys[0] ? 1 : 0) - (moveKeys[1] ? 1 : 0)) * multiplier;
						config.animations[curAnim].offsets[1] += ((moveKeys[2] ? 1 : 0) - (moveKeys[3] ? 1 : 0)) * multiplier;
						holdingArrowsElapsed -= (1 / 60);
						changedOffset = true;
					}
				}
			}
			else holdingArrowsTime = 0;

			if (changedOffset || FlxG.keys.justPressed.SPACE) splash();
		}

		if (!blockInput)
		{
			if (controls.BACK)
				MusicBeatState.switchState(new MasterEditorMenu());
			if (touchPad.buttonF.justPressed || FlxG.keys.justPressed.F1)
			{
				removeTouchPad();
				openSubState(new HoldSplashEditorHelpSubState());
			}
		}

		if (FlxG.mouse.overlaps(strums))
		{
			strums.forEach(function(strum:StrumNote)
			{
				if (FlxG.mouse.overlaps(strum))
				{
					if (!FlxG.mouse.justPressed)
					{
						if (strum.animation.curAnim.name != 'pressed' && strum.animation.curAnim.name != 'confirm')
							strum.playAnim('pressed');
					}
					else
					{
						strum.playAnim('confirm', true);

						var splash:SustainSplash = new SustainSplash(imageSkin);
						splash.config = config;
						splash.strumNote = strum;
						if (splash.animation.exists(curAnim))
						{
							splash.animation.play(curAnim, true);
							splash.setPosition(strum.x, strum.y);
							
							// Apply same base offset as setupSusSplash so editor preview matches gameplay
							splash.offset.set(106.25, 100);
							var conf = config.animations.get(curAnim);
							if (conf != null && conf.offsets != null)
							{
								splash.offset.x += conf.offsets[0];
								splash.offset.y += conf.offsets[1];
							}
							
							// Apply arrow RGB colors so the shader isn't black
							applyEditorShader(splash, strum.ID);
							
							// Auto-kill when animation finishes
							splash.animation.finishCallback = (_) -> splash.kill();
						}
						holdSplashes.add(splash);
					}
				}
				else strum.playAnim('static');
			});
		}
		else
		{
			for (strum in strums)
				strum.playAnim('static');
		}
	}

	override function closeSubState()
	{
		super.closeSubState();
		removeTouchPad();
		addTouchPad('LEFT_FULL', 'NOTE_SPLASH_EDITOR');
	}

	function applyEditorShader(splash:SustainSplash, noteID:Int)
	{
		// If allowRGB is off, disable the shader so the raw texture shows
		if (config == null || !config.allowRGB)
		{
			splash.rgbShader.enabled = false;
			splash.shader = splash.rgbShader.shader;
			return;
		}

		var noteData:Int = noteID % Note.colArray.length;
		Note.initializeGlobalRGBShader(noteData);
		var tempShader:RGBPalette = new RGBPalette();
		var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
		// 'Do not replace' checked (enabled=false) → use arrow RGB normally
		// 'Do not replace' unchecked (enabled=true) → channel goes black (being overridden but no value set)
		tempShader.r = !redEnabled ? arr[0] : FlxColor.BLACK;
		tempShader.g = !greenEnabled ? arr[1] : FlxColor.BLACK;
		tempShader.b = !blueEnabled ? arr[2] : FlxColor.BLACK;
		splash.rgbShader.copyValues(tempShader);
		splash.rgbShader.enabled = true;
		splash.shader = splash.rgbShader.shader;
	}

	function refreshPreviewShader()
	{
		holdSplashes.forEachAlive(function(s:SustainSplash) applyEditorShader(s, strums.members[0].ID));
	}

	function playHoldSplash(?name:String)
	{
		if (name == null || !config.animations.exists(name)) return;

		// Kill all previous splashes before creating a new one
		holdSplashes.forEach(s -> s.kill());

		var splash:SustainSplash = new SustainSplash(imageSkin);
		splash.config = config;
		splash.strumNote = strums.members[0];
		
		if (splash.animation.exists(name))
		{
			splash.animation.play(name, true);
			splash.setPosition(strums.members[0].x, strums.members[0].y);
			
			// Apply same base offset as setupSusSplash so editor preview matches gameplay
			splash.offset.set(106.25, 100);
			var conf = config.animations.get(name);
			if (conf != null && conf.offsets != null)
			{
				splash.offset.x += conf.offsets[0];
				splash.offset.y += conf.offsets[1];
			}
			
			// Apply arrow RGB colors so the shader isn't black
			applyEditorShader(splash, strums.members[0].ID);
			
			splash.alpha = 1;
			holdSplashes.add(splash);
		}
		else
		{
			errorText.alpha = 1;
			errorText.text = "ERROR while playing hold splash";

			FlxTween.cancelTweensOf(errorText);
			FlxTween.tween(errorText, {alpha: 0}, {startDelay: 1});
		}
	}

	function resetRGB()
	{
		redShader = [0, 0, 0];
		greenShader = [0, 0, 0];
		blueShader = [0, 0, 0];
	}

	function parseRGB()
	{
		resetRGB();
		// Hold splashes don't store RGB data yet, but we keep this for future compatibility
		redEnabled = blueEnabled = greenEnabled = false;
	}

	function setConfigRGB()
	{
		if (config == null)
			config = SustainSplash.createConfig();

		refreshPreviewShader();
	}

	var _file:FileReference;
	
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved file.");
	}

	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving file");
	}

	function saveHoldSplash()
	{
		imageSkin = imageInputText.text;
		var data:String = Json.stringify(config, "\t");
		if (data.length > 0)
		{
			#if mobile
			StorageUtil.saveContent('${imageSkin.split("/").pop()}.json', data);
			#else
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, imageSkin.split("/").pop() + ".json");
			#end
		}
	}

	override function destroy()
	{
		SustainSplash.configs.clear();
		super.destroy();

		FlxG.sound.music.volume = 1;
		FlxG.sound.muteKeys = [FlxKey.ZERO];
		FlxG.sound.volumeDownKeys = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
		FlxG.sound.volumeUpKeys = [FlxKey.NUMPADPLUS, FlxKey.PLUS];
	}
}

class HoldSplashEditorHelpSubState extends MusicBeatSubstate
{
	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		add(bg);

		var str:Array<String> = (controls.mobileC) ? [
			"Touch on a Strum",
			"to spawn a Hold Splash",
			"",
			"Arrow Keys - Move Offset",
			"Hold Z - Move Offsets 10x faster",
			"",
			"C - Copy Current Offset",
			"V - Paste Copied Offset",
			"",
			"Hold splashes have 2 animations:",
			"'hold' - Loops while holding",
			"'end' - Plays when releasing"
		] : [
			"Click on a Strum or Press Space",
			"to spawn a Hold Splash",
			"",
			"Arrow Keys - Move Offset",
			"Hold Shift - Move Offsets 10x faster",
			"",
			"Ctrl + C - Copy Current Offset",
			"Ctrl + V - Paste Copied Offset",
			"Ctrl + R - Reset Current Offset",
			"",
			"Hold splashes have 2 animations:",
			"'hold' - Loops while holding",
			"'end' - Plays when releasing"
		];

		var helpTexts:FlxSpriteGroup = new FlxSpriteGroup();
		for (i => txt in str)
		{
			if (txt.length < 1) continue;

			var helpText:FlxText = new FlxText(0, 0, 0, txt, 24);
			helpText.setFormat(null, 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
			helpText.borderColor = FlxColor.BLACK;
			helpText.scrollFactor.set();
			helpText.borderSize = 1;
			helpText.screenCenter();
			add(helpText);
			helpText.y += ((i - str.length / 2) * 32) + 16;
			helpTexts.add(helpText);
		}

		var txt:FlxText = new FlxText(0, 0, 0, (controls.mobileC ? "TAP" : "ENTER or ESCAPE") + " - Close", 24);
		txt.setFormat(null, 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		txt.borderColor = FlxColor.BLACK;
		txt.scrollFactor.set();
		txt.borderSize = 1;
		txt.screenCenter(X);
		txt.y = FlxG.height - txt.height - 20;
		add(txt);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT || controls.BACK #if mobile || FlxG.android.justReleased.BACK #end)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
		}
	}
}
