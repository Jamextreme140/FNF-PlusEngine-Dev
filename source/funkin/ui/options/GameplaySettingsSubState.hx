package funkin.ui.options;

import StringTools;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatSubstate;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSwitch;

class GameplaySettingsSubState extends MusicBeatSubstate
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

	var cardLayer:FlxTypedGroup<GameplaySettingsCard>;
	var overlayLayer:FlxSpriteGroup;
	var cards:Array<GameplaySettingsCard> = [];
	var activeDropdown:GameplayDropdownMenu;

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
	var cardBaseY:Array<Float> = [];

	var daHitSound:FlxSound = new FlxSound();

	public function new()
	{
		controls.isInSubstate = true;
		super();
	}

	override function create():Void
	{
		super.create();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Gameplay Settings Menu', null);
		#end

		OptionsMenuTheme.syncAccent();

		buildChrome();
		buildCards();
		changeSelection(lastSelected, true);
		refreshCardPositions(true);
		onChangeAutoPause();
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

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, phrase('gameplay_menu', 'Gameplay Settings'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, palette.strong, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			phrase('gameplay_menu_subtitle', 'Scroll direction, hit rules, timing windows and utility toggles now live in proper cards instead of the old option pile.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, palette.muted, LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, phrase('close', 'Close'), TEXT, 110, closeAndSave);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 330, panelY + 66, 290, phrase('gameplay_menu_status', 'Timing, rules and input behavior'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, palette.muted, RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			phrase('gameplay_menu_footer', 'ARROWS move. LEFT/RIGHT adjust. ENTER toggles or opens. R resets the selected option. ESC returns.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, 0xFF6D5F82, CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		cardLayer = new FlxTypedGroup<GameplaySettingsCard>();
		add(cardLayer);

		overlayLayer = new FlxSpriteGroup();
		add(overlayLayer);
	}

	function buildCards():Void
	{
		var cardY:Float = contentTop;
		var cardX:Float = panelX + 28;

		cardY = addCard(new GameplaySwitchCard(phraseSetting('downscroll', 'Downscroll'), phraseDescription('downscroll', 'If checked, notes go Down instead of Up, simple enough.'), cardWidth, ClientPrefs.data.downScroll, ClientPrefs.defaultData.downScroll, function(value:Bool) {
			ClientPrefs.data.downScroll = value;
			#if mobile
			onChangeDownscroll();
			#end
			saveSetting('Downscroll ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('middlescroll', 'Middlescroll'), phraseDescription('middlescroll', 'If checked, your notes get centered.'), cardWidth, ClientPrefs.data.middleScroll, ClientPrefs.defaultData.middleScroll, function(value:Bool) {
			ClientPrefs.data.middleScroll = value;
			#if mobile
			onChangeMiddlescroll();
			#end
			saveSetting('Middlescroll ' + boolLabel(value));
		}), cardX, cardY);

		#if mobile
		cardY = addCard(new GameplaySwitchCard(phraseSetting('aligned_receptors', 'Aligned Receptors'), phraseDescription('aligned_receptors', 'ONLY FOR HITBOX-ARROWS MODE! Aligns player receptors with hitbox lanes and puts opponent receptors in the corner.'), cardWidth, ClientPrefs.data.mobileReceptorAlign, ClientPrefs.defaultData.mobileReceptorAlign, function(value:Bool) {
			ClientPrefs.data.mobileReceptorAlign = value;
			onChangeMobileReceptorAlign();
			saveSetting('Aligned Receptors ' + boolLabel(value));
		}), cardX, cardY);
		#end

		cardY = addCard(new GameplaySwitchCard(phraseSetting('opponent_notes', 'Opponent Notes'), phraseDescription('opponent_notes', 'If unchecked, opponent notes get hidden.'), cardWidth, ClientPrefs.data.opponentStrums, ClientPrefs.defaultData.opponentStrums, function(value:Bool) {
			ClientPrefs.data.opponentStrums = value;
			saveSetting('Opponent Notes ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('ghost_tapping', 'Ghost Tapping'), phraseDescription('ghost_tapping', 'If checked, you will not get misses from pressing keys while there are no notes able to be hit.'), cardWidth, ClientPrefs.data.ghostTapping, ClientPrefs.defaultData.ghostTapping, function(value:Bool) {
			ClientPrefs.data.ghostTapping = value;
			saveSetting('Ghost Tapping ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('bad_and_shit_break_combo', 'Bad and Shit Break Combo'), phraseDescription('bad_and_shit_break_combo', 'If checked, hitting Bad or Shit notes will break your combo instead of counting like normal misses only.'), cardWidth, ClientPrefs.data.badShitBreakCombo, ClientPrefs.defaultData.badShitBreakCombo, function(value:Bool) {
			ClientPrefs.data.badShitBreakCombo = value;
			saveSetting('Bad and Shit Break Combo ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('version_text_on_gameplay', 'Version Text on Gameplay'), phraseDescription('version_text_on_gameplay', 'If checked, the version text will be shown.'), cardWidth, ClientPrefs.data.versionTextOnGameplay, ClientPrefs.defaultData.versionTextOnGameplay, function(value:Bool) {
			ClientPrefs.data.versionTextOnGameplay = value;
			saveSetting('Version Text on Gameplay ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('auto_pause', 'Auto Pause'), phraseDescription('auto_pause', 'If checked, the game automatically pauses if the screen is not in focus.'), cardWidth, ClientPrefs.data.autoPause, ClientPrefs.defaultData.autoPause, function(value:Bool) {
			ClientPrefs.data.autoPause = value;
			onChangeAutoPause();
			saveSetting('Auto Pause ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('pop_up_score', 'Pop Up Score'), phraseDescription('pop_up_score', 'If unchecked, hitting notes will not spawn rating and combo popups.'), cardWidth, ClientPrefs.data.popUpRating, ClientPrefs.defaultData.popUpRating, function(value:Bool) {
			ClientPrefs.data.popUpRating = value;
			saveSetting('Pop Up Score ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('disable_reset_button', 'Disable Reset Button'), phraseDescription('disable_reset_button', 'If checked, pressing Reset will not do anything.'), cardWidth, ClientPrefs.data.noReset, ClientPrefs.defaultData.noReset, function(value:Bool) {
			ClientPrefs.data.noReset = value;
			saveSetting('Disable Reset Button ' + boolLabel(value));
		}), cardX, cardY);

		#if mobile
		cardY = addCard(new GameplaySwitchCard(phraseSetting('game_over_vibration', 'Game Over Vibration'), phraseDescription('game_over_vibration', 'If checked, your device will vibrate at game over.'), cardWidth, ClientPrefs.data.gameOverVibration, ClientPrefs.defaultData.gameOverVibration, function(value:Bool) {
			ClientPrefs.data.gameOverVibration = value;
			onChangeVibration();
			saveSetting('Game Over Vibration ' + boolLabel(value));
		}), cardX, cardY);
		#end

		cardY = addCard(new GameplaySwitchCard(phraseSetting('sustains_as_one_note', 'Sustains as One Note'), phraseDescription('sustains_as_one_note', 'If checked, Hold Notes count as a single Hit/Miss and cannot be pressed if you missed the head note.'), cardWidth, ClientPrefs.data.guitarHeroSustains, ClientPrefs.defaultData.guitarHeroSustains, function(value:Bool) {
			ClientPrefs.data.guitarHeroSustains = value;
			saveSetting('Sustains as One Note ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplayChoiceCard(phraseSetting('hitsound_in_what_way', 'Hitsound in what way'), phraseDescription('hitsound_in_what_way', 'If checked, note and keys do a hitsound when pressed, else only when notes are hit.'), cardWidth, ['None', 'Keys', 'Notes'], ClientPrefs.data.hitsoundType, ClientPrefs.defaultData.hitsoundType, openChoiceMenu, function(value:String) {
			ClientPrefs.data.hitsoundType = value;
			saveSetting('Hitsound in what way: ' + value);
		}, 'hitsound_in_what_way'), cardX, cardY);

		cardY = addCard(new GameplaySliderCard(phraseSetting('hitsound_volume', 'Hitsound Volume'), phraseDescription('hitsound_volume', 'Funny notes go tick when you hit them.'), cardWidth, ClientPrefs.data.hitsoundVolume, ClientPrefs.defaultData.hitsoundVolume, 0.0, 1.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.hitsoundVolume = value;
			onChangeHitsoundVolume();
			saveSetting('Hitsound Volume: ' + percentLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplayChoiceCard(phraseSetting('hitsound_sound', 'Hitsound Sound'), phraseDescription('hitsound_sound', 'Choose the sound used for hitsounds.'), cardWidth, ['None', 'quaver', 'osu', 'clap', 'camellia', 'stepmania', '21st century humor', 'vine boom', 'sexus'], ClientPrefs.data.hitSounds, ClientPrefs.defaultData.hitSounds, openChoiceMenu, function(value:String) {
			ClientPrefs.data.hitSounds = value;
			onChangeHitsound();
			saveSetting('Hitsound Sound: ' + value);
		}, 'hitsound_sound'), cardX, cardY);

		cardY = addCard(new GameplaySliderCard(phraseSetting('rating_offset', 'Rating Offset'), phraseDescription('rating_offset', 'Changes how late or early you have to hit for a Flawless!! Higher values mean you have to hit later.'), cardWidth, ClientPrefs.data.ratingOffset, ClientPrefs.defaultData.ratingOffset, -30, 30, 1, 0, function(value:Float) {
			ClientPrefs.data.ratingOffset = Std.int(value);
			saveSetting('Rating Offset: ' + Std.int(value) + 'ms');
		}), cardX, cardY);

		cardY = addCard(new GameplaySliderCard(phraseSetting('flawless_hit_window', 'Flawless!! Hit Window'), phraseDescription('flawless_hit_window', 'Changes the amount of time you have for hitting a Flawless!! in milliseconds.'), cardWidth, ClientPrefs.data.flawlessWindow, ClientPrefs.defaultData.flawlessWindow, 15.0, 25.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.flawlessWindow = value;
			saveSetting('Flawless!! Hit Window: ' + value + 'ms');
		}), cardX, cardY);

		cardY = addCard(new GameplaySliderCard(phraseSetting('sick_hit_window', 'Sick! Hit Window'), phraseDescription('sick_hit_window', 'Changes the amount of time you have for hitting a Sick! in milliseconds.'), cardWidth, ClientPrefs.data.sickWindow, ClientPrefs.defaultData.sickWindow, 15.0, 45.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.sickWindow = value;
			saveSetting('Sick! Hit Window: ' + value + 'ms');
		}), cardX, cardY);

		cardY = addCard(new GameplaySliderCard(phraseSetting('good_hit_window', 'Good Hit Window'), phraseDescription('good_hit_window', 'Changes the amount of time you have for hitting a Good in milliseconds.'), cardWidth, ClientPrefs.data.goodWindow, ClientPrefs.defaultData.goodWindow, 15.0, 90.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.goodWindow = value;
			saveSetting('Good Hit Window: ' + value + 'ms');
		}), cardX, cardY);

		cardY = addCard(new GameplaySliderCard(phraseSetting('bad_hit_window', 'Bad Hit Window'), phraseDescription('bad_hit_window', 'Changes the amount of time you have for hitting a Bad in milliseconds.'), cardWidth, ClientPrefs.data.badWindow, ClientPrefs.defaultData.badWindow, 15.0, 135.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.badWindow = value;
			saveSetting('Bad Hit Window: ' + value + 'ms');
		}), cardX, cardY);

		cardY = addCard(new GameplaySliderCard(phraseSetting('safe_frames', 'Safe Frames'), phraseDescription('safe_frames', 'Changes how many frames you have for hitting a note earlier or late.'), cardWidth, ClientPrefs.data.safeFrames, ClientPrefs.defaultData.safeFrames, 2.0, 10.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.safeFrames = value;
			saveSetting('Safe Frames: ' + value);
		}), cardX, cardY);

		cardY = addCard(new GameplayChoiceCard(phraseSetting('accuracy_system', 'Accuracy System'), phraseDescription('accuracy_system', 'Choose the accuracy calculation system used by gameplay results.'), cardWidth, ['Wife3', 'Psych', 'Simple', 'osu!mania', 'DJMAX', 'ITG'], ClientPrefs.data.accuracySystem, ClientPrefs.defaultData.accuracySystem, openChoiceMenu, function(value:String) {
			ClientPrefs.data.accuracySystem = value;
			saveSetting('Accuracy System: ' + value);
		}, 'accuracy_system'), cardX, cardY);

		cardY = addCard(new GameplayChoiceCard(phraseSetting('system_score_multiplier', 'System Score Multiplier'), phraseDescription('system_score_multiplier', 'Choose the scoring system for note hits.'), cardWidth, ['Psych', 'Codename'], ClientPrefs.data.systemScoreMultiplier, ClientPrefs.defaultData.systemScoreMultiplier, openChoiceMenu, function(value:String) {
			ClientPrefs.data.systemScoreMultiplier = value;
			saveSetting('System Score Multiplier: ' + value);
		}, 'system_score_multiplier'), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('pause_countdown', 'Pause Countdown'), phraseDescription('pause_countdown', 'If checked, resuming from pause plays a countdown similar to the intro countdown.'), cardWidth, ClientPrefs.data.pauseCountdown, ClientPrefs.defaultData.pauseCountdown, function(value:Bool) {
			ClientPrefs.data.pauseCountdown = value;
			saveSetting('Pause Countdown ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('hey_intro', 'Hey Intro'), phraseDescription('hey_intro', 'If checked, BF and GF automatically do the Hey! animation when the countdown says Go!'), cardWidth, ClientPrefs.data.heyIntro, ClientPrefs.defaultData.heyIntro, function(value:Bool) {
			ClientPrefs.data.heyIntro = value;
			saveSetting('Hey Intro ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('break_timer', 'Break Timer'), phraseDescription('break_timer', 'If checked, a timer appears when the next notes are still far away.'), cardWidth, ClientPrefs.data.breakTimer, ClientPrefs.defaultData.breakTimer, function(value:Bool) {
			ClientPrefs.data.breakTimer = value;
			saveSetting('Break Timer ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new GameplaySwitchCard(phraseSetting('heavy_charts_mode', 'Heavy Charts Mode'), phraseDescription('heavy_charts_mode', 'If checked, enables the Heavy Charts system for better performance on charts with many notes.'), cardWidth, ClientPrefs.data.heavyCharts, ClientPrefs.defaultData.heavyCharts, function(value:Bool) {
			ClientPrefs.data.heavyCharts = value;
			onChangeHeavyCharts();
			saveSetting('Heavy Charts Mode ' + boolLabel(value));
		}), cardX, cardY);

		#if (HSCRIPT_ALLOWED && MODS_ALLOWED && sys && !mobile)
		cardY = addCard(new GameplaySwitchCard(phraseSetting('use_scriptable_custom_states', 'Use Scriptable/Custom States'), phraseDescription('use_scriptable_custom_states', 'If checked, ScriptableState and CustomState can replace hardcoded states when matching scripts exist.'), cardWidth, ClientPrefs.data.useScriptableCustomStates, ClientPrefs.defaultData.useScriptableCustomStates, function(value:Bool) {
			ClientPrefs.data.useScriptableCustomStates = value;
			saveSetting('Use Scriptable/Custom States ' + boolLabel(value));
		}), cardX, cardY);
		#end

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function addCard(card:GameplaySettingsCard, x:Float, y:Float):Float
	{
		card.x = x;
		card.y = y;
		cardLayer.add(card);
		cards.push(card);
		cardBaseY.push(y);
		return y + card.cardHeight + 10;
	}

	function phrase(key:String, fallback:String):String
	{
		return Language.getPhrase(key, fallback);
	}

	function phraseSetting(key:String, fallback:String):String
	{
		return phrase('setting_' + key, fallback);
	}

	function phraseDescription(key:String, fallback:String):String
	{
		return phrase('description_' + key, fallback);
	}

	function boolLabel(value:Bool):String
	{
		return value ? phrase('enabled', 'Enabled') : phrase('disabled', 'Disabled');
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
		scrollOffset = instant ? scrollTarget : FlxMath.lerp(scrollTarget, scrollOffset, Math.exp(-elapsedSmoothing()));
		for (index in 0...cards.length)
		{
			var card = cards[index];
			card.y = cardBaseY[index] + scrollOffset;
			card.applyVerticalClip(clipTop, clipBottom);
		}
	}

	inline function elapsedSmoothing():Float
	{
		return 0.18;
	}

	function openChoiceMenu(card:GameplayChoiceCard):Void
	{
		closeActiveDropdown();
		var menuY = card.getAnchorY() + 52;
		var menuHeight = GameplayDropdownMenu.getTotalHeight(card.options.length);
		if (menuY + menuHeight > contentBottom) menuY = card.getAnchorY() - menuHeight - 10;
		if (menuY < contentTop) menuY = contentTop;
		activeDropdown = new GameplayDropdownMenu(card.getAnchorX(), menuY, card.getAnchorWidth(), overlayLayer, card.options, card.currentValue, function(value:String) {
			card.setValueLabel(value);
		}, function() {
			activeDropdown = null;
		}, card.getOptionLabel);
		overlayLayer.add(activeDropdown);
		announce(card.titleText.text + phrase('gameplay_menu_opened_suffix', ' menu opened'), false);
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

	function onChangeHitsound():Void
	{
		if (ClientPrefs.data.hitSounds != 'None' && ClientPrefs.data.hitsoundVolume != 0)
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'));
			daHitSound.volume = ClientPrefs.data.hitsoundVolume;
			daHitSound.play();
		}
	}

	function onChangeHitsoundVolume():Void
	{
		if (ClientPrefs.data.hitSounds != 'None')
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${ClientPrefs.data.hitSounds}'));
			daHitSound.volume = ClientPrefs.data.hitsoundVolume;
			daHitSound.play();
		}
		else
			FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.data.hitsoundVolume);
	}

	function onChangeAutoPause():Void
	{
		FlxG.autoPause = ClientPrefs.data.autoPause;
	}

	function onChangeVibration():Void
	{
		#if mobile
		if (ClientPrefs.data.gameOverVibration)
			lime.ui.Haptic.vibrate(0, 500);
		#end
	}

	function onChangeHeavyCharts():Void
	{
		trace('Heavy Charts Mode: ${ClientPrefs.data.heavyCharts ? "ENABLED" : "DISABLED"}');
	}

	#if mobile
	function onChangeMobileReceptorAlign():Void
	{
		if (ClientPrefs.data.mobileReceptorAlign)
		{
			if (ClientPrefs.data.middleScroll)
				ClientPrefs.data.middleScroll = false;
			if (!ClientPrefs.data.downScroll)
				ClientPrefs.data.downScroll = true;
		}
	}

	function onChangeDownscroll():Void
	{
		if (ClientPrefs.data.downScroll && ClientPrefs.data.mobileReceptorAlign)
			ClientPrefs.data.mobileReceptorAlign = false;
	}

	function onChangeMiddlescroll():Void
	{
		if (ClientPrefs.data.middleScroll && ClientPrefs.data.mobileReceptorAlign)
			ClientPrefs.data.mobileReceptorAlign = false;
	}
	#end
}

private class GameplaySettingsCard extends FlxSpriteGroup
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

	public function new(title:String, description:String, width:Float)
	{
		super();
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

	public function handleLeft():Void {}
	public function handleRight():Void {}
	public function handleAccept():Void {}
	public function resetToDefault():Void {}

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
}

private class GameplaySwitchCard extends GameplaySettingsCard
{
	var toggle:MaterialSwitch;
	var valueText:FlxText;
	var currentValue:Bool;
	var defaultValue:Bool;
	var onApply:Bool->Void;

	public function new(title:String, description:String, width:Float, currentValue:Bool, defaultValue:Bool, onApply:Bool->Void)
	{
		super(title, description, width);
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
		valueText.text = value ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
		if (fireApply && onApply != null) onApply(value);
	}

	override public function handleLeft():Void setValue(false);
	override public function handleRight():Void setValue(true);
	override public function handleAccept():Void setValue(!currentValue);
	override public function resetToDefault():Void setValue(defaultValue);
}

private class GameplayChoiceCard extends GameplaySettingsCard
{
	public var options(default, null):Array<String>;
	public var currentValue(default, null):String;

	var defaultValue:String;
	var selectorButton:MaterialButton;
	var requestDropdown:GameplayChoiceCard->Void;
	var onApply:String->Void;
	var optionTranslationKey:String;

	public function new(title:String, description:String, width:Float, options:Array<String>, currentValue:String, defaultValue:String,
		requestDropdown:GameplayChoiceCard->Void, onApply:String->Void, ?optionTranslationKey:String)
	{
		super(title, description, width);
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
	override public function resetToDefault():Void setValueLabel(defaultValue);
}

private class GameplaySliderCard extends GameplaySettingsCard
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

	public function new(title:String, description:String, width:Float, currentValue:Float, defaultValue:Float, minValue:Float, maxValue:Float, stepValue:Float, decimals:Int, onApply:Float->Void)
	{
		super(title, description, width);
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
		slider.onChange = function(value:Float) {
			setValue(value, true);
		};
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
	override public function resetToDefault():Void setValue(defaultValue);
}

private class GameplayDropdownMenu extends FlxSpriteGroup
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
			var fill = isActive ? 0xFFE9DEFF : 0x00000000;
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
		if (onSelect != null) onSelect(items[selectedIndex]);
		closeMenu();
	}

	public function closeMenu():Void
	{
		if (hostLayer != null) hostLayer.remove(this, true);
		if (onClosed != null) onClosed();
		kill();
	}
}
