package funkin.ui.options;

import StringTools;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSwitch;
import funkin.ui.options.Option.OptionType;

class GameplayChangersSubstate extends MusicBeatSubstate
{
	private var curSelected:Int = 0;
	private var optionsArray:Array<GameplayOption> = [];
	private var cards:Array<GameplayChangerCard> = [];
	private var cardBaseY:Array<Float> = [];

	private var overlayLayer:FlxSpriteGroup;
	private var backdrop:FlxSprite;
	private var menuBG:FlxSprite;
	private var panelShadow:FlxSprite;
	private var panelSurface:FlxSprite;
	private var panelHeader:FlxSprite;
	private var panelOutline:FlxSprite;
	private var titleText:FlxText;
	private var subtitleText:FlxText;
	private var footerText:FlxText;
	private var statusText:FlxText;
	private var hintText:FlxText;
	private var closeButton:MaterialButton;
	private var resetButton:MaterialButton;
	private var cardLayer:FlxTypedGroup<GameplayChangerCard>;
	private var activeDropdown:GameplayChangerDropdownMenu;

	private var panelX:Float = 0;
	private var panelY:Float = 0;
	private var panelWidth:Float = 0;
	private var panelHeight:Float = 0;
	private var hiddenPanelX:Float = 0;
	private var drawerX:Float = 0;
	private var contentTop:Float = 0;
	private var contentBottom:Float = 0;
	private var cardWidth:Float = 0;
	private var scrollOffset:Float = 0;
	private var scrollTarget:Float = 0;
	private var contentHeight:Float = 0;
	private var isClosing:Bool = false;
	private var allowImmediateClose:Bool = false;

	#if mobile
	var touchScroll:funkin.mobile.backend.TouchScroll;
	#end

	function get_curOption():GameplayOption
		return optionsArray[curSelected];

	private var curOption(get, never):GameplayOption;

	public function new()
	{
		controls.isInSubstate = true;
		super();

		getOptions();
		buildChrome();
		buildCards();
		changeSelection(0, true);
		refreshCardPositions(true);
		animateOpen();

		#if mobile
		touchScroll = new funkin.mobile.backend.TouchScroll(true);
		funkin.mobile.backend.TouchUtil.setScrollHandler(touchScroll);
		#end
	}

	function getOptions():Void
	{
		var scrollType = new GameplayOption('Scroll Type', 'scrolltype', STRING, 'multiplicative', ['multiplicative', 'constant']);
		scrollType.optionTranslationKey = 'scroll_type';
		optionsArray.push(scrollType);

		var scrollSpeed = new GameplayOption('Scroll Speed', 'scrollspeed', FLOAT, 1);
		scrollSpeed.scrollSpeed = 2.0;
		scrollSpeed.minValue = 0.35;
		scrollSpeed.changeValue = 0.05;
		scrollSpeed.decimals = 2;
		applyScrollSpeedMode(scrollType.getValue(), scrollSpeed);
		optionsArray.push(scrollSpeed);

		#if FLX_PITCH
		var playbackRate = new GameplayOption('Playback Rate', 'songspeed', FLOAT, 1);
		playbackRate.scrollSpeed = 1;
		playbackRate.minValue = 0.5;
		playbackRate.maxValue = 3.0;
		playbackRate.changeValue = 0.05;
		playbackRate.displayFormat = '%vX';
		playbackRate.decimals = 2;
		optionsArray.push(playbackRate);
		#end

		var healthGain = new GameplayOption('Health Gain Multiplier', 'healthgain', FLOAT, 1);
		healthGain.scrollSpeed = 2.5;
		healthGain.minValue = 0;
		healthGain.maxValue = 5;
		healthGain.changeValue = 0.1;
		healthGain.displayFormat = '%vX';
		optionsArray.push(healthGain);

		var healthLoss = new GameplayOption('Health Loss Multiplier', 'healthloss', FLOAT, 1);
		healthLoss.scrollSpeed = 2.5;
		healthLoss.minValue = 0.5;
		healthLoss.maxValue = 5;
		healthLoss.changeValue = 0.1;
		healthLoss.displayFormat = '%vX';
		optionsArray.push(healthLoss);

		optionsArray.push(new GameplayOption('Instakill on Miss', 'instakill', BOOL, false));
		optionsArray.push(new GameplayOption('Practice Mode', 'practice', BOOL, false));
		optionsArray.push(new GameplayOption('Perfect Mode', 'perfect', BOOL, false));
		optionsArray.push(new GameplayOption('Opponent Mode', 'opponentplay', BOOL, false));
		optionsArray.push(new GameplayOption('No Drop Penalty', 'nodroppenalty', BOOL, false));
		optionsArray.push(new GameplayOption('Opponent Drain', 'opponentdrain', BOOL, false));
		optionsArray.push(new GameplayOption('Botplay', 'botplay', BOOL, false));

		scrollType.onChange = function()
		{
			applyScrollSpeedMode(scrollType.getValue(), scrollSpeed);
			refreshLinkedCards();
		};
	}

