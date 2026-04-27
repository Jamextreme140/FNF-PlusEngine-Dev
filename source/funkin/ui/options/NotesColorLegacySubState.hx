package funkin.ui.options;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import funkin.play.notes.Note;
import funkin.ui.components.md3.MD3ShapeTools;

class NotesColorLegacySubState extends MusicBeatSubstate
{
	var curSelectedNote:Int = 0;
	var curSelectedValue:Int = 0;
	var editingValue:Bool = false;
	var onPixel:Bool = false;
	var valueHoldTime:Float = 0;
	var valueRepeatTime:Float = 0;
	var valueHoldDirection:Int = 0;

	static final HOLD_REPEAT_DELAY:Float = 0.4;
	static final HOLD_REPEAT_INTERVAL:Float = 0.06;

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

	var rowHighlights:Array<FlxSprite> = [];
	var valueHighlights:Array<FlxSprite> = [];
	var noteLabels:Array<FlxText> = [];
	var valueTexts:Array<FlxText> = [];
	var valueHeaders:Array<FlxText> = [];

	var notes:FlxTypedGroup<Note>;
	var bigNote:Note;
	var footerText:FlxText;
	var modeText:FlxText;

	public function new()
	{
		controls.isInSubstate = true;
		super();
	}

	override function create():Void
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Legacy Note Colors Menu', null);
		#end

