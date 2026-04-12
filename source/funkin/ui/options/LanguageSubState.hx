package funkin.ui.options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import openfl.utils.Assets;
import funkin.ui.MusicBeatSubstate;
import funkin.ui.components.md3.MD3ShapeTools;
import funkin.ui.components.md3.MaterialButton;
import funkin.ui.components.md3.MaterialButton.ButtonType;

class LanguageSubState extends MusicBeatSubstate
{
	#if TRANSLATIONS_ALLOWED
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

	var cardLayer:FlxTypedGroup<LanguageCard>;
	var cards:Array<LanguageCard> = [];
	var cardBaseY:Array<Float> = [];

	var languages:Array<String> = [];
	var displayLanguages:Map<String, String> = [];
	var changedLanguage:Bool = false;

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
		DiscordClient.changePresence('Language Menu', null);
		#end

		OptionsMenuTheme.syncAccent();
		loadLanguages();
		buildChrome();
		buildCards();

		selectedCard = languages.indexOf(ClientPrefs.data.language);
		if (selectedCard < 0)
		{
			ClientPrefs.data.language = ClientPrefs.defaultData.language;
			selectedCard = Std.int(Math.max(0, languages.indexOf(ClientPrefs.data.language)));
		}
		if (lastSelected >= 0 && lastSelected < cards.length)
			selectedCard = lastSelected;

		changeSelection(selectedCard, true);
		refreshCardPositions(true);