	function applyScrollSpeedMode(mode:String, option:GameplayOption):Void
	{
		if (mode != 'constant')
		{
			option.displayFormat = '%vX';
			option.maxValue = 3;
		}
		else
		{
			option.displayFormat = '%v';
			option.maxValue = 6;
		}

		if (option.getValue() > option.maxValue)
			option.setValue(option.maxValue);
	}

	function buildChrome():Void
	{
		OptionsMenuTheme.syncAccent();
		var palette = OptionsMenuTheme.current();
		panelWidth = Math.min(680, FlxG.width - 36);
		panelHeight = FlxG.height - 28;
		panelX = 18;
		hiddenPanelX = -panelWidth - 28;
		drawerX = hiddenPanelX;
		panelY = 14;
		contentTop = panelY + 138;
		contentBottom = panelY + panelHeight - 56;
		cardWidth = panelWidth - 36;

		backdrop = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, OptionsMenuTheme.backdropColor());
		backdrop.alpha = 0;
		add(backdrop);

		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = palette.pale;
		menuBG.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		panelShadow = new FlxSprite();
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x30000000);
		add(panelShadow);

		panelSurface = new FlxSprite();
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, OptionsMenuTheme.panelSurfaceColor());
		add(panelSurface);

		panelHeader = new FlxSprite();
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 112, 34, 0, 0, 34, OptionsMenuTheme.panelHeaderColor());
		add(panelHeader);

		panelOutline = new FlxSprite();
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, OptionsMenuTheme.panelOutlineColor());
		add(panelOutline);

		titleText = new FlxText(0, 0, panelWidth - 210, Language.getPhrase('gameplay_changers_menu', 'Gameplay Changers'), 30);
		titleText.setFormat(Paths.font('inter-bold.otf'), 30, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(0, 0, panelWidth - 220,
			Language.getPhrase('gameplay_changers_menu_subtitle', 'A left-side drawer for modifiers, because the old text tower had the charisma of a tax form.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(0, 0, Language.getPhrase('close', 'Close'), TEXT, 96, requestClose);
		closeButton.allowMouseInput = false;
		add(closeButton);

		resetButton = new MaterialButton(0, 0, Language.getPhrase('reset', 'Reset'), OUTLINED, 96, resetAllOptions);
		resetButton.allowMouseInput = false;
		add(resetButton);

		statusText = new FlxText(0, 0, panelWidth - 56, Language.getPhrase('gameplay_changers_ready', 'Modifiers ready'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), LEFT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		hintText = new FlxText(0, 0, 260,
			Language.getPhrase('gameplay_changers_hint', 'UP/DOWN select. LEFT/RIGHT adjust. ENTER toggles or opens.'), 13);
		hintText.setFormat(Paths.font('inter.otf'), 13, OptionsMenuTheme.bodyTextColor(), RIGHT);
		hintText.antialiasing = ClientPrefs.data.antialiasing;
		add(hintText);

		footerText = new FlxText(0, 0, panelWidth - 48,
			Language.getPhrase('gameplay_changers_footer', 'R resets everything. ESC goes back. The drawer slides left because drama matters.'), 13);
		footerText.setFormat(Paths.font('inter.otf'), 13, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		cardLayer = new FlxTypedGroup<GameplayChangerCard>();
		add(cardLayer);

		overlayLayer = new FlxSpriteGroup();
		add(overlayLayer);

		applyDrawerLayout();
	}

	function applyDrawerLayout():Void
	{
		panelShadow.x = drawerX + 12;
		panelShadow.y = panelY + 10;
		panelSurface.x = drawerX;
		panelSurface.y = panelY;
		panelHeader.x = drawerX;
		panelHeader.y = panelY;
		panelOutline.x = drawerX;
		panelOutline.y = panelY;
		titleText.x = drawerX + 28;
		titleText.y = panelY + 18;
		subtitleText.x = drawerX + 28;
		subtitleText.y = panelY + 58;
		closeButton.x = drawerX + panelWidth - 128;
		closeButton.y = panelY + 24;
		resetButton.x = drawerX + panelWidth - 236;
		resetButton.y = panelY + 24;
		statusText.x = drawerX + 28;
		statusText.y = panelY + 102;
		hintText.x = drawerX + panelWidth - 292;
		hintText.y = panelY + 86;
		footerText.x = drawerX + 24;
		footerText.y = panelY + panelHeight - 34;
	}

	function buildCards():Void
	{
		cards = [];
		cardBaseY = [];
		var cardY:Float = contentTop;

		for (option in optionsArray)
		{
			var card = createCardForOption(option);
			cardY = addCard(card, 18, cardY);
		}

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function createCardForOption(option:GameplayOption):GameplayChangerCard
	{
		var description = option.getDescription();
		switch (option.type)
		{
			case BOOL:
				return new GameplayChangerSwitchCard(option, description, cardWidth, function(message:String) saveStatus(message));
			case STRING:
				return new GameplayChangerChoiceCard(option, description, cardWidth, openChoiceMenu, function(message:String) saveStatus(message));
			case INT, FLOAT, PERCENT:
				return new GameplayChangerSliderCard(option, description, cardWidth, function(message:String) saveStatus(message));
			default:
				return new GameplayChangerSwitchCard(option, description, cardWidth, function(message:String) saveStatus(message));
		}
	}

	function addCard(card:GameplayChangerCard, x:Float, y:Float):Float
	{
		card.x = drawerX + x;
		card.y = y;
		cardLayer.add(card);
		cards.push(card);
		cardBaseY.push(y);
		return y + card.cardHeight + 10;
	}

	function animateOpen():Void
	{
		FlxTween.tween(backdrop, {alpha: 0.72}, 0.24, {ease: FlxEase.quadOut});
		FlxTween.tween(this, {drawerX: panelX}, 0.32, {ease: FlxEase.quartOut});
	}

	function requestClose():Void
	{
		if (isClosing) return;
		close();
	}

	override function close():Void
	{
		if (allowImmediateClose)
		{
			super.close();
			return;
		}

		if (isClosing) return;
		isClosing = true;
		ClientPrefs.saveSettings();
		controls.isInSubstate = false;
		FlxG.sound.play(Paths.sound('cancelMenu'));
		closeActiveDropdown();
		FlxTween.tween(backdrop, {alpha: 0}, 0.2, {ease: FlxEase.quadIn});
		var self = this;
		FlxTween.tween(this, {drawerX: hiddenPanelX}, 0.24, {
			ease: FlxEase.quartIn,
			onComplete: function(_) {
				self.allowImmediateClose = true;
				self.close();
			}
		});
	}

	function getMinScroll():Float
	{
		return Math.min(0, (contentBottom - contentTop) - contentHeight);
	}

	function keepSelectionVisible():Void
	{
		if (cards.length == 0) return;
		var padding = 8.0;
		var baseY = cardBaseY[curSelected] + scrollTarget;
		var cardBottom = baseY + cards[curSelected].cardHeight;
		var topLimit = contentTop + padding;
		var bottomLimit = contentBottom - padding;
		if (baseY < topLimit) scrollTarget += topLimit - baseY;
		else if (cardBottom > bottomLimit) scrollTarget -= cardBottom - bottomLimit;
		scrollTarget = FlxMath.bound(scrollTarget, getMinScroll(), 0);
	}

	function refreshCardPositions(instant:Bool = false):Void
	{
		applyDrawerLayout();
		var clipTop = contentTop;
		var clipBottom = contentBottom;
		scrollOffset = instant ? scrollTarget : FlxMath.lerp(scrollTarget, scrollOffset, Math.exp(-0.18));
		for (index in 0...cards.length)
		{
			var card = cards[index];
			card.x = drawerX + 18;
			card.y = cardBaseY[index] + scrollOffset;
			card.applyVerticalClip(clipTop, clipBottom);
		}
	}

	function changeSelection(targetIndex:Int, instant:Bool = false):Void
	{
		if (cards.length == 0) return;
		curSelected = FlxMath.wrap(targetIndex, 0, cards.length - 1);
		keepSelectionVisible();
		for (index in 0...cards.length)
			cards[index].setSelected(index == curSelected, instant);
		statusText.text = cards[curSelected].option.name;
	}

	function moveSelection(change:Int):Void
	{
		changeSelection(curSelected + change);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
	}

	function saveStatus(message:String, playSound:Bool = true):Void
	{
		statusText.text = message;
		ClientPrefs.saveSettings();
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.5);
	}

	function resetAllOptions():Void
	{
		for (card in cards)
			card.resetToDefault();
		refreshLinkedCards();
		saveStatus(Language.getPhrase('gameplay_changers_reset_all', 'Gameplay changers reset'));
	}

	function refreshLinkedCards():Void
	{
		for (card in cards)
			card.refreshFromOption();
	}

	function openChoiceMenu(card:GameplayChangerChoiceCard):Void
	{
		closeActiveDropdown();
		var menuY = card.getAnchorY() + 52;
		var menuHeight = GameplayChangerDropdownMenu.getTotalHeight(card.options.length);
		if (menuY + menuHeight > contentBottom) menuY = card.getAnchorY() - menuHeight - 10;
		if (menuY < contentTop) menuY = contentTop;
		activeDropdown = new GameplayChangerDropdownMenu(card.getAnchorX(), menuY, card.getAnchorWidth(), overlayLayer, card.options, card.currentValue, function(value:String) {
			card.setValueLabel(value);
		}, function() {
			activeDropdown = null;
		}, card.getOptionLabel);
		overlayLayer.add(activeDropdown);
		statusText.text = card.option.name + Language.getPhrase('gameplay_changers_opened_suffix', ' menu opened');
	}

	function closeActiveDropdown():Void
	{
		if (activeDropdown != null) activeDropdown.closeMenu();
		activeDropdown = null;
	}

	override function update(elapsed:Float):Void
	{
		refreshCardPositions();
		super.update(elapsed);

		if (isClosing) return;

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
			requestClose();
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
		if (controls.UI_LEFT_P) cards[curSelected].handleLeft();
		if (controls.UI_RIGHT_P) cards[curSelected].handleRight();
		if (controls.ACCEPT) cards[curSelected].handleAccept();
		if (controls.RESET) resetAllOptions();
	}

	#if mobile
	function handleTouchInput():Void
	{
		var tapPos = touchScroll.getTapPosition();
		if (tapPos == null) return;

		if (activeDropdown != null)
		{
			var dropdownIndex = activeDropdown.getTouchItemIndex(tapPos.x, tapPos.y);
			if (dropdownIndex > -1)
			{
				activeDropdown.applyTouchSelection(dropdownIndex);
				activeDropdown.confirmSelection();
			}
			else if (!activeDropdown.containsTouchPoint(tapPos.x, tapPos.y))
			{
				closeActiveDropdown();
			}
			return;
		}

		if (isPointOverButton(closeButton, tapPos.x, tapPos.y))
		{
			requestClose();
			return;
		}

		if (isPointOverButton(resetButton, tapPos.x, tapPos.y))
		{
			resetAllOptions();
			return;
		}

		for (index in 0...cards.length)
		{
			var card = cards[index];
			if (card != null && isPointInsideRect(tapPos.x, tapPos.y, card.x, card.y, card.cardWidth, card.cardHeight))
			{
				if (index != curSelected)
					changeSelection(index);
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

private class GameplayChangerCard extends FlxSpriteGroup
{
	public var option(default, null):GameplayOption;
	public var cardWidth(default, null):Float;
	public var cardHeight(default, null):Float;
	public var titleText(default, null):FlxText;
	public var descriptionText(default, null):FlxText;

	var background:FlxSprite;
	var outline:FlxSprite;
	var accentBar:FlxSprite;
	var descriptionValue:String;
	var selected:Bool = false;
	var announce:String->Void;

	public function new(option:GameplayOption, description:String, width:Float, announce:String->Void)
	{
		super();
		this.option = option;
		this.announce = announce;
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

		titleText = new FlxText(30, 12, width - 60, option.name, 18);
		titleText.setFormat(Paths.font('inter-bold.otf'), 18, OptionsMenuTheme.optionTitleColor(false), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		descriptionText = new FlxText(30, 36, width - 60, description, 12);
		descriptionText.setFormat(Paths.font('inter.otf'), 12, OptionsMenuTheme.optionDescriptionColor(false), LEFT);
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
		var palette = OptionsMenuTheme.current();
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

	public function refreshFromOption():Void {}
	public function handleLeft():Void {}
	public function handleRight():Void {}
	public function handleAccept():Void {}
	public function resetToDefault():Void {}
	public function handleTouch(screenX:Float, screenY:Float):Bool return false;

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

	function announceValue(message:String):Void
	{
		if (announce != null) announce(message);
	}
}

private class GameplayChangerSwitchCard extends GameplayChangerCard
{
	var toggle:MaterialSwitch;
	var valueText:FlxText;

	public function new(option:GameplayOption, description:String, width:Float, announce:String->Void)
	{
		super(option, description, width, announce);
		titleText.fieldWidth = width - 220;
		reflowDescription(width - 220);

		valueText = new FlxText(width - 210, 16, 110, '', 13);
		valueText.setFormat(Paths.font('inter-bold.otf'), 13, OptionsMenuTheme.current().accent, RIGHT);
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		add(valueText);

		toggle = new MaterialSwitch(width - 82, 20, option.getValue());
		toggle.allowMouseInput = false;
		toggle.onChange = function(value:Bool) {
			setValue(value);
		};
		add(toggle);

		fitHeight(84, 16);
		valueText.y = Math.max(16, (cardHeight - valueText.height) * 0.5 - 1);
		toggle.y = (cardHeight - 32) * 0.5;
		refreshFromOption();
	}

	function setValue(value:Bool):Void
	{
		option.setValue(value);
		toggle.checked = value;
		valueText.text = value ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
		option.change();
		announceValue(option.name + ': ' + valueText.text);
	}

	override public function refreshFromOption():Void
	{
		var value:Bool = option.getValue();
		toggle.checked = value;
		valueText.text = value ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
	}

	override public function handleLeft():Void setValue(false);
	override public function handleRight():Void setValue(true);
	override public function handleAccept():Void setValue(!option.getValue());
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
	}
	override public function resetToDefault():Void
	{
		option.setValue(option.defaultValue);
		refreshFromOption();
		option.change();
	}
}

private class GameplayChangerChoiceCard extends GameplayChangerCard
{
	public var options(default, null):Array<String>;
	public var currentValue(default, null):String;

	var selectorButton:MaterialButton;
	var requestDropdown:GameplayChangerChoiceCard->Void;

	public function new(option:GameplayOption, description:String, width:Float, requestDropdown:GameplayChangerChoiceCard->Void, announce:String->Void)
	{
		super(option, description, width, announce);
		this.options = option.options;
		this.requestDropdown = requestDropdown;
		titleText.fieldWidth = width - 250;
		reflowDescription(width - 250);

		selectorButton = new MaterialButton(width - 214, 14, '', OUTLINED, 184, function() {
			if (requestDropdown != null) requestDropdown(this);
		});
		selectorButton.allowMouseInput = false;
		add(selectorButton);

		fitHeight(84, 16);
		selectorButton.y = (cardHeight - 44) * 0.5;
		refreshFromOption();
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
		var translationKey = option.optionTranslationKey;
		if (translationKey == null || translationKey.length == 0)
			return value;
		return Language.getPhrase('setting_' + translationKey + '-' + normalizeOptionKey(value), value);
	}

	public function setValueLabel(value:String):Void
	{
		currentValue = value;
		option.curOption = options.indexOf(value);
		option.setValue(value);
		selectorButton.label = shorten(getOptionLabel(value));
		option.change();
		announceValue(option.name + ': ' + getOptionLabel(value));
	}

	public function getAnchorX():Float return x + selectorButton.x;
	public function getAnchorY():Float return y + selectorButton.y;
	public function getAnchorWidth():Float return selectorButton.buttonWidth;

	override public function refreshFromOption():Void
	{
		currentValue = option.getValue();
		selectorButton.label = shorten(getOptionLabel(currentValue));
	}

	override public function handleLeft():Void cycle(-1);
	override public function handleRight():Void cycle(1);
	override public function handleAccept():Void if (requestDropdown != null) requestDropdown(this);
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
	}
	override public function resetToDefault():Void
	{
		option.setValue(option.defaultValue);
		option.curOption = options.indexOf(option.defaultValue);
		refreshFromOption();
		option.change();
	}
}

private class GameplayChangerSliderCard extends GameplayChangerCard
{
	var slider:MaterialSlider;
	var stepper:MaterialNumericStepper;
	var syncLock:Bool = false;

	public function new(option:GameplayOption, description:String, width:Float, announce:String->Void)
	{
		super(option, description, width, announce);
		titleText.fieldWidth = width - 32;
		reflowDescription(width - 44);
		var controlsY = descriptionText.y + descriptionText.height + 18;
		slider = new MaterialSlider(50, controlsY + 10, width - 380, option.getValue(), option.minValue, option.maxValue);
		slider.allowMouseInput = false;
		slider.onChange = function(value:Float) {
			setValue(value);
		};
		add(slider);
		stepper = new MaterialNumericStepper(width - 192, controlsY + 2, option.changeValue, option.getValue(), option.minValue, option.maxValue, option.decimals, 168, function(value:Float) {
			setValue(value);
		});
		stepper.allowMouseInput = false;
		add(stepper);
		fitHeight(controlsY + 62, 18);
		refreshFromOption();
	}

	function setValue(value:Float):Void
	{
		var factor = Math.pow(10, option.decimals);
		value = FlxMath.bound(value, option.minValue, option.maxValue);
		value = Math.round(value * factor) / factor;
		option.setValue(value);
		if (!syncLock)
		{
			syncLock = true;
			slider.value = value;
			stepper.value = value;
			syncLock = false;
		}
		option.change();
		announceValue(option.name + ': ' + option.getDisplayValue());
	}

	override public function refreshFromOption():Void
	{
		syncLock = true;
		slider.min = option.minValue;
		slider.max = option.maxValue;
		slider.value = option.getValue();
		stepper.min = option.minValue;
		stepper.max = option.maxValue;
		stepper.step = option.changeValue;
		stepper.decimals = option.decimals;
		stepper.value = option.getValue();
		syncLock = false;
	}

	override public function handleLeft():Void setValue(option.getValue() - option.changeValue);
	override public function handleRight():Void setValue(option.getValue() + option.changeValue);
	override public function handleAccept():Void setValue(option.getValue() + option.changeValue > option.maxValue ? option.minValue : option.getValue() + option.changeValue);
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		var sliderX = x + slider.x;
		var sliderY = y + slider.y - 8;
		var sliderH = 44.0;
		if (screenX >= sliderX && screenX <= sliderX + slider.sliderWidth && screenY >= sliderY && screenY <= sliderY + sliderH)
		{
			var normalized = FlxMath.bound((screenX - sliderX) / slider.sliderWidth, 0, 1);
			setValue(option.minValue + normalized * (option.maxValue - option.minValue));
			return true;
		}

		var stepperX = x + stepper.x;
		var stepperY = y + stepper.y;
		var stepperH = 44.0;
		if (screenX >= stepperX && screenX <= stepperX + stepper.stepperWidth && screenY >= stepperY && screenY <= stepperY + stepperH)
		{
			var localX = screenX - stepperX;
			if (localX <= 42)
				setValue(option.getValue() - option.changeValue);
			else if (localX >= stepper.stepperWidth - 42)
				setValue(option.getValue() + option.changeValue);
			return true;
		}

		handleAccept();
		return true;
	}
	override public function resetToDefault():Void
	{
		option.setValue(option.defaultValue);
		refreshFromOption();
		option.change();
	}
}

private class GameplayChangerDropdownMenu extends FlxSpriteGroup
{
	static inline var ITEM_HEIGHT:Int = 40;
	static inline var VERTICAL_PADDING:Int = 8;

	var items:Array<String>;
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
		MD3ShapeTools.fillRoundRect(background, Std.int(width), menuHeight, 20, OptionsMenuTheme.previewSurfaceColor());
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
			label.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.previewHintColor(false), LEFT);
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
			var fill = OptionsMenuTheme.interactiveFill(isActive);
			var textColor = isActive ? OptionsMenuTheme.previewTitleColor() : OptionsMenuTheme.previewHintColor(false);
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

	public function applyTouchSelection(index:Int):Void
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

	public function containsTouchPoint(screenX:Float, screenY:Float):Bool
	{
		return screenX >= x && screenX <= x + background.width && screenY >= y && screenY <= y + background.height;
	}

	public function getTouchItemIndex(screenX:Float, screenY:Float):Int
	{
		if (!containsTouchPoint(screenX, screenY)) return -1;
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

class GameplayOption
{
	public var onChange:Void->Void = null;
	public var type:OptionType = BOOL;
	public var scrollSpeed:Float = 50;
	public var defaultValue:Dynamic = null;
	public var curOption:Int = 0;
	public var options:Array<String> = null;
	public var changeValue:Dynamic = 1;
	public var minValue:Dynamic = null;
	public var maxValue:Dynamic = null;
	public var decimals:Int = 1;
	public var displayFormat:String = '%v';
	public var name:String = 'Unknown';
	public var optionTranslationKey:String = null;

	private var variable:String = null;
	var _name:String = null;

	public function new(name:String, variable:String, type:OptionType, defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null)
	{
		_name = name;
		this.name = Language.getPhrase('setting_$name', name);
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case BOOL:
					defaultValue = false;
				case INT, FLOAT:
					defaultValue = 0;
				case PERCENT:
					defaultValue = 1;
				case STRING:
					defaultValue = '';
					if (options != null && options.length > 0)
						defaultValue = options[0];
				default:
			}
		}

		if (getValue() == null)
			setValue(defaultValue);

		switch (type)
		{
			case STRING:
				var num:Int = options.indexOf(getValue());
				if (num > -1)
					curOption = num;
			case PERCENT:
				displayFormat = '%v%';
				changeValue = 0.01;
				minValue = 0;
				maxValue = 1;
				scrollSpeed = 0.5;
				decimals = 2;
			default:
		}
	}

	public function change():Void
	{
		if (onChange != null)
			onChange();
	}

	public function getValue():Dynamic
		return ClientPrefs.data.gameplaySettings.get(variable);

	public function setValue(value:Dynamic):Void
		ClientPrefs.data.gameplaySettings.set(variable, value);

	public function getDescription():String
		return Language.getPhrase('description_' + normalizeKey(_name), 'Adjust ' + name + '.');

	public function getDisplayValue():String
	{
		var text = displayFormat;
		var val:Dynamic = getValue();
		if (type == PERCENT) val = Std.int(Math.round(val * 100));
		var def:Dynamic = defaultValue;
		if (type == PERCENT) def = Std.int(Math.round(def * 100));
		return text.replace('%v', Std.string(val)).replace('%d', Std.string(def));
	}

	function normalizeKey(value:String):String
	{
		var key = value.toLowerCase();
		key = StringTools.replace(key, ' ', '_');
		key = StringTools.replace(key, '!', '');
		key = StringTools.replace(key, '/', '_');
		while (key.indexOf('__') != -1)
			key = StringTools.replace(key, '__', '_');
		return key;
	}

	public var internalName(get, never):String;
	private function get_internalName():String
		return _name;

	public var variableName(get, never):String;
	private function get_variableName():String
		return variable;
}
