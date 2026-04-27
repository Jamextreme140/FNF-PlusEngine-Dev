package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.components.md3.FilledTextField;
import funkin.ui.components.md3.MaterialBadge;
import funkin.ui.components.md3.MaterialBox;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialCard;
import funkin.ui.components.md3.MaterialCard.CardType;
import funkin.ui.components.md3.MaterialCheckbox;
import funkin.ui.components.md3.MaterialChip;
import funkin.ui.components.md3.MaterialChip.ChipType;
import funkin.ui.components.md3.MaterialDialog;
import funkin.ui.components.md3.MaterialDivider;
import funkin.ui.components.md3.MaterialFAB;
import funkin.ui.components.md3.MaterialFAB.FABSize;
import funkin.ui.components.md3.MaterialIconButton;
import funkin.ui.components.md3.MaterialIconButton.IconButtonType;
import funkin.ui.components.md3.MaterialLoadingIndicator;
import funkin.ui.components.md3.MaterialMenu;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialProgressIndicator;
import funkin.ui.components.md3.MaterialProgressIndicator.ProgressType;
import funkin.ui.components.md3.MaterialRadioButton;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSnackbar;
import funkin.ui.components.md3.MaterialSwitch;
import funkin.ui.components.md3.MaterialTabs;
import funkin.ui.components.md3.MaterialTabs.TabType;
import funkin.ui.components.md3.MaterialTextField;
import funkin.ui.components.md3.MaterialTooltip;
import funkin.ui.components.md3.MaterialWavyProgressIndicator;
import funkin.ui.components.md3.MaterialWavyProgressIndicator.WavyProgressType;
import funkin.ui.components.md3.MD3Theme;
import funkin.ui.title.TitleState;
import funkin.ui.debug.isolated.MD3IsolatedComponentState;

class MD3TestState extends MusicBeatState
{
	var background:FlxSprite;
	var headerSurface:FlxSprite;
	var content:FlxSpriteGroup;
	var fixedOverlay:FlxSpriteGroup;

	var headerTitle:FlxText;
	var headerHint:FlxText;
	var statusText:FlxText;
	var accentLabel:FlxText;

	var sectionTitles:Array<FlxText> = [];
	var bodyTexts:Array<FlxText> = [];

	var dialog:MaterialDialog;
	var menu:MaterialMenu;
	var snackbar:MaterialSnackbar;
	var tooltip:MaterialTooltip;
	var toolbarIcon:MaterialIconButton;
	var outlinedField:MaterialTextField;
	var filledField:FilledTextField;
	var slider:MaterialSlider;
	var stepper:MaterialNumericStepper;
	var linearProgress:MaterialProgressIndicator;
	var circularProgress:MaterialProgressIndicator;
	var wavyLinearProgress:MaterialWavyProgressIndicator;
	var wavyCircularProgress:MaterialWavyProgressIndicator;

	var scrollOffset:Float = 0;
	var scrollTarget:Float = 0;
	var maxScroll:Float = 0;
	var viewportTop:Float = 112;
	var contentHeight:Float = 0;
	var progressTimer:Float = 0;

	override function create():Void
	{
		super.create();

        Cursor.show();

		buildBackground();
		buildScrollableShowcase();
		buildFixedOverlay();
		refreshTheme();
		MD3Theme.addListener(refreshTheme);
	}

	function buildBackground():Void
	{
		background = new FlxSprite(0, 0);
		background.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		add(background);

		content = new FlxSpriteGroup(0, viewportTop);
		add(content);
	}

