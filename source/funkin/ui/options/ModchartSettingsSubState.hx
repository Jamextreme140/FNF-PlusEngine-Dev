package funkin.ui.options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import funkin.ui.MusicBeatSubstate;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSwitch;

class ModchartSettingsSubState extends MusicBeatSubstate
{
	static var lastSelected:Int = 0;

	var backdrop:FlxSprite;
	var menuBG:FlxSprite;
	var panelShadow:FlxSprite;
	var panelSurface:FlxSprite;
	var panelHeader:FlxSprite;
	var panelOutline:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var footerText:FlxText;
	var statusText:FlxText;
	var closeButton:MaterialButton;

	var cardLayer:FlxTypedGroup<ModchartSettingsCard>;
	var cards:Array<ModchartSettingsCard> = [];
	var cardBaseY:Array<Float> = [];

	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelWidth:Float = 0;
	var panelHeight:Float = 0;
	var contentTop:Float = 0;
	var contentBottom:Float = 0;
	var cardWidth:Float = 0;
	var selectedCard:Int = 0;
	var scrollOffset:Float = 0;
	var scrollTarget:Float = 0;
	var contentHeight:Float = 0;
	#if mobile
	var touchScroll:funkin.mobile.backend.TouchScroll;
	#end

	public function new()
	{
		controls.isInSubstate = true;
		super();
	}

	override function create():Void
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Modchart Settings Menu', null);
		#end

		OptionsMenuTheme.syncAccent();
		buildChrome();
		buildCards();
		changeSelection(lastSelected, true);
		refreshCardPositions(true);

