package funkin.ui.options;

import StringTools;

import flixel.math.FlxRect;
import funkin.data.stage.StageData;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.mainmenu.MainMenuState;

class OptionsState extends MusicBeatState
{
	var options:Array<String> = [];

	var backdrop:FlxSprite;
	var panelShadow:FlxSprite;
	public static var menuBG:FlxSprite;
	var panelSurface:FlxSprite;
	var panelHeader:FlxSprite;
	var panelOutline:FlxSprite;
	var titleText:FlxText;
	var subtitleText:FlxText;
	var footerText:FlxText;

	var optionCards:FlxTypedGroup<FlxSprite>;
	var optionTitles:FlxTypedGroup<FlxText>;
	var optionDescriptions:FlxTypedGroup<FlxText>;

	var panelX:Float = 0;
	var panelY:Float = 0;
	var panelWidth:Float = 0;
	var panelHeight:Float = 0;
	var cardsAnchorY:Float = 0;
	var cardWidth:Float = 0;
	var cardHeight:Float = 0;
	var cardSpacing:Float = 0;
	var lastThemeSignature:String = '';

	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	public static var onPlayState:Bool = false;

	#if mobile
	var touchScroll:funkin.mobile.backend.TouchScroll;
	#end

	function buildOptions():Array<String>
	{
		var opts:Array<String> = [];
		if (!ClientPrefs.data.colorQuantization) opts.push('Note Colors');
		opts.push('Controls');
		opts.push('Adjust Delay and Combo');
		opts.push('Graphics');
		opts.push('Visuals');
		opts.push('Gameplay');
		opts.push('Legacy');
		#if MODCHARTS_NOTITG_ALLOWED opts.push('Modchart'); #end
		#if TRANSLATIONS_ALLOWED opts.push('Language'); #end
		#if mobile opts.push('Mobile'); #end
		return opts;
	}

	function openSelectedSubstate(label:String)
	{
		if (label != 'Adjust Delay and Combo')
		{
			removeTouchPad();
			persistentUpdate = false;
			#if mobile
			if (touchScroll != null) touchScroll.reset();
			#end
		}

		switch (label)
		{
			case 'Note Colors':
				if (!ClientPrefs.data.colorQuantization)
					openSubState(new funkin.ui.options.NotesColorSubState());
			case 'Controls':
				openSubState(new funkin.ui.options.ControlsSubState());
			case 'Graphics':
				openSubState(new funkin.ui.options.GraphicsSettingsSubState());
			case 'Visuals':
				openSubState(new funkin.ui.options.VisualsSettingsSubState());
			case 'Gameplay':
				openSubState(new funkin.ui.options.GameplaySettingsSubState());
			case 'Legacy':
				openSubState(new funkin.ui.options.LegacySettingsSubState());
			case 'Modchart':
				openSubState(new funkin.ui.options.ModchartSettingsSubState());
			case 'Adjust Delay and Combo':
				MusicBeatState.switchState(new funkin.ui.options.NoteOffsetState());
			case 'Mobile':
				openSubState(new funkin.mobile.options.MobileSettingsSubState());
			case 'Language':
				openSubState(new funkin.ui.options.LanguageSubState());
		}
	}

	function getCategoryDescription(label:String):String
	{
		var fallback = switch (label)
		{
			case 'Note Colors': 'Adjust note palettes, quantization-related colors and visual readability for note lanes.';
			case 'Controls': 'Rebind keys, gamepad inputs and related control behavior.';
			case 'Adjust Delay and Combo': 'Tune hit offset, combo placement and live judgement feedback.';
			case 'Graphics': 'Performance, shaders, anti-aliasing, fullscreen behavior and display tuning.';
			case 'Visuals': 'HUD look, camera effects, interface visibility and presentation tweaks.';
			case 'Gameplay': 'Core gameplay behavior like scroll direction, hit rules and miscellaneous play modifiers.';
			case 'Legacy': 'Compatibility switches for older behavior and mod support quirks.';
			case 'Modchart': 'Performance and rendering settings related to advanced modcharts.';
			case 'Language': 'Change the game language and localized menu text.';
			case 'Mobile': 'Touch controls, hitboxes and mobile-specific interface options.';
			default: 'Choose a settings category.';
		};
		return Language.getPhrase('options_desc_' + normalizeOptionKey(label), fallback);
	}