	function buildFixedOverlay():Void
	{
		fixedOverlay = new FlxSpriteGroup();
		add(fixedOverlay);

		headerSurface = new FlxSprite(0, 0);
		headerSurface.makeGraphic(FlxG.width, Std.int(viewportTop), FlxColor.WHITE);
		fixedOverlay.add(headerSurface);

		headerTitle = makeText(28, 16, 520, "MD3 Test State", 30, true);
		fixedOverlay.add(headerTitle);

		headerHint = makeSupportText(28, 50, 760,
			"Mouse wheel or W/S scrolls. ESC closes overlays or returns to TitleState. This screen exists so the old MD3 kit can be judged without divine intervention.");
		fixedOverlay.add(headerHint);

		var backButton = new MaterialButton(28, 74, "Back", TEXT, 110, function() {
			MusicBeatState.switchState(new TitleState());
		});
		fixedOverlay.add(backButton);

		var dialogButton = new MaterialButton(152, 74, "Dialog", FILLED, 130, function() {
			dialog.open();
			setStatus("Dialog opened");
		});
		fixedOverlay.add(dialogButton);

		var menuButton = new MaterialButton(296, 74, "Menu", OUTLINED, 120, function() {
			menu.toggle();
			setStatus(menu.isOpen ? "Menu opened" : "Menu closed");
		});
		fixedOverlay.add(menuButton);

		var snackButton = new MaterialButton(430, 74, "Snackbar", FILLED, 150, function() {
			snackbar.show("MD3 showcase says hello", 3.0, "UNDO", function() {
				setStatus("Snackbar action pressed");
			});
			setStatus("Snackbar shown");
		});
		fixedOverlay.add(snackButton);

		var graphicsTestButton = new MaterialButton(596, 74, "Graphics Test", OUTLINED, 170, function() {
			MusicBeatState.switchState(new MD3GraphicsSettingsTestState());
		});
		fixedOverlay.add(graphicsTestButton);

		var isolatedButton = new MaterialButton(780, 74, "Isolated", TEXT, 110, function() {
			MusicBeatState.switchState(new MD3IsolatedComponentState());
		});
		fixedOverlay.add(isolatedButton);

		createAccentButton(904, "Purple", MD3Theme.ACCENT_PURPLE);
		createAccentButton(992, "Teal", MD3Theme.ACCENT_TEAL);
		createAccentButton(1064, "Amber", MD3Theme.ACCENT_AMBER);

		accentLabel = makeSupportText(1136, 83, 110, "Accents");
		fixedOverlay.add(accentLabel);

		toolbarIcon = new MaterialIconButton(FlxG.width - 88, 26, FILLED_TONAL, function() {
			snackbar.show("Top icon button pressed", 2.2);
			setStatus("Toolbar icon pressed");
		});
		paintGridIcon(toolbarIcon.iconSprite);
		fixedOverlay.add(toolbarIcon);

		var badge = new MaterialBadge(toolbarIcon.x + 24, toolbarIcon.y - 2, 7);
		fixedOverlay.add(badge);

		tooltip = new MaterialTooltip("Top actions and quick checks live here");
		tooltip.attachTo(toolbarIcon.x, toolbarIcon.y, 40, 40);
		fixedOverlay.add(tooltip);

		statusText = makeText(1088, 78, 170, "Ready", 16, false);
		statusText.alignment = RIGHT;
		fixedOverlay.add(statusText);

		menu = new MaterialMenu(menuButton.x, menuButton.y + 52,
			["Inspect spacing", "Ping snackbar", "Reset accent"],
			220,
			function(index:Int, label:String) {
				switch (index)
				{
					case 0:
						setStatus("Menu selected: " + label);
					case 1:
						snackbar.show("Menu launched another snackbar", 2.4);
						setStatus("Menu selected: " + label);
					case 2:
						MD3Theme.setAccent(MD3Theme.ACCENT_PURPLE);
						setStatus("Accent reset to Purple");
				}
			});
		add(menu);

		dialog = new MaterialDialog(
			"Legacy MD3 Audit",
			"This state gathers the old MD3 controls in one place so size, spacing, interaction and low-resolution behavior can be checked quickly.",
			"Looks Good",
			"Close",
			function() {
				setStatus("Dialog confirmed");
			},
			function() {
				setStatus("Dialog dismissed");
			}
		);
		add(dialog);

		snackbar = new MaterialSnackbar(420);
		add(snackbar);
	}

