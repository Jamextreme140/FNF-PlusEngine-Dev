package funkin.ui.options;

import StringTools;

import Main;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
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
		DiscordClient.changePresence('Graphics Settings Menu', null);
		#end

		OptionsMenuTheme.syncAccent();

		buildChrome();
		buildCards();
		changeSelection(lastSelected, true);
		refreshCardPositions(true);
		applyAntialiasingVisuals();

		#if mobile
		touchScroll = new funkin.mobile.backend.TouchScroll(true);
		funkin.mobile.backend.TouchUtil.setScrollHandler(touchScroll);
		#end
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

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, Language.getPhrase('graphics_menu', 'Graphics Settings'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			Language.getPhrase('graphics_menu_subtitle', 'Rendering, framerate, fullscreen and accessibility controls now live in actual cards instead of a vertical wall of text.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, Language.getPhrase('close', 'Close'), TEXT, 110, closeAndSave);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 330, panelY + 66, 290,
			Language.getPhrase('graphics_menu_status', '{1} • {2}x{3}', [Main.platform, FlxG.width, FlxG.height]), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			Language.getPhrase('graphics_menu_footer', 'ARROWS move. LEFT/RIGHT adjust. ENTER toggles or opens. R resets the selected option. ESC returns.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), CENTER);
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
			Language.getPhrase('setting_Low Quality', 'Low Quality'),
			Language.getPhrase('description_Low Quality', 'Disables some background details to reduce cost and loading times.'),
			columnWidth,
			ClientPrefs.data.lowQuality,
			ClientPrefs.defaultData.lowQuality,
			function(value:Bool) {
				ClientPrefs.data.lowQuality = value;
				saveSetting('Low Quality ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			Language.getPhrase('setting_Anti-Aliasing', 'Anti-Aliasing'),
			Language.getPhrase('description_Anti-Aliasing', 'Smooths sprite edges. Turning it off improves performance, but everything looks extra crunchy.'),
			columnWidth,
			ClientPrefs.data.antialiasing,
			ClientPrefs.defaultData.antialiasing,
			function(value:Bool) {
				ClientPrefs.data.antialiasing = value;
				applyAntialiasingVisuals();
				saveSetting('Anti-Aliasing ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			Language.getPhrase('setting_Shaders', 'Shaders'),
			Language.getPhrase('description_Shaders', "Toggles shader-based effects. Pretty? Yes. Cheap? Not always, especially on weaker " + Main.platform + "."),
			columnWidth,
			ClientPrefs.data.shaders,
			ClientPrefs.defaultData.shaders,
			function(value:Bool) {
				ClientPrefs.data.shaders = value;
				saveSetting('Shaders ' + boolLabel(value));
			}), cardX, cardY);

		#if !html5
		cardY = addCard(new GraphicsSwitchCard(
			Language.getPhrase('setting_VSync', 'VSync'),
			Language.getPhrase('description_VSync', 'Reduces tearing and aligns frame pacing to the display refresh rate. Some systems may need a restart.'),
			columnWidth,
			ClientPrefs.data.vsync,
			ClientPrefs.defaultData.vsync,
			function(value:Bool) {
				ClientPrefs.data.vsync = value;
				saveSetting('VSync ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsFramerateCard(
			Language.getPhrase('setting_Framerate', 'Framerate'),
			Language.getPhrase('description_Framerate', "Adjust the FPS cap used by the engine. Yes, this is the setting everybody pokes first."),
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
			Language.getPhrase('setting_Color Accessibility', 'Color Accessibility'),
			Language.getPhrase('description_Color Accessibility', 'Choose a color blindness filter if you need better separation or clearer note colors.'),
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
			Language.getPhrase('setting_GPU Caching', 'GPU Caching'),
			Language.getPhrase('description_GPU Caching', "Lets the GPU cache textures to reduce RAM use. Avoid it if your graphics card throws tantrums."),
			columnWidth,
			ClientPrefs.data.cacheOnGPU,
			ClientPrefs.defaultData.cacheOnGPU,
			function(value:Bool) {
				ClientPrefs.data.cacheOnGPU = value;
				saveSetting('GPU Caching ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			Language.getPhrase('setting_FPS Rework', 'Fixed Timestep'),
			Language.getPhrase('description_FPS Rework', 'Uses a fixed update step for steadier gameplay timing when rendering drops below the cap.'),
			columnWidth,
			ClientPrefs.data.fpsRework,
			ClientPrefs.defaultData.fpsRework,
			function(value:Bool) {
				ClientPrefs.data.fpsRework = value;
				applyFramerate();
				saveSetting('Fixed Timestep ' + boolLabel(value));
			}), cardX, cardY);

		cardY = addCard(new GraphicsSwitchCard(
			Language.getPhrase('setting_FPS Counter', 'FPS Counter'),
			Language.getPhrase('description_FPS Counter', 'Shows or hides the FPS counter in the corner.'),
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
			Language.getPhrase('setting_Fullscreen Mode', 'Fullscreen Mode'),
			Language.getPhrase('description_Fullscreen Mode', 'Choose how fullscreen behaves: borderless, borderless fix or exclusive fullscreen.'),
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
			Language.getPhrase('setting_Auto-Optimization Tier', 'Auto-Optimization Tier'),
			Language.getPhrase('description_Auto-Optimization Tier', 'Auto-detects device strength or forces a lower or higher optimization tier manually.'),
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
		announce(card.titleText.text + Language.getPhrase('graphics_menu_opened_suffix', ' menu opened'), false);
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

		#if mobile
		if (touchScroll != null)
		{
			var scrollDelta = touchScroll.update();
			if (activeDropdown == null && Math.abs(scrollDelta) > 0.5)
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

	#if mobile
	function handleTouchInput():Void
	{
		var tapPos = touchScroll.getTapPosition();
		if (tapPos == null) return;

		if (activeDropdown != null)
		{
			if (activeDropdown.containsPoint(tapPos.x, tapPos.y))
			{
				var itemIndex = activeDropdown.getItemIndexAt(tapPos.x, tapPos.y);
				if (itemIndex != -1)
					activeDropdown.selectIndex(itemIndex);
			}
			else
				closeActiveDropdown();
			return;
		}

		if (isPointInsideRect(tapPos.x, tapPos.y, closeButton.x, closeButton.y, closeButton.width, closeButton.height))
		{
			closeAndSave();
			return;
		}

		for (index in 0...cards.length)
		{
			var card = cards[index];
			if (card != null && card.containsPoint(tapPos.x, tapPos.y))
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
		titleText.setFormat(Paths.font('inter-bold.otf'), 18, OptionsMenuTheme.cardTitleColor(false), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		descriptionText = new FlxText(30, 34, width - 60, description, 12);
		descriptionText.setFormat(Paths.font('inter.otf'), 12, OptionsMenuTheme.cardDescriptionColor(false), LEFT);
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

	public function containsPoint(px:Float, py:Float):Bool
	{
		return px >= x && px <= x + cardWidth && py >= y && py <= y + cardHeight;
	}

	public function applyVerticalClip(yMin:Float, yMax:Float):Void
	{
		var topCut:Float = Math.max(0, yMin - y);
		var bottomCut:Float = Math.max(0, (y + cardHeight) - yMax);
		var visibleHeight:Float = cardHeight - topCut - bottomCut;

		if (visibleHeight <= 0)
		{
			visible = false;
			clipRect = null;
			return;
		}

		visible = true;
		if (topCut <= 0 && bottomCut <= 0)
			clipRect = null;
		else
			clipRect = new FlxRect(0, topCut, cardWidth, visibleHeight);
	}

	public function handleLeft():Void {}
	public function handleRight():Void {}
	public function handleAccept():Void {}
	public function resetToDefault():Void {}
	public function handleTouch(screenX:Float, screenY:Float):Bool return false;
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

	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
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

	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
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

	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		var sliderX = x + slider.x;
		var sliderY = y + slider.y - 8;
		if (screenX >= sliderX && screenX <= sliderX + slider.sliderWidth && screenY >= sliderY && screenY <= sliderY + 44)
		{
			var normalized = FlxMath.bound((screenX - sliderX) / slider.sliderWidth, 0, 1);
			var nextValue = minValue + normalized * (maxValue - minValue);
			setValue(Std.int(Math.round(nextValue)));
			return true;
		}

		var stepperX = x + stepper.x;
		var stepperY = y + stepper.y;
		if (screenX >= stepperX && screenX <= stepperX + stepper.stepperWidth && screenY >= stepperY && screenY <= stepperY + 44)
		{
			var localX = screenX - stepperX;
			if (localX <= 42)
				setValue(currentValue - 5);
			else if (localX >= stepper.stepperWidth - 42)
				setValue(currentValue + 5);
			return true;
		}

		handleAccept();
		return true;
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
		MD3ShapeTools.fillRoundRect(background, Std.int(width), menuHeight, 20, OptionsMenuTheme.panelSurfaceColor());
		add(background);

		outline = new FlxSprite();
		outline.antialiasing = ClientPrefs.data.antialiasing;
		MD3ShapeTools.strokeRoundRect(outline, Std.int(width), menuHeight, 20, 2, OptionsMenuTheme.neutralOutlineColor());
		add(outline);

		for (index in 0...items.length)
		{
			var rowY = VERTICAL_PADDING + index * ITEM_HEIGHT;
			var highlight = new FlxSprite(8, rowY);
			highlight.antialiasing = ClientPrefs.data.antialiasing;
			rowHighlights.push(highlight);
			add(highlight);

			var label = new FlxText(18, rowY + 10, width - 36, itemLabel != null ? itemLabel(items[index]) : items[index], 14);
			label.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.optionDescriptionColor(false), LEFT);
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
			var fill = OptionsMenuTheme.interactiveFill(isActive, isHovered);
			var textColor = isActive ? OptionsMenuTheme.titleColor() : OptionsMenuTheme.optionDescriptionColor(false);
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

	public function containsPoint(screenX:Float, screenY:Float):Bool
	{
		return screenX >= x && screenX <= x + background.width && screenY >= y && screenY <= y + background.height;
	}

	public function getItemIndexAt(screenX:Float, screenY:Float):Int
	{
		if (!containsPoint(screenX, screenY))
			return -1;

		var localY = screenY - y - VERTICAL_PADDING;
		if (localY < 0)
			return -1;

		var index = Std.int(localY / ITEM_HEIGHT);
		return index >= 0 && index < items.length ? index : -1;
	}

	public function selectIndex(index:Int):Void
	{
		if (items.length == 0)
			return;

		var clampedIndex = index;
		if (clampedIndex < 0)
			clampedIndex = 0;
		else if (clampedIndex >= items.length)
			clampedIndex = items.length - 1;

		selectedIndex = clampedIndex;
		refreshVisuals();
		confirmSelection();
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