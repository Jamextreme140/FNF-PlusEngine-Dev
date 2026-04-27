package funkin.ui.options;

import Main;
import StringTools;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.play.notes.Note;
import funkin.play.notes.NoteSplash;
import funkin.play.notes.StrumNote;
import funkin.ui.MusicBeatSubstate;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialNumericStepper;
import funkin.ui.components.md3.MaterialSlider;
import funkin.ui.components.md3.MaterialSwitch;

class VisualsSettingsSubState extends MusicBeatSubstate
{
	static var lastSelected:Int = 0;

	var backdrop:FlxSprite;
	var menuBG:FlxSprite;
	var panelShadow:FlxSprite;
	var panelSurface:FlxSprite;
	var panelHeader:FlxSprite;
	var panelOutline:FlxSprite;
	var previewSurface:FlxSprite;
	var previewOutline:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var previewTitleText:FlxText;
	var previewHintText:FlxText;
	var footerText:FlxText;
	var statusText:FlxText;
	var closeButton:MaterialButton;

	var cardLayer:FlxTypedGroup<VisualsSettingsCard>;
	var overlayLayer:FlxSpriteGroup;
	var cards:Array<VisualsSettingsCard> = [];
	var activeDropdown:VisualsDropdownMenu;

	var notes:FlxTypedGroup<StrumNote>;
	var splashes:FlxTypedGroup<NoteSplash>;
	var changedMusic:Bool = false;

	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelWidth:Float = 0;
	var panelHeight:Float = 0;
	var previewX:Float = 0;
	var previewY:Float = 0;
	var previewWidth:Float = 0;
	var previewHeight:Float = 0;
	var contentTop:Float = 0;
	var contentBottom:Float = 0;
	var cardWidth:Float = 0;
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
		DiscordClient.changePresence('Visuals Settings Menu', null);
		#end

		OptionsMenuTheme.syncAccent();

