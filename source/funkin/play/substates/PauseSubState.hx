package funkin.play.substates;

import funkin.audio.Conductor;
import funkin.data.Difficulty;
import funkin.data.song.Song;
import funkin.modding.Mods;
import funkin.save.Highscore;
import funkin.ui.Language;
import funkin.ui.LocaleUtils;
import funkin.ui.MusicBeatState;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.options.OptionsMenuTheme;
import funkin.ui.options.OptionsState;
import funkin.ui.story.StoryMenuState;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxStringUtil;

class PauseSubState extends MusicBeatSubstate
{
	var currentItems:Array<String> = [];
	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Chart Editor', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices:Array<String> = [];
	var cards:Array<PauseActionCard> = [];
	var cardBaseY:Array<Float> = [];
	var cardLayer:FlxTypedGroup<PauseActionCard>;

	var backdrop:FlxSprite;
	var menuBG:FlxSprite;
	var panelShadow:FlxSprite;
	var panelSurface:FlxSprite;
	var panelHeader:FlxSprite;
	var panelOutline:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var headerMetaText:FlxText;
	var statusText:FlxText;
	var hintText:FlxText;
	var footerText:FlxText;
	var resumeButton:MaterialButton;
	var summarySurface:FlxSprite;
	var summaryOutline:FlxSprite;
	var timeSurface:FlxSprite;
	var timeOutline:FlxSprite;
	var summaryTitleText:FlxText;
	var dateTimeText:FlxText;
	var timeSummaryText:FlxText;
	var sliderHintText:FlxText;
	var statsSummaryText:FlxText;
	var timeSlider:MaterialSlider;
	var syncingSlider:Bool = false;
	var summaryCardHeight:Float = 160;
	var dataCardHeight:Float = 338;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var pauseMusic:FlxSound;
	var curSelected:Int = 0;
	var curTime:Float = Math.max(0, Conductor.songPosition);
	var holdTime:Float = 0;
	var cantUnpause:Float = 0.1;
	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelWidth:Float = 0;
	var panelHeight:Float = 0;
	var hiddenPanelX:Float = 0;
	var drawerX:Float = 0;
	var drawerTargetX:Float = 0;
	var backdropTargetAlpha:Float = 0;
	var leftColumnX:Float = 0;
	var leftColumnWidth:Float = 0;
	var summaryX:Float = 0;
	var summaryWidth:Float = 0;
	var contentTop:Float = 0;
	var contentBottom:Float = 0;
	var scrollOffset:Float = 0;
	var scrollTarget:Float = 0;
	var contentHeight:Float = 0;
	var isClosing:Bool = false;
	var allowImmediateClose:Bool = false;
	var pendingCloseAction:Void->Void;

	#if mobile
	var touchScroll:funkin.mobile.backend.TouchScroll;
	#end

	public static var songName:String = null;

	public function new()
	{
		super();
		setupOverlayCamera();
		LocaleUtils.loadDeviceDateTimeSettings();
		prepareMenus();
		loadPauseMusic();
		buildChrome();
		rebuildCards();
		changeSelection(0, true);
		refreshSummary();
		refreshCardPositions(true);
		animateOpen();

		addTouchPad('LEFT_FULL', 'A_B');
		addTouchPadCamera();

		#if mobile
		touchScroll = new funkin.mobile.backend.TouchScroll(true);
		funkin.mobile.backend.TouchUtil.setScrollHandler(touchScroll);
		#end
	}

	function setupOverlayCamera():Void
	{
		if (PlayState.instance != null && PlayState.instance.camOther != null)
			cameras = [PlayState.instance.camOther];
		else if (FlxG.cameras != null && FlxG.cameras.list.length > 0)
			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	function pinSprite(sprite:FlxSprite):Void
	{
		sprite.scrollFactor.set();
		sprite.cameras = cameras;
	}

	function pinText(text:FlxText):Void
	{
		text.scrollFactor.set();
		text.cameras = cameras;
	}

	function pinGroup(group:FlxSpriteGroup):Void
	{
		group.scrollFactor.set();
		group.cameras = cameras;
	}

	function prepareMenus():Void
	{
		if (Difficulty.list.length < 2)
			menuItemsOG.remove('Change Difficulty');

		if (PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');
			var offset:Int = 0;
			if (!PlayState.instance.startingSong)
			{
				offset = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
			menuItemsOG.insert(3 + offset, 'End Song');
			menuItemsOG.insert(4 + offset, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + offset, 'Toggle Botplay');
		}
		else if (PlayState.instance.practiceMode && !PlayState.instance.startingSong)
		{
			menuItemsOG.insert(3, 'Skip Time');
		}

		if (PlayState.instance.videoCutscene != null)
			menuItemsOG.insert(1, 'Skip Video');

		currentItems = menuItemsOG.copy();
		difficultyChoices = [];
		for (i in 0...Difficulty.list.length)
			difficultyChoices.push(Difficulty.getString(i));
		difficultyChoices.push('BACK');
	}

	function loadPauseMusic():Void
	{
		pauseMusic = new FlxSound();
		try
		{
			var pauseSong:String = getPauseSong();
			if (pauseSong != null)
				pauseMusic.loadEmbedded(Paths.music(pauseSong), true, true);
		}
		catch (e:Dynamic) {}

		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(Math.max(1, pauseMusic.length / 2))));
		FlxG.sound.list.add(pauseMusic);
	}

