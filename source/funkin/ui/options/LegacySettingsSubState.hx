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
import funkin.ui.components.md3.MaterialSwitch;

class LegacySettingsSubState extends MusicBeatSubstate
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

	var cardLayer:FlxTypedGroup<LegacySettingsCard>;
	var cards:Array<LegacySettingsCard> = [];
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
		DiscordClient.changePresence('Legacy Settings Menu', null);
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

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, Language.getPhrase('legacy_menu', 'Legacy Settings'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			Language.getPhrase('legacy_menu_subtitle', 'Compatibility toggles for older Psych-era mods, shader quirks and a few nostalgia switches that still pay rent.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, Language.getPhrase('close', 'Close'), TEXT, 110, closeAndSave);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 360, panelY + 66, 320, Language.getPhrase('legacy_menu_status', 'Compatibility layer armed'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			Language.getPhrase('legacy_menu_footer', 'ARROWS move. LEFT/RIGHT change. ENTER toggles. R restores the selected option. ESC returns.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		cardLayer = new FlxTypedGroup<LegacySettingsCard>();
		add(cardLayer);
	}

	function buildCards():Void
	{
		var cardX = panelX + 28;
		var cardY = contentTop;

		cardY = addCard(new LegacySwitchCard('legacyMemoryManagement', phraseSetting('legacy_memory_management', 'Legacy Memory Management'), phraseDescription('legacy_memory_management', 'Uses Psych 0.7.3-style cleanup and avoids GPU texture disposal. Handy for ancient mods with fragile memory expectations.'), cardWidth, ClientPrefs.data.legacyMemoryManagement, ClientPrefs.defaultData.legacyMemoryManagement, function(value:Bool) {
			ClientPrefs.data.legacyMemoryManagement = value;
			saveSetting('Legacy Memory Management ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('legacyFileSystemAccess', phraseSetting('legacy_filesystem_access', 'Legacy FileSystem Access'), phraseDescription('legacy_filesystem_access', 'Restores direct FileSystem.readDirectory access for mods that assume old filesystem behavior.'), cardWidth, ClientPrefs.data.legacyFileSystemAccess, ClientPrefs.defaultData.legacyFileSystemAccess, function(value:Bool) {
			ClientPrefs.data.legacyFileSystemAccess = value;
			saveSetting('Legacy FileSystem Access ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('useLegacyFont', phraseSetting('use_legacy_font', 'Use Legacy Font'), phraseDescription('use_legacy_font', 'Switches the engine back to the classic VCR look instead of the newer font stack.'), cardWidth, ClientPrefs.data.useLegacyFont, ClientPrefs.defaultData.useLegacyFont, function(value:Bool) {
			ClientPrefs.data.useLegacyFont = value;
			saveSetting('Use Legacy Font ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('legacyShaderInit', phraseSetting('legacy_shader_init', 'Legacy Shader Init'), phraseDescription('legacy_shader_init', 'Uses the older shader bootstrap path for mods that were written before the safer modern wrapper existed.'), cardWidth, ClientPrefs.data.legacyShaderInit, ClientPrefs.defaultData.legacyShaderInit, function(value:Bool) {
			ClientPrefs.data.legacyShaderInit = value;
			saveSetting('Legacy Shader Init ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('useWavyTimeBar', phraseSetting('use_wavy_time_bar', 'Use Wavy Time Bar'), phraseDescription('use_wavy_time_bar', 'Uses the new wavy time bar in gameplay and loading screens. Leave this off if you want the classic engine bars instead.'), cardWidth, ClientPrefs.data.useWavyTimeBar, ClientPrefs.defaultData.useWavyTimeBar, function(value:Bool) {
			ClientPrefs.data.useWavyTimeBar = value;
			saveSetting('Use Wavy Time Bar ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('vanillaTransition', phraseSetting('vanilla_transition', 'Vanilla Transition'), phraseDescription('vanilla_transition', 'Brings back the classic transition flow instead of the custom Plus Engine wipe.'), cardWidth, ClientPrefs.data.vanillaTransition, ClientPrefs.defaultData.vanillaTransition, function(value:Bool) {
			ClientPrefs.data.vanillaTransition = value;
			saveSetting('Vanilla Transition ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('usePsychScoreText', phraseSetting('use_psych_score_text', 'Use Psych Score Text'), phraseDescription('use_psych_score_text', 'Keeps the original Psych HUD score formatting during gameplay.'), cardWidth, ClientPrefs.data.usePsychScoreText, ClientPrefs.defaultData.usePsychScoreText, function(value:Bool) {
			ClientPrefs.data.usePsychScoreText = value;
			saveSetting('Use Psych Score Text ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('newfreeplay', phraseSetting('use_new_freeplay', 'Use New Freeplay'), phraseDescription('use_new_freeplay', 'Disabling this sends you back to the classic Psych freeplay screen. Retro tourism, but optional.'), cardWidth, ClientPrefs.data.newfreeplay, ClientPrefs.defaultData.newfreeplay, function(value:Bool) {
			ClientPrefs.data.newfreeplay = value;
			saveSetting('Use New Freeplay ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new LegacySwitchCard('autoConvertChartsToV2', phraseSetting('auto_convert_charts_to_v2', 'Auto Convert Charts to V2'), phraseDescription('auto_convert_charts_to_v2', 'Automatically rewrites legacy psych_v1 charts into psych_v2 on load. Good for archival work, risky if you enjoy pristine fossils.'), cardWidth, ClientPrefs.data.autoConvertChartsToV2, ClientPrefs.defaultData.autoConvertChartsToV2, function(value:Bool) {
			ClientPrefs.data.autoConvertChartsToV2 = value;
			saveSetting('Auto Convert Charts to V2 ' + boolLabel(value));
		}), cardX, cardY);

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function addCard(card:LegacySettingsCard, x:Float, y:Float):Float
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
					card.handleAccept();
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

private class LegacySettingsCard extends FlxSpriteGroup
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
		titleText.setFormat(Paths.font('inter-bold.otf'), 18, 0xFF2C1E48, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		descriptionText = new FlxText(30, 36, width - 60, description, 12);
		descriptionText.setFormat(Paths.font('inter.otf'), 12, 0xFF76678B, LEFT);
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

private class LegacySwitchCard extends LegacySettingsCard
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
	override public function resetToDefault():Void setValue(defaultValue);
}

