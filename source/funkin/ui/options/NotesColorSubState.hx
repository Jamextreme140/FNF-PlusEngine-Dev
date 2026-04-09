package funkin.ui.options;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.math.FlxRect;
import lime.system.Clipboard;
import flixel.util.FlxGradient;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.play.notes.StrumNote;
import funkin.play.notes.Note;

import funkin.graphics.shaders.RGBPalette;
import funkin.graphics.shaders.RGBPalette.RGBShaderReference;

class NotesColorSubState extends MusicBeatSubstate
{
	var onModeColumn:Bool = true;
	var curSelectedMode:Int = 0;
	var curSelectedNote:Int = 0;
	var onPixel:Bool = false;
	var dataArray:Array<Array<FlxColor>>;

	var hexTypeLine:FlxSprite;
	var hexTypeNum:Int = -1;
	var hexTypeVisibleTimer:Float = 0;

	var copyButton:FlxSprite;
	var pasteButton:FlxSprite;

	var colorGradient:FlxSprite;
	var colorGradientSelector:FlxSprite;
	var colorPalette:FlxSprite;
	var colorWheel:FlxSprite;
	var colorWheelSelector:FlxSprite;

	var alphabetR:Alphabet;
	var alphabetG:Alphabet;
	var alphabetB:Alphabet;
	var alphabetHex:Alphabet;

	var modeBG:FlxSprite;
	var notesBG:FlxSprite;

	// controller support
	var controllerPointer:FlxSprite;
	var _lastControllerMode:Bool = false;
	var tipTxt:FlxText;
	
	// NotITG warning message
	var notITGWarningText:FlxText;
	var grid:FlxBackdrop;

	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelWidth:Float = 0;
	var panelHeight:Float = 0;
	var previewX:Float = 0;
	var previewY:Float = 0;
	var previewWidth:Float = 0;
	var previewHeight:Float = 0;
	var editorX:Float = 0;
	var editorY:Float = 0;
	var editorWidth:Float = 0;
	var editorHeight:Float = 0;

	public function new() {
		super();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Note Colors Menu", null);
		#end
		
		onPixel = PlayState.isPixelStage;
		panelWidth = FlxG.width - 8;
		panelHeight = FlxG.height - 8;
		panelX = (FlxG.width - panelWidth) * 0.5;
		panelY = (FlxG.height - panelHeight) * 0.5;
		previewWidth = Math.min(712, panelWidth * 0.59);
		previewHeight = panelHeight - 140;
		previewX = panelX + 18;
		previewY = panelY + 108;
		editorX = previewX + previewWidth + 18;
		editorY = previewY;
		editorWidth = panelX + panelWidth - 18 - editorX;
		editorHeight = previewHeight;

		var overlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xC0141020);
		add(overlay);

		OptionsMenuTheme.syncAccent();
		var palette = OptionsMenuTheme.current();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = palette.pale;
		bg.alpha = 0.16;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		grid = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0;
		grid.color = 0xFFAB8AE6;
		grid.clipRect = new FlxRect(panelX, panelY, panelWidth, panelHeight);
		FlxTween.tween(grid, {alpha: 1}, 0.5, {ease: FlxEase.quadOut});
		add(grid);