		#if mobile
		touchScroll = new funkin.mobile.backend.TouchScroll(true);
		funkin.mobile.backend.TouchUtil.setScrollHandler(touchScroll);
		#end
	}

	function buildChrome():Void
	{
		var palette = OptionsMenuTheme.current();
		panelWidth = Math.min(1180, FlxG.width - 40);
		panelHeight = Math.min(676, FlxG.height - 28);
		panelX = (FlxG.width - panelWidth) * 0.5;
		panelY = (FlxG.height - panelHeight) * 0.5;
		contentTop = panelY + 126;
		contentBottom = panelY + panelHeight - 52;
		cardWidth = panelWidth - 56;
		Cursor.hide();

		backdrop = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, OptionsMenuTheme.backdropColor());
		add(backdrop);

		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = palette.pale;
		menuBG.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		panelShadow = new FlxSprite(panelX + 10, panelY + 12);
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x26000000);
		add(panelShadow);

		panelSurface = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, OptionsMenuTheme.panelSurfaceColor());
		add(panelSurface);

		panelHeader = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 108, 34, 34, 0, 0, OptionsMenuTheme.panelHeaderColor());
		add(panelHeader);

		panelOutline = new FlxSprite(panelX, panelY);
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, OptionsMenuTheme.panelOutlineColor());
		add(panelOutline);

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, Language.getPhrase('modchart_menu', 'Modchart Settings'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			Language.getPhrase('modchart_menu_subtitle', 'Depth, arrow paths and hold rendering controls for charts that like to bend the engine in public.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, Language.getPhrase('close', 'Close'), TEXT, 110, closeAndSave);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 360, panelY + 66, 320, Language.getPhrase('modchart_menu_status', 'Advanced rendering playground'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			Language.getPhrase('modchart_menu_footer', 'ARROWS move. LEFT/RIGHT adjust. ENTER toggles. R restores the selected option. ESC returns.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		cardLayer = new FlxTypedGroup<ModchartSettingsCard>();
		add(cardLayer);
	}

	function buildCards():Void
	{
		var cardX = panelX + 28;
		var cardY = contentTop;

		cardY = addCard(new ModchartSwitchCard('camera3dEnabled', Language.getPhrase('setting_enable_3d_cameras', 'Enable 3D Cameras'), Language.getPhrase('description_enable_3d_cameras', 'Turns depth transformations on or off for modcharts that use 3D cameras.'), cardWidth, ClientPrefs.data.camera3dEnabled, ClientPrefs.defaultData.camera3dEnabled, function(value:Bool) {
			ClientPrefs.data.camera3dEnabled = value;
			saveSetting('Enable 3D Cameras ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new ModchartSliderCard('zScale', Language.getPhrase('setting_z_axis_depth_scale', 'Z Axis Depth Scale'), Language.getPhrase('description_z_axis_depth_scale', 'Controls how strong the perceived 3D depth becomes. Higher means more dramatic perspective.'), cardWidth, ClientPrefs.data.zScale, ClientPrefs.defaultData.zScale, 0.1, 5.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.zScale = value;
			saveSetting('Z Axis Depth Scale: ' + value);
		}), cardX, cardY);

		cardY = addCard(new ModchartSwitchCard('renderArrowPaths', Language.getPhrase('setting_render_arrow_paths', 'Render Arrow Paths'), Language.getPhrase('description_render_arrow_paths', 'Draws the path trail for notes. Great for debugging, less great for free performance.'), cardWidth, ClientPrefs.data.renderArrowPaths, ClientPrefs.defaultData.renderArrowPaths, function(value:Bool) {
			ClientPrefs.data.renderArrowPaths = value;
			saveSetting('Render Arrow Paths ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new ModchartSwitchCard('styledArrowPaths', Language.getPhrase('setting_styled_arrow_paths', 'Styled Arrow Paths'), Language.getPhrase('description_styled_arrow_paths', 'Applies extra color and transparency styling to note paths when rendering is enabled.'), cardWidth, ClientPrefs.data.styledArrowPaths, ClientPrefs.defaultData.styledArrowPaths, function(value:Bool) {
			ClientPrefs.data.styledArrowPaths = value;
			saveSetting('Styled Arrow Paths ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new ModchartSwitchCard('optimizeHolds', Language.getPhrase('setting_optimize_hold_rendering', 'Optimize Hold Rendering'), Language.getPhrase('description_optimize_hold_rendering', 'Cuts down sustain calculations for better performance, but very fancy modcharts may complain visually.'), cardWidth, ClientPrefs.data.optimizeHolds, ClientPrefs.defaultData.optimizeHolds, function(value:Bool) {
			ClientPrefs.data.optimizeHolds = value;
			saveSetting('Optimize Hold Rendering ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new ModchartSwitchCard('holdsBehindStrum', Language.getPhrase('setting_holds_behind_strums', 'Holds Behind Strums'), Language.getPhrase('description_holds_behind_strums', 'Places sustain notes behind the receptor line instead of over it.'), cardWidth, ClientPrefs.data.holdsBehindStrum, ClientPrefs.defaultData.holdsBehindStrum, function(value:Bool) {
			ClientPrefs.data.holdsBehindStrum = value;
			saveSetting('Holds Behind Strums ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new ModchartSliderCard('holdEndScale', Language.getPhrase('setting_hold_end_scale', 'Hold End Scale'), Language.getPhrase('description_hold_end_scale', 'Scales the sustain tail cap size. Leave it at 1.0 unless your chart is doing geometry crimes.'), cardWidth, ClientPrefs.data.holdEndScale, ClientPrefs.defaultData.holdEndScale, 0.1, 3.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.holdEndScale = value;
			saveSetting('Hold End Scale: ' + value);
		}), cardX, cardY);

		cardY = addCard(new ModchartSwitchCard('columnSpecificModifiers', Language.getPhrase('setting_column_specific_modifiers', 'Column Specific Modifiers'), Language.getPhrase('description_column_specific_modifiers', 'Allows modifiers to target specific lanes instead of applying globally. Stronger effect, higher cost.'), cardWidth, ClientPrefs.data.columnSpecificModifiers, ClientPrefs.defaultData.columnSpecificModifiers, function(value:Bool) {
			ClientPrefs.data.columnSpecificModifiers = value;
			saveSetting('Column Specific Modifiers ' + boolLabel(value));
		}), cardX, cardY);

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function addCard(card:ModchartSettingsCard, x:Float, y:Float):Float
	{
		card.x = x;
		card.y = y;
		cardLayer.add(card);
		cards.push(card);
		cardBaseY.push(y);
		return y + card.cardHeight + 10;
	}

	function boolLabel(value:Bool):String
	{
		return value ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
	}

	function saveSetting(message:String, playSound:Bool = true):Void
	{
		ClientPrefs.saveSettings();
		announce(message, playSound);
	}

	function announce(message:String, playSound:Bool = true):Void
	{
		statusText.text = message;
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.55);
	}

	function getMinScroll():Float
	{
		return Math.min(0, (contentBottom - contentTop) - contentHeight);
	}

	function keepSelectionVisible():Void
	{
		if (cards.length == 0) return;
		var padding = 8.0;
		var baseY = cardBaseY[selectedCard] + scrollTarget;
		var cardBottom = baseY + cards[selectedCard].cardHeight;
		var topLimit = contentTop + padding;
		var bottomLimit = contentBottom - padding;

		if (baseY < topLimit)
			scrollTarget += topLimit - baseY;
		else if (cardBottom > bottomLimit)
			scrollTarget -= cardBottom - bottomLimit;

		scrollTarget = FlxMath.bound(scrollTarget, getMinScroll(), 0);
	}

	function refreshCardPositions(instant:Bool = false):Void
	{
		var clipTop = contentTop;
		var clipBottom = contentBottom;
		scrollOffset = instant ? scrollTarget : FlxMath.lerp(scrollTarget, scrollOffset, Math.exp(-0.18));
		for (index in 0...cards.length)
		{
			var card = cards[index];
			card.y = cardBaseY[index] + scrollOffset;
			card.applyVerticalClip(clipTop, clipBottom);
		}
	}

	function changeSelection(targetIndex:Int, instant:Bool = false):Void
	{
		if (cards.length == 0) return;
		selectedCard = FlxMath.wrap(targetIndex, 0, cards.length - 1);
		lastSelected = selectedCard;
		keepSelectionVisible();
		for (index in 0...cards.length)
			cards[index].setSelected(index == selectedCard, instant);
		statusText.text = cards[selectedCard].titleText.text;
	}

	function moveSelection(change:Int):Void
	{
		changeSelection(selectedCard + change);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
	}

	function closeAndSave():Void
	{
		ClientPrefs.saveSettings();
		FlxG.sound.play(Paths.sound('cancelMenu'));
		close();
	}

	override function update(elapsed:Float):Void
	{
		refreshCardPositions();
		super.update(elapsed);

		#if mobile
		if (touchScroll != null)
		{
			var scrollDelta = touchScroll.update();
			if (Math.abs(scrollDelta) > 0.5)
			{
				scrollTarget += scrollDelta / 5;
				scrollTarget = FlxMath.bound(scrollTarget, getMinScroll(), 0);
			}

			if (touchScroll.wasTapped())
				handleTouchInput();
		}
		#end

		if (controls.BACK)
		{
			closeAndSave();
			return;
		}

		if (controls.UI_UP_P) moveSelection(-1);
		if (controls.UI_DOWN_P) moveSelection(1);
		if (controls.UI_LEFT_P) cards[selectedCard].handleLeft();
		if (controls.UI_RIGHT_P) cards[selectedCard].handleRight();
		if (controls.ACCEPT) cards[selectedCard].handleAccept();
		if (controls.RESET) cards[selectedCard].resetToDefault();
	}

	#if mobile
	function handleTouchInput():Void
	{
		var tapPos = touchScroll.getTapPosition();
		if (tapPos == null) return;

		if (isPointInsideRect(tapPos.x, tapPos.y, closeButton.x, closeButton.y, closeButton.width, closeButton.height))
		{
			closeAndSave();
			return;
		}

		for (index in 0...cards.length)
		{
			var card = cards[index];
			if (card != null && isPointInsideRect(tapPos.x, tapPos.y, card.x, card.y, card.cardWidth, card.cardHeight))
			{
				if (index != selectedCard)
					changeSelection(index, true);
				else
					card.handleTouch(tapPos.x, tapPos.y);
				return;
			}
		}
	}

	inline function isPointInsideRect(x:Float, y:Float, rectX:Float, rectY:Float, rectW:Float, rectH:Float):Bool
	{
		return x >= rectX && x <= rectX + rectW && y >= rectY && y <= rectY + rectH;
	}
	#end

	override function destroy():Void
	{
		#if mobile
		if (touchScroll != null)
		{
			touchScroll.destroy();
			touchScroll = null;
		}
		funkin.mobile.backend.TouchUtil.clearScrollHandler();
		#end

		super.destroy();
	}
}

private class ModchartSettingsCard extends FlxSpriteGroup
{
	public var settingId(default, null):String;
	public var cardWidth(default, null):Float;
	public var cardHeight(default, null):Float;
	public var titleText(default, null):FlxText;
	public var descriptionText(default, null):FlxText;

	var background:FlxSprite;
	var outline:FlxSprite;
	var accentBar:FlxSprite;
	var descriptionValue:String;
	var selected:Bool = false;

	public function new(settingId:String, title:String, description:String, width:Float)
	{
		super();
		this.settingId = settingId;
		descriptionValue = description;
		cardWidth = width;
		cardHeight = 84;

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		outline = new FlxSprite();
		outline.antialiasing = ClientPrefs.data.antialiasing;
		add(outline);

		accentBar = new FlxSprite(16, 16);
		accentBar.antialiasing = ClientPrefs.data.antialiasing;
		add(accentBar);

		titleText = new FlxText(30, 12, width - 60, title, 18);
		titleText.setFormat(Paths.font('inter-bold.otf'), 18, OptionsMenuTheme.cardTitleColor(false), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		descriptionText = new FlxText(30, 36, width - 60, description, 12);
		descriptionText.setFormat(Paths.font('inter.otf'), 12, OptionsMenuTheme.cardDescriptionColor(false), LEFT);
		descriptionText.antialiasing = ClientPrefs.data.antialiasing;
		add(descriptionText);

		reflowDescription(width - 60);
		fitHeight(86);
	}

	function reflowDescription(width:Float):Void
	{
		descriptionText.fieldWidth = width;
		descriptionText.text = descriptionValue;
	}

	function fitHeight(minHeight:Float, ?extraBottom:Float = 18):Void
	{
		cardHeight = Math.max(minHeight, descriptionText.y + descriptionText.height + extraBottom);
		redraw();
	}

	function redraw():Void
	{
		var fill = OptionsMenuTheme.cardFill(selected);
		var stroke = OptionsMenuTheme.cardStroke(selected);
		var accent = OptionsMenuTheme.cardAccent(selected);
		MD3ShapeTools.fillRoundRect(background, Std.int(cardWidth), Std.int(cardHeight), 24, fill);
		MD3ShapeTools.strokeRoundRect(outline, Std.int(cardWidth), Std.int(cardHeight), 24, 2, stroke);
		MD3ShapeTools.fillRoundRect(accentBar, 6, Std.int(Math.max(18, cardHeight - 32)), 4, accent);
		titleText.color = OptionsMenuTheme.cardTitleColor(selected);
		descriptionText.color = OptionsMenuTheme.cardDescriptionColor(selected);
	}

	public function setSelected(value:Bool, instant:Bool = false):Void
	{
		selected = value;
		redraw();
		alpha = value ? 1.0 : 0.92;
		scale.set(1, 1);
		updateHitbox();
		offset.set(0, 0);
	}

	public function handleLeft():Void {}
	public function handleRight():Void {}
	public function handleAccept():Void {}
	public function resetToDefault():Void {}
	public function handleTouch(screenX:Float, screenY:Float):Bool return false;

	public function applyVerticalClip(yMin:Float, yMax:Float):Void
	{
		var topCut = Math.max(0, yMin - y);
		var bottomCut = Math.max(0, (y + cardHeight) - yMax);
		var visibleHeight = cardHeight - topCut - bottomCut;

		if (visibleHeight <= 0)
		{
			visible = false;
			clipRect = null;
			return;
		}

		visible = true;
		clipRect = (topCut <= 0 && bottomCut <= 0) ? null : new FlxRect(0, topCut, cardWidth, visibleHeight);
	}
}

private class ModchartSwitchCard extends ModchartSettingsCard
{
	var toggle:MaterialSwitch;
	var valueText:FlxText;
	var currentValue:Bool;
	var defaultValue:Bool;
	var onApply:Bool->Void;

	public function new(settingId:String, title:String, description:String, width:Float, currentValue:Bool, defaultValue:Bool, onApply:Bool->Void)
	{
		super(settingId, title, description, width);
		this.defaultValue = defaultValue;
		this.onApply = onApply;

		titleText.fieldWidth = width - 220;
		reflowDescription(width - 220);

		valueText = new FlxText(width - 210, 16, 110, '', 13);
		valueText.setFormat(Paths.font('inter-bold.otf'), 13, OptionsMenuTheme.current().accent, RIGHT);
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		add(valueText);

		toggle = new MaterialSwitch(width - 82, 20, currentValue);
		toggle.allowMouseInput = false;
		toggle.onChange = function(value:Bool) setValue(value);
		add(toggle);

		fitHeight(84, 16);
		valueText.y = Math.max(16, (cardHeight - valueText.height) * 0.5 - 1);
		toggle.y = (cardHeight - 32) * 0.5;
		setValue(currentValue, false);
	}

	function setValue(value:Bool, fireApply:Bool = true):Void
	{
		currentValue = value;
		toggle.checked = value;
		valueText.text = value ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
		if (fireApply && onApply != null) onApply(value);
	}

	override public function setSelected(value:Bool, instant:Bool = false):Void
	{
		valueText.color = OptionsMenuTheme.current().accent;
		super.setSelected(value, instant);
	}

	override public function handleLeft():Void setValue(false);
	override public function handleRight():Void setValue(true);
	override public function handleAccept():Void setValue(!currentValue);
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
	}
	override public function resetToDefault():Void setValue(defaultValue);
}

private class ModchartSliderCard extends ModchartSettingsCard
{
	var slider:MaterialSlider;
	var stepper:MaterialNumericStepper;
	var currentValue:Float;
	var defaultValue:Float;
	var minValue:Float;
	var maxValue:Float;
	var stepValue:Float;
	var decimals:Int;
	var syncLock:Bool = false;
	var onApply:Float->Void;

	public function new(settingId:String, title:String, description:String, width:Float, currentValue:Float, defaultValue:Float, minValue:Float, maxValue:Float, stepValue:Float, decimals:Int, onApply:Float->Void)
	{
		super(settingId, title, description, width);
		this.defaultValue = defaultValue;
		this.minValue = minValue;
		this.maxValue = maxValue;
		this.stepValue = stepValue;
		this.decimals = decimals;
		this.onApply = onApply;

		titleText.fieldWidth = width - 32;
		reflowDescription(width - 44);

		var controlsY = descriptionText.y + descriptionText.height + 18;
		slider = new MaterialSlider(50, controlsY + 10, width - 380, currentValue, minValue, maxValue);
		slider.allowMouseInput = false;
		slider.onChange = function(value:Float) setValue(value, true);
		add(slider);

		stepper = new MaterialNumericStepper(width - 192, controlsY + 2, stepValue, currentValue, minValue, maxValue, decimals, 168, function(value:Float) {
			setValue(value, true);
		});
		stepper.allowMouseInput = false;
		add(stepper);

		fitHeight(controlsY + 62, 18);
		setValue(currentValue, false);
	}

	function setValue(value:Float, fireApply:Bool = true):Void
	{
		var factor = Math.pow(10, decimals);
		value = FlxMath.bound(value, minValue, maxValue);
		value = Math.round(value * factor) / factor;
		currentValue = value;
		if (!syncLock)
		{
			syncLock = true;
			slider.value = value;
			stepper.value = value;
			syncLock = false;
		}
		if (fireApply && onApply != null) onApply(value);
	}

	override public function handleLeft():Void setValue(currentValue - stepValue);
	override public function handleRight():Void setValue(currentValue + stepValue);
	override public function handleAccept():Void setValue(currentValue + stepValue > maxValue ? minValue : currentValue + stepValue);
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		var sliderX = x + slider.x;
		var sliderY = y + slider.y - 8;
		if (screenX >= sliderX && screenX <= sliderX + slider.sliderWidth && screenY >= sliderY && screenY <= sliderY + 44)
		{
			var normalized = FlxMath.bound((screenX - sliderX) / slider.sliderWidth, 0, 1);
			setValue(minValue + normalized * (maxValue - minValue));
			return true;
		}

		var stepperX = x + stepper.x;
		var stepperY = y + stepper.y;
		if (screenX >= stepperX && screenX <= stepperX + stepper.stepperWidth && screenY >= stepperY && screenY <= stepperY + 44)
		{
			var localX = screenX - stepperX;
			if (localX <= 42)
				setValue(currentValue - stepValue);
			else if (localX >= stepper.stepperWidth - 42)
				setValue(currentValue + stepValue);
			return true;
		}

		handleAccept();
		return true;
	}
	override public function resetToDefault():Void setValue(defaultValue);
}
