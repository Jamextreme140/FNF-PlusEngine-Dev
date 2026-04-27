package funkin.ui.debug;

import Main;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.shaders.ColorblindFilter;
import funkin.ui.MusicBeatState;
import funkin.ui.components.md3.MD3Metrics;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MD3Theme;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSnackbar;
import funkin.ui.components.md3.MaterialSwitch;
import funkin.ui.options.GraphicsSettingsSubState;
import funkin.util.WindowMode;

class MD3GraphicsSettingsTestState extends MusicBeatState
{
	var background:FlxSprite;
	var appBar:FlxSprite;
	var content:FlxSpriteGroup;
	var fixedOverlay:FlxSpriteGroup;

	var titleText:FlxText;
	var subtitleText:FlxText;
	var statusText:FlxText;
	var sectionTexts:Array<FlxText> = [];
	var rows:Array<MD3SettingsRowBase> = [];

	var snackbar:MaterialSnackbar;

	var scrollOffset:Float = 0;
	var scrollTarget:Float = 0;
	var maxScroll:Float = 0;
	var viewportTop:Float = 108;
	var contentHeight:Float = 0;

	override function create():Void
	{
		super.create();
		Cursor.show();

		buildBackground();
		buildHeader();
		buildContent();
		refreshTheme();
		applyAntialiasingVisuals();
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

	function buildHeader():Void
	{
		fixedOverlay = new FlxSpriteGroup();
		add(fixedOverlay);

		appBar = new FlxSprite(0, 0);
		appBar.makeGraphic(FlxG.width, Std.int(viewportTop), FlxColor.WHITE);
		fixedOverlay.add(appBar);

		titleText = makeText(28, 16, 560, Language.getPhrase('graphics_menu', 'Graphics Settings'), 30, true);
		fixedOverlay.add(titleText);

		subtitleText = makeSupportText(28, 52, 880,
			"Android-like MD3 test screen driven by the same preferences as the classic graphics substate. ESC goes back, and Classic opens the old menu for side-by-side checking.");
		fixedOverlay.add(subtitleText);

		var backButton = new MaterialButton(28, 72, "Back", TEXT, 110, function() {
			MusicBeatState.switchState(new MD3TestState());
		});
		fixedOverlay.add(backButton);

		var classicButton = new MaterialButton(152, 72, "Classic", OUTLINED, 130, function() {
			openSubState(new GraphicsSettingsSubState());
			setStatus("Opened classic Graphics Settings");
		});
		fixedOverlay.add(classicButton);

		var resetButton = new MaterialButton(296, 72, "Reset Accent", FILLED, 160, function() {
			MD3Theme.setAccent(MD3Theme.ACCENT_PURPLE);
			setStatus("Accent reset to Purple");
		});
		fixedOverlay.add(resetButton);

		statusText = makeText(978, 76, 270, "Ready", 16, false);
		statusText.alignment = RIGHT;
		fixedOverlay.add(statusText);

		snackbar = new MaterialSnackbar(420);
		add(snackbar);
	}

	function buildContent():Void
	{
		var rowY:Float = 18;
		var rowX:Float = 56;
		var rowWidth:Float = FlxG.width - 112;

		rowY = addSectionLabel(rowY, "Rendering", "Same option set as GraphicsSettingsSubState, but laid out like a touch-first settings page.");

		addRow(new MD3SwitchSettingsRow(rowX, rowY, rowWidth,
			"Low Quality",
			"Disables some background details to reduce cost and loading times.",
			ClientPrefs.data.lowQuality,
			function(value:Bool) {
				ClientPrefs.data.lowQuality = value;
				saveAndNotify("Low Quality " + boolLabel(value));
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		addRow(new MD3SwitchSettingsRow(rowX, rowY, rowWidth,
			"Anti-Aliasing",
			"Smooths edges for sprites and UI. Disabling it saves cost at the expense of sharper visuals.",
			ClientPrefs.data.antialiasing,
			function(value:Bool) {
				ClientPrefs.data.antialiasing = value;
				applyAntialiasingVisuals();
				saveAndNotify("Anti-Aliasing " + boolLabel(value));
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		addRow(new MD3SwitchSettingsRow(rowX, rowY, rowWidth,
			"Shaders",
			"Toggles shader-based visuals and effects. Good candidate to disable on weaker devices.",
			ClientPrefs.data.shaders,
			function(value:Bool) {
				ClientPrefs.data.shaders = value;
				saveAndNotify("Shaders " + boolLabel(value));
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		addRow(new MD3SwitchSettingsRow(rowX, rowY, rowWidth,
			"GPU Caching",
			"Uses the GPU for texture caching to reduce RAM usage. Leave it off if the graphics card is unstable.",
			ClientPrefs.data.cacheOnGPU,
			function(value:Bool) {
				ClientPrefs.data.cacheOnGPU = value;
				saveAndNotify("GPU Caching " + boolLabel(value));
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		var colorModes = ['None', 'Protanopia', 'Protanomaly', 'Deuteranopia', 'Deuteranomaly', 'Tritanopia', 'Tritanomaly', 'Achromatopsia', 'Achromatomaly'];
		var colorRow = new MD3ChoiceSettingsRow(rowX, rowY, rowWidth,
			"Color Accessibility",
			"Cycles through the same color blindness filters as the classic graphics menu.",
			ClientPrefs.data.colorblindMode,
			null);
		colorRow.button.onClick = function() {
			ClientPrefs.data.colorblindMode = nextString(colorModes, ClientPrefs.data.colorblindMode);
			colorRow.setValueLabel(ClientPrefs.data.colorblindMode);
			ClientPrefs.saveSettings();
			ColorblindFilter.UpdateColors();
			snackbar.show("Color Accessibility: " + ClientPrefs.data.colorblindMode, 2.0);
			setStatus("Color Accessibility: " + ClientPrefs.data.colorblindMode);
		};
		addRow(colorRow);
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		rowY += 10;
		rowY = addSectionLabel(rowY, "Performance", "Frame pacing and overlays. This is where the original graphics substate mixes technical toggles with quality knobs.");

		#if !html5
		addRow(new MD3SwitchSettingsRow(rowX, rowY, rowWidth,
			"VSync",
			"Reduces tearing and aligns pacing to the monitor refresh rate. Full effect can require a restart.",
			ClientPrefs.data.vsync,
			function(value:Bool) {
				ClientPrefs.data.vsync = value;
				saveAndNotify("VSync " + boolLabel(value));
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;
		#end

		var minFramerate = #if mobile 30 #else 60 #end;
		addRow(new MD3StepperSettingsRow(rowX, rowY, rowWidth,
			"Framerate",
			"Adjusts the FPS cap used by the engine. The classic menu exposes the same setting as a numeric option.",
			ClientPrefs.data.framerate,
			5,
			minFramerate,
			240,
			0,
			function(value:Float) {
				ClientPrefs.data.framerate = Std.int(value);
				applyFramerate();
				saveAndNotify("Framerate: " + ClientPrefs.data.framerate + " FPS");
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		addRow(new MD3SwitchSettingsRow(rowX, rowY, rowWidth,
			"Fixed Timestep",
			"Uses a fixed update step for steadier gameplay timing when rendering drops below the cap.",
			ClientPrefs.data.fpsRework,
			function(value:Bool) {
				ClientPrefs.data.fpsRework = value;
				applyFramerate();
				saveAndNotify("Fixed Timestep " + boolLabel(value));
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		addRow(new MD3SwitchSettingsRow(rowX, rowY, rowWidth,
			"FPS Counter",
			"Shows or hides the counter in the corner, just like the original graphics settings menu.",
			ClientPrefs.data.showFPS,
			function(value:Bool) {
				ClientPrefs.data.showFPS = value;
				applyFPSCounter();
				saveAndNotify("FPS Counter " + boolLabel(value));
			}));
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;

		rowY += 10;
		rowY = addSectionLabel(rowY, "Platform", "Options that depend on OS-specific behavior or mobile detection.");

		#if windows
		var fullscreenModes = ['Borderless', 'Borderless Fix', 'Exclusive'];
		var fullscreenRow = new MD3ChoiceSettingsRow(rowX, rowY, rowWidth,
			"Fullscreen Mode",
			"Cycles between the same modes used by WindowMode. The selected value is applied next time fullscreen is toggled.",
			ClientPrefs.data.fullscreenMode,
			null);
		fullscreenRow.button.onClick = function() {
			ClientPrefs.data.fullscreenMode = nextString(fullscreenModes, ClientPrefs.data.fullscreenMode);
			fullscreenRow.setValueLabel(ClientPrefs.data.fullscreenMode);
			saveAndNotify("Fullscreen Mode: " + ClientPrefs.data.fullscreenMode);
		};
		addRow(fullscreenRow);
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;
		#end

		#if android
		var tierChoices = ['Auto (Recommended)', 'Force Low-End', 'Force Mid-Range', 'Force High-End'];
		var tierRow = new MD3ChoiceSettingsRow(rowX, rowY, rowWidth,
			"Auto-Optimization Tier",
			"Matches the Android optimizer override from the classic graphics menu.",
			tierChoices[0],
			null);
		tierRow.button.onClick = function() {
			var nextTier = nextString(tierChoices, tierRow.getValueLabel());
			tierRow.setValueLabel(nextTier);
			switch (nextTier)
			{
				case 'Force Low-End': funkin.mobile.AndroidOptimizer.forceOptimizationTier(0);
				case 'Force Mid-Range': funkin.mobile.AndroidOptimizer.forceOptimizationTier(1);
				case 'Force High-End': funkin.mobile.AndroidOptimizer.forceOptimizationTier(2);
				default: funkin.mobile.AndroidOptimizer.init();
			}
			snackbar.show("Optimization Tier: " + nextTier, 2.0);
			setStatus("Optimization Tier: " + nextTier);
		};
		addRow(tierRow);
		rowY += MD3SettingsRowBase.ROW_HEIGHT + 12;
		#end

		contentHeight = rowY + 32;
		recomputeScrollLimits();
	}

	function addRow(row:MD3SettingsRowBase):Void
	{
		rows.push(row);
		content.add(row);
	}

	function addSectionLabel(y:Float, title:String, summary:String):Float
	{
		var titleLabel = makeText(56, y, 520, title, 26, true);
		sectionTexts.push(titleLabel);
		content.add(titleLabel);

		var summaryLabel = makeSupportText(56, y + 30, FlxG.width - 112, summary);
		sectionTexts.push(summaryLabel);
		content.add(summaryLabel);

		return y + 74;
	}

	function boolLabel(value:Bool):String
	{
		return value ? 'Enabled' : 'Disabled';
	}

	function nextString(options:Array<String>, current:String):String
	{
		var index = options.indexOf(current);
		if (index < 0) index = 0;
		return options[(index + 1) % options.length];
	}

	function saveAndNotify(message:String):Void
	{
		ClientPrefs.saveSettings();
		snackbar.show(message, 1.8);
		setStatus(message);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.55);
	}

	function applyFramerate():Void
	{
		ClientPrefs.applyFramePacing();
	}

	function applyFPSCounter():Void
	{
		if (Main.fpsVar != null)
			Main.fpsVar.visible = ClientPrefs.data.showFPS;
	}

	function applyAntialiasingVisuals():Void
	{
		applyAntialiasingRecursive(this);
	}

	function applyAntialiasingRecursive(target:Dynamic):Void
	{
		if (target == null) return;

		if (Std.isOfType(target, FlxSprite))
		{
			cast(target, FlxSprite).antialiasing = ClientPrefs.data.antialiasing;
		}

		if (Reflect.hasField(target, 'members'))
		{
			var members:Array<Dynamic> = Reflect.field(target, 'members');
			if (members != null)
			{
				for (member in members)
				{
					applyAntialiasingRecursive(member);
				}
			}
		}
	}

	function makeText(x:Float, y:Float, width:Float, text:String, size:Int, headline:Bool):FlxText
	{
		var label = new FlxText(x, y, width, text, size);
		label.setFormat(Paths.font('inter.otf'), size, headline ? MD3Theme.onSurface : MD3Theme.primary, LEFT);
		label.antialiasing = ClientPrefs.data.antialiasing;
		return label;
	}

	function makeSupportText(x:Float, y:Float, width:Float, text:String):FlxText
	{
		var label = new FlxText(x, y, width, text, 16);
		label.setFormat(Paths.font('inter.otf'), 16, MD3Theme.onSurfaceVariant, LEFT);
		label.antialiasing = ClientPrefs.data.antialiasing;
		return label;
	}

	function setStatus(message:String):Void
	{
		if (statusText != null)
			statusText.text = message;
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
		if (appBar != null) appBar.color = MD3Theme.surfaceContainerLow;
		if (titleText != null) titleText.color = MD3Theme.onSurface;
		if (subtitleText != null) subtitleText.color = MD3Theme.onSurfaceVariant;
		if (statusText != null) statusText.color = MD3Theme.primary;

		for (label in sectionTexts)
		{
			if (label != null)
			{
				label.color = (label.size >= 26) ? MD3Theme.onSurface : MD3Theme.onSurfaceVariant;
			}
		}

		for (row in rows)
		{
			row.refreshTheme();
		}
	}

	override function closeSubState():Void
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		setStatus("Returned from classic Graphics Settings");
	}

	override function update(elapsed:Float):Void
	{
		handleInput();
		updateScroll(elapsed);
		super.update(elapsed);
	}

	function handleInput():Void
	{
		if (FlxG.keys.justPressed.ESCAPE && subState == null)
		{
			MusicBeatState.switchState(new MD3TestState());
		}
	}

	function updateScroll(elapsed:Float):Void
	{
		if (subState == null)
		{
			if (FlxG.mouse.wheel != 0)
				scrollTarget += FlxG.mouse.wheel * 56;

			if (FlxG.keys.pressed.W || FlxG.keys.pressed.UP)
				scrollTarget += 22;

			if (FlxG.keys.pressed.S || FlxG.keys.pressed.DOWN)
				scrollTarget -= 22;
		}

		scrollTarget = FlxMath.bound(scrollTarget, -maxScroll, 0);
		scrollOffset = FlxMath.lerp(scrollOffset, scrollTarget, 0.22);
		if (Math.abs(scrollOffset - scrollTarget) < 0.1)
			scrollOffset = scrollTarget;

		content.y = viewportTop + scrollOffset;
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(refreshTheme);
		super.destroy();
	}
}

class MD3SettingsRowBase extends FlxSpriteGroup
{
	public static inline var ROW_HEIGHT:Float = 88;

	var background:FlxSprite;
	var titleText:FlxText;
	var summaryText:FlxText;
	var rowWidth:Float;

	public function new(x:Float, y:Float, width:Float, title:String, summary:String)
	{
		super(x, y);
		rowWidth = width;

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		titleText = new FlxText(20, 14, width - 240, title, 18);
		titleText.setFormat(Paths.font('inter.otf'), 18, MD3Theme.onSurface, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		summaryText = new FlxText(20, 40, width - 240, summary, 14);
		summaryText.setFormat(Paths.font('inter.otf'), 14, MD3Theme.onSurfaceVariant, LEFT);
		summaryText.antialiasing = ClientPrefs.data.antialiasing;
		add(summaryText);

		refreshTheme();
	}

	public function refreshTheme():Void
	{
		MD3ShapeTools.fillAndStrokeRoundRect(background, Std.int(rowWidth), Std.int(ROW_HEIGHT), MD3Metrics.corner(18, rowWidth, ROW_HEIGHT), 1,
			MD3Theme.surfaceContainerLowest, MD3Theme.outlineVariant);
		background.color = MD3Theme.surfaceContainerLowest;
		titleText.color = MD3Theme.onSurface;
		summaryText.color = MD3Theme.onSurfaceVariant;
	}
}

class MD3SwitchSettingsRow extends MD3SettingsRowBase
{
	public var control:MaterialSwitch;

	public function new(x:Float, y:Float, width:Float, title:String, summary:String, checked:Bool, onToggle:Bool->Void)
	{
		super(x, y, width, title, summary);
		control = new MaterialSwitch(width - 86, (MD3SettingsRowBase.ROW_HEIGHT - MD3Metrics.size(32)) * 0.5, checked);
		control.onChange = onToggle;
		add(control);
	}
}

class MD3StepperSettingsRow extends MD3SettingsRowBase
{
	public var stepper:MaterialNumericStepper;

	public function new(x:Float, y:Float, width:Float, title:String, summary:String, value:Float,
		step:Float, min:Float, max:Float, decimals:Int, onChange:Float->Void)
	{
		super(x, y, width, title, summary);
		stepper = new MaterialNumericStepper(width - 224, (MD3SettingsRowBase.ROW_HEIGHT - MD3Metrics.size(44)) * 0.5,
			step, value, min, max, decimals, 190, onChange);
		add(stepper);
	}
}

class MD3ChoiceSettingsRow extends MD3SettingsRowBase
{
	public var button:MaterialButton;
	static inline var BUTTON_WIDTH:Float = 240;

	public function new(x:Float, y:Float, width:Float, title:String, summary:String, valueLabel:String, onActivate:Void->Void)
	{
		super(x, y, width, title, summary);
		button = new MaterialButton(width - BUTTON_WIDTH - 24, (MD3SettingsRowBase.ROW_HEIGHT - MD3Metrics.size(44)) * 0.5, valueLabel, OUTLINED, BUTTON_WIDTH, onActivate);
		add(button);
	}

	public function setValueLabel(label:String):Void
	{
		button.label = label;
		trace('[MD3ChoiceSettingsRow] setValueLabel=' + label + ' button=(' + button.x + ', ' + button.y + ')');
	}

	public function getValueLabel():String
	{
		return button.label;
	}
}