		var panelShadow:FlxSprite = new FlxSprite(panelX + 10, panelY + 12);
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x2A000000);
		add(panelShadow);

		var panelSurface:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, 0xF3F9F5FC);
		add(panelSurface);

		var panelHeader:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 104, 34, 34, 0, 0, 0xFFFFFBFF);
		add(panelHeader);

		var panelOutline:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, 0x22FFFFFF);
		add(panelOutline);

		var previewSurface:FlxSprite = new FlxSprite(previewX, previewY);
		MD3ShapeTools.fillAndStrokeRoundRect(previewSurface, Std.int(previewWidth), Std.int(previewHeight), 28, 2, 0xFFF3EDF9, 0xFFE1D6EF);
		add(previewSurface);

		var editorSurface:FlxSprite = new FlxSprite(editorX, editorY);
		MD3ShapeTools.fillAndStrokeRoundRect(editorSurface, Std.int(editorWidth), Std.int(editorHeight), 28, 2, 0xFFFCF8FF, 0xFFE6DCF1);
		add(editorSurface);

		var titleText:FlxText = new FlxText(panelX + 34, panelY + 18, panelWidth - 68, Language.getPhrase('note_colors_menu', 'Note Colors'), 30);
		titleText.setFormat(Paths.font('inter-bold.otf'), 30, palette.strong, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		var subtitleText:FlxText = new FlxText(panelX + 34, panelY + 56, panelWidth - 68,
			Language.getPhrase('note_colors_menu_subtitle', 'Tune arrow palettes without leaving the editor. Preview on the left, precise color control on the right.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, palette.muted, LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		var previewLabel:FlxText = new FlxText(previewX + 22, previewY + 18, previewWidth - 132, Language.getPhrase('note_colors_preview_label', 'Preview Lane'), 20);
		previewLabel.setFormat(Paths.font('inter-bold.otf'), 20, 0xFF2A1D3E, LEFT);
		previewLabel.antialiasing = ClientPrefs.data.antialiasing;
		add(previewLabel);

		var previewHint:FlxText = new FlxText(previewX + 22, previewY + 68, previewWidth - 44,
			Language.getPhrase('note_colors_preview_hint', 'Choose the RGB channel above, then pick the note lane below.'), 14);
		previewHint.setFormat(Paths.font('inter.otf'), 14, 0xFF6E5E83, LEFT);
		previewHint.antialiasing = ClientPrefs.data.antialiasing;
		add(previewHint);

		var editorLabel:FlxText = new FlxText(editorX + 22, editorY + 18, editorWidth - 44, Language.getPhrase('note_colors_editor_label', 'Color Mixer'), 20);
		editorLabel.setFormat(Paths.font('inter-bold.otf'), 20, 0xFF2A1D3E, LEFT);
		editorLabel.antialiasing = ClientPrefs.data.antialiasing;
		add(editorLabel);

		var editorHint:FlxText = new FlxText(editorX + 22, editorY + 46, editorWidth - 44,
			Language.getPhrase('note_colors_editor_hint', 'Copy, paste, drag the wheel or type the hex value. Tiny chaos, but organized chaos.'), 14);
		editorHint.setFormat(Paths.font('inter.otf'), 14, 0xFF6E5E83, LEFT);
		editorHint.antialiasing = ClientPrefs.data.antialiasing;
		add(editorHint);

		modeBG = new FlxSprite(previewX + (previewWidth - 372) * 0.5, previewY + 116);
		MD3ShapeTools.fillRoundRect(modeBG, 372, 108, 26, 0x227A63DA);
		modeBG.visible = false;
		add(modeBG);

		notesBG = new FlxSprite(previewX + 30, previewY + 246);
		MD3ShapeTools.fillRoundRect(notesBG, Std.int(previewWidth - 60), 118, 26, 0x1F7A63DA);
		notesBG.visible = false;
		add(notesBG);

		modeNotes = new FlxTypedGroup<FlxSprite>();
		add(modeNotes);

		myNotes = new FlxTypedGroup<StrumNote>();
		add(myNotes);

		var toggleText:FlxText = new FlxText(previewX + 22, previewY + 44, previewWidth - 132,
			(controls.mobileC)
				? Language.getPhrase('note_colors_toggle_mobile', 'Tap the note icon to switch between standard and pixel previews.')
				: Language.getPhrase('note_colors_toggle_desktop', 'Press CTRL or click the note icon to switch between standard and pixel previews.'), 14);
		toggleText.setFormat(Paths.font('inter.otf'), 14, 0xFF6E5E83, LEFT);
		toggleText.antialiasing = ClientPrefs.data.antialiasing;
		add(toggleText);

		copyButton = new FlxSprite(panelX + panelWidth - 196, panelY + 22).loadGraphic(Paths.image('noteColorMenu/copy'));
		copyButton.alpha = 0.6;
		add(copyButton);

		pasteButton = new FlxSprite(panelX + panelWidth - 98, panelY + 22).loadGraphic(Paths.image('noteColorMenu/paste'));
		pasteButton.alpha = 0.6;
		add(pasteButton);

		var wheelSize:Int = Std.int(Math.min(264, editorWidth - 110));
		var wheelX:Float = editorX + 142;
		var wheelY:Float = editorY + 176;

		colorGradient = FlxGradient.createGradientFlxSprite(48, wheelSize, [FlxColor.WHITE, FlxColor.BLACK]);
		colorGradient.setPosition(editorX + 64, wheelY);
		add(colorGradient);

		colorGradientSelector = new FlxSprite(colorGradient.x - 10, wheelY).makeGraphic(68, 8, FlxColor.WHITE);
		colorGradientSelector.offset.y = 5;
		colorGradientSelector.alpha = 0.88;
		add(colorGradientSelector);

		colorPalette = new FlxSprite(editorX + 64, wheelY + wheelSize + 16).loadGraphic(Paths.image('noteColorMenu/palette', false));
		colorPalette.scale.set(20, 20);
		colorPalette.updateHitbox();
		colorPalette.antialiasing = false;
		colorPalette.y = editorY + editorHeight - colorPalette.height - 20;
		add(colorPalette);
		
		colorWheel = new FlxSprite(wheelX, wheelY).loadGraphic(Paths.image('noteColorMenu/colorWheel'));
		colorWheel.setGraphicSize(wheelSize, wheelSize);
		colorWheel.updateHitbox();
		add(colorWheel);

		colorWheelSelector = new FlxShapeCircle(0, 0, 8, {thickness: 0}, FlxColor.WHITE);
		colorWheelSelector.offset.set(8, 8);
		colorWheelSelector.alpha = 0.6;
		add(colorWheelSelector);

		var txtX = editorX + (editorWidth * 0.5) - 28;
		var txtY = editorY + 132;
		alphabetR = makeColorAlphabet(txtX - 100, txtY);
		add(alphabetR);
		alphabetG = makeColorAlphabet(txtX, txtY);
		add(alphabetG);
		alphabetB = makeColorAlphabet(txtX + 100, txtY);
		add(alphabetB);
		alphabetHex = makeColorAlphabet(txtX, txtY - 55);
		add(alphabetHex);
		hexTypeLine = new FlxSprite(0, 20).makeGraphic(4, 56, FlxColor.WHITE);
		hexTypeLine.visible = false;
		add(hexTypeLine);
		
		// Must be created before spawnNotes() because the preview refresh touches it.
		notITGWarningText = new FlxText(previewX + 24, previewY + previewHeight - 54, previewWidth - 48, '', 19);
		notITGWarningText.setFormat(Paths.font('inter-bold.otf'), 19, 0xFFD63B58, CENTER, FlxTextBorderStyle.OUTLINE, 0xFFFDF7FF);
		notITGWarningText.borderSize = 3;
		notITGWarningText.visible = false;
		notITGWarningText.scrollFactor.set();
		add(notITGWarningText);

		spawnNotes();
		updateNotes(true);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

		var tipX = panelX + 26;
		var tipY = panelY + panelHeight - 56;
		var reset:String;

		if (controls.mobileC) {
			reset = "C";
			tipY = panelY + panelHeight - 80;
		} else
			reset = "RESET";

		var tip:FlxText = new FlxText(tipX, tipY, panelWidth - 52, Language.getPhrase('note_colors_tip', 'Press {1} to Reset the selected Note Part.', [reset]), 16);
		tip.setFormat(Paths.font('inter.otf'), 15, 0xFF5E506F, LEFT);
		tip.antialiasing = ClientPrefs.data.antialiasing;
		add(tip);

		tipTxt = new FlxText(tipX, tipY + 24, panelWidth - 52, '', 16);
		tipTxt.setFormat(Paths.font('inter.otf'), 15, 0xFF5E506F, LEFT);
		tipTxt.antialiasing = ClientPrefs.data.antialiasing;
		add(tipTxt);
		updateTip();

		controllerPointer = new FlxShapeCircle(0, 0, 20, {thickness: 0}, FlxColor.WHITE);
		controllerPointer.offset.set(20, 20);
		controllerPointer.screenCenter();
		controllerPointer.alpha = 0.6;
		add(controllerPointer);
		
		if (!controls.controllerMode) Cursor.show(); else Cursor.hide();

		addTouchPad('NONE', 'B_C');
		controls.isInSubstate = true;
		if (touchPad != null)
		{
			if (touchPad.buttonB != null) touchPad.buttonB.x = FlxG.width - 132;
			if (touchPad.buttonC != null)
			{
				touchPad.buttonC.x = 0;
				touchPad.buttonC.y = FlxG.height - 135;
			}
		}
	}

	function updateTip()
	{
		var key:String = !controls.controllerMode ? Language.getPhrase('note_colors_shift', 'Shift') : Language.getPhrase('note_colors_lb', 'Left Shoulder Button');
		if (!controls.mobileC)
			tipTxt.text = Language.getPhrase('note_colors_hold_tip', 'Hold {1} + Press RESET key to fully reset the selected Note.', [key]);
	}
	var _storedColor:FlxColor;
	var changingNote:Bool = false;
	var holdingOnObj:FlxSprite;
	var allowedTypeKeys:Map<FlxKey, String> = [
		ZERO => '0', ONE => '1', TWO => '2', THREE => '3', FOUR => '4', FIVE => '5', SIX => '6', SEVEN => '7', EIGHT => '8', NINE => '9',
		NUMPADZERO => '0', NUMPADONE => '1', NUMPADTWO => '2', NUMPADTHREE => '3', NUMPADFOUR => '4', NUMPADFIVE => '5', NUMPADSIX => '6',
		NUMPADSEVEN => '7', NUMPADEIGHT => '8', NUMPADNINE => '9', A => 'A', B => 'B', C => 'C', D => 'D', E => 'E', F => 'F'];

	override function update(elapsed:Float) {
		if (controls.BACK) {
			Cursor.hide();
			FlxG.sound.play(Paths.sound('cancelMenu'));
			controls.isInSubstate = false;
			close();
			return;
		}

		super.update(elapsed);

		// Early controller checking
		if(FlxG.gamepads.anyJustPressed(ANY)) controls.controllerMode = true;
		else if(FlxG.mouse.justPressed || FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0) controls.controllerMode = false;
		//
		
		var changedToController:Bool = false;
		if(controls.controllerMode != _lastControllerMode)
		{
			//trace('changed controller mode');
			if (!controls.controllerMode)
				Cursor.show();
			else
				Cursor.hide();
			{
				controllerPointer.x = FlxG.mouse.x;
				controllerPointer.y = FlxG.mouse.y;
				changedToController = true;
			}
			// changed to keyboard mid state
			/*else
			{
				FlxG.mouse.x = controllerPointer.x;
				FlxG.mouse.y = controllerPointer.y;
			}
			// apparently theres no easy way to change mouse position that i know, oh well
			*/
			_lastControllerMode = controls.controllerMode;
			updateTip();
		}

		// controller things
		var analogX:Float = 0;
		var analogY:Float = 0;
		var analogMoved:Bool = false;
		if(controls.controllerMode && (changedToController || FlxG.gamepads.anyInput()))
		{
			for (gamepad in FlxG.gamepads.getActiveGamepads())
			{
				analogX = gamepad.getXAxis(LEFT_ANALOG_STICK);
				analogY = gamepad.getYAxis(LEFT_ANALOG_STICK);
				analogMoved = (analogX != 0 || analogY != 0);
				if(analogMoved) break;
			}
			controllerPointer.x = Math.max(0, Math.min(FlxG.width, controllerPointer.x + analogX * 1000 * elapsed));
			controllerPointer.y = Math.max(0, Math.min(FlxG.height, controllerPointer.y + analogY * 1000 * elapsed));
		}
		var controllerPressed:Bool = (controls.controllerMode && controls.ACCEPT);
		//

		if(FlxG.keys.justPressed.CONTROL)
		{
			onPixel = !onPixel;
			spawnNotes();
			updateNotes(true);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
		}

		if(hexTypeNum > -1)
		{
			var keyPressed:FlxKey = cast (FlxG.keys.firstJustPressed(), FlxKey);
			hexTypeVisibleTimer += elapsed;
			var changed:Bool = false;
			if(changed = FlxG.keys.justPressed.LEFT)
				hexTypeNum--;
			else if(changed = FlxG.keys.justPressed.RIGHT)
				hexTypeNum++;
			else if(allowedTypeKeys.exists(keyPressed))
			{
				//trace('keyPressed: $keyPressed, lil str: ' + allowedTypeKeys.get(keyPressed));
				var curColor:String = alphabetHex.text;
				var newColor:String = curColor.substring(0, hexTypeNum) + allowedTypeKeys.get(keyPressed) + curColor.substring(hexTypeNum + 1);

				var colorHex:FlxColor = FlxColor.fromString('#' + newColor);
				setShaderColor(colorHex);
				_storedColor = getShaderColor();
				updateColors();
				
				// move you to next letter
				hexTypeNum++;
				changed = true;
			}
			else if(FlxG.keys.justPressed.ENTER)
				hexTypeNum = -1;
			
			var end:Bool = false;
			if(changed)
			{
				if (hexTypeNum > 5) //Typed last letter
				{
					hexTypeNum = -1;
					end = true;
					hexTypeLine.visible = false;
				}
				else
				{
					if(hexTypeNum < 0) hexTypeNum = 0;
					else if(hexTypeNum > 5) hexTypeNum = 5;
					centerHexTypeLine();
					hexTypeLine.visible = true;
				}
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			if(!end) hexTypeLine.visible = Math.floor(hexTypeVisibleTimer * 2) % 2 == 0;
		}
		else
		{
			var add:Int = 0;
			if(analogX == 0 && !changedToController)
			{
				if(controls.UI_LEFT_P) add = -1;
				else if(controls.UI_RIGHT_P) add = 1;
			}

			if(analogY == 0 && !changedToController && (controls.UI_UP_P || controls.UI_DOWN_P))
			{
				onModeColumn = !onModeColumn;
				modeBG.visible = onModeColumn;
				notesBG.visible = !onModeColumn;
			}
	
			if(add != 0)
			{
				if(onModeColumn) changeSelectionMode(add);
				else changeSelectionNote(add);
			}
			hexTypeLine.visible = false;
		}

		// Copy/Paste buttons
		var generalMoved:Bool = (FlxG.mouse.justMoved || analogMoved);
		var generalPressed:Bool = (FlxG.mouse.justPressed || controllerPressed);
		if(generalMoved)
		{
			copyButton.alpha = 0.6;
			pasteButton.alpha = 0.6;
		}

		if(pointerOverlaps(copyButton))
		{
			copyButton.alpha = 1;
			if(generalPressed)
			{
				Clipboard.text = getShaderColor().toHexString(false, false);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				trace('copied: ' + Clipboard.text);
			}
			hexTypeNum = -1;
		}
		else if (pointerOverlaps(pasteButton))
		{
			pasteButton.alpha = 1;
			if(generalPressed)
			{
				var formattedText = Clipboard.text.trim().toUpperCase().replace('#', '').replace('0x', '');
				var newColor:Null<FlxColor> = FlxColor.fromString('#' + formattedText);
				//trace('#${Clipboard.text.trim().toUpperCase()}');
				if(newColor != null && formattedText.length == 6)
				{
					setShaderColor(newColor);
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					_storedColor = getShaderColor();
					updateColors();
				}
				else // Invalid clipboard color.
					FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			}
			hexTypeNum = -1;
		}

		bigNote.setGraphicSize(228);
		if(generalPressed)
		{
			hexTypeNum = -1;
			if (pointerOverlaps(modeNotes))
			{
				modeNotes.forEachAlive(function(note:FlxSprite) {
					if (curSelectedMode != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedMode = note.ID;
						onModeColumn = true;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (pointerOverlaps(myNotes))
			{
				myNotes.forEachAlive(function(note:StrumNote) {
					if (curSelectedNote != note.ID && pointerOverlaps(note))
					{
						modeBG.visible = notesBG.visible = false;
						curSelectedNote = note.ID;
						onModeColumn = false;
						bigNote.rgbShader.parent = Note.globalRgbShaders[note.ID];
						bigNote.shader = Note.globalRgbShaders[note.ID].shader;
						updateNotes();
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
					}
				});
			}
			else if (pointerOverlaps(colorWheel)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorWheel;
			}
			else if (pointerOverlaps(colorGradient)) {
				_storedColor = getShaderColor();
				holdingOnObj = colorGradient;
			}
			else if (pointerOverlaps(colorPalette)) {
				setShaderColor(colorPalette.pixels.getPixel32(
					Std.int((pointerX() - colorPalette.x) / colorPalette.scale.x), 
					Std.int((pointerY() - colorPalette.y) / colorPalette.scale.y)));
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
				updateColors();
			}
			else if (pointerOverlaps(skinNote))
			{
				onPixel = !onPixel;
				spawnNotes();
				updateNotes(true);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if(pointerOverlapsHexValue())
			{
				hexTypeNum = 0;
				for (letter in alphabetHex.letters)
				{
					if(letter.x - letter.offset.x + letter.width <= pointerX()) hexTypeNum++;
					else break;
				}
				if(hexTypeNum > 5) hexTypeNum = 5;
				hexTypeLine.visible = true;
				centerHexTypeLine();
			}
			else holdingOnObj = null;
		}
		// holding
		if(holdingOnObj != null)
		{
			if (FlxG.mouse.justReleased || (controls.controllerMode && controls.justReleased('accept')))
			{
				holdingOnObj = null;
				_storedColor = getShaderColor();
				updateColors();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
			}
			else if (generalMoved || generalPressed)
			{
				if (holdingOnObj == colorGradient)
				{
					var newBrightness = 1 - FlxMath.bound((pointerY() - colorGradient.y) / colorGradient.height, 0, 1);
					_storedColor.alpha = 1;
					if(_storedColor.brightness == 0) //prevent bug
						setShaderColor(FlxColor.fromRGBFloat(newBrightness, newBrightness, newBrightness));
					else
						setShaderColor(FlxColor.fromHSB(_storedColor.hue, _storedColor.saturation, newBrightness));
					updateColors(_storedColor);
				}
				else if (holdingOnObj == colorWheel)
				{
					var center:FlxPoint = new FlxPoint(colorWheel.x + colorWheel.width/2, colorWheel.y + colorWheel.height/2);
					var mouse:FlxPoint = pointerFlxPoint();
					var hue:Float = FlxMath.wrap(FlxMath.wrap(Std.int(mouse.degreesTo(center)), 0, 360) - 90, 0, 360);
					var sat:Float = FlxMath.bound(mouse.dist(center) / colorWheel.width*2, 0, 1);
					//trace('$hue, $sat');
					if(sat != 0) setShaderColor(FlxColor.fromHSB(hue, sat, _storedColor.brightness));
					else setShaderColor(FlxColor.fromRGBFloat(_storedColor.brightness, _storedColor.brightness, _storedColor.brightness));
					updateColors();
				}
			} 
		}
		else if((touchPad != null && touchPad.buttonC != null && touchPad.buttonC.justPressed) || (controls.RESET && hexTypeNum < 0))
		{
			if(FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER))
			{
				for (i in 0...3)
				{
					var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
					var color:FlxColor = !onPixel ? ClientPrefs.defaultData.arrowRGB[curSelectedNote][i] :
													ClientPrefs.defaultData.arrowRGBPixel[curSelectedNote][i];
					switch(i)
					{
						case 0:
							getShader().r = strumRGB.r = color;
						case 1:
							getShader().g = strumRGB.g = color;
						case 2:
							getShader().b = strumRGB.b = color;
					}
					dataArray[curSelectedNote][i] = color;
				}
			}
			setShaderColor(!onPixel ? ClientPrefs.defaultData.arrowRGB[curSelectedNote][curSelectedMode] : ClientPrefs.defaultData.arrowRGBPixel[curSelectedNote][curSelectedMode]);
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.6);
			updateColors();
		}
	}

	function pointerOverlaps(obj:Dynamic)
	{
		if (!controls.controllerMode) return FlxG.mouse.overlaps(obj);
		return FlxG.overlap(controllerPointer, obj);
	}

	function pointerX():Float
	{
		if (!controls.controllerMode) return FlxG.mouse.x;
		return controllerPointer.x;
	}
	function pointerY():Float
	{
		if (!controls.controllerMode) return FlxG.mouse.y;
		return controllerPointer.y;
	}
	function pointerFlxPoint():FlxPoint
	{
		if (!controls.controllerMode) return FlxG.mouse.getScreenPosition();
		return controllerPointer.getScreenPosition();
	}

	function centerHexTypeLine()
	{
		//trace(hexTypeNum);
		if(hexTypeNum > 0)
		{
			var letter = alphabetHex.letters[hexTypeNum-1];
			hexTypeLine.x = letter.x - letter.offset.x + letter.width;
		}
		else
		{
			var letter = alphabetHex.letters[0];
			hexTypeLine.x = letter.x - letter.offset.x;
		}
		hexTypeLine.x += hexTypeLine.width;
		hexTypeVisibleTimer = 0;
	}

	function changeSelectionMode(change:Int = 0) {
		curSelectedMode += change;
		if (curSelectedMode < 0)
			curSelectedMode = 2;
		if (curSelectedMode >= 3)
			curSelectedMode = 0;

		modeBG.visible = true;
		notesBG.visible = false;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
	function changeSelectionNote(change:Int = 0) {
		curSelectedNote += change;
		if (curSelectedNote < 0)
			curSelectedNote = dataArray.length-1;
		if (curSelectedNote >= dataArray.length)
			curSelectedNote = 0;
		
		modeBG.visible = false;
		notesBG.visible = true;
		bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		updateNotes();
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	// alphabets
	function makeColorAlphabet(x:Float = 0, y:Float = 0):Alphabet
	{
		var text:Alphabet = new Alphabet(x, y, '', true);
		text.alignment = CENTERED;
		text.setScale(0.44);
		add(text);
		return text;
	}

	function pointerOverlapsHexValue():Bool
	{
		if (alphabetHex == null || alphabetHex.letters == null || alphabetHex.letters.length == 0) return false;

		var first = alphabetHex.letters[0];
		var last = alphabetHex.letters[alphabetHex.letters.length - 1];
		var minX:Float = first.x - first.offset.x - 8;
		var maxX:Float = last.x - last.offset.x + last.width + 8;
		var minY:Float = first.y - first.offset.y - 6;
		var maxY:Float = minY + Math.max(first.height, hexTypeLine.height) + 12;
		return pointerX() >= minX && pointerX() <= maxX && pointerY() >= minY && pointerY() <= maxY;
	}

	// notes sprites functions
	var skinNote:FlxSprite;
	var modeNotes:FlxTypedGroup<FlxSprite>;
	var myNotes:FlxTypedGroup<StrumNote>;
	var bigNote:Note;
	public function spawnNotes()
	{
		dataArray = !onPixel ? ClientPrefs.data.arrowRGB : ClientPrefs.data.arrowRGBPixel;
		if (onPixel) PlayState.stageUI = "pixel";

		var modeBaseX:Float = modeBG.x + 34;
		var modeBaseY:Float = modeBG.y - 10;
		var modeSpacing:Float = 116;
		var strumBaseX:Float = notesBG.x + 85;
		var strumSpacing:Float = (notesBG.width - 164) / dataArray.length;
		var previewCenterX:Float = previewX + previewWidth * 0.5;

		// clear groups
		modeNotes.forEachAlive(function(note:FlxSprite) {
			//note.kill();
			note.destroy();
		});
		myNotes.forEachAlive(function(note:StrumNote) {
			//note.kill();
			note.destroy();
		});
		modeNotes.clear();
		myNotes.clear();

		if(skinNote != null)
		{
			remove(skinNote);
			skinNote.destroy();
		}
		if(bigNote != null)
		{
			remove(bigNote);
			bigNote.destroy();
		}

		// respawn stuff
		var res:Int = onPixel ? 160 : 17;
		skinNote = new FlxSprite(previewX + previewWidth - 84, previewY + 18).loadGraphic(Paths.image('noteColorMenu/' + (onPixel ? 'note' : 'notePixel')), true, res, res);
		skinNote.antialiasing = ClientPrefs.data.antialiasing;
		skinNote.setGraphicSize(62);
		skinNote.updateHitbox();
		skinNote.animation.add('anim', [0], 24, true);
		skinNote.animation.play('anim', true);
		if(!onPixel) skinNote.antialiasing = false;
		add(skinNote);

		var res:Int = !onPixel ? 160 : 17;
		for (i in 0...3)
		{
			var newNote:FlxSprite = new FlxSprite(modeBaseX + (modeSpacing * i), modeBaseY).loadGraphic(Paths.image('noteColorMenu/' + (!onPixel ? 'note' : 'notePixel')), true, res, res);
			newNote.antialiasing = ClientPrefs.data.antialiasing;
			newNote.setGraphicSize(76);
			newNote.updateHitbox();
			newNote.animation.add('anim', [i], 24, true);
			newNote.animation.play('anim', true);
			newNote.ID = i;
			if(onPixel) newNote.antialiasing = false;
			modeNotes.add(newNote);
		}

		Note.globalRgbShaders = [];
		for (i in 0...dataArray.length)
		{
			Note.initializeGlobalRGBShader(i);
			var newNote:StrumNote = new StrumNote(strumBaseX + (strumSpacing * i), notesBG.y - 50, i, 0);
			newNote.useRGBShader = true;
			newNote.setGraphicSize(90);
			newNote.updateHitbox();
			newNote.ID = i;
			// Re-check NotITG skin to apply proper settings
			newNote.checkNotITGSkin();
			myNotes.add(newNote);
		}

		bigNote = new Note(0, 0, false, true);
		bigNote.setPosition(previewCenterX - 88, previewY + 328);
		bigNote.setGraphicSize(176);
		bigNote.updateHitbox();
		bigNote.rgbShader.parent = Note.globalRgbShaders[curSelectedNote];
		bigNote.shader = Note.globalRgbShaders[curSelectedNote].shader;
		for (i in 0...Note.colArray.length)
		{
			if(!onPixel) bigNote.animation.addByPrefix('note$i', Note.colArray[i] + '0', 24, true);
			else bigNote.animation.add('note$i', [i + 4], 24, true);
		}
		insert(members.indexOf(myNotes) + 1, bigNote);
		_storedColor = getShaderColor();
		PlayState.stageUI = "normal";
	}

	function updateNotes(?instant:Bool = false)
	{
		for (note in modeNotes)
			note.alpha = (curSelectedMode == note.ID) ? 1 : 0.6;

		for (note in myNotes)
		{
			var newAnim:String = curSelectedNote == note.ID ? 'confirm' : 'pressed';
			note.alpha = (curSelectedNote == note.ID) ? 1 : 0.6;
			if(note.animation.curAnim == null || note.animation.curAnim.name != newAnim) note.playAnim(newAnim, true);
			if(instant) note.animation.curAnim.finish();
		}
		bigNote.animation.play('note$curSelectedNote', true);
		updateColors();
		updateNotITGWarning(); // Check if NotITG is being used
	}
	
	function updateNotITGWarning()
	{
		// Ensure the warning text exists before updating it.
		if(notITGWarningText == null) return;
		
		// Check if the current note skin is NotITG
		var isNotITG:Bool = false;
		var skin:String = Note.defaultNoteSkin;
		var postfix:String = Note.getNoteSkinPostfix();
		
		if(postfix != null && postfix.length > 0)
		{
			var customSkin:String = skin + postfix;
			if(Paths.fileExists('images/$customSkin.png', IMAGE)) 
				skin = customSkin;
		}
		
		if(skin != null)
			isNotITG = skin.toLowerCase().contains('notitg');
		
		if(isNotITG)
		{
			notITGWarningText.text = Language.getPhrase("note_colors_notitg", "RGB SHADERS DISABLED - NotITG skin preserves original colors");
			notITGWarningText.visible = true;
			// Make the warning pulse so it remains visible without taking over the screen.
			FlxTween.cancelTweensOf(notITGWarningText);
			FlxTween.tween(notITGWarningText, {alpha: 0}, 0.5, {
				type: PINGPONG,
				ease: FlxEase.sineInOut
			});
		}
		else
		{
			FlxTween.cancelTweensOf(notITGWarningText);
			notITGWarningText.visible = false;
			notITGWarningText.alpha = 1;
		}
	}

	function updateColors(specific:Null<FlxColor> = null)
	{
		var color:FlxColor = getShaderColor();
		var wheelColor:FlxColor = specific == null ? getShaderColor() : specific;
		alphabetR.text = Std.string(color.red);
		alphabetG.text = Std.string(color.green);
		alphabetB.text = Std.string(color.blue);
		alphabetHex.text = color.toHexString(false, false);
		for (letter in alphabetHex.letters) letter.color = color;

		colorWheel.color = FlxColor.fromHSB(0, 0, color.brightness);
		colorWheelSelector.setPosition(colorWheel.x + colorWheel.width/2, colorWheel.y + colorWheel.height/2);
		if(wheelColor.brightness != 0)
		{
			var hueWrap:Float = wheelColor.hue * Math.PI / 180;
			colorWheelSelector.x += Math.sin(hueWrap) * colorWheel.width/2 * wheelColor.saturation;
			colorWheelSelector.y -= Math.cos(hueWrap) * colorWheel.height/2 * wheelColor.saturation;
		}
		colorGradientSelector.y = colorGradient.y + colorGradient.height * (1 - color.brightness);

		var strumRGB:RGBShaderReference = myNotes.members[curSelectedNote].rgbShader;
		switch(curSelectedMode)
		{
			case 0:
				getShader().r = strumRGB.r = color;
			case 1:
				getShader().g = strumRGB.g = color;
			case 2:
				getShader().b = strumRGB.b = color;
		}
	}

	function setShaderColor(value:FlxColor) dataArray[curSelectedNote][curSelectedMode] = value;
	function getShaderColor() return dataArray[curSelectedNote][curSelectedMode];
	function getShader() return Note.globalRgbShaders[curSelectedNote];

	override function destroy()
	{
		// Cancel the warning tween to avoid leaving a dangling animation behind.
		if(notITGWarningText != null)
			FlxTween.cancelTweensOf(notITGWarningText);
		
		Note.globalRgbShaders = [];
		super.destroy();
	}
}