	function buildScrollableShowcase():Void
	{
		var cursorY:Float = 0;

		cursorY = addSectionHeader(cursorY, "Actions", "Buttons, chips and toggles. These are the first things that suffer when targets are too tiny.");

		content.add(new MaterialButton(36, cursorY, "Filled Button", FILLED, 180, function() setStatus("Filled button pressed")));
		content.add(new MaterialButton(232, cursorY, "Outlined", OUTLINED, 170, function() setStatus("Outlined button pressed")));
		content.add(new MaterialButton(418, cursorY, "Text Action", TEXT, 170, function() setStatus("Text button pressed")));
		content.add(new MaterialButton(604, cursorY, "Filled Alt", FILLED, 170, function() setStatus("Alternate filled button pressed")));
		content.add(new MaterialButton(790, cursorY, "Graphics Settings Test", OUTLINED, 240, function() {
			MusicBeatState.switchState(new MD3GraphicsSettingsTestState());
		}));
		cursorY += 70;

		content.add(new MaterialChip(36, cursorY, "Assist", ASSIST, false, function() setStatus("Assist chip tapped")));
		content.add(new MaterialChip(168, cursorY, "Filter", FILTER, true, function() setStatus("Filter chip toggled")));
		content.add(new MaterialChip(312, cursorY, "Input", INPUT, false, function() setStatus("Input chip tapped"), function() setStatus("Input chip delete")));
		content.add(new MaterialChip(456, cursorY, "Suggestion", SUGGESTION, false, function() setStatus("Suggestion chosen")));
		cursorY += 62;

		content.add(new MaterialCheckbox(36, cursorY, "Checkbox target", true, function(value:Bool) {
			setStatus("Checkbox: " + (value ? "checked" : "unchecked"));
		}));

		var toggle = new MaterialSwitch(284, cursorY - 2, true);
		toggle.onChange = function(value:Bool) {
			setStatus("Switch: " + (value ? "enabled" : "disabled"));
		};
		content.add(toggle);

		content.add(new MaterialRadioButton(448, cursorY, "Low density", "low", "density", true, function(value:String) {
			setStatus("Radio: " + value);
		}));
		content.add(new MaterialRadioButton(650, cursorY, "Balanced", "balanced", "density", false, function(value:String) {
			setStatus("Radio: " + value);
		}));
		cursorY += 64;

		cursorY = addSectionDivider(cursorY);

		cursorY = addSectionHeader(cursorY, "Inputs", "Text fields, slider and numeric stepping. Useful for quickly spotting focus and sizing issues.");

		outlinedField = new MaterialTextField(36, cursorY, 320, "Display Name");
		outlinedField.text = "Player One";
		outlinedField.onChange = function(value:String) {
			setStatus("Outlined field: " + value);
		};
		content.add(outlinedField);

		filledField = new FilledTextField(394, cursorY, 340, "Contact");
		filledField.text = "support@plusengine.dev";
		filledField.errorText = "Example validation message";
		filledField.hasError = true;
		filledField.onChange = function(value:String) {
			setStatus("Filled field: " + value);
		};
		content.add(filledField);
		cursorY += 98;

		slider = new MaterialSlider(36, cursorY + 12, 520, 0.65, 0.0, 1.0);
		slider.onChange = function(value:Float) {
			stepper.value = Math.round(value * 100);
			setStatus("Slider: " + Std.string(FlxMath.roundDecimal(value, 2)));
		};
		content.add(slider);

		stepper = new MaterialNumericStepper(606, cursorY, 5, 65, 0, 100, 0, 170, function(value:Float) {
			slider.value = value / 100;
			setStatus("Stepper: " + Std.string(Std.int(value)));
		});
		content.add(stepper);
		cursorY += 78;

		cursorY = addSectionDivider(cursorY);

		cursorY = addSectionHeader(cursorY, "Navigation", "Tabs and menu triggers. This is where cramped spacing usually feels most obvious.");

		content.add(new MaterialTabs(36, cursorY, ["Overview", "Tokens", "States"], PRIMARY, 520, function(index:Int, label:String) {
			setStatus("Primary tab: " + label);
		}));
		content.add(new MaterialTabs(590, cursorY, ["Mobile", "Desktop", "TV"], SECONDARY, 390, function(index:Int, label:String) {
			setStatus("Secondary tab: " + label);
		}));
		cursorY += 78;

		cursorY = addSectionDivider(cursorY);

		cursorY = addSectionHeader(cursorY, "Surfaces", "Cards and panels. This area makes rounded-corner quality brutally obvious at 1280x720.");

		buildCardRow(cursorY);
		cursorY += 174;

		var box = new MaterialBox(36, cursorY, 540, 180, "Material Box");
		box.canDrag = false;
		box.canMinimize = false;
		var boxTitle = makeText(18, 18, 480, "Embedded content area", 18, true);
		var boxBody = makeSupportText(18, 52, 470, "Use this container to test spacing, title bars and surface hierarchy. It is static here so scroll behavior stays predictable.");
		box.content.add(boxTitle);
		box.content.add(boxBody);
		content.add(box);
		cursorY += 206;

		cursorY = addSectionDivider(cursorY);

		cursorY = addSectionHeader(cursorY, "Indicators", "Progress, loading and ephemeral feedback. If these read well at 720p, the rest of the UI usually follows.");

		linearProgress = new MaterialProgressIndicator(36, cursorY + 12, LINEAR, 420);
		linearProgress.value = 0.48;
		content.add(linearProgress);

		var indeterminate = new MaterialProgressIndicator(36, cursorY + 52, LINEAR, 420);
		indeterminate.indeterminate = true;
		content.add(indeterminate);

		circularProgress = new MaterialProgressIndicator(536, cursorY, CIRCULAR);
		circularProgress.value = 0.72;
		content.add(circularProgress);

		content.add(new MaterialLoadingIndicator(640, cursorY - 2, 54, true));

		wavyLinearProgress = new MaterialWavyProgressIndicator(36, cursorY + 94, LINEAR, 420);
		wavyLinearProgress.value = 0.63;
		content.add(wavyLinearProgress);

		wavyCircularProgress = new MaterialWavyProgressIndicator(536, cursorY + 76, CIRCULAR, 58);
		wavyCircularProgress.value = 0.44;
		content.add(wavyCircularProgress);
		cursorY += 182;

		cursorY = addSectionDivider(cursorY);

		cursorY = addSectionHeader(cursorY, "Extended Actions", "Floating action buttons and icon buttons. Handy for checking target sizes without guesswork.");

		var smallFab = new MaterialFAB(36, cursorY + 8, SMALL, "", function() setStatus("Small FAB pressed"));
		paintPlusIcon(smallFab.iconSprite);
		content.add(smallFab);

		var regularFab = new MaterialFAB(108, cursorY, REGULAR, "", function() setStatus("Regular FAB pressed"));
		paintPlusIcon(regularFab.iconSprite);
		content.add(regularFab);

		var extendedFab = new MaterialFAB(190, cursorY, REGULAR, "Compose", function() setStatus("Extended FAB pressed"));
		paintPlayIcon(extendedFab.iconSprite);
		content.add(extendedFab);

		var largeFab = new MaterialFAB(396, cursorY - 16, LARGE, "", function() setStatus("Large FAB pressed"));
		paintGridIcon(largeFab.iconSprite);
		content.add(largeFab);

		var iconStandard = new MaterialIconButton(560, cursorY + 8, STANDARD, function() setStatus("Standard icon button pressed"));
		paintMinusIcon(iconStandard.iconSprite);
		content.add(iconStandard);

		var iconFilled = new MaterialIconButton(614, cursorY + 8, FILLED, function() setStatus("Filled icon button pressed"));
		paintPlusIcon(iconFilled.iconSprite);
		content.add(iconFilled);

		var iconTonal = new MaterialIconButton(668, cursorY + 8, FILLED_TONAL, function() setStatus("Tonal icon button pressed"));
		paintGridIcon(iconTonal.iconSprite);
		content.add(iconTonal);

		var iconOutlined = new MaterialIconButton(722, cursorY + 8, OUTLINED, function() setStatus("Outlined icon button pressed"));
		paintPlayIcon(iconOutlined.iconSprite);
		content.add(iconOutlined);

		cursorY += 134;
		contentHeight = cursorY + 48;
		recomputeScrollLimits();
	}

