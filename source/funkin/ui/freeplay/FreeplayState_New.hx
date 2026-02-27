package funkin.ui.freeplay;

import funkin.graphics.shaders.BlurEffect;

class FreeplayState_New extends MusicBeatState {
    var bg:FlxSprite;
    var blackOverlay:FlxSprite;
    var dinamic:FlxSprite;
    var album:FlxSprite;
    var uiprincipal:FlxSprite;
    var list:FlxSprite;
    var cardsGroup:FlxTypedGroup<FlxSprite>;
    var blurEffect:BlurEffect;
    //var diff:Array<FlxSpriteGroup>;

    var accuracyIcon:FlxSprite;
    var bpmIcon:FlxSprite;
    var fireIcon:FlxSprite;
    var gamesettingsIcon:FlxSprite;
    var medalIcon:FlxSprite;
    var playIcon:FlxSprite;
    var searchIcon:FlxSprite;
    var settingsIcon:FlxSprite;
    var speedIcon:FlxSprite;
    var starIcon:FlxSprite;
    var starFullIcon:FlxSprite;
    var timerIcon:FlxSprite;
    var trophyIcon:FlxSprite;

    var speedText:FlxText;
    var timerText:FlxText;
    var bpmText:FlxText;

    var scoreText:FlxText;
    var scoreData:FlxText;
    var accuracyText:FlxText;
    var accuracyData:FlxText;
    var comboText:FlxText;
    var comboData:FlxText;
    var ratingText:FlxText;
    var ratingData:FlxText;

    var playText:FlxText;
    var diffText:FlxText;
    var modText:FlxText;
    var notesText:FlxText;
    var noteDiffText:FlxText;
    var themeText:FlxText;
    var songsText:FlxText;
    var searchtipText:FlxText;
    var todayText:FlxText;
    var totalSongsText:FlxText;
    var modsLoadedText:FlxText;

    override public function create():Void {
        super.create();

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();
		
		// Apply Gaussian blur effect to background using shader
		blurEffect = new BlurEffect();
		blurEffect.strength = 5.0; // 1-10 for good blur effect
		bg.shader = blurEffect.shader;
		//bgZoom = defaultBgZoom = 1;

        blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackOverlay.alpha = 0.5;
		add(blackOverlay);

        dinamic = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/dinamic'));
		dinamic.antialiasing = ClientPrefs.data.antialiasing;
		dinamic.setGraphicSize(FlxG.width, FlxG.height);
		dinamic.updateHitbox();
		add(dinamic);

        album = new FlxSprite().loadGraphic(Paths.image('albumRoll/example'));
        album.x = 49;
        album.y = 98;
        album.antialiasing = ClientPrefs.data.antialiasing;
        album.setGraphicSize(206, 206);
        album.updateHitbox();
        add(album);

        uiprincipal = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/uiprin'));
        uiprincipal.antialiasing = ClientPrefs.data.antialiasing;
        uiprincipal.setGraphicSize(FlxG.width, FlxG.height);
        uiprincipal.updateHitbox();
        add(uiprincipal);

        list = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/list'));
        list.antialiasing = ClientPrefs.data.antialiasing;
        list.setGraphicSize(FlxG.width, FlxG.height);
        list.updateHitbox();
        add(list);

        searchIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/search'));
        searchIcon.x = 895;
        searchIcon.y = 170;
        searchIcon.antialiasing = ClientPrefs.data.antialiasing;
        searchIcon.setGraphicSize(16, 16);
        searchIcon.updateHitbox();
        add(searchIcon);

        playIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/play'));
        playIcon.x = 80.8;
        playIcon.y = 566.7;
        playIcon.antialiasing = ClientPrefs.data.antialiasing;
        playIcon.setGraphicSize(30, 30);
        playIcon.updateHitbox();
        add(playIcon);

        playText = new FlxText(110.8, 565, 0, 'Play');
        playText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.PURPLE, 'left');
        add(playText);

        starIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/star'));
        starIcon.x = 299.8;
        starIcon.y = 570.5;
        starIcon.antialiasing = ClientPrefs.data.antialiasing;
        starIcon.setGraphicSize(24, 24);
        starIcon.updateHitbox();
        add(starIcon);

        trophyIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/trophy'));
        trophyIcon.x = 54;
        trophyIcon.y = 350;
        trophyIcon.antialiasing = ClientPrefs.data.antialiasing;
        trophyIcon.setGraphicSize(16.5, 16.5);
        trophyIcon.updateHitbox();
        add(trophyIcon);

        scoreText = new FlxText(74.8, 349, 0, 'High Score');
        scoreText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(scoreText);

        scoreData = new FlxText(54, 375, 0, '123,456');
        scoreData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(scoreData);

        accuracyIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/accuracy'));
        accuracyIcon.x = 224.6;
        accuracyIcon.y = 350;
        accuracyIcon.antialiasing = ClientPrefs.data.antialiasing;
        accuracyIcon.setGraphicSize(16.5, 16.5);
        accuracyIcon.updateHitbox();
        add(accuracyIcon);

        accuracyText = new FlxText(244.6, 349, 0, 'Accuracy');
        accuracyText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(accuracyText);

        accuracyData = new FlxText(224.6, 375, 0, '98.5%');
        accuracyData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(accuracyData);

        fireIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/fire'));
        fireIcon.x = 395.6;
        fireIcon.y = 350;
        fireIcon.antialiasing = ClientPrefs.data.antialiasing;
        fireIcon.setGraphicSize(16.5, 16.5);
        fireIcon.updateHitbox();
        add(fireIcon);

        comboText = new FlxText(415.6, 349, 0, 'Max Combo');
        comboText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(comboText);

        comboData = new FlxText(395.6, 375, 0, '456x');
        comboData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(comboData);

        medalIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/medal'));
        medalIcon.x = 566.1;
        medalIcon.y = 350;
        medalIcon.antialiasing = ClientPrefs.data.antialiasing;
        medalIcon.setGraphicSize(16.5, 16.5);
        medalIcon.updateHitbox();
        add(medalIcon);

        ratingText = new FlxText(586.1, 349, 0, 'Rating');
        ratingText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.GRAY, 'left');
        add(ratingText);

        ratingData = new FlxText(566.1, 375, 0, 'S++');
        ratingData.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.BLACK, 'left');
        add(ratingData);

        speedIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/speed'));
        speedIcon.x = 296.2;
        speedIcon.y = 193;
        speedIcon.antialiasing = ClientPrefs.data.antialiasing;
        speedIcon.setGraphicSize(16, 16);
        speedIcon.updateHitbox();
        add(speedIcon);

        speedText = new FlxText(316.2, 192.5, 0, '1.0x');
        speedText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.PURPLE, 'left');
        add(speedText);

        timerIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/timer'));
        timerIcon.x = 394.8;
        timerIcon.y = 193;
        timerIcon.antialiasing = ClientPrefs.data.antialiasing;
        timerIcon.setGraphicSize(16, 16);
        timerIcon.updateHitbox();
        add(timerIcon);

        timerText = new FlxText(413.8, 192.5, 0, '1:23');
        timerText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.PURPLE, 'left');
        add(timerText);

        bpmIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/bpm'));
        bpmIcon.x = 476.1;
        bpmIcon.y = 193;
        bpmIcon.antialiasing = ClientPrefs.data.antialiasing;
        bpmIcon.setGraphicSize(16, 16);
        bpmIcon.updateHitbox();
        add(bpmIcon);

        bpmText = new FlxText(494.1, 192.5, 0, '120 BPM');
        bpmText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.PURPLE, 'left');
        add(bpmText);

        themeText = new FlxText(294.2, 235.5, 0, 'Example Theme');
        themeText.setFormat(Paths.font('inter-bold.otf'), 36, FlxColor.BLACK, 'left');
        add(themeText);

        modText = new FlxText(294.2, 280.5, 0, 'Friday Night Funkin\'');
        modText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.GRAY, 'left');
        add(modText);

        cardsGroup = new FlxTypedGroup<FlxSprite>();
        add(cardsGroup);
        
        // Create 7 cards vertically
        for (i in 0...7) {
            var card:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/card'));
            card.x = 880;
            card.y = 275 + (i * 74); // 74 pixels between each card
            card.antialiasing = ClientPrefs.data.antialiasing;
            card.updateHitbox();
            cardsGroup.add(card);
        }
    }
}