	function buildChrome():Void
	{
		OptionsMenuTheme.syncAccent();
		var palette = OptionsMenuTheme.current();
		var blackTheme = OptionsMenuTheme.isDark();
		var backdropColor = blackTheme ? 0xFF070809 : 0xFF120C19;
		var panelSurfaceColor = blackTheme ? 0xFF101216 : 0xFFF9F5FC;
		var panelHeaderColor = blackTheme ? 0xFF171A1F : 0xFFFFFBFF;
		var panelOutlineColor = blackTheme ? 0xFF2A2E36 : 0x24FFFFFF;
		var metaColor = blackTheme ? 0xFF9BA1AD : 0xFF6D5F82;
		var summarySurfaceColor = blackTheme ? 0xFF171A1F : 0xFFFFFBFF;
		var summaryOutlineColor = blackTheme ? 0xFF30343C : 0xFFDCCEEB;
		var timeSurfaceColor = blackTheme ? 0xFF111317 : 0xFFFCF8FF;
		var statsColor = blackTheme ? 0xFFE8EBF0 : 0xFF2C1E48;
		var timeSummaryColor = blackTheme ? 0xFFC7CDD7 : 0xFF4D34A8;
		var sliderHintColor = blackTheme ? 0xFF9BA1AD : 0xFF7B6D93;
		var titleColor = blackTheme ? 0xFFF5F7FA : palette.strong;
		var bodyColor = blackTheme ? 0xFFC4CBD6 : palette.muted;
		var dateTimeColor = blackTheme ? 0xFF9BA1AD : palette.muted;

		panelWidth = Math.min(960, FlxG.width - 36);
		panelHeight = FlxG.height - 28;
		panelX = 18;
		hiddenPanelX = -panelWidth - 28;
		drawerX = hiddenPanelX;
		drawerTargetX = hiddenPanelX;
		backdropTargetAlpha = 0;
		panelY = 14;
		leftColumnWidth = Math.min(460, panelWidth * 0.48);
		summaryWidth = panelWidth - leftColumnWidth - 72;
		leftColumnX = 18;
		summaryX = leftColumnX + leftColumnWidth + 24;
		contentTop = panelY + 146;
		contentBottom = panelY + panelHeight - 56;
		summaryCardHeight = 160;
		dataCardHeight = Math.min(338, panelHeight - 250);

		backdrop = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, backdropColor);
		backdrop.alpha = 0;
		pinSprite(backdrop);
		add(backdrop);

		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = palette.pale;
		menuBG.alpha = blackTheme ? 0.05 : 0.09;
		menuBG.updateHitbox();
		menuBG.screenCenter();
		pinSprite(menuBG);
		add(menuBG);

