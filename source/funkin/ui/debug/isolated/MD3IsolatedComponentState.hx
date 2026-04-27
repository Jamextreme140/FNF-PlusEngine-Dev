package funkin.ui.debug.isolated;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.components.md3.MD3Theme;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialLoadingIndicator;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSwitch;
import funkin.ui.debug.MD3TestState;

class MD3IsolatedComponentState extends MusicBeatState
{
	var background:FlxSprite;
	var crosshairH:FlxSprite;
	var crosshairV:FlxSprite;
	var infoText:FlxText;
	var titleText:FlxText;
	var hintText:FlxText;
	var componentLayer:FlxSpriteGroup;
	var currentComponent:Dynamic;
	var currentMode:Int = 0;
	var labels:Array<String> = ['None', 'Protanopia', 'Protanomaly', 'Deuteranopia', 'Deuteranomaly', 'Tritanopia', 'Tritanomaly', 'Achromatopsia', 'Achromatomaly'];
	var labelIndex:Int = 0;
	var switchRef:MaterialSwitch;
	var stepperRef:MaterialNumericStepper;
	var sliderRef:MaterialSlider;
	var buttonRef:MaterialButton;
	var loadingRef:MaterialLoadingIndicator;

	static var MODES:Array<String> = ['Switch', 'Numeric Stepper', 'Slider', 'Choice Button', 'Loading'];

	override function create():Void
	{
		super.create();
		Cursor.show();

		background = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFF6F1F8);
		add(background);

		crosshairH = new FlxSprite(0, FlxG.height / 2).makeGraphic(FlxG.width, 1, 0x336750A4);
		add(crosshairH);
		crosshairV = new FlxSprite(FlxG.width / 2, 0).makeGraphic(1, FlxG.height, 0x336750A4);
		add(crosshairV);

		titleText = new FlxText(24, 20, FlxG.width - 48, '', 28);
		titleText.setFormat(Paths.font('inter.otf'), 28, MD3Theme.onSurface, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		hintText = new FlxText(24, 54, FlxG.width - 48,
			'Q/E changes component. SPACE interacts. ESC returns to MD3TestState. This screen keeps a single component centered so coordinate weirdness has nowhere to hide.', 16);
		hintText.setFormat(Paths.font('inter.otf'), 16, MD3Theme.onSurfaceVariant, LEFT);
		hintText.antialiasing = ClientPrefs.data.antialiasing;
		add(hintText);

		componentLayer = new FlxSpriteGroup();
		add(componentLayer);

		infoText = new FlxText(24, FlxG.height - 180, FlxG.width - 48, '', 16);
		infoText.setFormat(Paths.font('inter.otf'), 16, MD3Theme.primary, LEFT);
		infoText.antialiasing = ClientPrefs.data.antialiasing;
		add(infoText);

		loadMode(0);
	}

	function loadMode(index:Int):Void
	{
		currentMode = (index + MODES.length) % MODES.length;
		componentLayer.clear();
		currentComponent = null;
		switchRef = null;
		stepperRef = null;
		sliderRef = null;
		buttonRef = null;
		loadingRef = null;

		titleText.text = 'MD3 Isolated: ' + MODES[currentMode];

		switch (currentMode)
		{
			case 0:
				switchRef = new MaterialSwitch(FlxG.width / 2 - 26, FlxG.height / 2 - 16, false);
				currentComponent = switchRef;
				componentLayer.add(switchRef);
			case 1:
				stepperRef = new MaterialNumericStepper(FlxG.width / 2 - 95, FlxG.height / 2 - 22, 5, 60, 0, 240, 0, 190, function(value:Float) {});
				currentComponent = stepperRef;
				componentLayer.add(stepperRef);
			case 2:
				sliderRef = new MaterialSlider(FlxG.width / 2 - 180, FlxG.height / 2 - 12, 360, 0.5, 0.0, 1.0);
				currentComponent = sliderRef;
				componentLayer.add(sliderRef);
			case 3:
				buttonRef = new MaterialButton(FlxG.width / 2 - 120, FlxG.height / 2 - 22, labels[labelIndex], OUTLINED, 240, function() {
					cycleLabel();
				});
				currentComponent = buttonRef;
				componentLayer.add(buttonRef);
			case 4:
				loadingRef = new MaterialLoadingIndicator(FlxG.width / 2 - 48, FlxG.height / 2 - 48, 96, true);
				currentComponent = loadingRef;
				componentLayer.add(loadingRef);
		}

		trace('[MD3IsolatedComponentState] loadMode=' + MODES[currentMode]);
		updateInfo();
	}

	function cycleLabel():Void
	{
		labelIndex = (labelIndex + 1) % labels.length;
		if (buttonRef != null)
		{
			buttonRef.label = labels[labelIndex];
		}
		updateInfo();
	}

	function updateInfo():Void
	{
		var lines:Array<String> = [
			'Mode: ' + MODES[currentMode],
			'Screen center: (' + Std.int(FlxG.width / 2) + ', ' + Std.int(FlxG.height / 2) + ')'
		];

		if (switchRef != null)
			lines.push(switchRef.getDebugLayout());
		if (stepperRef != null)
			lines.push(stepperRef.getDebugLayout());
		if (sliderRef != null)
			lines.push(sliderRef.getDebugLayout());
		if (buttonRef != null)
			lines.push(buttonRef.getDebugLayout());
		if (loadingRef != null)
			lines.push(loadingRef.getDebugLayout());

		infoText.text = lines.join('\n');
	}

	override function update(elapsed:Float):Void
	{
		if (FlxG.keys.justPressed.Q)
			loadMode(currentMode - 1);
		if (FlxG.keys.justPressed.E)
			loadMode(currentMode + 1);

		if (FlxG.keys.justPressed.SPACE)
		{
			if (switchRef != null) switchRef.toggle();
			if (stepperRef != null) stepperRef.value += 5;
			if (sliderRef != null) sliderRef.value = Math.min(1, sliderRef.value + 0.1);
			if (buttonRef != null) cycleLabel();
		}

		if (FlxG.keys.justPressed.BACKSPACE && stepperRef != null)
			stepperRef.value -= 5;
		if (FlxG.keys.justPressed.BACKSPACE && sliderRef != null)
			sliderRef.value = Math.max(0, sliderRef.value - 0.1);

		if (FlxG.keys.justPressed.ESCAPE)
			MusicBeatState.switchState(new MD3TestState());

		updateInfo();
		super.update(elapsed);
	}
}