		#if mobile
		touchScroll = new funkin.mobile.backend.TouchScroll(true);
		funkin.mobile.backend.TouchUtil.setScrollHandler(touchScroll);
		#end
	}

	function loadLanguages():Void
	{
		languages = [];
		displayLanguages = [];

		for (lang in Language.getAvailableLanguages())
		{
			if (!languages.contains(lang.code))
			{
				languages.push(lang.code);
				displayLanguages.set(lang.code, lang.name);
			}
		}

		var directories:Array<String> = Mods.directoriesWithFile(Paths.getSharedPath(), 'data/');
		for (directory in directories)
		{
			for (file in Paths.readDirectory(directory))
			{
				if (!file.toLowerCase().endsWith('.lang'))
					continue;

				var langFile = file.substring(0, file.length - '.lang'.length).trim();
				if (!languages.contains(langFile))
					languages.push(langFile);

				if (displayLanguages.exists(langFile))
					continue;

				var path = '$directory/$file';
				#if MODS_ALLOWED
				var txt = File.getContent(path);
				#else
				var txt = Assets.getText(path);
				#end

				var id = txt.indexOf('\n');
				if (id > 0)
				{
					var name = txt.substr(0, id).trim();
					if (!name.contains(':'))
						displayLanguages.set(langFile, name);
				}
				else if (txt.trim().length > 0 && !txt.contains(':'))
				{
					displayLanguages.set(langFile, txt.trim());
				}
			}
		}

		languages.sort(function(a:String, b:String) {
			var aName = (displayLanguages.exists(a) ? displayLanguages.get(a) : a).toLowerCase();
			var bName = (displayLanguages.exists(b) ? displayLanguages.get(b) : b).toLowerCase();
			if (aName < bName) return -1;
			if (aName > bName) return 1;
			return 0;
		});
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

		titleText = new FlxText(panelX + 34, panelY + 18, panelWidth - 260, Language.getPhrase('language_menu', 'Language'), 31);
		titleText.setFormat(Paths.font('inter-bold.otf'), 31, OptionsMenuTheme.titleColor(), LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		subtitleText = new FlxText(panelX + 34, panelY + 58, panelWidth - 320,
			Language.getPhrase('language_menu_subtitle', 'Choose the language used by menus, settings and everything else that loves appearing on screen.'), 15);
		subtitleText.setFormat(Paths.font('inter.otf'), 15, OptionsMenuTheme.bodyTextColor(), LEFT);
		subtitleText.antialiasing = ClientPrefs.data.antialiasing;
		add(subtitleText);

		closeButton = new MaterialButton(panelX + panelWidth - 150, panelY + 28, Language.getPhrase('close', 'Close'), TEXT, 110, closeOrReload);
		closeButton.allowMouseInput = false;
		add(closeButton);

		statusText = new FlxText(panelX + panelWidth - 360, panelY + 66, 320, Language.getPhrase('language_menu_status', 'Pick one and press ENTER to apply'), 14);
		statusText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.bodyTextColor(), RIGHT);
		statusText.antialiasing = ClientPrefs.data.antialiasing;
		add(statusText);

		footerText = new FlxText(panelX + 28, panelY + panelHeight - 34, panelWidth - 56,
			Language.getPhrase('language_menu_footer', 'ARROWS move. ENTER applies the selected language. ESC returns and reloads if needed.'), 14);
		footerText.setFormat(Paths.font('inter.otf'), 14, OptionsMenuTheme.footerTextColor(), CENTER);
		footerText.antialiasing = ClientPrefs.data.antialiasing;
		add(footerText);

		cardLayer = new FlxTypedGroup<LanguageCard>();
		add(cardLayer);
	}

	function buildCards():Void
	{
		var cardX = panelX + 28;
		var cardY = contentTop;

		for (langCode in languages)
		{
			var displayName = displayLanguages.exists(langCode) ? displayLanguages.get(langCode) : langCode;
			cardY = addCard(new LanguageCard(langCode, displayName, getExampleTextForLanguage(langCode), cardWidth), cardX, cardY);
		}

		contentHeight = Math.max(0, cardY - contentTop - 10);
	}

	function addCard(card:LanguageCard, x:Float, y:Float):Float
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

	function changeSelection(targetIndex:Int, instant:Bool = false):Void
	{
		if (cards.length == 0) return;
		selectedCard = FlxMath.wrap(targetIndex, 0, cards.length - 1);
		lastSelected = selectedCard;
		keepSelectionVisible();
		for (index in 0...cards.length)
			cards[index].setSelected(index == selectedCard, instant);
		statusText.text = cards[selectedCard].titleText.text + ' [' + cards[selectedCard].languageCode + ']';
	}

	function moveSelection(change:Int):Void
	{
		changeSelection(selectedCard + change);
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.45);
	}

	function applySelectedLanguage():Void
	{
		if (cards.length == 0) return;
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.6);
		ClientPrefs.data.language = cards[selectedCard].languageCode;
		ClientPrefs.saveSettings();
		Language.reloadPhrases();
		changedLanguage = true;
		statusText.text = Language.getPhrase('language_applied', 'Applied') + ': ' + cards[selectedCard].titleText.text;
	}

	function closeOrReload():Void
	{
		FlxG.sound.play(Paths.sound('cancelMenu'));
		if (changedLanguage)
		{
			FlxTransitionableState.skipNextTransIn = true;
			FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.resetState();
		}
		else
		{
			close();
		}
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

		var mult = FlxG.keys.pressed.SHIFT ? 4 : 1;
		if (controls.BACK)
		{
			closeOrReload();
			return;
		}

		if (controls.UI_UP_P) moveSelection(-1 * mult);
		if (controls.UI_DOWN_P) moveSelection(1 * mult);
		if (controls.ACCEPT) applySelectedLanguage();
	}

	#if mobile
	function handleTouchInput():Void
	{
		var tapPos = touchScroll.getTapPosition();
		if (tapPos == null) return;

		if (isPointInsideRect(tapPos.x, tapPos.y, closeButton.x, closeButton.y, closeButton.width, closeButton.height))
		{
			closeOrReload();
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
					applySelectedLanguage();
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

	function getExampleTextForLanguage(langCode:String):String
	{
		var exampleTexts:Map<String, String> = [
			'en-US' => 'This is an example text in English United States language',
			'es-LA' => 'Este es un ejemplo de texto en el idioma Español Latinoamérica',
			'es-ES' => 'Este es un ejemplo de texto en el idioma Español de España',
			'fr-FR' => 'Ceci est un exemple de texte en langue Française France',
			'pt-BR' => 'Este é um exemplo de texto no idioma Português Brasil',
			'it-IT' => 'Questo è un esempio di testo nella lingua Italiana Italia',
			'de-DE' => 'Dies ist ein Beispieltext in deutscher Sprache Deutschland',
			'ja-JP' => 'これは日本語での例文テキストです',
			'nl-NL' => 'Dit is een voorbeeldtekst in de Nederlandse taal Nederland',
			'zh-CN' => '这是中文（简体）语言的示例文本',
			'zh-HK' => '這是中文（香港）語言的示例文本'
			// 'id-ID' => 'Ini adalah teks contoh dalam bahasa Indonesia Nusantara' - Sorry i was tried translating Indonesian - sirthegamercoder
		];
		return exampleTexts.exists(langCode) ? exampleTexts.get(langCode) : 'This is an example text in the selected language';
	}
	#else
	public function new()
	{
		super();
	}
	#end
}

#if TRANSLATIONS_ALLOWED
private class LanguageCard extends FlxSpriteGroup
{
	public var languageCode(default, null):String;
	public var cardWidth(default, null):Float;
	public var cardHeight(default, null):Float;
	public var titleText(default, null):FlxText;

	var background:FlxSprite;
	var outline:FlxSprite;
	var accentBar:FlxSprite;
	var codeText:FlxText;
	var sampleText:FlxText;
	var sampleValue:String;
	var selected:Bool = false;

	public function new(languageCode:String, displayName:String, sample:String, width:Float)
	{
		super();
		this.languageCode = languageCode;
		this.sampleValue = sample;
		cardWidth = width;
		cardHeight = 96;

		background = new FlxSprite();
		background.antialiasing = ClientPrefs.data.antialiasing;
		add(background);

		outline = new FlxSprite();
		outline.antialiasing = ClientPrefs.data.antialiasing;
		add(outline);

		accentBar = new FlxSprite(16, 16);
		accentBar.antialiasing = ClientPrefs.data.antialiasing;
		add(accentBar);

		titleText = new FlxText(30, 12, width - 180, displayName, 20);
		titleText.setFormat(Paths.font('inter-bold.otf'), 20, 0xFF2C1E48, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		add(titleText);

		codeText = new FlxText(width - 186, 16, 156, languageCode, 13);
		codeText.setFormat(Paths.font('inter-bold.otf'), 13, OptionsMenuTheme.current().accent, RIGHT);
		codeText.antialiasing = ClientPrefs.data.antialiasing;
		add(codeText);

		sampleText = new FlxText(30, 42, width - 60, sample, 12);
		sampleText.setFormat(Paths.font('inter.otf'), 12, 0xFF76678B, LEFT);
		sampleText.antialiasing = ClientPrefs.data.antialiasing;
		add(sampleText);

		fitHeight(98);
	}

	function fitHeight(minHeight:Float, ?extraBottom:Float = 18):Void
	{
		cardHeight = Math.max(minHeight, sampleText.y + sampleText.height + extraBottom);
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
		codeText.color = palette.accent;
		sampleText.color = OptionsMenuTheme.cardDescriptionColor(selected);
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
		clipRect = (topCut <= 0 && bottomCut <= 0) ? null : new FlxRect(0, topCut, cardWidth, visibleHeight);
	}
}
#end