		buildChrome();
		buildPreview();
		buildCards();
		changeSelection(lastSelected, true);
		refreshCardPositions(true);
		refreshAccentTheme();
		onChangeNoteSkin();
		onChangeSplashSkin();
		onChangeQuantization();

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
		previewX = panelX + 28;
		previewY = panelY + 118;
		previewWidth = panelWidth - 56;
		previewHeight = 112;
		contentTop = previewY + previewHeight + 16;
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

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, Language.getPhrase('visuals_menu', 'Visuals Settings'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			Language.getPhrase('visuals_menu_subtitle', 'HUD, note skins, splash behaviour, pause music and all the visual seasoning live here now, with room to breathe.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, Language.getPhrase('close', 'Close'), TEXT, 110, closeAndSave);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 330, panelY + 66, 290, Language.getPhrase('visuals_preview_ready', 'Preview ready'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		previewSurface = new FlxSprite(previewX, previewY);
		MD3ShapeTools.fillRoundRect(previewSurface, Std.int(previewWidth), Std.int(previewHeight), 26, OptionsMenuTheme.previewSurfaceColor());
		add(previewSurface);

		previewOutline = new FlxSprite(previewX, previewY);
		MD3ShapeTools.strokeRoundRect(previewOutline, Std.int(previewWidth), Std.int(previewHeight), 26, 2, OptionsMenuTheme.neutralOutlineColor());
		add(previewOutline);

		previewTitleText = new FlxText(previewX + 24, previewY + 16, 280, Language.getPhrase('visuals_live_preview', 'Live Preview'), 18);
		previewTitleText.setFormat(Paths.font('inter-bold.otf'), 18, OptionsMenuTheme.previewTitleColor(), LEFT);
		previewTitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(previewTitleText);

		previewHintText = new FlxText(previewX + 24, previewY + 42, previewWidth - 48,
			Language.getPhrase('visuals_live_preview_hint', 'Note skins, splash skins, splash opacity and quantization update here in real time.'), 13);
		previewHintText.setFormat(Paths.font('inter.otf'), 13, OptionsMenuTheme.previewHintColor(), LEFT);
		previewHintText.antialiasing = ClientPrefs.data.antialiasing;
		add(previewHintText);

		cardLayer = new FlxTypedGroup<VisualsSettingsCard>();
		add(cardLayer);

		overlayLayer = new FlxSpriteGroup();
		add(overlayLayer);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			Language.getPhrase('visuals_menu_footer', 'ARROWS move. LEFT/RIGHT adjust. ENTER toggles or opens. R resets the selected option. ESC returns.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);
	}

	function buildPreview():Void
	{
		notes = new FlxTypedGroup<StrumNote>();
		splashes = new FlxTypedGroup<NoteSplash>();
		add(notes);
		add(splashes);

		var spacing:Float = 110;
		var startX:Float = previewX + previewWidth - 496;
		var noteY:Float = previewY + 42;

		for (i in 0...Note.colArray.length)
		{
			var note:StrumNote = new StrumNote(startX + spacing * i, noteY, i, 0);
			note.setGraphicSize(Std.int(note.width * 0.9));
			note.updateHitbox();
			changeNoteSkin(note);
			notes.add(note);

			var splash:NoteSplash = new NoteSplash(0, 0, NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix());
			splash.inEditor = true;
			splash.babyArrow = note;
			splash.ID = i;
			splash.kill();
			splashes.add(splash);
		}
	}

	function buildCards():Void
	{
		var cardY:Float = contentTop;
		var cardX:Float = panelX + 28;

		var noteSkins:Array<String> = Mods.mergeAllTextsNamed('images/noteSkins/list.txt');
		if (noteSkins.length > 0)
		{
			if (!noteSkins.contains(ClientPrefs.data.noteSkin))
				ClientPrefs.data.noteSkin = ClientPrefs.defaultData.noteSkin;
			prependUnique(noteSkins, ClientPrefs.defaultData.noteSkin);
			cardY = addCard(new VisualsChoiceCard('noteSkin', Language.getPhrase('setting_note_skins', 'Note Skins:'), Language.getPhrase('description_note_skins', 'Select your preferred Note skin.'), cardWidth, noteSkins, ClientPrefs.data.noteSkin, ClientPrefs.defaultData.noteSkin, openChoiceMenu, function(value:String) {
				ClientPrefs.data.noteSkin = value;
				onChangeNoteSkin();
				saveSetting('Note Skin: ' + value);
			}, 'note_skins'), cardX, cardY);
		}

		cardY = addCard(new VisualsSwitchCard('noteRGB', Language.getPhrase('setting_note_rgb', 'Note RGB Shader'), Language.getPhrase('description_note_rgb', 'If checked, notes use the RGB palette shader. Disable it to keep their original colors when possible.'), cardWidth, ClientPrefs.data.noteRGB, ClientPrefs.defaultData.noteRGB, function(value:Bool) {
			ClientPrefs.data.noteRGB = value;
			onChangeNoteRGB();
			saveSetting('Note RGB Shader ' + boolLabel(value));
		}), cardX, cardY);

		var noteSplashes:Array<String> = Mods.mergeAllTextsNamed('images/noteSplashes/list.txt');
		if (noteSplashes.length > 0)
		{
			if (!noteSplashes.contains(ClientPrefs.data.splashSkin))
				ClientPrefs.data.splashSkin = ClientPrefs.defaultData.splashSkin;
			prependUnique(noteSplashes, ClientPrefs.defaultData.splashSkin);
			cardY = addCard(new VisualsChoiceCard('splashSkin', Language.getPhrase('setting_note_splashes', 'Note Splashes:'), Language.getPhrase('description_note_splashes', 'Select your preferred Note Splash variation.'), cardWidth, noteSplashes, ClientPrefs.data.splashSkin, ClientPrefs.defaultData.splashSkin, openChoiceMenu, function(value:String) {
				ClientPrefs.data.splashSkin = value;
				onChangeSplashSkin();
				saveSetting('Note Splashes: ' + value);
			}, 'note_splashes'), cardX, cardY);
		}

		cardY = addCard(new VisualsSliderCard('splashAlpha', Language.getPhrase('setting_note_splash_opacity', 'Note Splash Opacity'), Language.getPhrase('description_note_splash_opacity', 'How transparent note splashes should be.'), cardWidth, ClientPrefs.data.splashAlpha, ClientPrefs.defaultData.splashAlpha, 0.0, 1.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.splashAlpha = value;
			playNoteSplashes();
			saveSetting('Note Splash Opacity: ' + percentLabel(value));
		}), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('colorQuantization', Language.getPhrase('setting_color_quantization', 'Color Quantization'), Language.getPhrase('description_color_quantization', 'If checked, notes are colored by rhythm subdivision like StepMania and override default arrow colors.'), cardWidth, ClientPrefs.data.colorQuantization, ClientPrefs.defaultData.colorQuantization, function(value:Bool) {
			ClientPrefs.data.colorQuantization = value;
			onChangeQuantization();
			saveSetting('Color Quantization ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new VisualsChoiceCard('menuAccentColor', Language.getPhrase('setting_menu_accent_color', 'Menu Accent Color'), Language.getPhrase('description_menu_accent_color', 'Pick the accent tint used by these refreshed options menus.'), cardWidth, OptionsMenuTheme.ACCENT_CHOICES, OptionsMenuTheme.normalizeAccent(ClientPrefs.data.menuAccentColor), OptionsMenuTheme.normalizeAccent(ClientPrefs.defaultData.menuAccentColor), openChoiceMenu, function(value:String) {
			onChangeMenuAccent(value);
		}, 'menu_accent_color'), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('menuDarkTheme', Language.getPhrase('setting_menu_dark_theme', 'Dark Theme'), Language.getPhrase('description_menu_dark_theme', 'Uses darker surfaces for the refreshed options and pause menus.'), cardWidth, ClientPrefs.data.menuDarkTheme, ClientPrefs.defaultData.menuDarkTheme, function(value:Bool) {
			onChangeMenuDarkTheme(value);
		}), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('hideHud', Language.getPhrase('setting_hide_hud', 'Hide HUD'), Language.getPhrase('description_hide_hud', 'If checked, hides most HUD elements.'), cardWidth, ClientPrefs.data.hideHud, ClientPrefs.defaultData.hideHud, function(value:Bool) { ClientPrefs.data.hideHud = value; saveSetting('Hide HUD ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('hideSustainSplash', Language.getPhrase('setting_hide_sustain_splash', 'Hide Sustain Splash'), Language.getPhrase('description_hide_sustain_splash', 'If checked, hides Sustain Splash.'), cardWidth, ClientPrefs.data.hideSustainSplash, ClientPrefs.defaultData.hideSustainSplash, function(value:Bool) { ClientPrefs.data.hideSustainSplash = value; saveSetting('Hide Sustain Splash ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('showKeyViewer', Language.getPhrase('setting_show_key_viewer', 'Show Key Viewer'), Language.getPhrase('description_show_key_viewer', 'If checked, shows a key viewer displaying which keys are being pressed.'), cardWidth, ClientPrefs.data.showKeyViewer, ClientPrefs.defaultData.showKeyViewer, function(value:Bool) { ClientPrefs.data.showKeyViewer = value; saveSetting('Show Key Viewer ' + boolLabel(value)); }), cardX, cardY);

		cardY = addCard(new VisualsChoiceCard('keyViewerColor', Language.getPhrase('setting_key_viewer_color', 'Key Viewer Color:'), Language.getPhrase('description_key_viewer_color', 'Select the color for the key viewer buttons.'), cardWidth, ['Gray', 'Red', 'Blue', 'Green', 'Purple', 'Orange', 'Pink', 'Cyan', 'White', 'Black'], ClientPrefs.data.keyViewerColor, ClientPrefs.defaultData.keyViewerColor, openChoiceMenu, function(value:String) {
			ClientPrefs.data.keyViewerColor = value;
			onChangeKeyViewerColor();
			saveSetting('Key Viewer Color: ' + value);
		}, 'key_viewer_color'), cardX, cardY);

		cardY = addCard(new VisualsChoiceCard('iconBounceType', Language.getPhrase('setting_icon_bounce', 'Icon Bounce'), Language.getPhrase('description_icon_bounce', 'Select the icon bounce style you prefer. Scripts using this may expect the default value.'), cardWidth, ['Default', 'D&B', 'Old', 'NF'], ClientPrefs.data.iconBounceType, ClientPrefs.defaultData.iconBounceType, openChoiceMenu, function(value:String) {
			ClientPrefs.data.iconBounceType = value;
			saveSetting('Icon Bounce: ' + value);
		}, 'icon_bounce'), cardX, cardY);

		cardY = addCard(new VisualsChoiceCard('timeBarType', Language.getPhrase('setting_time_bar', 'Time Bar:'), Language.getPhrase('description_time_bar', 'Choose what the time bar displays during gameplay.'), cardWidth, ['Time Left', 'Time Elapsed', 'Song Name', 'Disabled'], ClientPrefs.data.timeBarType, ClientPrefs.defaultData.timeBarType, openChoiceMenu, function(value:String) {
			ClientPrefs.data.timeBarType = value;
			saveSetting('Time Bar: ' + value);
		}, 'time_bar'), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('shadedTimeBar', Language.getPhrase('setting_gradient_time_bar', 'Gradient Time Bar'), Language.getPhrase('description_gradient_time_bar', 'If checked, the time bar is shaded according to the character icon colors.'), cardWidth, ClientPrefs.data.shadedTimeBar, ClientPrefs.defaultData.shadedTimeBar, function(value:Bool) { ClientPrefs.data.shadedTimeBar = value; saveSetting('Gradient Time Bar ' + boolLabel(value)); }), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('flashing', Language.getPhrase('setting_flashing_lights', 'Flashing Lights'), Language.getPhrase('description_flashing_lights', 'Disable this if you are sensitive to flashing lights.'), cardWidth, ClientPrefs.data.flashing, ClientPrefs.defaultData.flashing, function(value:Bool) { ClientPrefs.data.flashing = value; saveSetting('Flashing Lights ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('camZooms', Language.getPhrase('setting_camera_zooms', 'Camera Zooms'), Language.getPhrase('description_camera_zooms', 'If unchecked, the camera will not zoom in on beat hits.'), cardWidth, ClientPrefs.data.camZooms, ClientPrefs.defaultData.camZooms, function(value:Bool) { ClientPrefs.data.camZooms = value; saveSetting('Camera Zooms ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('scoreZoom', Language.getPhrase('setting_score_text_grow_on_hit', 'Score Text Grow on Hit'), Language.getPhrase('description_score_text_grow_on_hit', 'If unchecked, disables the score text growing every time you hit a note.'), cardWidth, ClientPrefs.data.scoreZoom, ClientPrefs.defaultData.scoreZoom, function(value:Bool) { ClientPrefs.data.scoreZoom = value; saveSetting('Score Text Grow on Hit ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('timeBump', Language.getPhrase('setting_time_text_bump', 'Time Text Bump'), Language.getPhrase('description_time_text_bump', 'If unchecked, disables the time text bump animation on beat.'), cardWidth, ClientPrefs.data.timeBump, ClientPrefs.defaultData.timeBump, function(value:Bool) { ClientPrefs.data.timeBump = value; saveSetting('Time Text Bump ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('abbreviateScore', Language.getPhrase('setting_abbreviate_score', 'Abbreviate Score'), Language.getPhrase('description_abbreviate_score', 'If enabled, the score is abbreviated like 10.00K or 1.00M.'), cardWidth, ClientPrefs.data.abbreviateScore, ClientPrefs.defaultData.abbreviateScore, function(value:Bool) { ClientPrefs.data.abbreviateScore = value; saveSetting('Abbreviate Score ' + boolLabel(value)); }), cardX, cardY);

		cardY = addCard(new VisualsSliderCard('healthBarAlpha', Language.getPhrase('setting_health_bar_opacity', 'Health Bar Opacity'), Language.getPhrase('description_health_bar_opacity', 'How transparent the health bar and icons should be.'), cardWidth, ClientPrefs.data.healthBarAlpha, ClientPrefs.defaultData.healthBarAlpha, 0.0, 1.0, 0.1, 1, function(value:Float) {
			ClientPrefs.data.healthBarAlpha = value;
			saveSetting('Health Bar Opacity: ' + percentLabel(value));
		}), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('smoothHealthBar', Language.getPhrase('setting_smooth_health_bar', 'Smooth Health Bar'), Language.getPhrase('description_smooth_health_bar', 'If checked, the health bar moves smoothly instead of instantly.'), cardWidth, ClientPrefs.data.smoothHealthBar, ClientPrefs.defaultData.smoothHealthBar, function(value:Bool) { ClientPrefs.data.smoothHealthBar = value; saveSetting('Smooth Health Bar ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('smoothHPBug', Language.getPhrase('setting_health_bar_overflow', 'Health Bar Overflow'), Language.getPhrase('description_health_bar_overflow', 'If checked, health icons can go outside the bar edges on health spikes.'), cardWidth, ClientPrefs.data.smoothHPBug, ClientPrefs.defaultData.smoothHPBug, function(value:Bool) { ClientPrefs.data.smoothHPBug = value; saveSetting('Health Bar Overflow ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('showWatermark', Language.getPhrase('setting_show_watermark', 'Show Watermark'), Language.getPhrase('description_show_watermark', 'If checked, shows the watermark on screen.'), cardWidth, ClientPrefs.data.showWatermark, ClientPrefs.defaultData.showWatermark, function(value:Bool) { ClientPrefs.data.showWatermark = value; onChangeWatermark(); saveSetting('Show Watermark ' + boolLabel(value)); }), cardX, cardY);

		cardY = addCard(new VisualsChoiceCard('pauseMusic', Language.getPhrase('setting_pause_music', 'Pause Music:'), Language.getPhrase('description_pause_music', 'Choose the song used in the pause screen.'), cardWidth, ['None', 'Tea Time', 'Breakfast', 'Breakfast (Pico)'], ClientPrefs.data.pauseMusic, ClientPrefs.defaultData.pauseMusic, openChoiceMenu, function(value:String) {
			ClientPrefs.data.pauseMusic = value;
			onChangePauseMusic();
			saveSetting('Pause Music: ' + value);
		}, 'pause_music'), cardX, cardY);

		#if CHECK_FOR_UPDATES
		cardY = addCard(new VisualsSwitchCard('checkForUpdates', Language.getPhrase('setting_check_for_updates', 'Check for Updates'), Language.getPhrase('description_check_for_updates', 'On release builds, checks for updates when you start the game.'), cardWidth, ClientPrefs.data.checkForUpdates, ClientPrefs.defaultData.checkForUpdates, function(value:Bool) { ClientPrefs.data.checkForUpdates = value; saveSetting('Check for Updates ' + boolLabel(value)); }), cardX, cardY);
		#end

		#if DISCORD_ALLOWED
		cardY = addCard(new VisualsSwitchCard('discordRPC', Language.getPhrase('setting_discord_rich_presence', 'Discord Rich Presence'), Language.getPhrase('description_discord_rich_presence', 'Disable this to prevent accidental leaks and hide the application from Discord status.'), cardWidth, ClientPrefs.data.discordRPC, ClientPrefs.defaultData.discordRPC, function(value:Bool) { ClientPrefs.data.discordRPC = value; saveSetting('Discord Rich Presence ' + boolLabel(value)); }), cardX, cardY);
		#end

		cardY = addCard(new VisualsSwitchCard('comboStacking', Language.getPhrase('setting_combo_stacking', 'Combo Stacking'), Language.getPhrase('description_combo_stacking', 'If unchecked, ratings and combo do not stack, saving memory and making them easier to read.'), cardWidth, ClientPrefs.data.comboStacking, ClientPrefs.defaultData.comboStacking, function(value:Bool) { ClientPrefs.data.comboStacking = value; saveSetting('Combo Stacking ' + boolLabel(value)); }), cardX, cardY);
		cardY = addCard(new VisualsSwitchCard('showCombo', Language.getPhrase('setting_show_combo_sprite', 'Show Combo Sprite'), Language.getPhrase('description_show_combo_sprite', 'If checked, shows the COMBO sprite when you hit notes.'), cardWidth, ClientPrefs.data.showCombo, ClientPrefs.defaultData.showCombo, function(value:Bool) { ClientPrefs.data.showCombo = value; saveSetting('Show Combo Sprite ' + boolLabel(value)); }), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('comboInGame', Language.getPhrase('setting_combo_in_game', 'Combo and Rating in camGame'), Language.getPhrase('description_combo_in_game', 'If enabled, combo and ratings render in camGame instead of camHUD.'), cardWidth, ClientPrefs.data.comboInGame, ClientPrefs.defaultData.comboInGame, function(value:Bool) {
			ClientPrefs.data.comboInGame = value;
			if (PlayState.instance != null && PlayState.instance.comboGroup != null)
				PlayState.instance.comboGroup.cameras = [value ? PlayState.instance.camGame : PlayState.instance.camHUD];
			saveSetting('Combo and Rating in camGame ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('judgementCounter', Language.getPhrase('setting_judgement_counter', 'Judgement Counter'), Language.getPhrase('description_judgement_counter', 'Shows the judgement counter during gameplay.'), cardWidth, ClientPrefs.data.judgementCounter, ClientPrefs.defaultData.judgementCounter, function(value:Bool) {
			ClientPrefs.data.judgementCounter = value;
			ClientPrefs.judgementCounter = value;
			saveSetting('Judgement Counter ' + boolLabel(value));
		}), cardX, cardY);

		cardY = addCard(new VisualsSwitchCard('showEndCountdown', Language.getPhrase('setting_show_end_countdown', 'Show End Countdown'), Language.getPhrase('description_show_end_countdown', 'If checked, shows a countdown in the last seconds of the song.'), cardWidth, ClientPrefs.data.showEndCountdown, ClientPrefs.defaultData.showEndCountdown, function(value:Bool) { ClientPrefs.data.showEndCountdown = value; saveSetting('Show End Countdown ' + boolLabel(value)); }), cardX, cardY);

		cardY = addCard(new VisualsStepperCard('endCountdownSeconds', Language.getPhrase('setting_end_countdown_seconds', 'End Countdown Seconds'), Language.getPhrase('description_end_countdown_seconds', 'How many seconds before the song ends the countdown appears.'), cardWidth, ClientPrefs.data.endCountdownSeconds, ClientPrefs.defaultData.endCountdownSeconds, 10, 30, 1, function(value:Int) {
			ClientPrefs.data.endCountdownSeconds = value;
			saveSetting('End Countdown Seconds: ' + value + 's');
		}), cardX, cardY);

		#if windows
		cardY = addCard(new VisualsSwitchCard('changeWindowBorderColorWithNoteHit', Language.getPhrase('setting_change_window_border_color_with_note_hit', 'Change Window Border Color With Note Hit'), Language.getPhrase('description_change_window_border_color_with_note_hit', 'Changes the window border color when you hit a note. Windows 11 only.'), cardWidth, ClientPrefs.data.changeWindowBorderColorWithNoteHit, ClientPrefs.defaultData.changeWindowBorderColorWithNoteHit, function(value:Bool) { ClientPrefs.data.changeWindowBorderColorWithNoteHit = value; saveSetting('Window Border Color With Note Hit ' + boolLabel(value)); }), cardX, cardY);
		#end

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function prependUnique(list:Array<String>, value:String):Void
	{
		list.remove(value);
		list.insert(0, value);
	}

	function addCard(card:VisualsSettingsCard, x:Float, y:Float):Float
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

	function refreshPreviewAccent():Void
	{
		if (cards.length == 0) return;
		var palette = OptionsMenuTheme.current();
		var focusPreview = switch (cards[selectedCard].settingId)
		{
			case 'noteSkin', 'splashSkin', 'splashAlpha', 'colorQuantization', 'menuAccentColor': true;
			default: false;
		};
		MD3ShapeTools.strokeRoundRect(previewOutline, Std.int(previewWidth), Std.int(previewHeight), 26, 2, focusPreview ? palette.accent : OptionsMenuTheme.neutralOutlineColor());
		previewHintText.color = OptionsMenuTheme.previewHintColor(focusPreview);
	}

	function refreshAccentTheme():Void
	{
		var palette = OptionsMenuTheme.current();
		menuBG.color = palette.pale;
		menuBG.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		backdrop.makeGraphic(FlxG.width, FlxG.height, OptionsMenuTheme.backdropColor());
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 34, OptionsMenuTheme.panelSurfaceColor());
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 108, 34, 34, 0, 0, OptionsMenuTheme.panelHeaderColor());
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 34, 2, OptionsMenuTheme.panelOutlineColor());
		MD3ShapeTools.fillRoundRect(previewSurface, Std.int(previewWidth), Std.int(previewHeight), 26, OptionsMenuTheme.previewSurfaceColor());
		titleText.color = OptionsMenuTheme.titleColor();
		subtitleText.color = OptionsMenuTheme.bodyTextColor();
		statusText.color = OptionsMenuTheme.bodyTextColor();
		footerText.color = OptionsMenuTheme.footerTextColor();
		previewTitleText.color = OptionsMenuTheme.previewTitleColor();

		for (index in 0...cards.length)
			cards[index].setSelected(index == selectedCard, true);

		refreshPreviewAccent();
	}

	function openChoiceMenu(card:VisualsChoiceCard):Void
	{
		closeActiveDropdown();
		var menuY = card.getAnchorY() + 52;
		var menuHeight = VisualsDropdownMenu.getTotalHeight(card.options.length);
		if (menuY + menuHeight > contentBottom) menuY = card.getAnchorY() - menuHeight - 10;
		if (menuY < contentTop) menuY = contentTop;
		activeDropdown = new VisualsDropdownMenu(card.getAnchorX(), menuY, card.getAnchorWidth(), overlayLayer, card.options, card.currentValue, function(value:String) {
			card.setValueLabel(value);
		}, function() {
			activeDropdown = null;
		}, card.getOptionLabel);
		overlayLayer.add(activeDropdown);
		announce(card.titleText.text + Language.getPhrase('visuals_menu_opened_suffix', ' menu opened'), false);
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
		for (index in 0...cards.length) cards[index].setSelected(index == selectedCard, instant);
		statusText.text = cards[selectedCard].titleText.text;
		refreshPreviewAccent();
	}

	function moveSelection(change:Int):Void
	{
		changeSelection(selectedCard + change);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
	}

	function onChangeMenuAccent(value:String):Void
	{
		ClientPrefs.data.menuAccentColor = OptionsMenuTheme.normalizeAccent(value);
		OptionsMenuTheme.syncAccent();
		refreshAccentTheme();
		saveSetting('Menu Accent Color: ' + ClientPrefs.data.menuAccentColor);
	}

	function onChangeMenuDarkTheme(value:Bool):Void
	{
		ClientPrefs.data.menuDarkTheme = value;
		OptionsMenuTheme.syncAccent();
		refreshAccentTheme();
		saveSetting('Dark Theme ' + boolLabel(value));
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

	function onChangePauseMusic():Void
	{
		if (ClientPrefs.data.pauseMusic == 'None') FlxG.sound.music.volume = 0;
		else FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.pauseMusic)));
		changedMusic = true;
	}

	function onChangeNoteSkin():Void
	{
		notes.forEachAlive(function(note:StrumNote) {
			changeNoteSkin(note);
			note.centerOffsets();
			note.centerOrigin();
		});
		onChangeNoteRGB();
	}

	function onChangeNoteRGB():Void
	{
		onChangeQuantization();
	}

	function changeNoteSkin(note:StrumNote):Void
	{
		var skin:String = Note.defaultNoteSkin;
		var postfix:String = Note.getNoteSkinPostfix();
		if (postfix.length > 0)
		{
			var customSkin:String = skin + postfix;
			if (Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		}
		note.texture = skin;
		note.playAnim('static');
		note.refreshColorMode();
	}

	function onChangeSplashSkin():Void
	{
		var skin:String = NoteSplash.defaultNoteSplash + NoteSplash.getSplashSkinPostfix();
		for (splash in splashes) splash.loadSplash(skin);
		playNoteSplashes();
	}

	function playNoteSplashes():Void
	{
		var rand:Int = 0;
		if (splashes.members[0] != null && splashes.members[0].maxAnims > 1) rand = FlxG.random.int(0, splashes.members[0].maxAnims - 1);
		for (splash in splashes)
		{
			splash.revive();
			splash.spawnSplashNote(0, 0, splash.ID, null, false);
			if (splash.maxAnims > 1) splash.noteData = splash.noteData % Note.colArray.length + (rand * Note.colArray.length);
			var anim:String = splash.playDefaultAnim();
			var conf = splash.config.animations.get(anim);
			var offsets:Array<Float> = [0, 0];
			var minFps:Int = 22;
			var maxFps:Int = 26;
			if (conf != null)
			{
				offsets = conf.offsets;
				minFps = conf.fps[0];
				if (minFps < 0) minFps = 0;
				maxFps = conf.fps[1];
				if (maxFps < 0) maxFps = 0;
			}
			splash.offset.set(10, 10);
			if (offsets != null)
			{
				splash.offset.x += offsets[0];
				splash.offset.y += offsets[1];
			}
			if (splash.animation.curAnim != null) splash.animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
		}
	}

	function onChangeWatermark():Void
	{
		if (Main.watermarkSprite != null) Main.watermarkSprite.visible = ClientPrefs.data.showWatermark;
		if (Main.watermark != null) Main.watermark.visible = ClientPrefs.data.showWatermark;
	}

	function onChangeKeyViewerColor():Void
	{
		if (PlayState.instance != null && PlayState.instance.keyViewer != null) PlayState.instance.keyViewer.updateKeyColors();
	}

	function onChangeQuantization():Void
	{
		for (note in notes)
		{
			note.refreshColorMode();
			if (note.rgbShader == null) continue;
			if (!ClientPrefs.data.noteRGB || !note.useRGBShader)
			{
				note.rgbShader.enabled = false;
				continue;
			}
			note.rgbShader.enabled = true;
			if (ClientPrefs.data.colorQuantization)
			{
				var simulatedBeat:Float = note.ID * 0.25;
				var quantColors:Array<FlxColor> = Note.getQuantizationRGB(simulatedBeat);
				if (quantColors != null)
				{
					note.rgbShader.r = quantColors[0];
					note.rgbShader.g = quantColors[1];
					note.rgbShader.b = quantColors[2];
				}
			}
			else
			{
				var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[note.ID];
				if (arr != null && note.ID > -1 && note.ID < arr.length)
				{
					note.rgbShader.r = arr[0];
					note.rgbShader.g = arr[1];
					note.rgbShader.b = arr[2];
				}
			}
		}
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

		if (changedMusic && !OptionsState.onPlayState) FlxG.sound.playMusic(Paths.music('freakyMenu'), 1, true);
		Note.globalRgbShaders = [];
		super.destroy();
	}
}

private class VisualsSettingsCard extends FlxSpriteGroup
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
		this.descriptionValue = description;
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
		refreshTheme();
		alpha = value ? 1.0 : 0.92;
		scale.set(1, 1);
		updateHitbox();
		offset.set(0, 0);
	}

	public function refreshTheme():Void
	{
		redraw();
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

private class VisualsSwitchCard extends VisualsSettingsCard
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
		valueText.text = value ? 'Enabled' : 'Disabled';
		if (fireApply && onApply != null) onApply(value);
	}

	override public function refreshTheme():Void
	{
		valueText.color = OptionsMenuTheme.current().accent;
		super.refreshTheme();
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

private class VisualsChoiceCard extends VisualsSettingsCard
{
	public var options(default, null):Array<String>;
	public var currentValue(default, null):String;
	var defaultValue:String;
	var selectorButton:MaterialButton;
	var requestDropdown:VisualsChoiceCard->Void;
	var onApply:String->Void;
	var optionTranslationKey:String;

	public function new(settingId:String, title:String, description:String, width:Float, options:Array<String>, currentValue:String, defaultValue:String, requestDropdown:VisualsChoiceCard->Void, onApply:String->Void, ?optionTranslationKey:String)
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
	override function handleLeft():Void cycle(-1);
	override function handleRight():Void cycle(1);
	override function handleAccept():Void if (requestDropdown != null) requestDropdown(this);
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
		handleAccept();
		return true;
	}
	override function resetToDefault():Void setValueLabel(defaultValue);
}

private class VisualsSliderCard extends VisualsSettingsCard
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

private class VisualsStepperCard extends VisualsSettingsCard
{
	var stepper:MaterialNumericStepper;
	var currentValue:Int;
	var defaultValue:Int;
	var minValue:Int;
	var maxValue:Int;
	var stepValue:Int;
	var onApply:Int->Void;

	public function new(settingId:String, title:String, description:String, width:Float, currentValue:Int, defaultValue:Int, minValue:Int, maxValue:Int, stepValue:Int, onApply:Int->Void)
	{
		super(settingId, title, description, width);
		this.defaultValue = defaultValue;
		this.minValue = minValue;
		this.maxValue = maxValue;
		this.stepValue = stepValue;
		this.onApply = onApply;
		titleText.fieldWidth = width - 32;
		reflowDescription(width - 44);
		var controlsY = descriptionText.y + descriptionText.height + 18;
		stepper = new MaterialNumericStepper(width - 192, controlsY, stepValue, currentValue, minValue, maxValue, 0, 168, function(value:Float) {
			setValue(Std.int(value));
		});
		stepper.allowMouseInput = false;
		add(stepper);
		fitHeight(controlsY + 58, 18);
		setValue(currentValue, false);
	}

	function setValue(value:Int, fireApply:Bool = true):Void
	{
		currentValue = Std.int(FlxMath.bound(value, minValue, maxValue));
		stepper.value = currentValue;
		if (fireApply && onApply != null) onApply(currentValue);
	}

	override public function handleLeft():Void setValue(currentValue - stepValue);
	override public function handleRight():Void setValue(currentValue + stepValue);
	override public function handleAccept():Void setValue(currentValue + stepValue > maxValue ? minValue : currentValue + stepValue);
	override public function handleTouch(screenX:Float, screenY:Float):Bool
	{
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

private class VisualsDropdownMenu extends FlxSpriteGroup
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
		if (onSelect != null) onSelect(items[selectedIndex]);
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
		if (hostLayer != null) hostLayer.remove(this, true);
		if (onClosed != null) onClosed();
		kill();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}
}