	function buildCardRow(startY:Float):Void
	{
		var elevated = new MaterialCard(36, startY, ELEVATED, 260, 140, function() {
			setStatus("Elevated card clicked");
		});
		elevated.addContent(makeText(18, 18, 220, "Elevated", 20, true));
		elevated.addContent(makeSupportText(18, 54, 220, "Soft surface, useful for grouping actions without heavy borders."));
		content.add(elevated);

		var filled = new MaterialCard(324, startY, FILLED, 260, 140, function() {
			setStatus("Filled card clicked");
		});
		filled.addContent(makeText(18, 18, 220, "Filled", 20, true));
		filled.addContent(makeSupportText(18, 54, 220, "Dense but readable. Good when contrast must stay calm."));
		content.add(filled);

		var outlined = new MaterialCard(612, startY, OUTLINED, 260, 140, function() {
			setStatus("Outlined card clicked");
		});
		outlined.addContent(makeText(18, 18, 220, "Outlined", 20, true));
		outlined.addContent(makeSupportText(18, 54, 220, "The sharpest test for border clarity and corner quality."));
		content.add(outlined);
	}

	function createAccentButton(x:Float, label:String, accent:FlxColor):Void
	{
		var button = new MaterialButton(x, 74, label, TEXT, 92, function() {
			MD3Theme.setAccent(accent);
			setStatus("Accent: " + label);
		});
		fixedOverlay.add(button);
	}