		panelShadow = new FlxSprite();
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 34, 0x32000000);
		pinSprite(panelShadow);
		add(panelShadow);

		panelSurface = new FlxSprite();
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, panelSurfaceColor);
		pinSprite(panelSurface);
		add(panelSurface);

		panelHeader = new FlxSprite();
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 118, 34, 0, 0, 34, panelHeaderColor);
		pinSprite(panelHeader);
		add(panelHeader);

		panelOutline = new FlxSprite();
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, panelOutlineColor);
		pinSprite(panelOutline);
		add(panelOutline);

		titleText = new FlxText(0, 0, panelWidth - 220, Language.getPhrase('pause_title', 'Pause'), 32);
		titleText.setFormat(Paths.font('inter-bold.otf'), 32, titleColor, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(titleText);
		add(titleText);

		subtitleText = new FlxText(0, 0, panelWidth - 220,
			Language.getPhrase('pause_subtitle', 'Same pause, new drawer. Less alphabet soup, more actual UI.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, bodyColor, LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(subtitleText);
		add(subtitleText);

		headerMetaText = new FlxText(0, 0, panelWidth - 260, '', 14);
		headerMetaText.setFormat(Paths.font('inter.otf'), 14, metaColor, LEFT);
		headerMetaText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(headerMetaText);
		add(headerMetaText);

		resumeButton = new MaterialButton(0, 0, Language.getPhrase('pause_Resume', 'Resume'), TEXT, 108, function() {
			handleMenuAction('Resume');
		});
		resumeButton.allowMouseInput = true;
		pinGroup(resumeButton);
		add(resumeButton);

		statusText = new FlxText(0, 0, leftColumnWidth, Language.getPhrase('pause_status_ready', 'Paused'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, metaColor, LEFT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(statusText);
		add(statusText);

		hintText = new FlxText(0, 0, 330,
			Language.getPhrase('pause_hint_controls', 'UP/DOWN select. LEFT/RIGHT adjusts time. ENTER activates. ESC resumes.'), 13);
		hintText.setFormat(Paths.font('inter.otf'), 13, bodyColor, RIGHT);
		hintText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(hintText);
		add(hintText);

		footerText = new FlxText(0, 0, panelWidth - 48,
			Language.getPhrase('pause_footer', 'The drawer slides in from the left. Because if we are pausing, we may as well do it with style.'), 13);
		footerText.setFormat(Paths.font('inter.otf'), 13, metaColor, CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(footerText);
		add(footerText);

		cardLayer = new FlxTypedGroup<PauseActionCard>();
		cardLayer.cameras = cameras;
		add(cardLayer);

		summarySurface = new FlxSprite();
		MD3ShapeTools.fillRoundRect(summarySurface, Std.int(summaryWidth), Std.int(summaryCardHeight), 28, summarySurfaceColor);
		pinSprite(summarySurface);
		add(summarySurface);

		summaryOutline = new FlxSprite();
		MD3ShapeTools.strokeRoundRect(summaryOutline, Std.int(summaryWidth), Std.int(summaryCardHeight), 28, 2, summaryOutlineColor);
		pinSprite(summaryOutline);
		add(summaryOutline);

		timeSurface = new FlxSprite();
		MD3ShapeTools.fillRoundRect(timeSurface, Std.int(summaryWidth), Std.int(dataCardHeight), 28, timeSurfaceColor);
		pinSprite(timeSurface);
		add(timeSurface);

		timeOutline = new FlxSprite();
		MD3ShapeTools.strokeRoundRect(timeOutline, Std.int(summaryWidth), Std.int(dataCardHeight), 28, 2, summaryOutlineColor);
		pinSprite(timeOutline);
		add(timeOutline);

		summaryTitleText = new FlxText(0, 0, summaryWidth - 40, Language.getPhrase('pause_current_run', 'Current run'), 24);
		summaryTitleText.setFormat(Paths.font('inter-bold.otf'), 24, titleColor, LEFT);
		summaryTitleText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(summaryTitleText);
		add(summaryTitleText);

		dateTimeText = new FlxText(0, 0, summaryWidth - 40, '', 14);
		dateTimeText.setFormat(Paths.font('inter.otf'), 14, dateTimeColor, LEFT);
		dateTimeText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(dateTimeText);
		add(dateTimeText);

		timeSummaryText = new FlxText(0, 0, summaryWidth - 40, '', 18);
		timeSummaryText.setFormat(Paths.font('inter.otf'), 18, timeSummaryColor, LEFT);
		timeSummaryText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(timeSummaryText);
		add(timeSummaryText);

		timeSlider = new MaterialSlider(0, 0, summaryWidth - 40, 0, 0, Math.max(1, getSongLength()));
		timeSlider.onChange = function(value:Float) {
			if (syncingSlider) return;
			setPauseTargetTime(value);
		};
		pinGroup(timeSlider);
		add(timeSlider);

		sliderHintText = new FlxText(0, 0, summaryWidth - 40, '', 15);
		sliderHintText.setFormat(Paths.font('inter.otf'), 15, sliderHintColor, LEFT);
		sliderHintText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(sliderHintText);
		add(sliderHintText);

		statsSummaryText = new FlxText(0, 0, summaryWidth - 40, '', 17);
		statsSummaryText.setFormat(Paths.font('inter.otf'), 17, statsColor, LEFT);
		statsSummaryText.antialiasing = ClientPrefs.data.antialiasing;
		pinText(statsSummaryText);
		add(statsSummaryText);

		missingTextBG = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		missingTextBG.scale.set(FlxG.width, FlxG.height);
		missingTextBG.updateHitbox();
		missingTextBG.alpha = 0.65;
		missingTextBG.visible = false;
		pinSprite(missingTextBG);
		add(missingTextBG);

		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font('phantom.ttf'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		pinText(missingText);
		add(missingText);

		applyDrawerLayout();
	}

	function rebuildCards():Void
	{
		for (card in cards)
		{
			cardLayer.remove(card, true);
			card.destroy();
		}

		cards = [];
		cardBaseY = [];
		if (curSelected < 0)
			curSelected = 0;
		else if (curSelected > currentItems.length - 1)
			curSelected = currentItems.length - 1;

		var cardY:Float = contentTop;
		for (item in currentItems)
		{
			var card = new PauseActionCard(leftColumnWidth, item);
			card.setPinned(cameras);
			cardLayer.add(card);
			cards.push(card);
			cardBaseY.push(cardY);
			card.x = drawerX + leftColumnX;
			card.y = cardY;
			cardY += card.cardHeight + 10;
		}

		contentHeight = Math.max(0, cardY - contentTop - 10);
		updateVisibleCards();
		scrollTarget = FlxMath.bound(scrollTarget, getMinScroll(), 0);
		scrollOffset = scrollTarget;
	}

	function animateOpen():Void
	{
		drawerTargetX = panelX;
		backdropTargetAlpha = 0.72;
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
		headerMetaText.x = drawerX + 28;
		headerMetaText.y = panelY + 92;
		resumeButton.x = drawerX + panelWidth - 132;
		resumeButton.y = panelY + 24;
		statusText.x = drawerX + 28;
		statusText.y = panelY + 118;
		hintText.x = drawerX + panelWidth - 354;
		hintText.y = panelY + 92;
		footerText.x = drawerX + 24;
		footerText.y = panelY + panelHeight - 34;

		summarySurface.x = drawerX + summaryX;
		summarySurface.y = contentTop;
		summaryOutline.x = summarySurface.x;
		summaryOutline.y = summarySurface.y;
		timeSurface.x = drawerX + summaryX;
		timeSurface.y = contentTop + summaryCardHeight + 14;
		timeOutline.x = timeSurface.x;
		timeOutline.y = timeSurface.y;

		summaryTitleText.x = summarySurface.x + 20;
		summaryTitleText.y = summarySurface.y + 18;
		dateTimeText.x = summarySurface.x + 20;
		dateTimeText.y = summarySurface.y + 54;
		timeSummaryText.x = timeSurface.x + 20;
		timeSummaryText.y = timeSurface.y + 18;
		timeSlider.x = timeSurface.x + 20;
		timeSlider.y = timeSurface.y + 54;
		sliderHintText.x = timeSurface.x + 20;
		sliderHintText.y = timeSurface.y + 96;
		statsSummaryText.x = timeSurface.x + 20;
		statsSummaryText.y = timeSurface.y + 126;
	}

	function getPauseSong():String
	{
		var formattedSongName:String = (songName != null ? Paths.formatToSongPath(songName) : '');
		var formattedPauseMusic:String = Paths.formatToSongPath(ClientPrefs.data.pauseMusic);
		if (formattedSongName == 'none' || (formattedSongName != 'none' && formattedPauseMusic == 'none'))
			return null;
		return formattedSongName != '' ? formattedSongName : formattedPauseMusic;
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
		scrollOffset = instant ? scrollTarget : FlxMath.lerp(scrollOffset, scrollTarget, 0.22);
		var clipTop = contentTop;
		var clipBottom = contentBottom;

		for (index in 0...cards.length)
		{
			var card = cards[index];
			card.x = drawerX + leftColumnX;
			card.y = cardBaseY[index] + scrollOffset;
			card.applyVerticalClip(clipTop, clipBottom);
		}
	}

	function changeSelection(targetIndex:Int, instant:Bool = false):Void
	{
		if (cards.length == 0) return;
		curSelected = FlxMath.wrap(targetIndex, 0, cards.length - 1);
		if (currentItems[curSelected] == 'Skip Time')
			curTime = Math.max(0, Conductor.songPosition);

		keepSelectionVisible();
		updateVisibleCards();
		for (index in 0...cards.length)
			cards[index].setSelected(index == curSelected, instant);

		statusText.text = getCardTitle(currentItems[curSelected]);
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	function moveSelection(change:Int):Void
	{
		changeSelection(curSelected + change);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
	}

	function updateVisibleCards():Void
	{
		var nextY:Float = contentTop;
		for (index in 0...cards.length)
		{
			var item = currentItems[index];
			cards[index].refresh(getCardTitle(item), getCardDescription(item), getCardValue(item));
			cardBaseY[index] = nextY;
			nextY += cards[index].cardHeight + 12;
		}
		contentHeight = Math.max(0, nextY - contentTop - 12);
		scrollTarget = FlxMath.bound(scrollTarget, getMinScroll(), 0);
	}

	function getCardTitle(item:String):String
	{
		if (item == 'BACK')
			return Language.getPhrase('back', 'Back');
		return Language.getPhrase('pause_' + item, item);
	}

	function getCardDescription(item:String):String
	{
		if (isDifficultyMenu())
		{
			if (item == 'BACK')
				return Language.getPhrase('pause_difficulty_back_desc', 'Return to the main pause actions.');
			return Language.getPhrase('pause_difficulty_desc', 'Restart this song using the selected difficulty.');
		}

		switch (item)
		{
			case 'Resume': return Language.getPhrase('pause_resume_desc', 'Return to the song.');
			case 'Restart Song': return Language.getPhrase('pause_restart_desc', 'Restart from the beginning of the current chart.');
			case 'Chart Editor': return Language.getPhrase('pause_chart_editor_desc', 'Open the chart editor using the current song data.');
			case 'Leave Charting Mode': return Language.getPhrase('pause_leave_charting_desc', 'Restart and leave charting mode.');
			case 'Change Difficulty': return Language.getPhrase('pause_change_difficulty_desc', 'Open the difficulty picker for this song.');
			case 'Skip Time': return Language.getPhrase('pause_skip_time_desc', 'Choose a target time and jump there when you confirm.');
			case 'Skip Video': return Language.getPhrase('pause_skip_video_desc', 'Skip the active cutscene and return to gameplay.');
			case 'End Song': return Language.getPhrase('pause_end_song_desc', 'Force the song to finish immediately.');
			case 'Toggle Practice Mode': return Language.getPhrase('pause_practice_desc', 'Toggle practice mode for this run.');
			case 'Toggle Botplay': return Language.getPhrase('pause_botplay_desc', 'Toggle botplay on the fly.');
			case 'Options': return Language.getPhrase('pause_options_desc', 'Open the settings menu from here.');
			case 'Exit to menu': return Language.getPhrase('pause_exit_desc', 'Leave the song and go back to the menu.');
			default: return '';
		}
	}

	function getCardValue(item:String):String
	{
		if (isDifficultyMenu())
		{
			if (item == 'BACK') return Language.getPhrase('pause_difficulty_back_value', 'Pause actions');
			return item.toUpperCase();
		}

		switch (item)
		{
			case 'Change Difficulty':
				return Difficulty.getString().toUpperCase();
			case 'Skip Time':
				return FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / '
					+ FlxStringUtil.formatTime(Math.max(0, Math.floor(getSongLength() / 1000)), false);
			case 'Toggle Practice Mode':
				return PlayState.instance.practiceMode ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
			case 'Toggle Botplay':
				return PlayState.instance.cpuControlled ? Language.getPhrase('enabled', 'Enabled') : Language.getPhrase('disabled', 'Disabled');
			case 'Resume':
				return ClientPrefs.data.pauseCountdown ? Language.getPhrase('pause_resume_countdown', 'Countdown') : Language.getPhrase('pause_resume_now', 'Immediate');
			default:
				return '';
		}
	}

	function isDifficultyMenu():Bool
	{
		return currentItems == difficultyChoices;
	}

	function getSongLength():Float
	{
		if (FlxG.sound.music != null && FlxG.sound.music.length > 0)
			return FlxG.sound.music.length;
		return Math.max(curTime, Conductor.songPosition);
	}

	function canControlTimeSlider():Bool
	{
		return menuItemsOG.contains('Skip Time') && !isDifficultyMenu();
	}

	function setPauseTargetTime(value:Float):Void
	{
		curTime = FlxMath.bound(value, 0, getSongLength());
		updateVisibleCards();
		refreshSummary();
	}

	function refreshSummary():Void
	{
		if (PlayState.instance == null || timeSlider == null)
			return;

		dateTimeText.text = LocaleUtils.formatDateTimeAccordingToDevice(Date.now());
		headerMetaText.text = PlayState.SONG.song + '  •  ' + Difficulty.getString().toUpperCase() + '  •  '
			+ Language.getPhrase('blueballed', 'Blueballed: {1}', [PlayState.deathCounter]);

		var songLength = Math.max(1, getSongLength());
		var previewTime = FlxMath.bound(currentItems.length > 0 && currentItems[curSelected] == 'Skip Time' ? curTime : Math.max(0, Conductor.songPosition), 0, songLength);
		var canSeek = canControlTimeSlider();

		syncingSlider = true;
		timeSlider.max = songLength;
		timeSlider.enabled = canSeek;
		timeSlider.allowMouseInput = canSeek;
		timeSlider.value = previewTime;
		syncingSlider = false;

		var previewString = FlxStringUtil.formatTime(Math.max(0, Math.floor(previewTime / 1000)), false);
		var totalString = FlxStringUtil.formatTime(Math.max(0, Math.floor(songLength / 1000)), false);
		timeSummaryText.text = Language.getPhrase('pause_time_target', 'Time target: {1} / {2}', [previewString, totalString]);
		sliderHintText.text = canSeek
			? Language.getPhrase('pause_time_hint', 'Drag to set a target. Select Skip Time and press ACCEPT to jump.')
			: Language.getPhrase('pause_time_hint_locked', 'The slider is view-only while no time jump action is available.');

		var state = PlayState.instance;
		var ratingPercent = CoolUtil.floorDecimal(state.ratingPercent * 100, 2);
		var ratingLabel = state.ratingName != null ? Language.getPhrase('rating_' + state.ratingName, state.ratingName) : '?';
		var fcLabel = (state.ratingFC != null && state.ratingFC.length > 0) ? Language.getPhrase(state.ratingFC, state.ratingFC) : Language.getPhrase('rating_clear', 'Clear');
		statsSummaryText.text = Language.getPhrase('pause_stats_summary',
			'Score: {1}\nHits: {2}\nMisses: {3}\nRating: {4}% - {5} [{6}]\nMax Combo: {7}\nCombo Breaks: {8}\nMode: {9}',
			[
				state.songScore,
				state.songHits,
				state.songMisses,
				Std.string(ratingPercent),
				ratingLabel,
				fcLabel,
				state.maxCombo,
				state.comboBreaks,
				getCurrentModeLabel()
			]);
	}

	function getCurrentModeLabel():String
	{
		var state = PlayState.instance;
		if (state == null)
			return Language.getPhrase('mode_standard', 'Standard');

		var modes:Array<String> = [];
		if (PlayState.chartingMode) modes.push(Language.getPhrase('charting_mode', 'Charting Mode'));
		if (state.practiceMode) modes.push(Language.getPhrase('practice_mode', 'Practice Mode'));
		if (state.cpuControlled) modes.push(Language.getPhrase('botplay', 'Botplay'));
		if (state.perfectMode) modes.push(Language.getPhrase('perfect_mode', 'Perfect Mode'));
		if (state.playOpponent) modes.push(Language.getPhrase('opponent_mode', 'Opponent Mode'));
		if (modes.length < 1) modes.push(Language.getPhrase('mode_standard', 'Standard'));
		return modes.join(' / ');
	}

	function setStatus(message:String, playSound:Bool = false):Void
	{
		statusText.text = message;
		if (playSound)
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
	}

	function requestClose(?callback:Void->Void):Void
	{
		pendingCloseAction = callback;
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
		FlxG.sound.play(Paths.sound('cancelMenu'));
		drawerTargetX = hiddenPanelX;
		backdropTargetAlpha = 0;
	}

	function updateBotplayText():Void
	{
		if (PlayState.instance.botplayTxt == null) return;

		if (PlayState.instance.cpuControlled)
			PlayState.instance.botplayTxt.text = Language.getPhrase('botplay', 'Botplay').toUpperCase();
		else if (PlayState.instance.practiceMode)
			PlayState.instance.botplayTxt.text = Language.getPhrase('practice_mode', 'Practice Mode').toUpperCase();
		else if (PlayState.instance.perfectMode)
			PlayState.instance.botplayTxt.text = Language.getPhrase('perfect_mode', 'Perfect Mode').toUpperCase();
		else if (PlayState.instance.playOpponent)
			PlayState.instance.botplayTxt.text = Language.getPhrase('opponent_mode', 'Opponent Mode').toUpperCase();

		PlayState.instance.botplayTxt.visible = (PlayState.instance.cpuControlled || PlayState.instance.practiceMode || PlayState.instance.perfectMode || PlayState.instance.playOpponent);
		PlayState.instance.botplayTxt.alpha = 1;
		PlayState.instance.botplaySine = 0;
	}

	function handleMenuAction(item:String):Void
	{
		if (cantUnpause > 0 && controls.controllerMode) return;

		if (isDifficultyMenu())
		{
			handleDifficultyChoice(item);
			return;
		}

		switch (item)
		{
			case 'Resume':
				Paths.clearUnusedMemory();
				if (ClientPrefs.data.pauseCountdown && PlayState.instance != null)
					PlayState.instance.resumingWithCountdown = true;
				requestClose();

			#if VIDEOS_ALLOWED
			case 'Skip Video':
				requestClose(function() {
					if (PlayState.instance.videoCutscene != null && PlayState.instance.videoCutscene.onSkip != null)
						PlayState.instance.videoCutscene.onSkip();
				});
			#end

			case 'Change Difficulty':
				currentItems = difficultyChoices;
				scrollTarget = 0;
				rebuildCards();
				var nextSelection:Int = curSelected;
				if (nextSelection > currentItems.length - 1)
					nextSelection = currentItems.length - 1;
				changeSelection(nextSelection, true);
				setStatus(Language.getPhrase('pause_pick_difficulty', 'Pick a difficulty'), true);

			case 'Toggle Practice Mode':
				PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
				PlayState.changedDifficulty = true;
				updateBotplayText();
				updateVisibleCards();
				refreshSummary();
				setStatus(getCardTitle(item) + ': ' + getCardValue(item), true);

			case 'Toggle Botplay':
				PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
				PlayState.changedDifficulty = true;
				updateBotplayText();
				updateVisibleCards();
				refreshSummary();
				setStatus(getCardTitle(item) + ': ' + getCardValue(item), true);

			case 'Restart Song':
				requestClose(function() restartSong());

			case 'Chart Editor':
				requestClose(function() PlayState.instance.openChartEditor());

			case 'Leave Charting Mode':
				requestClose(function() {
					PlayState.chartingMode = false;
					restartSong();
				});

			case 'Skip Time':
				if (curTime < Conductor.songPosition)
				{
					requestClose(function() {
						PlayState.startOnTime = curTime;
						restartSong(true);
					});
				}
				else
				{
					requestClose(function() {
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}
					});
				}

			case 'End Song':
				requestClose(function() {
					PlayState.instance.notes.clear();
					PlayState.instance.unspawnNotes = [];
					PlayState.instance.preloadedNotes = [];
					PlayState.instance.finishSong(true);
				});

			case 'Options':
				PlayState.instance.paused = true;
				PlayState.instance.vocals.volume = 0;
				PlayState.instance.canResync = false;
				MusicBeatState.switchState(new OptionsState());
				if (ClientPrefs.data.pauseMusic != 'None')
				{
					FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)), pauseMusic.volume);
					FlxTween.tween(FlxG.sound.music, {volume: 1}, 0.8);
					FlxG.sound.music.time = pauseMusic.time;
				}
				OptionsState.onPlayState = true;

			case 'Exit to menu':
				#if DISCORD_ALLOWED DiscordClient.resetClientID(); #end
				PlayState.deathCounter = 0;
				PlayState.seenCutscene = false;
				PlayState.instance.canResync = false;
				Mods.loadTopMod();
				if (PlayState.isStoryMode)
					MusicBeatState.switchState(new StoryMenuState());
				else if (ClientPrefs.data.newfreeplay)
					MusicBeatState.switchState(new FreeplayState());
				else
					MusicBeatState.switchState(new funkin.ui.freeplay.FreeplayState_Psych());

				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				PlayState.changedDifficulty = false;
				PlayState.chartingMode = false;
				FlxG.camera.followLerp = 0;
		}
	}

	function handleDifficultyChoice(item:String):Void
	{
		if (item == 'BACK')
		{
			currentItems = menuItemsOG.copy();
			scrollTarget = 0;
			rebuildCards();
			changeSelection(0, true);
			setStatus(Language.getPhrase('pause_status_ready', 'Paused'), true);
			return;
		}

		var diffIndex = currentItems.indexOf(item);
		var songLowercase = Paths.formatToSongPath(PlayState.SONG.song);
		var poop = Highscore.formatSong(songLowercase, diffIndex);
		try
		{
			Song.loadFromJson(poop, songLowercase);
			PlayState.storyDifficulty = diffIndex;
			FlxG.sound.music.volume = 0;
			PlayState.changedDifficulty = true;
			PlayState.chartingMode = false;
			requestClose(function() MusicBeatState.resetState());
		}
		catch (e:haxe.Exception)
		{
			var errorStr = e.message;
			if (errorStr.startsWith('[lime.utils.Assets] ERROR:'))
				errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length - 1);
			else
				errorStr += '\n\n' + e.stack;

			missingText.text = 'ERROR WHILE LOADING CHART:\n' + errorStr;
			missingText.screenCenter(Y);
			missingText.visible = true;
			missingTextBG.visible = true;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	function adjustSkipTime(elapsed:Float):Void
	{
		if (!canControlTimeSlider() || currentItems[curSelected] != 'Skip Time')
		{
			holdTime = 0;
			return;
		}

		if (controls.UI_LEFT_P || (touchPad != null && touchPad.buttonLeft.justPressed))
		{
			curTime -= 1000;
			holdTime = 0;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		if (controls.UI_RIGHT_P || (touchPad != null && touchPad.buttonRight.justPressed))
		{
			curTime += 1000;
			holdTime = 0;
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		var leftHeld = controls.UI_LEFT || (touchPad != null && touchPad.buttonLeft.pressed);
		var rightHeld = controls.UI_RIGHT || (touchPad != null && touchPad.buttonRight.pressed);
		if (leftHeld || rightHeld)
		{
			holdTime += elapsed;
			if (holdTime > 0.5)
				curTime += 45000 * elapsed * (leftHeld ? -1 : 1);
		}
		else holdTime = 0;

		curTime = FlxMath.bound(curTime, 0, getSongLength());
		updateVisibleCards();
		refreshSummary();
	}

	function handleMouseCards():Void
	{
		#if FLX_MOUSE
		if (!FlxG.mouse.justPressed) return;
		var point = FlxG.mouse.getScreenPosition();
		for (index in 0...cards.length)
		{
			var card = cards[index];
			if (!card.visible || !card.containsPoint(point)) continue;
			if (index == curSelected) handleMenuAction(currentItems[curSelected]);
			else changeSelection(index);
			return;
		}
		#end
	}

	override function update(elapsed:Float):Void
	{
		cantUnpause -= elapsed;
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);
		drawerX = approach(drawerX, drawerTargetX, elapsed * 14);
		backdrop.alpha = approach(backdrop.alpha, backdropTargetAlpha, elapsed * 16);
		refreshCardPositions();
		refreshSummary();

		if (isClosing && Math.abs(drawerX - hiddenPanelX) < 1.5 && backdrop.alpha < 0.02)
		{
			var callback = pendingCloseAction;
			pendingCloseAction = null;
			allowImmediateClose = true;
			super.close();
			if (callback != null)
				callback();
			return;
		}

		if (isClosing) return;

		if (FlxG.keys.justPressed.F5)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			PlayState.nextReloadAll = true;
			MusicBeatState.resetState();
			return;
		}

		#if mobile
		if (touchScroll != null)
		{
			var scrollDelta = touchScroll.update();
			if (Math.abs(scrollDelta) > 0.5)
			{
				scrollTarget += -scrollDelta / 5;
				scrollTarget = FlxMath.bound(scrollTarget, getMinScroll(), 0);
			}
		}
		#end

		handleMouseCards();

		if (controls.BACK || (touchPad != null && touchPad.buttonB.justPressed))
		{
			requestClose();
			return;
		}

		if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed)) moveSelection(-1);
		if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed)) moveSelection(1);

		adjustSkipTime(elapsed);

		if (controls.ACCEPT || (touchPad != null && touchPad.buttonA.justPressed))
			handleMenuAction(currentItems[curSelected]);

		if (touchPad == null)
		{
			addTouchPad('LEFT_FULL', 'A_B');
			addTouchPadCamera();
		}
	}

	public static function restartSong(noTrans:Bool = false):Void
	{
		PlayState.instance.paused = true;
		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if (noTrans)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
		}
		MusicBeatState.resetState();
	}

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

		pauseMusic.destroy();
		pendingCloseAction = null;
		super.destroy();
	}

	inline function approach(current:Float, target:Float, speed:Float):Float
	{
		return current + (target - current) * (1 - Math.exp(-speed));
	}
}

