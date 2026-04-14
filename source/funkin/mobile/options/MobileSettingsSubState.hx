package funkin.mobile.options;

import StringTools;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import funkin.mobile.backend.MobileData;
import funkin.mobile.backend.MobileScaleMode;
import funkin.ui.MusicBeatSubstate;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSwitch;
import funkin.ui.options.OptionsMenuTheme;

class MobileSettingsSubState extends MusicBeatSubstate
{
	static var lastSelected:Int = 0;

	final exControlTypes:Array<String> = ['NONE', 'SINGLE', 'DOUBLE'];
	final hintOptions:Array<String> = ['No Gradient', 'No Gradient (Old)', 'Gradient', 'Hidden'];

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

	var cardLayer:FlxTypedGroup<MobileSettingsCard>;
	var overlayLayer:FlxSpriteGroup;
	var cards:Array<MobileSettingsCard> = [];
	var activeDropdown:MobileSettingsDropdownMenu;
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
		DiscordClient.changePresence('Mobile Settings Menu', null);
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

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, Language.getPhrase('mobile_menu', 'Mobile Settings'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			Language.getPhrase('mobile_menu_subtitle', 'Touch controls, hitboxes, wide-screen behaviour and a few Android niceties without the old options wall.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, Language.getPhrase('close', 'Close'), TEXT, 110, closeAndSave);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 360, panelY + 66, 320, Language.getPhrase('mobile_menu_status', 'Touch-friendly tuning area'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			Language.getPhrase('mobile_menu_footer', 'ARROWS move. LEFT/RIGHT adjust. ENTER toggles or opens. R resets the selected option. ESC returns.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		cardLayer = new FlxTypedGroup<MobileSettingsCard>();
		add(cardLayer);

		overlayLayer = new FlxSpriteGroup();
		add(overlayLayer);
	}

	function buildCards():Void
	{
		var cardX = panelX + 28;
		var cardY = contentTop;

		#if android
		var tierName = funkin.mobile.AndroidOptimizer.getTierName();
		var gpuName = funkin.util.Native.detectGPU();
		var tierInfo = 'Detected: ' + tierName + ' | GPU: ' + gpuName + '\nQuality settings were auto-configured. You can still override graphics manually.\nStorage is scoped to Android/data.';
		cardY = addCard(new MobileInfoCard('deviceInfo', Language.getPhrase('mobile_device_info', 'Device Performance Info'), tierInfo, cardWidth), cardX, cardY);
		#end

		cardY = addCard(new MobileChoiceCard('extraButtons', phraseSetting('extra_controls', 'Extra Controls'), phraseDescription('extra_controls', 'Choose how many extra mobile buttons you want available for mod mechanics.'), cardWidth, exControlTypes, ClientPrefs.data.extraButtons, ClientPrefs.defaultData.extraButtons, openChoiceMenu, function(value:String) {
			ClientPrefs.data.extraButtons = value;
			saveSetting('Extra Controls: ' + value);
		}, 'extra_controls'), cardX, cardY);

		cardY = addCard(new MobileSliderCard('controlsAlpha', phraseSetting('mobile_controls_opacity', 'Mobile Controls Opacity'), phraseDescription('mobile_controls_opacity', 'Adjust button opacity without making them vanish into the void.'), cardWidth, ClientPrefs.data.controlsAlpha, ClientPrefs.defaultData.controlsAlpha, 0.001, 1.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.controlsAlpha = value;
			if (touchPad != null) touchPad.alpha = value;
			ClientPrefs.toggleVolumeKeys();
			saveSetting('Mobile Controls Opacity: ' + percentLabel(value));
		}), cardX, cardY);

		#if mobile
		cardY = addCard(new MobileSwitchCard('screensaver', phraseSetting('allow_phone_screensaver', 'Allow Phone Screensaver'), phraseDescription('allow_phone_screensaver', 'Lets the device sleep after inactivity according to the phone settings.'), cardWidth, ClientPrefs.data.screensaver, ClientPrefs.defaultData.screensaver, function(value:Bool) {
			ClientPrefs.data.screensaver = value;
			lime.system.System.allowScreenTimeout = value;
			saveSetting('Allow Phone Screensaver ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new MobileSwitchCard('infinityDisplay', phraseSetting('infinity_display', 'Infinity Display'), phraseDescription('infinity_display', 'Expands the visible play area on wider phone ratios while keeping old 1280x720 mods sane.'), cardWidth, ClientPrefs.data.infinityDisplay, ClientPrefs.defaultData.infinityDisplay, function(value:Bool) {
			ClientPrefs.data.infinityDisplay = value;
			FlxG.scaleMode = new MobileScaleMode();
			saveSetting('Infinity Display ' + boolLabel(value));
		}), cardX, cardY);
		#end

		if (MobileData.mode == 3)
		{
			cardY = addCard(new MobileChoiceCard('hitboxType', phraseSetting('hitbox_design', 'Hitbox Design'), phraseDescription('hitbox_design', 'Choose how the hitbox visuals should look on touch controls.'), cardWidth, hintOptions, ClientPrefs.data.hitboxType, ClientPrefs.defaultData.hitboxType, openChoiceMenu, function(value:String) {
				ClientPrefs.data.hitboxType = value;
				saveSetting('Hitbox Design: ' + value);
			}, 'hitbox_design'), cardX, cardY);

			cardY = addCard(new MobileSwitchCard('hitboxPos', phraseSetting('hitbox_position', 'Hitbox Position'), phraseDescription('hitbox_position', 'Places the hitbox at the bottom when enabled, otherwise it stays up top.'), cardWidth, ClientPrefs.data.hitboxPos, ClientPrefs.defaultData.hitboxPos, function(value:Bool) {
				ClientPrefs.data.hitboxPos = value;
				saveSetting('Hitbox Position ' + boolLabel(value));
			}), cardX, cardY);
		}

		cardY = addCard(new MobileSwitchCard('dynamicColors', phraseSetting('dynamic_controls_color', 'Dynamic Controls Color'), phraseDescription('dynamic_controls_color', 'Makes the mobile controls follow your note colors during gameplay.'), cardWidth, ClientPrefs.data.dynamicColors, ClientPrefs.defaultData.dynamicColors, function(value:Bool) {
			ClientPrefs.data.dynamicColors = value;
			saveSetting('Dynamic Controls Color ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new MobileSwitchCard('showMobileDebugButtons', phraseSetting('show_debug_buttons', 'Show Debug Buttons'), phraseDescription('show_debug_buttons', 'Displays the Trace and Debug buttons in the top-right corner.'), cardWidth, ClientPrefs.data.showMobileDebugButtons, ClientPrefs.defaultData.showMobileDebugButtons, function(value:Bool) {
			ClientPrefs.data.showMobileDebugButtons = value;
			onChangeMobileDebugButtons();
			saveSetting('Show Debug Buttons ' + boolLabel(value));
		}), cardX, cardY);

		#if android
		cardY = addCard(new MobileButtonCard('openDataFolder', Language.getPhrase('mobile_open_data_folder', 'Open Data Folder'), Language.getPhrase('mobile_open_data_folder_desc', 'Opens Android/data/com.leninasto.plusengine/files/ in the system file explorer.'), cardWidth, Language.getPhrase('open', 'Open'), function() {
			openDataFolder();
			announce(Language.getPhrase('mobile_opening_data_folder', 'Opening data folder...'), false);
		}), cardX, cardY);
		#end

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function addCard(card:MobileSettingsCard, x:Float, y:Float):Float
	{
		card.x = x;
		card.y = y;
		cardLayer.add(card);
		cards.push(card);
		cardBaseY.push(y);
		return y + card.cardHeight + 10;
	}

	function phraseSetting(key:String, fallback:String):String
	{
		return Language.getPhrase('setting_' + key, fallback);
	}

	function phraseDescription(key:String, fallback:String):String
	{
		return Language.getPhrase('description_' + key, fallback);
	}

	function boolLabel(value:Bool):String
	{
		return value ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
	}

	function percentLabel(value:Float):String
	{
		return Std.string(Std.int(Math.round(value * 100))) + '%';
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
		if (baseY < topLimit) scrollTarget += topLimit - baseY;
		else if (cardBottom > bottomLimit) scrollTarget -= cardBottom - bottomLimit;
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

	function openChoiceMenu(card:MobileChoiceCard):Void
	{
		closeActiveDropdown();
		var menuY = card.getAnchorY() + 52;
		var menuHeight = MobileSettingsDropdownMenu.getTotalHeight(card.options.length);
		if (menuY + menuHeight > contentBottom) menuY = card.getAnchorY() - menuHeight - 10;
		if (menuY < contentTop) menuY = contentTop;
		activeDropdown = new MobileSettingsDropdownMenu(card.getAnchorX(), menuY, card.getAnchorWidth(), overlayLayer, card.options, card.currentValue, function(value:String) {
			card.setValueLabel(value);
		}, function() {
			activeDropdown = null;
		}, card.getOptionLabel);
		overlayLayer.add(activeDropdown);
		announce(card.titleText.text + Language.getPhrase('mobile_menu_opened_suffix', ' menu opened'), false);
	}

	function closeActiveDropdown():Void
	{
		if (activeDropdown != null) activeDropdown.closeMenu();
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
			var dropdownIndex = activeDropdown.getItemIndexAt(tapPos.x, tapPos.y);
			if (dropdownIndex > -1)
			{
				activeDropdown.selectIndex(dropdownIndex);
				activeDropdown.confirmSelection();
			}
			else if (!activeDropdown.containsPoint(tapPos.x, tapPos.y))
			{
				closeActiveDropdown();
			}
			return;
		}

		if (isPointOverButton(closeButton, tapPos.x, tapPos.y))
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

	inline function isPointOverButton(button:MaterialButton, x:Float, y:Float):Bool
	{
		return button != null && isPointInsideRect(x, y, button.x, button.y, button.width, button.height);
	}

	inline function isPointInsideRect(x:Float, y:Float, rectX:Float, rectY:Float, rectW:Float, rectH:Float):Bool
	{
		return x >= rectX && x <= rectX + rectW && y >= rectY && y <= rectY + rectH;
	}
	#end

	function onChangeMobileDebugButtons():Void
	{
		#if mobile
		if (Main.traceButton != null)
			Main.traceButton.visible = ClientPrefs.data.showMobileDebugButtons;
		if (Main.debugButton != null)
			Main.debugButton.visible = ClientPrefs.data.showMobileDebugButtons;
		#end
	}

	#if android
	function openDataFolder():Void
	{
		try
		{
			funkin.external.android.DataFolderUtil.openDataFolder();
		}
		catch (e:Dynamic)
		{
			trace('[MobileSettings] Error opening data folder: ' + e);
			CoolUtil.showPopUp('Could not open data folder.\nError: ' + e, Language.getPhrase('mobile_error', 'Error!'));
		}
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

private class MobileSettingsCard extends FlxSpriteGroup
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

private class MobileInfoCard extends MobileSettingsCard
{
	public function new(settingId:String, title:String, description:String, width:Float)
	{
		super(settingId, title, description, width);
		fitHeight(110, 18);
	}
}

private class MobileSwitchCard extends MobileSettingsCard
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

private class MobileChoiceCard extends MobileSettingsCard
{
	public var options(default, null):Array<String>;
	public var currentValue(default, null):String;

	var defaultValue:String;
	var selectorButton:MaterialButton;
	var requestDropdown:MobileChoiceCard->Void;
	var onApply:String->Void;
	var optionTranslationKey:String;

	public function new(settingId:String, title:String, description:String, width:Float, options:Array<String>, currentValue:String, defaultValue:String, requestDropdown:MobileChoiceCard->Void, onApply:String->Void, ?optionTranslationKey:String)
	{
		super(settingId, title, description, width);
		this.options = options;
		this.defaultValue = defaultValue;
		this.requestDropdown = requestDropdown;
		this.onApply = onApply;
		this.optionTranslationKey = optionTranslationKey;

		titleText.fieldWidth = width - 250;
		reflowDescription(width - 250);

		selectorButton = new MaterialButton(width - 214, 14, '', OUTLINED, 184, function() {
			if (requestDropdown != null) requestDropdown(this);
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
		if (fireApply && onApply != null) onApply(value);
	}

	public function getAnchorX():Float return x + selectorButton.x;
	public function getAnchorY():Float return y + selectorButton.y;
	public function getAnchorWidth():Float return selectorButton.buttonWidth;
	override public function handleLeft():Void cycle(-1);
	override public function handleRight():Void cycle(1);
	override public function handleAccept():Void if (requestDropdown != null) requestDropdown(this);
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
	}
	override public function resetToDefault():Void setValueLabel(defaultValue);
}

private class MobileSliderCard extends MobileSettingsCard
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
		var sliderH = 44.0;
		if (screenX >= sliderX && screenX <= sliderX + slider.sliderWidth && screenY >= sliderY && screenY <= sliderY + sliderH)
		{
			var normalized = FlxMath.bound((screenX - sliderX) / slider.sliderWidth, 0, 1);
			setValue(minValue + normalized * (maxValue - minValue));
			return true;
		}

		var stepperX = x + stepper.x;
		var stepperY = y + stepper.y;
		var stepperH = 44.0;
		if (screenX >= stepperX && screenX <= stepperX + stepper.stepperWidth && screenY >= stepperY && screenY <= stepperY + stepperH)
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

private class MobileButtonCard extends MobileSettingsCard
{
	var actionButton:MaterialButton;
	var onApply:Void->Void;

	public function new(settingId:String, title:String, description:String, width:Float, buttonLabel:String, onApply:Void->Void)
	{
		super(settingId, title, description, width);
		this.onApply = onApply;

		titleText.fieldWidth = width - 250;
		reflowDescription(width - 250);

		actionButton = new MaterialButton(width - 214, 14, buttonLabel, FILLED, 184, function() {
			if (this.onApply != null) this.onApply();
		});
		actionButton.allowMouseInput = false;
		add(actionButton);

		fitHeight(84, 16);
		actionButton.y = (cardHeight - 44) * 0.5;
	}

	override public function handleAccept():Void
	{
		if (onApply != null) onApply();
	}

	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
	}
}

private class MobileSettingsDropdownMenu extends FlxSpriteGroup
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

	public function new(x:Float, y:Float, width:Float, hostLayer:FlxSpriteGroup, items:Array<String>, currentValue:String, onSelect:String->Void, onClosed:Void->Void, ?itemLabel:String->String)
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
		var darkTheme = OptionsMenuTheme.isDark();
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

	public function selectIndex(index:Int):Void
	{
		selectedIndex = index;
		if (selectedIndex < 0)
			selectedIndex = 0;
		else if (selectedIndex > items.length - 1)
			selectedIndex = items.length - 1;
		refreshVisuals();
	}

	public function confirmSelection():Void
	{
		if (onSelect != null) onSelect(items[selectedIndex]);
		closeMenu();
	}

	public function containsPoint(screenX:Float, screenY:Float):Bool
	{
		return screenX >= x && screenX <= x + background.width && screenY >= y && screenY <= y + background.height;
	}

	public function getItemIndexAt(screenX:Float, screenY:Float):Int
	{
		if (!containsPoint(screenX, screenY)) return -1;

		var localY = screenY - y - VERTICAL_PADDING;
		if (localY < 0) return -1;
		var row = Std.int(localY / ITEM_HEIGHT);
		return row >= 0 && row < items.length ? row : -1;
	}

	public function closeMenu():Void
	{
		if (hostLayer != null) hostLayer.remove(this, true);
		if (onClosed != null) onClosed();
		kill();
	}
}