	function addSectionHeader(y:Float, title:String, body:String):Float
	{
		var titleText = makeText(36, y, 420, title, 28, true);
		sectionTitles.push(titleText);
		content.add(titleText);

		var bodyText = makeSupportText(36, y + 32, 860, body);
		bodyTexts.push(bodyText);
		content.add(bodyText);

		return y + 78;
	}

	function addSectionDivider(y:Float):Float
	{
		var divider = new MaterialDivider(36, y, FlxG.width - 72, false, 0, 0);
		content.add(divider);
		return y + 26;
	}

	function makeText(x:Float, y:Float, width:Float, text:String, size:Int, headline:Bool):FlxText
	{
		var label = new FlxText(x, y, width, text, size);
		label.setFormat(Paths.font("inter.otf"), size, headline ? MD3Theme.onSurface : MD3Theme.primary, LEFT);
		label.antialiasing = ClientPrefs.data.antialiasing;
		return label;
	}

	function makeSupportText(x:Float, y:Float, width:Float, text:String):FlxText
	{
		var label = new FlxText(x, y, width, text, 16);
		label.setFormat(Paths.font("inter.otf"), 16, MD3Theme.onSurfaceVariant, LEFT);
		label.antialiasing = ClientPrefs.data.antialiasing;
		return label;
	}

	function paintPlusIcon(sprite:FlxSprite):Void
	{
		paintIcon(sprite, function(px:Int, py:Int, size:Int):Bool {
			var center = Std.int(size / 2);
			return Math.abs(px - center) <= 2 || Math.abs(py - center) <= 2;
		});
	}

	function paintMinusIcon(sprite:FlxSprite):Void
	{
		paintIcon(sprite, function(px:Int, py:Int, size:Int):Bool {
			var center = Std.int(size / 2);
			return Math.abs(py - center) <= 2 && px >= 4 && px <= size - 5;
		});
	}

	function paintPlayIcon(sprite:FlxSprite):Void
	{
		paintIcon(sprite, function(px:Int, py:Int, size:Int):Bool {
			return px >= 6 && px <= size - 7 && py >= 4 + Std.int(Math.abs(px - 6) * 0.65) && py <= size - 5 - Std.int(Math.abs(px - 6) * 0.65);
		});
	}