private class PauseActionCard extends FlxSpriteGroup
{
	static inline var CONTENT_OFFSET_Y:Float = 6;
	static inline var BAR_X:Float = 16;
	static inline var BAR_Y:Float = 16 + CONTENT_OFFSET_Y;
	static inline var BAR_WIDTH:Int = 6;
	static inline var TITLE_X:Float = 30;
	static inline var TITLE_Y:Float = 12 + CONTENT_OFFSET_Y;
	static inline var DESCRIPTION_X:Float = 30;
	static inline var DESCRIPTION_Y:Float = 36 + CONTENT_OFFSET_Y;
	static inline var VALUE_WIDTH:Float = 126;
	static inline var VALUE_Y:Float = 16 + CONTENT_OFFSET_Y;
	static inline var SIDE_PADDING:Float = 24;
	static inline var VALUE_GAP:Float = 18;

	public var item(default, null):String;
	public var cardWidth(default, null):Float;
	public var cardHeight(default, null):Float;

	var background:FlxSprite;
	var outline:FlxSprite;
	var accentBar:FlxSprite;
	var titleText:FlxText;
	var descriptionText:FlxText;
	var valueText:FlxText;
	var selected:Bool = false;

	public function new(width:Float, item:String)
	{
		super();
		this.item = item;
		cardWidth = width;
		cardHeight = 86;

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		outline = new FlxSprite();
		outline.antialiasing = ClientPrefs.data.antialiasing;
		add(outline);

		accentBar = new FlxSprite(BAR_X, BAR_Y);
		accentBar.antialiasing = ClientPrefs.data.antialiasing;
		add(accentBar);

		titleText = new FlxText(TITLE_X, TITLE_Y, width - 60, '', 17);
		titleText.setFormat(Paths.font('inter-bold.otf'), 18, 0xFF2C1E48, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		descriptionText = new FlxText(DESCRIPTION_X, DESCRIPTION_Y, width - 60, '', 12);
		descriptionText.setFormat(Paths.font('inter.otf'), 12, 0xFF76678B, LEFT);
		descriptionText.antialiasing = ClientPrefs.data.antialiasing;
		add(descriptionText);

		valueText = new FlxText(width - VALUE_WIDTH - SIDE_PADDING, VALUE_Y, VALUE_WIDTH, '', 12);
		valueText.setFormat(Paths.font('inter-bold.otf'), 13, OptionsMenuTheme.current().accent, RIGHT);
		valueText.antialiasing = ClientPrefs.data.antialiasing;
		add(valueText);

		redraw();
	}

	public function setPinned(cameraList:Array<FlxCamera>):Void
	{
		cameras = cameraList;
		scrollFactor.set();
		for (member in members)
		{
			if (member != null)
			{
				member.cameras = cameraList;
				member.scrollFactor.set();
			}
		}
	}

	public function refresh(title:String, description:String, value:String):Void
	{
		var hasValue = value != null && value.length > 0;
		var textWidth = hasValue ? cardWidth - (TITLE_X + SIDE_PADDING + VALUE_WIDTH + VALUE_GAP) : cardWidth - 60;
		titleText.text = title;
		titleText.fieldWidth = textWidth;
		descriptionText.text = description;
		descriptionText.fieldWidth = textWidth;
		valueText.text = value;
		valueText.visible = hasValue;
		cardHeight = Math.max(86, DESCRIPTION_Y + descriptionText.height + 18);
		valueText.x = cardWidth - VALUE_WIDTH - SIDE_PADDING;
		valueText.y = Math.max(VALUE_Y, (cardHeight - valueText.height) * 0.5 - 1);
		redraw();
	}

	function redraw():Void
	{
		var palette = OptionsMenuTheme.current();
		var blackTheme = palette.name == 'Black';
		var fill = blackTheme ? (selected ? 0xFF181B20 : 0xFF101216) : (selected ? palette.mist : 0xFFFCF8FF);
		var stroke = blackTheme ? (selected ? palette.accent : 0xFF30343C) : (selected ? palette.accent : 0xFFDCCEEB);
		var accent = blackTheme ? (selected ? palette.accent : 0xFF434852) : (selected ? palette.accent : palette.pale);
		var accentHeight = Std.int(Math.max(18, cardHeight - 32));
		MD3ShapeTools.fillRoundRect(background, Std.int(cardWidth), Std.int(cardHeight), 24, fill);
		MD3ShapeTools.strokeRoundRect(outline, Std.int(cardWidth), Std.int(cardHeight), 24, 2, stroke);
		accentBar.x = BAR_X;
		accentBar.y = BAR_Y;
		MD3ShapeTools.fillRoundRect(accentBar, BAR_WIDTH, accentHeight, 4, accent);
		accentBar.alpha = selected ? 1.0 : 0.72;
		titleText.color = blackTheme ? (selected ? 0xFFF5F7FA : 0xFFE6EAF0) : (selected ? palette.strong : 0xFF402D61);
		descriptionText.color = blackTheme ? (selected ? 0xFFC4CBD6 : 0xFF99A1AE) : (selected ? palette.muted : 0xFF7B6D93);
		valueText.color = blackTheme ? (selected ? palette.accent : 0xFFB7BEC9) : (selected ? palette.accent : 0xFF7B6D93);
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
		if (topCut <= 0 && bottomCut <= 0)
			clipRect = null;
		else
			clipRect = new FlxRect(0, topCut, cardWidth, visibleHeight);
	}

	public function containsPoint(point:FlxPoint):Bool
	{
		return point.x >= x && point.x <= x + cardWidth && point.y >= y && point.y <= y + cardHeight;
	}
}