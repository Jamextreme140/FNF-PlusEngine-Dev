package funkin.ui.options;

import StringTools;

import Main;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.graphics.shaders.ColorblindFilter;
import funkin.ui.MusicBeatSubstate;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSwitch;

class GraphicsSettingsSubState extends MusicBeatSubstate
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

	var cardLayer:FlxTypedGroup<GraphicsSettingsCard>;
	var overlayLayer:FlxSpriteGroup;
	var cards:Array<GraphicsSettingsCard> = [];
	var activeDropdown:GraphicsDropdownMenu;

	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelWidth:Float = 0;
	var panelHeight:Float = 0;
	var contentTop:Float = 0;
	var contentBottom:Float = 0;
	var columnWidth:Float = 0;
	var selectedCard:Int = 0;
	var scrollOffset:Float = 0;
	var scrollTarget:Float = 0;
	var contentHeight:Float = 0;
	var cardBaseY:Array<Float> = [];

	public function new()
	{
		controls.isInSubstate = true;
		super();
	}

	override function create():Void
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Graphics Settings Menu', null);
		#end

		OptionsMenuTheme.syncAccent();

		buildChrome();
		buildCards();
		changeSelection(lastSelected, true);
		refreshCardPositions(true);
		applyAntialiasingVisuals();
	}

	function buildChrome():Void
	{
		var palette = OptionsMenuTheme.current();
		panelWidth = Math.min(1180, FlxG.width - 40);
		panelHeight = Math.min(664, FlxG.height - 32);
		panelX = (FlxG.width - panelWidth) * 0.5;
		panelY = (FlxG.height - panelHeight) * 0.5;
		contentTop = panelY + 126;
		contentBottom = panelY + panelHeight - 52;
		columnWidth = panelWidth - 56;
		Cursor.hide();

		backdrop = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xD2141020);
		add(backdrop);

		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = palette.pale;
		menuBG.alpha = 0.14;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		panelShadow = new FlxSprite(panelX + 10, panelY + 12);
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x26000000);
		add(panelShadow);

		panelSurface = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, 0xFFF8F4FC);
		add(panelSurface);

		panelHeader = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 108, 34, 34, 0, 0, 0xFFFFFBFF);
		add(panelHeader);

		panelOutline = new FlxSprite(panelX, panelY);
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, 0x24FFFFFF);
		add(panelOutline);

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, Language.getPhrase('graphics_menu', 'Graphics Settings'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, palette.strong, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			phrase('graphics_menu_subtitle', 'Rendering, framerate, fullscreen and accessibility controls now live in actual cards instead of a vertical wall of text.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, palette.muted, LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, phrase('close', 'Close'), TEXT, 110, closeAndSave);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 330, panelY + 66, 290,
			Language.getPhrase('graphics_menu_status', '{1} • {2}x{3}', [Main.platform, FlxG.width, FlxG.height]), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, palette.muted, RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			phrase('graphics_menu_footer', 'ARROWS move. LEFT/RIGHT adjust. ENTER toggles or opens. R resets the selected option. ESC returns.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, 0xFF6D5F82, CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		cardLayer = new FlxTypedGroup<GraphicsSettingsCard>();
		add(cardLayer);

		overlayLayer = new FlxSpriteGroup();
		add(overlayLayer);
	}

	function buildCards():Void
	{
		var cardY:Float = contentTop;
		var cardX:Float = panelX + 28;
		var currentRefreshRate:Int = FlxG.stage.application.window.displayMode.refreshRate;
		var minFramerate:Int = #if mobile 30 #else 60 #end;
		var framerateDefault:Int = Std.int(FlxMath.bound(currentRefreshRate, minFramerate, 240));

		cardY = addCard(new GraphicsSwitchCard(
			phraseSetting('Low Quality', 'Low Quality'),
			phraseDescription('Low Quality', 'Disables some background details to reduce cost and loading times.'),
			columnWidth,
			ClientPrefs.data.lowQuality,
			ClientPrefs.defaultData.lowQuality,
			function(value:Bool) {
				ClientPrefs.data.lowQuality = value;
				saveSetting('Low Quality ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			phraseSetting('Anti-Aliasing', 'Anti-Aliasing'),
			phraseDescription('Anti-Aliasing', 'Smooths sprite edges. Turning it off improves performance, but everything looks extra crunchy.'),
			columnWidth,
			ClientPrefs.data.antialiasing,
			ClientPrefs.defaultData.antialiasing,
			function(value:Bool) {
				ClientPrefs.data.antialiasing = value;
				applyAntialiasingVisuals();
				saveSetting('Anti-Aliasing ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			phraseSetting('Shaders', 'Shaders'),
			phraseDescription('Shaders', "Toggles shader-based effects. Pretty? Yes. Cheap? Not always, especially on weaker " + Main.platform + "."),
			columnWidth,
			ClientPrefs.data.shaders,
			ClientPrefs.defaultData.shaders,
			function(value:Bool) {
				ClientPrefs.data.shaders = value;
				saveSetting('Shaders ' + boolLabel(value));
			}), cardX, cardY);

		#if !html5
		cardY = addCard(new GraphicsSwitchCard(
			phraseSetting('VSync', 'VSync'),
			phraseDescription('VSync', 'Reduces tearing and aligns frame pacing to the display refresh rate. Some systems may need a restart.'),
			columnWidth,
			ClientPrefs.data.vsync,
			ClientPrefs.defaultData.vsync,
			function(value:Bool) {
				ClientPrefs.data.vsync = value;
				saveSetting('VSync ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsFramerateCard(
			phraseSetting('Framerate', 'Framerate'),
			phraseDescription('Framerate', "Adjust the FPS cap used by the engine. Yes, this is the setting everybody pokes first."),
			columnWidth,
			ClientPrefs.data.framerate,
			framerateDefault,
			minFramerate,
			240,
			function(value:Int, playSound:Bool) {
				ClientPrefs.data.framerate = value;
				applyFramerate();
				saveSetting('Framerate: ' + value + ' FPS', playSound);
			}), cardX, cardY);
		#end

		cardY = addCard(new GraphicsChoiceCard(
			phraseSetting('Color Accessibility', 'Color Accessibility'),
			phraseDescription('Color Accessibility', 'Choose a color blindness filter if you need better separation or clearer note colors.'),
			columnWidth,
			['None', 'Protanopia', 'Protanomaly', 'Deuteranopia', 'Deuteranomaly', 'Tritanopia', 'Tritanomaly', 'Achromatopsia', 'Achromatomaly'],
			ClientPrefs.data.colorblindMode,
			ClientPrefs.defaultData.colorblindMode,
			openChoiceMenu,
			function(value:String) {
				ClientPrefs.data.colorblindMode = value;
				ClientPrefs.saveSettings();
				ColorblindFilter.UpdateColors();
				announce('Color Accessibility: ' + value);
			}, 'Color Accessibility'), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			phraseSetting('GPU Caching', 'GPU Caching'),
			phraseDescription('GPU Caching', "Lets the GPU cache textures to reduce RAM use. Avoid it if your graphics card throws tantrums."),
			columnWidth,
			ClientPrefs.data.cacheOnGPU,
			ClientPrefs.defaultData.cacheOnGPU,
			function(value:Bool) {
				ClientPrefs.data.cacheOnGPU = value;
				saveSetting('GPU Caching ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			phraseSetting('FPS Rework', 'FPS Rework'),
			phraseDescription('FPS Rework', 'Uses the alternate frame pacing path so the game does not feel slow when FPS drops below the cap.'),
			columnWidth,
			ClientPrefs.data.fpsRework,
			ClientPrefs.defaultData.fpsRework,
			function(value:Bool) {
				ClientPrefs.data.fpsRework = value;
				applyFramerate();
				saveSetting('FPS Rework ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			phraseSetting('FPS Counter', 'FPS Counter'),
			phraseDescription('FPS Counter', 'Shows or hides the FPS counter in the corner.'),
			columnWidth,
			ClientPrefs.data.showFPS,
			ClientPrefs.defaultData.showFPS,
			function(value:Bool) {
				ClientPrefs.data.showFPS = value;
				applyFPSCounter();
				saveSetting('FPS Counter ' + boolLabel(value));
			}), cardX, cardY);

		#if windows
		cardY = addCard(new GraphicsChoiceCard(
			phraseSetting('Fullscreen Mode', 'Fullscreen Mode'),
			phraseDescription('Fullscreen Mode', 'Choose how fullscreen behaves: borderless, borderless fix or exclusive fullscreen.'),
			columnWidth,
			['Borderless', 'Borderless Fix', 'Exclusive'],
			ClientPrefs.data.fullscreenMode,
			ClientPrefs.defaultData.fullscreenMode,
			openChoiceMenu,
			function(value:String) {
				ClientPrefs.data.fullscreenMode = value;
				saveSetting('Fullscreen Mode: ' + value);
			}, 'Fullscreen Mode'), cardX, cardY);
		#end

		#if android
		var tierChoices = ['Auto (Recommended)', 'Force Low-End', 'Force Mid-Range', 'Force High-End'];
		cardY = addCard(new GraphicsChoiceCard(
			phraseSetting('Auto-Optimization Tier', 'Auto-Optimization Tier'),
			phraseDescription('Auto-Optimization Tier', 'Auto-detects device strength or forces a lower or higher optimization tier manually.'),
			columnWidth,
			tierChoices,
			tierChoices[0],
			tierChoices[0],
			openChoiceMenu,
			function(value:String) {
				switch (value)
				{
					case 'Force Low-End': funkin.mobile.AndroidOptimizer.forceOptimizationTier(0);
					case 'Force Mid-Range': funkin.mobile.AndroidOptimizer.forceOptimizationTier(1);
					case 'Force High-End': funkin.mobile.AndroidOptimizer.forceOptimizationTier(2);
					default: funkin.mobile.AndroidOptimizer.init();
				}
				announce('Optimization Tier: ' + value);
			}, 'Auto-Optimization Tier'), cardX, cardY);
		#end

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function addCard(card:GraphicsSettingsCard, x:Float, y:Float):Float
	{
		card.x = x;
		card.y = y;
		cardLayer.add(card);
		cards.push(card);
		cardBaseY.push(y);
		return y + card.cardHeight + 10;
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
		scrollOffset = instant ? scrollTarget : FlxMath.lerp(scrollTarget, scrollOffset, Math.exp(-0.18));

		for (index in 0...cards.length)
		{
			var card = cards[index];
			card.y = cardBaseY[index] + scrollOffset;
			card.visible = card.y + card.cardHeight >= contentTop - 12 && card.y <= contentBottom + 12;
		}
	}

	function phraseSetting(key:String, fallback:String):String
	{
		return Language.getPhrase('setting_' + key, fallback);
	}

	function phrase(key:String, fallback:String):String
	{
		return Language.getPhrase(key, fallback);
	}

	function phraseDescription(key:String, fallback:String):String
	{
		return Language.getPhrase('description_' + key, fallback);
	}

	function boolLabel(value:Bool):String
	{
		return value ? phrase('enabled', 'Enabled') : phrase('disabled', 'Disabled');
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

	function applyFramerate():Void
	{
		if (ClientPrefs.data.fpsRework)
			FlxG.stage.window.frameRate = ClientPrefs.data.framerate;
		else if (ClientPrefs.data.framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = ClientPrefs.data.framerate;
			FlxG.drawFramerate = ClientPrefs.data.framerate;
		}
		else
		{
			FlxG.drawFramerate = ClientPrefs.data.framerate;
			FlxG.updateFramerate = ClientPrefs.data.framerate;
		}
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
			cast(target, FlxSprite).antialiasing = ClientPrefs.data.antialiasing;

		if (Reflect.hasField(target, 'members'))
		{
			var members:Array<Dynamic> = Reflect.field(target, 'members');
			if (members != null)
			{
				for (member in members)
					applyAntialiasingRecursive(member);
			}
		}
	}

	function openChoiceMenu(card:GraphicsChoiceCard):Void
	{
		closeActiveDropdown();

		var menuY = card.getAnchorY() + 52;
		var menuHeight = GraphicsDropdownMenu.getTotalHeight(card.options.length);
		var panelBottom = contentBottom;
		var panelTop = contentTop;
		if (menuY + menuHeight > panelBottom)
			menuY = card.getAnchorY() - menuHeight - 10;
		if (menuY < panelTop)
			menuY = panelTop;

		activeDropdown = new GraphicsDropdownMenu(
			card.getAnchorX(),
			menuY,
			card.getAnchorWidth(),
			overlayLayer,
			card.options,
			card.currentValue,
			function(value:String) {
				card.setValueLabel(value);
			},
			function() {
				activeDropdown = null;
			}, card.getOptionLabel);
		overlayLayer.add(activeDropdown);
		announce(card.titleText.text + phrase('graphics_menu_opened_suffix', ' menu opened'), false);
	}

	function closeActiveDropdown():Void
	{
		if (activeDropdown != null)
			activeDropdown.closeMenu();
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

		if (controls.BACK)
		{
			if (activeDropdown != null)
			{
				closeActiveDropdown();
				return;
			}
			closeAndSave();
			return;
		}

		if (activeDropdown != null)
		{
			if (controls.UI_UP_P) activeDropdown.moveSelection(-1);
			if (controls.UI_DOWN_P) activeDropdown.moveSelection(1);
			if (controls.ACCEPT) activeDropdown.confirmSelection();
			return;
		}

		if (controls.UI_UP_P) moveSelection(-1);
		if (controls.UI_DOWN_P) moveSelection(1);

		if (controls.UI_LEFT_P) cards[selectedCard].handleLeft();
		if (controls.UI_RIGHT_P) cards[selectedCard].handleRight();
		if (controls.ACCEPT) cards[selectedCard].handleAccept();
		if (controls.RESET) cards[selectedCard].resetToDefault();
	}
}

private class GraphicsSettingsCard extends FlxSpriteGroup
{
	public var cardWidth(default, null):Float;
	public var cardHeight(default, null):Float;
	public var titleText(default, null):FlxText;
	public var descriptionText(default, null):FlxText;

	var background:FlxSprite;
	var outline:FlxSprite;
	var accentBar:FlxSprite;
	var descriptionValue:String;
	var selected:Bool = false;

	public function new(title:String, description:String, width:Float, height:Float = 72)
	{
		super();

		cardWidth = width;
		cardHeight = height;
		descriptionValue = description;

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		outline = new FlxSprite();
		outline.antialiasing = ClientPrefs.data.antialiasing;
		add(outline);

		accentBar = new FlxSprite(16, 16);
		accentBar.antialiasing = ClientPrefs.data.antialiasing;
		add(accentBar);

		titleText = new FlxText(30, 11, width - 60, title, 18);
		titleText.setFormat(Paths.font('inter-bold.otf'), 18, 0xFF2C1E48, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		descriptionText = new FlxText(30, 34, width - 60, description, 12);
		descriptionText.setFormat(Paths.font('inter.otf'), 12, 0xFF76678B, LEFT);
		descriptionText.antialiasing = ClientPrefs.data.antialiasing;
		add(descriptionText);

		reflowDescription(width - 60);
		fitHeight(height);
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
		var palette = OptionsMenuTheme.current();
		var fill = selected ? palette.mist : 0xFFFCF8FF;
		var stroke = selected ? palette.accent : 0xFFDCCEEB;
		var accent = selected ? palette.accent : palette.pale;
		MD3ShapeTools.fillRoundRect(background, Std.int(cardWidth), Std.int(cardHeight), 24, fill);
		MD3ShapeTools.strokeRoundRect(outline, Std.int(cardWidth), Std.int(cardHeight), 24, 2, stroke);
		MD3ShapeTools.fillRoundRect(accentBar, 6, Std.int(Math.max(18, cardHeight - 32)), 4, accent);
		titleText.color = selected ? palette.strong : 0xFF402D61;
		descriptionText.color = selected ? palette.muted : 0xFF7B6D93;
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

	public function containsPoint(px:Float, py:Float):Bool
	{
		return px >= x && px <= x + cardWidth && py >= y && py <= y + cardHeight;
	}

	public function handleLeft():Void {}
	public function handleRight():Void {}
	public function handleAccept():Void {}
	public function resetToDefault():Void {}
}

private class GraphicsSwitchCard extends GraphicsSettingsCard
{
	var toggle:MaterialSwitch;
	var valueText:FlxText;
	var currentValue:Bool;
	var defaultValue:Bool;
	var onApply:Bool->Void;

	public function new(title:String, description:String, width:Float, currentValue:Bool, defaultValue:Bool, onApply:Bool->Void)
	{
		super(title, description, width, 72);

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
		toggle.onChange = function(value:Bool) {
			setValue(value);
		};
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
		valueText.text = value ? 'Enabled' : 'Disabled';
		if (fireApply && onApply != null)
			onApply(value);
	}

	override public function handleLeft():Void
	{
		setValue(false);
	}

	override public function handleRight():Void
	{
		setValue(true);
	}

	override public function handleAccept():Void
	{
		setValue(!currentValue);
	}

	override public function resetToDefault():Void
	{
		setValue(defaultValue);
	}
}

private class GraphicsChoiceCard extends GraphicsSettingsCard
{
	public var options(default, null):Array<String>;
	public var currentValue(default, null):String;

	var defaultValue:String;
	var selectorButton:MaterialButton;
	var requestDropdown:GraphicsChoiceCard->Void;
	var onApply:String->Void;
	var optionTranslationKey:String;

	public function new(title:String, description:String, width:Float, options:Array<String>, currentValue:String, defaultValue:String,
		requestDropdown:GraphicsChoiceCard->Void, onApply:String->Void, ?optionTranslationKey:String)
	{
		super(title, description, width, 72);

		this.options = options;
		this.defaultValue = defaultValue;
		this.requestDropdown = requestDropdown;
		this.onApply = onApply;
		this.optionTranslationKey = optionTranslationKey;

		titleText.fieldWidth = width - 250;
		reflowDescription(width - 250);

		selectorButton = new MaterialButton(width - 214, 14, '', OUTLINED, 184, function() {
			if (requestDropdown != null)
				requestDropdown(this);
		});
		selectorButton.allowMouseInput = false;
		add(selectorButton);

		fitHeight(84, 16);
		selectorButton.y = (cardHeight - 44) * 0.5;

		setValueLabel(currentValue, false);
	}

	function cycle(direction:Int):Void
	{
		var index = options.indexOf(currentValue);
		if (index < 0) index = 0;
		index = FlxMath.wrap(index + direction, 0, options.length - 1);
		setValueLabel(options[index]);
	}

	function shorten(value:String):String
	{
		return value.length > 17 ? value.substr(0, 16) + '…' : value;
	}

	function normalizeOptionKey(value:String):String
	{
		var key = value.toLowerCase();
		key = StringTools.replace(key, ' ', '_');
		key = StringTools.replace(key, '(', '');
		key = StringTools.replace(key, ')', '');
		key = StringTools.replace(key, ':', '');
		key = StringTools.replace(key, '/', '_');
		key = StringTools.replace(key, '&', 'and');
		key = StringTools.replace(key, '.', '');
		key = StringTools.replace(key, '!', '');
		key = StringTools.replace(key, ',', '');
		key = StringTools.replace(key, '-', '_');
		while (key.indexOf('__') != -1)
			key = StringTools.replace(key, '__', '_');
		return key;
	}

	public function getOptionLabel(value:String):String
	{
		if (optionTranslationKey == null || optionTranslationKey.length == 0)
			return value;
		return Language.getPhrase('setting_' + optionTranslationKey + '-' + normalizeOptionKey(value), value);
	}

	public function setValueLabel(value:String, fireApply:Bool = true):Void
	{
		currentValue = value;
		selectorButton.label = shorten(getOptionLabel(value));
		if (fireApply && onApply != null)
			onApply(value);
	}

	public function getAnchorX():Float
	{
		return x + selectorButton.x;
	}

	public function getAnchorY():Float
	{
		return y + selectorButton.y;
	}

	public function getAnchorWidth():Float
	{
		return selectorButton.buttonWidth;
	}

	override public function handleLeft():Void
	{
		cycle(-1);
	}

	override public function handleRight():Void
	{
		cycle(1);
	}

	override public function handleAccept():Void
	{
		if (requestDropdown != null)
			requestDropdown(this);
	}

	override public function resetToDefault():Void
	{
		setValueLabel(defaultValue);
	}
}

private class GraphicsFramerateCard extends GraphicsSettingsCard
{
	var slider:MaterialSlider;
	var stepper:MaterialNumericStepper;
	var currentValue:Int;
	var defaultValue:Int;
	var minValue:Int;
	var maxValue:Int;
	var syncLock:Bool = false;
	var onApply:Int->Bool->Void;

	public function new(title:String, description:String, width:Float, currentValue:Int, defaultValue:Int, minValue:Int, maxValue:Int,
		onApply:Int->Bool->Void)
	{
		super(title, description, width, 102);

		this.defaultValue = defaultValue;
		this.minValue = minValue;
		this.maxValue = maxValue;
		this.onApply = onApply;

		titleText.fieldWidth = width - 32;
		reflowDescription(width - 44);
		var controlsY = descriptionText.y + descriptionText.height + 18;

		slider = new MaterialSlider(22, controlsY + 10, width - 234, currentValue, minValue, maxValue);
		slider.allowMouseInput = false;
		slider.onChange = function(value:Float) {
			setValue(Std.int(Math.round(value)), true, false);
		};
		add(slider);

		stepper = new MaterialNumericStepper(width - 192, controlsY + 2, 5, currentValue, minValue, maxValue, 0, 168, function(value:Float) {
			setValue(Std.int(value));
		});
		stepper.allowMouseInput = false;
		add(stepper);

		fitHeight(controlsY + 62, 18);

		setValue(currentValue, false, false);
	}

	function setValue(value:Int, fireApply:Bool = true, playSound:Bool = true):Void
	{
		value = Std.int(FlxMath.bound(value, minValue, maxValue));
		currentValue = value;

		if (!syncLock)
		{
			syncLock = true;
			slider.value = value;
			stepper.value = value;
			syncLock = false;
		}

		if (fireApply && onApply != null)
			onApply(value, playSound);
	}

	override public function handleLeft():Void
	{
		setValue(currentValue - 5);
	}

	override public function handleRight():Void
	{
		setValue(currentValue + 5);
	}

	override public function handleAccept():Void
	{
		setValue(currentValue + 5 > maxValue ? minValue : currentValue + 5);
	}

	override public function resetToDefault():Void
	{
		setValue(defaultValue);
	}
}

private class GraphicsDropdownMenu extends FlxSpriteGroup
{
	static inline var ITEM_HEIGHT:Int = 40;
	static inline var VERTICAL_PADDING:Int = 8;

	var items:Array<String>;
	var hoverIndex:Int = -1;
	var selectedIndex:Int = 0;
	var hostLayer:FlxSpriteGroup;
	var onSelect:String->Void;
	var onClosed:Void->Void;
	var itemLabel:String->String;
	var background:FlxSprite;
	var outline:FlxSprite;
	var rowHighlights:Array<FlxSprite> = [];
	var rowLabels:Array<FlxText> = [];

	public function new(x:Float, y:Float, width:Float, hostLayer:FlxSpriteGroup, items:Array<String>, currentValue:String, onSelect:String->Void, onClosed:Void->Void,
		?itemLabel:String->String)
	{
		super(x, y);

		this.hostLayer = hostLayer;
		this.items = items;
		this.onSelect = onSelect;
		this.onClosed = onClosed;
		this.itemLabel = itemLabel;
		selectedIndex = items.indexOf(currentValue);
		if (selectedIndex < 0) selectedIndex = 0;

		var menuHeight = getTotalHeight(items.length);

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.fillRoundRect(background, Std.int(width), menuHeight, 20, 0xFFF8F4FC);
		add(background);

		outline = new FlxSprite();
		outline.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.strokeRoundRect(outline, Std.int(width), menuHeight, 20, 2, 0xFFD9C9F1);
		add(outline);

		for (index in 0...items.length)
		{
			var rowY = VERTICAL_PADDING + index * ITEM_HEIGHT;
			var highlight = new FlxSprite(8, rowY);
			highlight.antialiasing = ClientPrefs.data.antialiasing;
			rowHighlights.push(highlight);
			add(highlight);

			var label = new FlxText(18, rowY + 10, width - 36, itemLabel != null ? itemLabel(items[index]) : items[index], 14);
			label.setFormat(Paths.font('inter.otf'), 14, 0xFF3E2C5F, LEFT);
			label.antialiasing = ClientPrefs.data.antialiasing;
			rowLabels.push(label);
			add(label);
		}

		refreshVisuals();
	}

	public static function getTotalHeight(itemCount:Int):Int
	{
		return VERTICAL_PADDING * 2 + itemCount * ITEM_HEIGHT;
	}

	function refreshVisuals():Void
	{
		for (index in 0...rowHighlights.length)
		{
			var isActive = index == selectedIndex;
			var isHovered = index == hoverIndex;
			var fill = isActive ? 0xFFE9DEFF : (isHovered ? 0xFFF3EBFF : 0x00000000);
			var textColor = isActive ? 0xFF2E1A4F : 0xFF4A3967;
			MD3ShapeTools.fillRoundRect(rowHighlights[index], Std.int(background.width) - 16, ITEM_HEIGHT - 4, 14, fill);
			rowLabels[index].color = textColor;
		}
	}

	public function moveSelection(change:Int):Void
	{
		selectedIndex = FlxMath.wrap(selectedIndex + change, 0, items.length - 1);
		refreshVisuals();
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
	}

	public function confirmSelection():Void
	{
		if (onSelect != null)
			onSelect(items[selectedIndex]);
		closeMenu();
	}

	public function closeMenu():Void
	{
		if (hostLayer != null)
			hostLayer.remove(this, true);
		if (onClosed != null)
			onClosed();
		kill();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}