	function normalizeOptionKey(value:String):String
	{
		var key = value.toLowerCase();
		key = StringTools.replace(key, ' ', '_');
		key = StringTools.replace(key, '!', '');
		key = StringTools.replace(key, '/', '_');
		while (key.indexOf('__') != -1)
			key = StringTools.replace(key, '__', '_');
		return key;
	}

	function redrawCard(card:FlxSprite, selected:Bool):Void
	{
		MD3ShapeTools.fillAndStrokeRoundRect(card, Std.int(cardWidth), Std.int(cardHeight), 24, 2,
			OptionsMenuTheme.cardFill(selected), OptionsMenuTheme.cardStroke(selected));
	}

	function refreshThemeChrome():Void
	{
		lastThemeSignature = OptionsMenuTheme.signature();
		backdrop.makeGraphic(FlxG.width, FlxG.height, OptionsMenuTheme.backdropColor());
		menuBG.color = OptionsMenuTheme.current().pale;
		menuBG.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 32, OptionsMenuTheme.panelSurfaceColor());
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 112, 32, 32, 0, 0, OptionsMenuTheme.panelHeaderColor());
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 32, 2, OptionsMenuTheme.panelOutlineColor());
		titleText.color = OptionsMenuTheme.titleColor();
		subtitleText.color = OptionsMenuTheme.bodyTextColor();
		footerText.color = OptionsMenuTheme.footerTextColor();
	}

	function refreshOptionLayout(elapsed:Float, instant:Bool = false):Void
	{
		var clipTop = panelY + 124;
		var clipBottom = panelY + panelHeight - 56;

		for (index in 0...optionCards.members.length)
		{
			var card = optionCards.members[index];
			var title = optionTitles.members[index];
			var description = optionDescriptions.members[index];
			if (card == null || title == null || description == null) continue;

			var targetY = index - lerpSelected;
			var desiredX = panelX + (panelWidth - cardWidth) * 0.5;
			var desiredY = cardsAnchorY + targetY * cardSpacing;
			var selected = index == curSelected;
			var targetScale = 1.0;
			var targetAlpha = selected ? 1.0 : 0.74;

			if (instant)
			{
				card.x = desiredX;
				card.y = desiredY;
				card.scale.set(targetScale, targetScale);
				card.alpha = targetAlpha;
			}
			else
			{
				card.x = FlxMath.lerp(desiredX, card.x, Math.exp(-elapsed * 11.0));
				card.y = FlxMath.lerp(desiredY, card.y, Math.exp(-elapsed * 10.0));
				card.scale.x = FlxMath.lerp(targetScale, card.scale.x, Math.exp(-elapsed * 12.0));
				card.scale.y = FlxMath.lerp(targetScale, card.scale.y, Math.exp(-elapsed * 12.0));
				card.alpha = FlxMath.lerp(targetAlpha, card.alpha, Math.exp(-elapsed * 12.0));
			}

			card.updateHitbox();
			card.offset.set(0, 0);
			redrawCard(card, selected);

			title.fieldWidth = cardWidth - 56;
			title.x = card.x + (cardWidth - title.fieldWidth) * 0.5;
			title.y = card.y + 14;
			title.color = OptionsMenuTheme.optionTitleColor(selected);
			title.alpha = card.alpha;

			description.fieldWidth = cardWidth - 70;
			description.x = card.x + (cardWidth - description.fieldWidth) * 0.5;
			description.y = title.y + 31;
			description.color = OptionsMenuTheme.optionDescriptionColor(selected);
			description.alpha = selected ? 1.0 : 0.85;

			applyVerticalClip(card, clipTop, clipBottom);
			applyVerticalClip(title, clipTop, clipBottom);
			applyVerticalClip(description, clipTop, clipBottom);
		}
	}

	static function applyVerticalClip(spr:FlxSprite, yMin:Float, yMax:Float):Void
	{
		if (spr == null) return;
		var height:Float = spr.frameHeight;
		if (height <= 0)
		{
			spr.visible = false;
			return;
		}

		var topCut:Float = Math.max(0, yMin - spr.y);
		var bottomCut:Float = Math.max(0, (spr.y + height) - yMax);
		var visibleHeight:Float = height - topCut - bottomCut;
		if (visibleHeight <= 0)
		{
			spr.visible = false;
			spr.clipRect = null;
		}
		else
		{
			spr.visible = true;
			spr.clipRect = new FlxRect(0, topCut, spr.frameWidth, visibleHeight);
		}
	}

	override function create()
	{
		OptionsMenuTheme.syncAccent();
		Cursor.hide();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end

		options = buildOptions();
		panelWidth = Math.min(980, FlxG.width - 64);
		panelHeight = Math.min(632, FlxG.height - 64);
		panelX = (FlxG.width - panelWidth) * 0.5;
		panelY = (FlxG.height - panelHeight) * 0.5;
		cardWidth = Math.min(760, panelWidth - 88);
		cardHeight = 78;
		cardSpacing = 88;
		cardsAnchorY = panelY + 138;

		backdrop = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, OptionsMenuTheme.backdropColor());
		add(backdrop);

		menuBG = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.antialiasing = ClientPrefs.data.antialiasing;
		menuBG.color = OptionsMenuTheme.current().pale;
		menuBG.alpha = OptionsMenuTheme.menuBackgroundAlpha();
		menuBG.updateHitbox();
		menuBG.screenCenter();
		add(menuBG);

		panelShadow = new FlxSprite(panelX + 10, panelY + 12);
		MD3ShapeTools.fillRoundRect(panelShadow, Std.int(panelWidth), Std.int(panelHeight), 32, 0x26000000);
		add(panelShadow);

		panelSurface = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRect(panelSurface, Std.int(panelWidth), Std.int(panelHeight), 32, OptionsMenuTheme.panelSurfaceColor());
		add(panelSurface);

		panelHeader = new FlxSprite(panelX, panelY);
		MD3ShapeTools.fillRoundRectComplex(panelHeader, Std.int(panelWidth), 112, 32, 32, 0, 0, OptionsMenuTheme.panelHeaderColor());
		add(panelHeader);

		panelOutline = new FlxSprite(panelX, panelY);
		MD3ShapeTools.strokeRoundRect(panelOutline, Std.int(panelWidth), Std.int(panelHeight), 32, 2, OptionsMenuTheme.panelOutlineColor());
		add(panelOutline);

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 68, Language.getPhrase('options_menu', 'Options'), 32);
		titleText.setFormat(Paths.font('inter-bold.otf'), 32, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 68,
			Language.getPhrase('options_menu_subtitle', 'Select a settings category. Each card opens a focused submenu instead of throwing the whole house at you.'), 16);
		subtitleText.setFormat(Paths.font('inter.otf'), 16, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		var footerMessage = Language.getPhrase('options_menu_footer', 'ENTER selects. ESC returns.');
		if (controls.mobileC)
			footerMessage += ' ' + Language.getPhrase('mobile_controls_tip', 'Press {1} to Go Mobile Controls Menu', [(FlxG.onMobile ? 'C' : 'CTRL or C')]);

		footerText = new FlxText(panelX + 34, panelY + panelHeight - 42, panelWidth - 68, footerMessage, 15);
		footerText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		optionCards = new FlxTypedGroup<FlxSprite>();
		optionTitles = new FlxTypedGroup<FlxText>();
		optionDescriptions = new FlxTypedGroup<FlxText>();
		add(optionCards);
		add(optionTitles);
		add(optionDescriptions);

		for (option in options)
		{
			var card = new FlxSprite();
			card.antialiasing = ClientPrefs.data.antialiasing;
			redrawCard(card, false);
			optionCards.add(card);

			var title = new FlxText(0, 0, cardWidth - 56, Language.getPhrase('options_$option', option), 22);
			title.setFormat(Paths.font('inter-bold.otf'), 22, 0xFF45335E, CENTER);
			title.antialiasing = ClientPrefs.data.antialiasing;
			optionTitles.add(title);

			var description = new FlxText(0, 0, cardWidth - 70, getCategoryDescription(option), 13);
			description.setFormat(Paths.font('inter.otf'), 13, 0xFF7E6F95, CENTER);
			description.antialiasing = ClientPrefs.data.antialiasing;
			optionDescriptions.add(description);
		}

		lerpSelected = curSelected;
		changeSelection();
		ClientPrefs.saveSettings();

		#if mobile
		touchScroll = new funkin.mobile.backend.TouchScroll(true);
		funkin.mobile.backend.TouchUtil.setScrollHandler(touchScroll);
		#end

		refreshOptionLayout(0, true);
		refreshThemeChrome();
		addTouchPad('UP_DOWN', 'A_B_C');

		super.create();
	}

	override function closeSubState()
	{
		super.closeSubState();
		ClientPrefs.saveSettings();
		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Options Menu', null);
		#end
		controls.isInSubstate = false;
		removeTouchPad();
		addTouchPad('NONE', 'B_C');
		persistentUpdate = true;

		#if mobile
		if (touchScroll != null) touchScroll.reset();
		changeSelection(0);
		#end
	}

	var exiting = false;
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (lastThemeSignature != OptionsMenuTheme.signature())
			refreshThemeChrome();

		lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
		refreshOptionLayout(elapsed);

		if (!exiting)
		{
			if (controls.UI_UP_P) changeSelection(-1);
			if (controls.UI_DOWN_P) changeSelection(1);

			#if mobile
			if (touchScroll != null)
			{
				var scrollDelta = touchScroll.update();
				if (Math.abs(scrollDelta) > 0.5)
				{
					lerpSelected += -scrollDelta / 150;
					lerpSelected = FlxMath.bound(lerpSelected, 0, options.length - 1);

					var newSelected = Math.round(lerpSelected);
					if (newSelected != curSelected)
						changeSelection(newSelected - curSelected);
				}

				if (touchScroll.wasTapped())
					handleTouchOptions();
			}
			#end

			if ((touchPad != null && touchPad.buttonC != null && touchPad.buttonC.justPressed) || (FlxG.keys.justPressed.CONTROL && controls.mobileC))
			{
				persistentUpdate = false;
				openSubState(new funkin.mobile.substates.MobileControlSelectSubState());
			}

			if (controls.BACK)
			{
				exiting = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				if (onPlayState)
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState());
					FlxG.sound.music.volume = 0;
				}
				else
				{
					MusicBeatState.switchState(new MainMenuState());
				}
			}
			else if (controls.ACCEPT)
			{
				openSelectedSubstate(options[curSelected]);
			}
		}
	}

	#if mobile
	function handleTouchOptions():Void
	{
		var tapPos = touchScroll.getTapPosition();
		if (tapPos == null) return;

		for (i in 0...optionCards.members.length)
		{
			var card = optionCards.members[i];
			if (card != null && card.visible && card.overlapsPoint(new FlxPoint(tapPos.x, tapPos.y)))
			{
				if (i == curSelected)
					openSelectedSubstate(options[curSelected]);
				else
				{
					curSelected = i;
					lerpSelected = i;
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				break;
			}
		}
	}
	#end

	function changeSelection(change:Int = 0)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
		if (change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	override function destroy()
	{
		#if mobile
		if (touchScroll != null)
		{
			touchScroll.destroy();
			touchScroll = null;
		}
		funkin.mobile.backend.TouchUtil.clearScrollHandler();
		#end

		ClientPrefs.loadPrefs();
		super.destroy();
	}
}