		onPixel = PlayState.isPixelStage;
		buildLayout();
		spawnPreview();
		refreshSelection(true);
	}

	function buildLayout():Void
	{
		OptionsMenuTheme.syncAccent();
		var palette = OptionsMenuTheme.current();

		panelWidth = Math.min(1180, FlxG.width - 36);
		panelHeight = Math.min(676, FlxG.height - 20);
		panelX = (FlxG.width - panelWidth) * 0.5;
		panelY = (FlxG.height - panelHeight) * 0.5;
		previewWidth = Math.min(676, panelWidth * 0.56);
		previewHeight = panelHeight - 136;
		previewX = panelX + 18;
		previewY = panelY + 104;
		editorX = previewX + previewWidth + 18;
		editorY = previewY;
		editorWidth = panelX + panelWidth - 18 - editorX;
		editorHeight = previewHeight;

		var overlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, OptionsMenuTheme.backdropColor());
		add(overlay);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = palette.pale;
		bg.alpha = 0.16;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

		var grid:FlxBackdrop = new FlxBackdrop(FlxGridOverlay.createGrid(80, 80, 160, 160, true, 0x33FFFFFF, 0x0));
		grid.velocity.set(40, 40);
		grid.alpha = 0.16;
		grid.color = OptionsMenuTheme.gridAccentColor();
		grid.clipRect = new FlxRect(panelX, panelY, panelWidth, panelHeight);
		add(grid);

		var panelShadow:FlxSprite = new FlxSprite(panelX + 10, panelY + 12);
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x26000000);
		add(panelShadow);

		var panelSurface:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, OptionsMenuTheme.panelSurfaceColor());
		add(panelSurface);

		var panelHeader:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 100, 34, 34, 0, 0, OptionsMenuTheme.panelHeaderColor());
		add(panelHeader);

		var panelOutline:FlxSprite = new FlxSprite(panelX, panelY);
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, OptionsMenuTheme.panelOutlineColor());
		add(panelOutline);

		var previewSurface:FlxSprite = new FlxSprite(previewX, previewY);
		MD3ShapeTools.fillAndStrokeRoundRect(previewSurface, Std.int(previewWidth), Std.int(previewHeight), 28, 2,
			OptionsMenuTheme.previewSurfaceColor(), OptionsMenuTheme.neutralOutlineColor());
		add(previewSurface);

		var editorSurface:FlxSprite = new FlxSprite(editorX, editorY);
		MD3ShapeTools.fillAndStrokeRoundRect(editorSurface, Std.int(editorWidth), Std.int(editorHeight), 28, 2,
			OptionsMenuTheme.cardFill(false), OptionsMenuTheme.neutralOutlineColor());
		add(editorSurface);

		var titleText:FlxText = new FlxText(panelX + 34, panelY + 18, panelWidth - 68,
			Language.getPhrase('note_colors_legacy_title', 'Legacy Note Colors'), 30);
		titleText.setFormat(Paths.font('inter-bold.otf'), 30, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		var subtitleText:FlxText = new FlxText(panelX + 34, panelY + 56, panelWidth - 68,
			Language.getPhrase('note_colors_legacy_subtitle', 'RGB is off, so note colors use classic Hue, Saturation and Brightness offsets. Same sprites, more old-school attitude.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		var previewLabel:FlxText = new FlxText(previewX + 22, previewY + 18, previewWidth - 128,
			Language.getPhrase('note_colors_preview_label', 'Preview Lane'), 20);
		previewLabel.setFormat(Paths.font('inter-bold.otf'), 20, OptionsMenuTheme.previewTitleColor(), LEFT);
		previewLabel.antialiasing = ClientPrefs.data.antialiasing;
		add(previewLabel);

		var previewHint:FlxText = new FlxText(previewX + 22, previewY + 44, previewWidth - 160,
			Language.getPhrase('note_colors_legacy_preview_hint', 'CTRL toggles normal and pixel previews. The selected lane updates live below.'), 14);
		previewHint.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.previewHintColor(false), LEFT);
		previewHint.antialiasing = ClientPrefs.data.antialiasing;
		add(previewHint);

		modeText = new FlxText(editorX + 22, editorY + 18, editorWidth - 44, '', 18);
		modeText.setFormat(Paths.font('inter-bold.otf'), 18, OptionsMenuTheme.previewTitleColor(), LEFT);
		modeText.antialiasing = ClientPrefs.data.antialiasing;
		add(modeText);

		var editorHint:FlxText = new FlxText(editorX + 22, editorY + 48, editorWidth - 44,
			Language.getPhrase('note_colors_legacy_editor_hint', 'UP/DOWN picks the lane. LEFT/RIGHT picks Hue, Saturation or Brightness. ENTER edits. RESET clears the selected value, SHIFT + RESET clears the whole lane.'), 14);
		editorHint.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.previewHintColor(false), LEFT);
		editorHint.antialiasing = ClientPrefs.data.antialiasing;
		add(editorHint);

		var tableTop:Float = editorY + 112;
		var labelWidth:Float = 92;
		var valueWidth:Float = 110;
		var rowHeight:Float = 78;
		var startX:Float = editorX + 22;
		var headerY:Float = tableTop;

		var headers = [
			Language.getPhrase('note_colors_hue', 'Hue'),
			Language.getPhrase('note_colors_saturation', 'Saturation'),
			Language.getPhrase('note_colors_brightness', 'Brightness')
		];
		for (i in 0...headers.length)
		{
			var header:FlxText = new FlxText(startX + labelWidth + 20 + i * valueWidth, headerY, valueWidth, headers[i], 15);
			header.setFormat(Paths.font('inter-bold.otf'), 15, OptionsMenuTheme.cardTitleColor(false), CENTER);
			header.antialiasing = ClientPrefs.data.antialiasing;
			add(header);
			valueHeaders.push(header);
		}

		for (noteIndex in 0...Note.colArray.length)
		{
			var rowY:Float = tableTop + 34 + noteIndex * rowHeight;
			var rowHighlight:FlxSprite = new FlxSprite(startX, rowY - 8);
			MD3ShapeTools.fillRoundRect(rowHighlight, Std.int(editorWidth - 44), Std.int(rowHeight - 10), 20, 0x0);
			add(rowHighlight);
			rowHighlights.push(rowHighlight);

			var noteLabel:FlxText = new FlxText(startX + 10, rowY + 14, labelWidth, Language.getPhrase('note_lane_' + noteIndex, 'Lane ' + (noteIndex + 1)), 18);
			noteLabel.setFormat(Paths.font('inter-bold.otf'), 18, OptionsMenuTheme.cardTitleColor(false), LEFT);
			noteLabel.antialiasing = ClientPrefs.data.antialiasing;
			add(noteLabel);
			noteLabels.push(noteLabel);

			for (valueIndex in 0...3)
			{
				var x:Float = startX + labelWidth + 20 + valueIndex * valueWidth;
				var valueHighlight:FlxSprite = new FlxSprite(x - 6, rowY + 6);
				MD3ShapeTools.fillRoundRect(valueHighlight, Std.int(valueWidth - 12), 38, 16, 0x0);
				add(valueHighlight);
				valueHighlights.push(valueHighlight);

				var valueText:FlxText = new FlxText(x, rowY + 12, valueWidth - 12, '0', 20);
				valueText.setFormat(Paths.font('inter-bold.otf'), 20, OptionsMenuTheme.cardTitleColor(false), CENTER);
				valueText.antialiasing = ClientPrefs.data.antialiasing;
				add(valueText);
				valueTexts.push(valueText);
			}
		}

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56, '', 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);
	}

	function spawnPreview():Void
	{
		var previousStageUI:String = PlayState.stageUI;
		PlayState.stageUI = onPixel ? 'pixel' : 'normal';

		if (notes != null)
		{
			remove(notes);
			notes.destroy();
		}
		if (bigNote != null)
		{
			remove(bigNote);
			bigNote.destroy();
		}

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var spacing:Float = onPixel ? 102 : 110;
		var startX:Float = previewX + previewWidth * 0.5 - (spacing * (Note.colArray.length - 1)) * 0.5;
		var noteY:Float = previewY + 126;
		var noteSize:Int = onPixel ? 116 : 106;
		Note.globalRgbShaders = [];
		for (i in 0...Note.colArray.length)
		{
			Note.initializeGlobalRGBShader(i);
			var note:Note = new Note(0, i, null, false, true);
			note.setGraphicSize(noteSize);
			note.updateHitbox();
			note.setPosition(startX + spacing * i - note.width * 0.5, noteY);
			note.ID = i;
			note.alpha = i == curSelectedNote ? 1 : 0.72;
			note.refreshLegacyColorSwap();
			note.refreshColorMode();
			notes.add(note);
		}

		bigNote = new Note(0, curSelectedNote, null, false, true);
		bigNote.setPosition(previewX + previewWidth * 0.5 - 88, previewY + 330);
		bigNote.setGraphicSize(176);
		bigNote.updateHitbox();
		for (i in 0...Note.colArray.length)
		{
			if (!onPixel) bigNote.animation.addByPrefix('note$i', Note.colArray[i] + '0', 24, true);
			else bigNote.animation.add('note$i', [i + 4], 24, true);
		}
		insert(members.indexOf(notes) + 1, bigNote);
		PlayState.stageUI = previousStageUI;
		refreshPreviewColors();
	}

	function refreshPreviewColors():Void
	{
		for (note in notes)
		{
			note.alpha = note.ID == curSelectedNote ? 1 : 0.72;
			note.refreshLegacyColorSwap();
			note.refreshColorMode();
		}

		bigNote.noteData = curSelectedNote;
		bigNote.animation.play('note$curSelectedNote', true);
		bigNote.refreshLegacyColorSwap();
		bigNote.refreshColorMode();
	}

	function getValueIndex(noteIndex:Int, typeIndex:Int):Int
	{
		return noteIndex * 3 + typeIndex;
	}

	function getSelectedValues():Array<Float>
	{
		return ClientPrefs.data.arrowHSV[curSelectedNote];
	}

	function resetSelectedValue():Void
	{
		ClientPrefs.data.arrowHSV[curSelectedNote][curSelectedValue] = 0;
		ClientPrefs.saveSettings();
		refreshSelection();
	}

	function resetSelectedLane():Void
	{
		for (i in 0...3)
			ClientPrefs.data.arrowHSV[curSelectedNote][i] = 0;
		ClientPrefs.saveSettings();
		refreshSelection();
	}

	function updateValue(change:Float):Void
	{
		var values:Array<Float> = getSelectedValues();
		var maxValue:Float = curSelectedValue == 0 ? 180 : 100;
		var newValue:Float = values[curSelectedValue] + change;
		if (newValue < -maxValue) newValue = -maxValue;
		if (newValue > maxValue) newValue = maxValue;
		values[curSelectedValue] = Math.round(newValue);
		ClientPrefs.saveSettings();
		refreshSelection();
	}

	function clearValueRepeat():Void
	{
		valueHoldTime = 0;
		valueRepeatTime = 0;
		valueHoldDirection = 0;
	}

	function beginValueRepeat(direction:Int):Void
	{
		valueHoldDirection = direction;
		valueHoldTime = 0;
		valueRepeatTime = 0;
	}

	function refreshSelection(?instant:Bool = false):Void
	{
		var accent:Int = OptionsMenuTheme.current().accent;
		for (noteIndex in 0...Note.colArray.length)
		{
			var rowSelected:Bool = noteIndex == curSelectedNote;
			var rowColor:Int = rowSelected ? OptionsMenuTheme.accentOverlay(0.18) : 0x0;
			MD3ShapeTools.fillRoundRect(rowHighlights[noteIndex], Std.int(editorWidth - 44), 68, 20, rowColor);
			noteLabels[noteIndex].color = rowSelected ? OptionsMenuTheme.cardTitleColor(true) : OptionsMenuTheme.cardTitleColor(false);

			for (valueIndex in 0...3)
			{
				var visualIndex:Int = getValueIndex(noteIndex, valueIndex);
				var selectedValue:Bool = rowSelected && valueIndex == curSelectedValue;
				var highlightColor:Int = selectedValue ? (editingValue ? accent : OptionsMenuTheme.accentOverlay(0.24)) : 0x0;
				MD3ShapeTools.fillRoundRect(valueHighlights[visualIndex], 98, 38, 16, highlightColor);
				valueTexts[visualIndex].text = Std.string(Math.round(ClientPrefs.data.arrowHSV[noteIndex][valueIndex]));
				valueTexts[visualIndex].color = selectedValue ? (editingValue ? OptionsMenuTheme.panelSurfaceColor() : OptionsMenuTheme.cardTitleColor(true)) : OptionsMenuTheme.cardTitleColor(false);
			}
		}

		modeText.text = editingValue
			? Language.getPhrase('note_colors_legacy_mode_edit', 'Editing value')
			: Language.getPhrase('note_colors_legacy_mode_select', 'Selecting lane / component');
		footerText.text = Language.getPhrase('note_colors_legacy_footer', 'ENTER toggles edit mode. CTRL changes pixel preview. ESC goes back.');
		refreshPreviewColors();
	}

	override function update(elapsed:Float):Void
	{
		if (controls.BACK)
		{
			if (editingValue)
			{
				editingValue = false;
				clearValueRepeat();
				refreshSelection();
				FlxG.sound.play(Paths.sound('cancelMenu'));
				return;
			}

			controls.isInSubstate = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			close();
			return;
		}

		super.update(elapsed);

		if (FlxG.keys.justPressed.CONTROL)
		{
			onPixel = !onPixel;
			spawnPreview();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.55);
			return;
		}

		if (controls.RESET)
		{
			if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(LEFT_SHOULDER))
				resetSelectedLane();
			else
				resetSelectedValue();
			FlxG.sound.play(Paths.sound('cancelMenu'), 0.55);
			return;
		}

		if (controls.ACCEPT)
		{
			editingValue = !editingValue;
			if (!editingValue)
				clearValueRepeat();
			refreshSelection();
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.55);
			return;
		}

		if (editingValue)
		{
			var valueStep:Float = 1;
			if (FlxG.keys.pressed.SHIFT || FlxG.gamepads.anyPressed(RIGHT_SHOULDER))
				valueStep = curSelectedValue == 0 ? 5 : 2;

			if (controls.UI_LEFT_P)
			{
				updateValue(-valueStep);
				beginValueRepeat(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
			}
			else if (controls.UI_RIGHT_P)
			{
				updateValue(valueStep);
				beginValueRepeat(1);
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
			}
			else
			{
				var heldDirection:Int = 0;
				if (controls.UI_LEFT)
					heldDirection = -1;
				else if (controls.UI_RIGHT)
					heldDirection = 1;

				if (heldDirection == 0 || heldDirection != valueHoldDirection)
				{
					clearValueRepeat();
				}
				else
				{
					valueHoldTime += elapsed;
					if (valueHoldTime >= HOLD_REPEAT_DELAY)
					{
						valueRepeatTime += elapsed;
						while (valueRepeatTime >= HOLD_REPEAT_INTERVAL)
						{
							updateValue(valueStep * valueHoldDirection);
							valueRepeatTime -= HOLD_REPEAT_INTERVAL;
							FlxG.sound.play(Paths.sound('scrollMenu'), 0.35);
						}
					}
				}
			}
		}
		else
		{
			clearValueRepeat();
			if (controls.UI_UP_P)
			{
				curSelectedNote = FlxMath.wrap(curSelectedNote - 1, 0, Note.colArray.length - 1);
				refreshSelection();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
			}
			else if (controls.UI_DOWN_P)
			{
				curSelectedNote = FlxMath.wrap(curSelectedNote + 1, 0, Note.colArray.length - 1);
				refreshSelection();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
			}

			if (controls.UI_LEFT_P)
			{
				curSelectedValue = FlxMath.wrap(curSelectedValue - 1, 0, 2);
				refreshSelection();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
			}
			else if (controls.UI_RIGHT_P)
			{
				curSelectedValue = FlxMath.wrap(curSelectedValue + 1, 0, 2);
				refreshSelection();
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
			}
		}
	}

	override function destroy():Void
	{
		Note.globalRgbShaders = [];
		super.destroy();
	}
}