	function paintGridIcon(sprite:FlxSprite):Void
	{
		paintIcon(sprite, function(px:Int, py:Int, size:Int):Bool {
			var cell = Std.int(size / 3);
			var localX = px % cell;
			var localY = py % cell;
			return localX >= 2 && localX <= cell - 3 && localY >= 2 && localY <= cell - 3;
		});
	}

	function paintIcon(sprite:FlxSprite, predicate:Int->Int->Int->Bool):Void
	{
		var size = Std.int(sprite.width);
		sprite.makeGraphic(size, size, FlxColor.TRANSPARENT, true);
		for (py in 0...size)
		{
			for (px in 0...size)
			{
				if (predicate(px, py, size))
				{
					sprite.pixels.setPixel32(px, py, FlxColor.WHITE);
				}
			}
		}
		sprite.dirty = true;
	}

	function setStatus(message:String):Void
	{
		if (statusText != null)
		{
			statusText.text = message;
		}
	}

	function recomputeScrollLimits():Void
	{
		maxScroll = Math.max(0, contentHeight - (FlxG.height - viewportTop - 24));
		scrollTarget = FlxMath.bound(scrollTarget, -maxScroll, 0);
		scrollOffset = FlxMath.bound(scrollOffset, -maxScroll, 0);
		content.y = viewportTop + scrollOffset;
	}

	function refreshTheme():Void
	{
		if (background != null) background.color = MD3Theme.background;
		if (headerSurface != null) headerSurface.color = MD3Theme.surfaceContainerLow;
		if (headerTitle != null) headerTitle.color = MD3Theme.onSurface;
		if (headerHint != null) headerHint.color = MD3Theme.onSurfaceVariant;
		if (statusText != null) statusText.color = MD3Theme.primary;
		if (accentLabel != null) accentLabel.color = MD3Theme.onSurfaceVariant;

		for (label in sectionTitles)
		{
			label.color = MD3Theme.onSurface;
		}

		for (label in bodyTexts)
		{
			label.color = MD3Theme.onSurfaceVariant;
		}
	}

	override function update(elapsed:Float):Void
	{
		handleStateInput();
		updateScroll(elapsed);

		progressTimer += elapsed;
		if (linearProgress != null)
		{
			linearProgress.value = (Math.sin(progressTimer * 1.15) + 1) * 0.5;
		}
		if (circularProgress != null)
		{
			circularProgress.value = (Math.cos(progressTimer * 0.8) + 1) * 0.5;
		}
		if (wavyLinearProgress != null)
		{
			wavyLinearProgress.value = (Math.sin(progressTimer * 0.95 + 1.1) + 1) * 0.5;
		}
		if (wavyCircularProgress != null)
		{
			wavyCircularProgress.value = (Math.cos(progressTimer * 1.05 + 0.45) + 1) * 0.5;
		}

		super.update(elapsed);
	}

	function handleStateInput():Void
	{
		var typing = (outlinedField != null && outlinedField.focused) || (filledField != null && filledField.focused);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			if (dialog != null && dialog.isOpen)
			{
				dialog.close();
				setStatus("Dialog closed");
			}
			else if (menu != null && menu.isOpen)
			{
				menu.close();
				setStatus("Menu closed");
			}
			else if (!typing)
			{
				MusicBeatState.switchState(new TitleState());
			}
		}
	}

	function updateScroll(elapsed:Float):Void
	{
		var typing = (outlinedField != null && outlinedField.focused) || (filledField != null && filledField.focused);
		if (!typing)
		{
			if (FlxG.mouse.wheel != 0)
			{
				scrollTarget += FlxG.mouse.wheel * 56;
			}

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.UP)
			{
				scrollTarget += 22;
			}
			if (FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN)
			{
				scrollTarget -= 22;
			}
		}

		scrollTarget = FlxMath.bound(scrollTarget, -maxScroll, 0);
		scrollOffset = FlxMath.lerp(scrollOffset, scrollTarget, 0.22);
		if (Math.abs(scrollOffset - scrollTarget) < 0.1)
		{
			scrollOffset = scrollTarget;
		}
		content.y = viewportTop + scrollOffset;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(refreshTheme);
		super.destroy();
	}
}