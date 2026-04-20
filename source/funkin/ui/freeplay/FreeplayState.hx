package funkin.ui.freeplay;

import funkin.graphics.shaders.BlurEffect;
import funkin.data.stage.StageData;
import funkin.data.story.level.WeekData;
import funkin.data.stepmania.SMFile;
import funkin.save.Highscore;
import funkin.data.song.Song;
import funkin.data.song.Song.SwagSong;
import funkin.play.HealthIcon;
import funkin.ui.options.GameplayChangersSubstate;
import funkin.play.substates.ResetScoreSubState;
import funkin.ui.components.PsychUIInputText;
import funkin.ui.components.md3.MaterialChip;
import funkin.ui.components.md3.MaterialChip.ChipType;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.math.FlxRect;
#if MODS_ALLOWED
import sys.FileSystem;
#end

#if mobile
import funkin.mobile.backend.StorageUtil;
#end

import haxe.Json;
import haxe.io.Path;

#if funkin.vis
import funkin.vis.dsp.SpectralAnalyzer;
#end

#if (target.threaded && sys)
import sys.thread.Mutex;
import funkin.util.ThreadUtil;
#end

class FreeplayState extends MusicBeatState {
    // Instance reference
    public static var instance:FreeplayState;
    public var songs:Array<SongMetadata> = [];
    public var filteredSongs:Array<SongMetadata> = [];
    public var showingFavorites:Bool = false;
    
    public static var curSelected:Int = 0;
    var curDifficulty:Int = -1;
    private static var lastDifficultyName:String = Difficulty.getDefault();

    var viewOffset:Float = 0;
    var lerpViewOffset:Float = 0;
    
    var lerpScore:Int = 0;
    var lerpRating:Float = 0;
    var intendedScore:Int = 0;
    var intendedRating:Float = 0;
    
    private var curPlaying:Bool = false;
    public static var viewingOpponentScores:Bool = false;
    var instPlaying:Int = -1;
    var previewTimer:FlxTimer = null;
    var previewLoadTimer:FlxTimer = null;
    var previewLoadToken:Int = 0;
    static inline var PREVIEW_LOAD_DELAY:Float = 0.12;
    var _prevInstSongName:String = null; // Track previous inst to unload from cache
    var holdTime:Float = 0;
    var stopMusicPlay:Bool = false;
    
    var bgZoom:Float = 1;
    var defaultBgZoom:Float = 1;
    var currentBPM:Float = 102;
    
    var albumZoom:Float = 0.75;
    var defaultAlbumZoom:Float = 0.75;
    
    var intendedColor:Int;
    // Material Design 3 default color scheme (purple-based)
    var _curOnDarkColor:Int = 0xFFF3EBFF;  // On-Surface: light purple for primary text
    var _curHeaderColor:Int = 0xFF6B11AA;  // Primary: vibrant purple for headers
    var _curAccentColor:Int = 0xFFB566FF;  // Primary Variant: bright purple for interactive elements (improved visibility)
    var _curLabelColor:Int = 0xFF6B6875;   // On-Surface Variant: muted purple-gray for labels
    
    // Audio
    public static var vocals:FlxSound = null;
    public static var opponentVocals:FlxSound = null;
    public static var instSound:FlxSound = null;

    // Async inst loading — avoids main-thread stutter when switching songs
    #if (target.threaded && sys)
    var _pendingInstSound:openfl.media.Sound = null;
    var _pendingInstToken:Int = 0;
    var _pendingInstIndex:Int = -1;
    var _pendingInstBpm:Float = 102;
    var _instLoadMutex:Mutex = new Mutex();
    #end
    
    // Touch support
    #if mobile
    var backChip:MaterialChip;
    var touchScroll:funkin.mobile.backend.TouchScroll;
    var difficultyScroll:funkin.mobile.backend.TouchScroll;
    var backChipHitbox:FlxSprite;
    var gameplayChangersChip:MaterialChip;
    var resetScoreChip:MaterialChip;
    var gameplayChangersChipHitbox:FlxSprite;
    var resetScoreChipHitbox:FlxSprite;
    #end
    
    var playTouchTarget:FlxSprite;
    // Icon arrays for songs
    private var iconArray:Array<HealthIcon> = [];
    
    var _drawDistance:Int = 6;
    var _lastVisibles:Array<Int> = [];

    var _lastDiffCurSelected:Int = -1;
    var _lastDiffListLen:Int = -1;
    var _lastDiffForStyle:Int = -1;   // gate setBorderStyle rebuilds
    var _cachedModsCount:Int = 0;     // Mods.parseList() cached — never changes during freeplay
    var _timeAccum:Float = 0.0;       // throttle Date.now() to 1/sec
    var _lastIntendedColor:Int = -1;  // gate HSL recompute
    var _cachedTargetOnDark:Int = 0;
    var _cachedTargetHeader:Int = 0;
    var _cachedTargetAccent:Int = 0;
    var _cachedTargetLabel:Int = 0;
    var _cachedVisibleIndices:Array<Int> = [];
    var _visCacheValid:Bool = false;
    var _lastShowingFavorites:Bool = false;
    var _vizUpdateAccum:Float = 0.0;
    var _vizTargetHeights:Array<Float> = [];
    var _vizCurrentHeights:Array<Float> = [];
    #if mobile
    static inline var VIZ_UPDATE_INTERVAL:Float = 1 / 45;
    #else
    static inline var VIZ_UPDATE_INTERVAL:Float = 1 / 60;
    #end
    static inline var VIZ_MIN_H:Float = 2;
    static inline var VIZ_SMOOTH_SPEED:Float = 18;
    var _lastAppliedBgZoom:Float = -1;
    var _lastAppliedAlbumZoom:Float = -1;

    var diffViewOffset:Float = 0;
    var lerpDiffViewOffset:Float = 0;

    static inline var DIFF_DRAW_DIST:Float = 3.0;
    static inline var DIFF_CENTER_X:Float = 170;
    static inline var DIFF_PILL_STEP:Float = 90;
    
    // UI Elements (existing)
    var bg:FlxSprite;
    var blackOverlay:FlxSprite;
    var dinamic:FlxSprite;
    var album:FlxSprite;
    var bgTransition:FlxSprite;
    var bgFadeTween:FlxTween = null;
    var currentBgAssetKey:String = 'menuDesat';
    var currentBgFolderKey:String = '';
    var currentAlbumAssetKey:String = 'albumRoll/example';
    var uiprincipal:FlxSprite;
    var list:FlxSprite;
    var cardsGroup:FlxTypedGroup<FlxSprite>;
    var cardSongText:FlxTypedGroup<FlxText>;
    var cardModText:FlxTypedGroup<FlxText>;
    var diffsGroup:FlxTypedGroup<FlxSprite>;
    var diffsTextGroup:FlxTypedGroup<FlxText>;
    var barsGroup:FlxTypedGroup<FlxSprite>;
    var _barTweens:Array<FlxTween> = []; // One tween per bar, for proper cancellation

    // Full-width bottom spectral visualizer bars (driven by SpectralAnalyzer)
    var vizBarsGroup:FlxTypedGroup<FlxSprite>;

    // SpectralAnalyzer for live bottom bar visualization
    #if funkin.vis
    var _analyzer:SpectralAnalyzer = null;
    var _analyzerLevels:Array<funkin.vis.dsp.SpectralAnalyzer.Bar> = null;
    // Flag: retry analyzer init every frame until __audioSource is ready (same pattern as ABotSpeaker).
    var _needsAnalyzerInit:Bool = false;
    #end

    // Note density bar constants (small section, chart-data only)
    static inline var BAR_COUNT:Int    = 24;
    static inline var BAR_WIDTH:Int    = 8;
    static inline var BAR_STEP:Int     = 10;   // bar width + gap
    static inline var BAR_START_X:Float = 417;
    static inline var BAR_BASELINE_Y:Float = 605;
    static inline var BAR_MIN_H:Int    = 4;
    static inline var BAR_MAX_H:Int    = 64;

    // Full-width bottom spectral visualizer bar constants
    #if mobile
    static inline var VIZ_BAR_COUNT:Int = 96;
    #else
    static inline var VIZ_BAR_COUNT:Int = 160;
    #end
    static inline var VIZ_BAR_MAX_H:Int = 240;
    static inline var VIZ_BAR_FILL:Float = 0.62;
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

    var freeplayText:FlxText;
    var searchInput:PsychUIInputText;
    var searchQuery:String = '';

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
    var searchTipText:FlxText;

    var allLevels:FlxText;
    var favorites:FlxText;
    
    // Additional UI elements
    var opponentModeText:FlxText;
    var missingTextBG:FlxSprite;
    var missingText:FlxText;
    var noFavoritesText:FlxText;
    var bottomString:String;
    var bottomText:FlxText;
    
    override public function create():Void {
        super.create();

        // Initialize instance
        instance = this;
        persistentUpdate = true;
        PlayState.isStoryMode = false;
        WeekData.reloadWeekFiles(false);

        #if DISCORD_ALLOWED
        // Updating Discord Rich Presence
        DiscordClient.changePresence("In the Menus", null);
        #end

        loadSongsFromWeeks();
        loadStepManiaFiles();
        loadFavorites();

        Cursor.show();

        bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);
		bg.screenCenter();

        bgTransition = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
        bgTransition.antialiasing = ClientPrefs.data.antialiasing;
        bgTransition.alpha = 0;
        bgTransition.visible = false;
        add(bgTransition);
        bgTransition.screenCenter();
		
		#if !mobile
		blurEffect = new BlurEffect();
		blurEffect.strength = 5.0;
		bg.shader = blurEffect.shader;
        bgTransition.shader = blurEffect.shader;
		#end
		//bgZoom = defaultBgZoom = 1;

        blackOverlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackOverlay.alpha = 0.5;
		add(blackOverlay);

        // Full-width bottom spectral visualizer bars — behind all UI, above blackOverlay.
        // Driven exclusively by SpectralAnalyzer; note density bars are separate.
        vizBarsGroup = new FlxTypedGroup<FlxSprite>();
        var vizBarW:Int = Std.int(FlxG.width / VIZ_BAR_COUNT); // 1280 / 64 = 20px per slot
        var vizDrawW:Int = Std.int(Math.max(1, vizBarW * VIZ_BAR_FILL));
        var vizOffsetX:Float = (vizBarW - vizDrawW) * 0.5;
        for(i in 0...VIZ_BAR_COUNT) {
            var vbar:FlxSprite = new FlxSprite();
            vbar.makeGraphic(vizDrawW, VIZ_BAR_MAX_H, FlxColor.WHITE);
            vbar.x = i * vizBarW + vizOffsetX;
            vbar.y = FlxG.height - 2;
            vbar.scale.y = 2 / VIZ_BAR_MAX_H;
            vbar.alpha = 0.0;
            vbar.ID = i;
            vizBarsGroup.add(vbar);
            _vizTargetHeights.push(VIZ_MIN_H);
            _vizCurrentHeights.push(VIZ_MIN_H);
        }
        add(vizBarsGroup);

        freeplayText = new FlxText(45, 28, 0, 'Freeplay');
        freeplayText.setFormat(Paths.font('inter-bold.otf'), 32, FlxColor.WHITE, 'left');
        freeplayText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.fromRGBFloat(0, 0, 0, 0.45), 2, 1);
        add(freeplayText);

        dinamic = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/dinamic'));
		dinamic.antialiasing = ClientPrefs.data.antialiasing;
		dinamic.setGraphicSize(FlxG.width, FlxG.height);
		dinamic.updateHitbox();
		add(dinamic);

        album = new FlxSprite().loadGraphic(Paths.image('albumRoll/example'));
        album.x = 49;
        album.y = 98;
        album.antialiasing = ClientPrefs.data.antialiasing;
        album.setGraphicSize(100, 100);
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
        searchIcon.color = FlxColor.GRAY;
        searchIcon.antialiasing = ClientPrefs.data.antialiasing;
        searchIcon.setGraphicSize(16, 16);
        searchIcon.updateHitbox();
        add(searchIcon);

        // Functional search input
        searchInput = new PsychUIInputText(920, 165, 240, '', 14);
        searchInput.onChange = function(old:String, cur:String) {
            searchQuery = cur.toLowerCase();
            filterSongs();
            if(cur == '') {
                searchTipText.visible = true;
            } else {
                searchTipText.visible = false;
            }
        };
                
        
        add(searchInput);

        searchTipText = new FlxText(925, 168, 0, 'Search here..');
        searchTipText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.GRAY, 'left');
        add(searchTipText);

        playIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/play'));
        playIcon.x = 80.8;
        playIcon.y = 566.7;
        playIcon.antialiasing = ClientPrefs.data.antialiasing;
        playIcon.setGraphicSize(30, 30);
        playIcon.updateHitbox();
        add(playIcon);

        playText = new FlxText(115, 565, 0, 'Play');
        playText.setFormat(Paths.font('inter-bold.otf'), 22, FlxColor.PURPLE, 'left');
        add(playText);

        playTouchTarget = new FlxSprite(playIcon.x - 30, playIcon.y - 12);
        playTouchTarget.makeGraphic(
            Std.int((playText.x + playText.width) - playTouchTarget.x + 30),
            Std.int(Math.max(playIcon.height, playText.height) + 24),
            FlxColor.WHITE
        );

        playTouchTarget.alpha = 0;
        add(playTouchTarget);

        #if mobile
        backChip = new MaterialChip(54, 60, Language.getPhrase('back', 'Back'), ASSIST, false, goBackToMainMenu);
        add(backChip);
        backChipHitbox = createMobileActionHitbox(backChip, 14, 10);

        gameplayChangersChip = new MaterialChip(backChip.x + Math.max(backChip.width, 112) + 16, 60, Language.getPhrase('gameplay_changers_menu', 'Gameplay Changers'), ASSIST, false, openGameplayChangersSubstate);
        add(gameplayChangersChip);
        gameplayChangersChipHitbox = createMobileActionHitbox(gameplayChangersChip, 14, 10);

        resetScoreChip = new MaterialChip(gameplayChangersChip.x + Math.max(gameplayChangersChip.width, 172) + 12, 60,
            Language.getPhrase('reset_score', 'Reset score'), ASSIST, false, openResetScoreSubstate);
        add(resetScoreChip);
        resetScoreChipHitbox = createMobileActionHitbox(resetScoreChip, 14, 10);
        #end

        starIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/star'));
        starIcon.x = 299.8;
        starIcon.y = 570.5;
        starIcon.antialiasing = ClientPrefs.data.antialiasing;
        starIcon.setGraphicSize(24, 24);
        starIcon.updateHitbox();
        add(starIcon);

        starFullIcon = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/icons/starFull'));
        starFullIcon.x = 299.8;
        starFullIcon.y = 570.5;
        starFullIcon.antialiasing = ClientPrefs.data.antialiasing;
        starFullIcon.setGraphicSize(24, 24);
        starFullIcon.updateHitbox();
        starFullIcon.visible = false;
        add(starFullIcon);

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

        themeText = new FlxText(294.2, 230, 0, 'Example Theme');
        themeText.setFormat(Paths.font('inter-bold.otf'), 36, FlxColor.WHITE, 'left');
        themeText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.fromRGBFloat(0, 0, 0, 0.45), 2, 1);
        add(themeText);

        modText = new FlxText(294.2, 275.5, 0, 'Friday Night Funkin\'');
        modText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.WHITE, 'left');
        modText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.fromRGBFloat(0, 0, 0, 0.45), 2, 1);
        add(modText);

        todayText = new FlxText(1126, 38, 0, '20:14\n28/02/2026');
        todayText.setFormat(Paths.font('inter-bold.otf'), 13, FlxColor.BLACK, 'center');
        add(todayText);

        notesText = new FlxText(417, 470, 0, 'Notes Density');
        notesText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.BLACK, 'left');
        add(notesText);

        noteDiffText = new FlxText(613.2, 473.8, 0, '(Hard) 123 notes');
        noteDiffText.setFormat(Paths.font('inter-bold.otf'), 10, FlxColor.GRAY, 'left');
        add(noteDiffText);

        diffText = new FlxText(42.5, 454.2, 0, 'Select Difficulty');
        diffText.setFormat(Paths.font('inter-bold.otf'), 17, FlxColor.WHITE, 'left');
        diffText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.fromRGBFloat(0, 0, 0, 0.45), 2, 1);
        add(diffText);

        songsText = new FlxText(883, 124, 0, 'Songs List');
        songsText.setFormat(Paths.font('inter-bold.otf'), 18, FlxColor.BLACK, 'left');
        add(songsText);

        totalSongsText = new FlxText(990, 40, 0, 'TOTAL SONGS\n123');
        totalSongsText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.WHITE, 'right');
        totalSongsText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.fromRGBFloat(0, 0, 0, 0.45), 2, 1);
        add(totalSongsText);

        modsLoadedText = new FlxText(890, 40, 0, 'MODS LOADED\n5');
        modsLoadedText.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.WHITE, 'right');
        modsLoadedText.setBorderStyle(FlxTextBorderStyle.SHADOW, FlxColor.fromRGBFloat(0, 0, 0, 0.45), 2, 1);
        add(modsLoadedText);

        allLevels = new FlxText(890, 210, 0, 'All Levels');
        allLevels.setFormat(Paths.font('inter-bold.otf'), 16, FlxColor.PURPLE, 'center');
        add(allLevels);

        favorites = new FlxText(980, 210, 0, 'Favorites');
        favorites.setFormat(Paths.font('inter-bold.otf'), 16, FlxColor.GRAY, 'center');
        add(favorites);

        diffsGroup = new FlxTypedGroup<FlxSprite>();
        add(diffsGroup);
        
        diffsTextGroup = new FlxTypedGroup<FlxText>();
        add(diffsTextGroup);

        updateDifficultyDisplay();

        cardsGroup = new FlxTypedGroup<FlxSprite>();
        add(cardsGroup);
        
        cardSongText = new FlxTypedGroup<FlxText>();
        add(cardSongText);

        cardModText = new FlxTypedGroup<FlxText>();
        add(cardModText);

        for (i in 0...songs.length) {
            if (songs[i] == null || songs[i].songName == null || songs[i].songName == "") {
                trace('Skipping invalid song at index $i');
                continue;
            }
            
            try {
                var card:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/card'));
                card.x = 880;
                card.y = 275 + (i * 74);
                card.antialiasing = ClientPrefs.data.antialiasing;
                card.color = songs[i].color; 
                card.updateHitbox();
                card.ID = i;
                cardsGroup.add(card);
                
                var songText:FlxText = new FlxText(0, 0, 0, songs[i].songName);
                songText.setFormat(Paths.font('inter-bold.otf'), 14, FlxColor.BLACK, 'left');
                songText.x = 950;
                songText.y = 290 + (i * 74);
                songText.ID = i;
                cardSongText.add(songText);

                var modName:String = songs[i].folder;
                if (modName == null || modName == '') {
                    modName = 'Friday Night Funkin\'';
                }
                var modTextItem:FlxText = new FlxText(0, 0, 0, modName);
                modTextItem.setFormat(Paths.font('inter-bold.otf'), 12, FlxColor.GRAY, 'left');
                modTextItem.x = 950;
                modTextItem.y = 310 + (i * 74);
                modTextItem.ID = i;
                cardModText.add(modTextItem);
                
                // Set mod context for proper icon loading
                var previousMod:String = Mods.currentModDirectory;
                if(songs[i].folder != null && songs[i].folder != '') {
                    Mods.currentModDirectory = songs[i].folder;
                }
                
                var characterName = songs[i].songCharacter;
                if (songs[i].isStepMania) {
                    characterName = 'stepmania';
                }
                if (characterName == null || characterName == "") {
                    characterName = 'face';
                }
                
                var icon:HealthIcon = new HealthIcon(characterName, false, false);
                icon.setGraphicSize(70, 70);
                icon.updateHitbox();
                icon.x = 840;
                icon.y = 235 + (i * 74);
                iconArray.push(icon);
                add(icon);
                
                // Restore previous mod context
                Mods.currentModDirectory = previousMod;
                
            } catch (e:Dynamic) {
                trace('Error creating card for song ${songs[i].songName}: $e');
                continue;
            }
        }

        barsGroup = new FlxTypedGroup<FlxSprite>();
        add(barsGroup);
        
        // Bars: vertical equalizer-style, anchored from BAR_BASELINE_Y upward.
        // Fixed 12xBAR_MAX_H bitmap so setGraphicSize never allocs new BitmapData.
        _barTweens = [];
        for (i in 0...BAR_COUNT) {
            var bar:FlxSprite = new FlxSprite();
            bar.makeGraphic(BAR_WIDTH, BAR_MAX_H, FlxColor.WHITE);
            bar.setGraphicSize(BAR_WIDTH, BAR_MIN_H);
            bar.updateHitbox();
            bar.color = FlxColor.PURPLE;
            bar.x = BAR_START_X + (i * BAR_STEP);
            bar.y = BAR_BASELINE_Y - BAR_MIN_H;
            bar.alpha = 0.18;
            bar.ID = i;
            barsGroup.add(bar);
            _barTweens.push(null);
        }

        if(curSelected >= songs.length) curSelected = 0;
        if(songs.length > 0) {
            bg.color = songs[curSelected].color;
            intendedColor = bg.color;
            dinamic.color = intendedColor;
        }
        viewOffset = curSelected;
        lerpViewOffset = curSelected;
        
        curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));
        
        #if mobile
        var leText:String = Language.getPhrase("freeplay_tip_mobile", "Tap Play to start / Tap the Gameplay Changers or Reset Score chips / Tap a song card to select it.");
        #else
        final space:String = "SPACE";
        final control:String = "CTRL";
        final reset:String = "RESET";
        var leText:String = Language.getPhrase("freeplay_tip", "Press {1} to listen to the Song / Press {2} to open the Gameplay Changers Menu / Press {3} to Reset your Score and Accuracy.", [space, control, reset]);
        #end
        bottomString = leText;
        var size:Int = 16;
        bottomText = new FlxText(0, FlxG.height - 24, FlxG.width, leText, size);
        bottomText.setFormat(Paths.font("inter-bold.otf"), size, FlxColor.WHITE, CENTER);
        bottomText.scrollFactor.set();
        add(bottomText);
        
        opponentModeText = new FlxText(FlxG.width * 0.68, 5, 0, "", 20);
        opponentModeText.setFormat(Paths.font("inter-bold.otf"), 20, FlxColor.YELLOW, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        opponentModeText.borderSize = 1.5;
        opponentModeText.visible = false;
        add(opponentModeText);
        
        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        missingTextBG.alpha = 0.6;
        missingTextBG.visible = false;
        add(missingTextBG);
        
        missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
        missingText.setFormat(Paths.font("inter-bold.otf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        missingText.scrollFactor.set();
        missingText.visible = false;
        add(missingText);
        
        noFavoritesText = new FlxText(880, 400, 300, '', 20);
        noFavoritesText.setFormat(Paths.font("inter-bold.otf"), 20, FlxColor.GRAY, CENTER);
        noFavoritesText.text = "¯\\_(ツ)_/¯\n\nNo favorites yet";
        noFavoritesText.visible = false;
        add(noFavoritesText);
        
        Conductor.bpm = 102;
        
        // Start the visualizer with the freeplay menu music right away.
        #if funkin.vis
        _needsAnalyzerInit = true;
        #end
        
        changeSelection();
        updateTexts();
        updateDynamicData();
        
        #if mobile
        touchScroll = new funkin.mobile.backend.TouchScroll(true);
        difficultyScroll = new funkin.mobile.backend.TouchScroll(false);
        funkin.mobile.backend.TouchUtil.setScrollHandler(touchScroll);
        #end
    }
    
    /**
     * Load songs from all weeks
     */
    function loadSongsFromWeeks():Void {
        final accept:String = (controls.mobileC) ? "A" : "ACCEPT";
        final reject:String = (controls.mobileC) ? "B" : "BACK";

        if(WeekData.weeksList.length < 1) {
            FlxTransitionableState.skipNextTransIn = true;
            persistentUpdate = false;
            MusicBeatState.switchState(new funkin.ui.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress " + accept + " to go to the Week Editor Menu.\nPress " + reject + " to return to Main Menu.",
                function() MusicBeatState.switchState(new funkin.ui.debug.MasterEditorMenu()),
                function() MusicBeatState.switchState(new funkin.ui.mainmenu.MainMenuState())));
            return;
        }

        for (i in 0...WeekData.weeksList.length) {
            if(weekIsLocked(WeekData.weeksList[i])) continue;

            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
            var leSongs:Array<String> = [];
            var leChars:Array<String> = [];

            for (j in 0...leWeek.songs.length) {
                leSongs.push(leWeek.songs[j][0]);
                leChars.push(leWeek.songs[j][1]);
            }

            WeekData.setDirectoryFromWeek(leWeek);
            for (song in leWeek.songs) {
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3)
                    colors = [146, 113, 253];
                var songColor:Int = FlxColor.fromRGB(colors[0], colors[1], colors[2]);
                addSong(song[0], i, song[1], songColor);
            }
        }
        
        loadFavorites();
        
        Mods.loadTopMod();

        // Cache mods count once — never changes while inside freeplay.
        #if MODS_ALLOWED
        var _ml = Mods.parseList();
        _cachedModsCount = (_ml != null) ? _ml.enabled.length : 0;
        #end
    }
    
    /**
     * Add a song to the list
     */
    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int) {
        songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
    }
    
    /**
     * Check if week is locked
     */
    function weekIsLocked(name:String):Bool {
        var leWeek:WeekData = WeekData.weeksLoaded.get(name);
        return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!funkin.ui.story.StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !funkin.ui.story.StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
    }

    function getVisibleSongIndices():Array<Int> {
        var visibleIndices:Array<Int> = [];
        if(showingFavorites) {
            for(i in 0...songs.length) {
                if(songs[i].isFavorite) {
                    visibleIndices.push(i);
                }
            }
        } else {
            for(i in 0...songs.length) {
                visibleIndices.push(i);
            }
        }
        return visibleIndices;
    }

    function getCurrentVisibleSelectionIndex(visibleIndices:Array<Int>):Int {
        for(vi in 0...visibleIndices.length) {
            if(visibleIndices[vi] == curSelected) {
                return vi;
            }
        }
        return 0;
    }
    
    /**
     * Update function - main game loop
     */
    override function update(elapsed:Float) {
        super.update(elapsed);

        #if (target.threaded && sys)
        // Dispatch a pending inst sound loaded by the background thread.
        // playMusic() and all OpenAL calls must happen on the main thread.
        _instLoadMutex.acquire();
        var pendingSound:openfl.media.Sound = _pendingInstSound;
        var pendingToken:Int = _pendingInstToken;
        var pendingIndex:Int = _pendingInstIndex;
        var pendingBpm:Float = _pendingInstBpm;
        if(pendingSound != null) _pendingInstSound = null;
        _instLoadMutex.release();

        if(pendingSound != null && pendingToken == previewLoadToken && pendingIndex == curSelected) {
            try {
                // Register in Paths cache so it gets cleaned up correctly later
                var cacheKey:String = Paths.getPath(
                    Language.getFileTranslation('${Paths.formatToSongPath(songs[pendingIndex].songName)}/Inst') + '.${Paths.SOUND_EXT}',
                    openfl.utils.AssetType.SOUND, 'songs', true
                );
                if(!Paths.currentTrackedSounds.exists(cacheKey))
                    Paths.currentTrackedSounds.set(cacheKey, pendingSound);
                Paths.localTrackedAssets.push(cacheKey);

                FlxG.sound.playMusic(pendingSound, 0, true);
                FlxG.sound.music.fadeIn(1.0, 0, 0.7);
                instSound = FlxG.sound.music;
                instPlaying = pendingIndex;

                Conductor.bpm = pendingBpm;

                #if funkin.vis
                _analyzer = null;
                _analyzerLevels = null;
                _needsAnalyzerInit = true;
                #end
            } catch(e:Dynamic) {
                trace('[FreePlay] Error playing async-loaded inst: $e');
                FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
            }
        }
        #end

        updateTexts(elapsed);

        if(WeekData.weeksList.length < 1)
            return;

        if (FlxG.sound.music == null) {
            FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
        }

        if (FlxG.sound.music.volume < 0.7)
            FlxG.sound.music.volume += 0.5 * elapsed;
        
        // instSound is now an alias for FlxG.sound.music when preview is active,
        // so a single assignment covers both states.
        Conductor.songPosition = FlxG.sound.music.time;
        
        bgZoom = FlxMath.lerp(defaultBgZoom, bgZoom, Math.exp(-elapsed * 3.125));
        if (_lastAppliedBgZoom < 0 || Math.abs(bgZoom - _lastAppliedBgZoom) > 0.0008) {
            bg.scale.set(bgZoom, bgZoom);
            bg.updateHitbox();
            bg.screenCenter();
            _lastAppliedBgZoom = bgZoom;
        }
        
        albumZoom = FlxMath.lerp(defaultAlbumZoom, albumZoom, Math.exp(-elapsed * 4));
        albumZoom = Math.min(albumZoom, 1.01);
        
        var baseX:Float = 49;
        var baseY:Float = 98;
        var baseSize:Float = 206;
        var centerX:Float = baseX + (baseSize / 2);
        var centerY:Float = baseY + (baseSize / 2);
        
        if (_lastAppliedAlbumZoom < 0 || Math.abs(albumZoom - _lastAppliedAlbumZoom) > 0.001) {
            album.scale.set(albumZoom, albumZoom);
            album.updateHitbox();
            _lastAppliedAlbumZoom = albumZoom;
        }

        album.x = centerX - (album.width / 2);
        album.y = centerY - (album.height / 2);

        lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
        lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

        if (Math.abs(lerpScore - intendedScore) <= 10)
            lerpScore = intendedScore;
        if (Math.abs(lerpRating - intendedRating) <= 0.01)
            lerpRating = intendedRating;

        updateDynamicData();

        var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

        // Disable navigation when typing in search
        var isTyping:Bool = (PsychUIInputText.focusOn == searchInput);

        if (!isTyping) {
            #if mobile
            var touchSongNavigationActive:Bool = false;
            var touchDiffNavigationActive:Bool = false;
            var anyTouchInDiffArea:Bool = isAnyTouchInDifficultyArea();

            if (anyTouchInDiffArea)
            {
                if (difficultyScroll != null)
                {
                    var diffScrollDelta = difficultyScroll.update();
                    touchDiffNavigationActive = difficultyScroll.isTouchActive() || difficultyScroll.isCurrentlyScrolling();

                    if (Math.abs(diffScrollDelta) > 0.01 && Difficulty.list.length > 0)
                    {
                        diffViewOffset += -diffScrollDelta / 120;
                        diffViewOffset = FlxMath.bound(diffViewOffset, 0, Difficulty.list.length - 1);
                    }

                    // If the difficulty scroll detected a short tap, forward it to the
                    // generic pointer handler so single taps can select a pill.
                    if (difficultyScroll.wasTapped()) {
                        var tapPos = difficultyScroll.getTapPosition();
                        if (tapPos != null) {
                            handleFreeplayPointerPress(tapPos.x, tapPos.y);
                        }
                    }

                    if (difficultyScroll.didReleaseScroll() && Difficulty.list.length > 0)
                    {
                        var snappedDiff:Int = Math.round(diffViewOffset);
                        if (snappedDiff < 0) snappedDiff = 0;
                        else if (snappedDiff > Difficulty.list.length - 1) snappedDiff = Difficulty.list.length - 1;

                        if (snappedDiff != curDifficulty)
                        {
                            changeDiff(snappedDiff - curDifficulty);
                            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                        }
                        diffViewOffset = snappedDiff;
                    }
                }
            }
            else if (touchScroll != null)
            {
                var scrollDelta = touchScroll.update();
                touchSongNavigationActive = touchScroll.isTouchActive() || touchScroll.isCurrentlyScrolling();

                var visibleTouchIndices:Array<Int> = getVisibleSongIndices();
                if (visibleTouchIndices.length > 0)
                {
                    if (Math.abs(scrollDelta) > 0.01)
                    {
                        viewOffset += -scrollDelta / 74;
                        viewOffset = FlxMath.bound(viewOffset, 0, visibleTouchIndices.length - 1);
                    }

                    if (touchScroll.didReleaseScroll())
                    {
                        var snappedVisibleIndex:Int = Math.round(viewOffset);
                        if (snappedVisibleIndex < 0) snappedVisibleIndex = 0;
                        else if (snappedVisibleIndex > visibleTouchIndices.length - 1) snappedVisibleIndex = visibleTouchIndices.length - 1;

                        viewOffset = snappedVisibleIndex;
                    }
                }
            }

            var allowSongDigitalNav:Bool = !touchSongNavigationActive;
            var allowDiffDigitalNav:Bool = !touchDiffNavigationActive;
            var allowPointerClick:Bool = !touchSongNavigationActive && !touchDiffNavigationActive;

            if (touchScroll != null && touchScroll.wasTapped() && allowPointerClick)
            {
                var tapPos = touchScroll.getTapPosition();
                if (tapPos != null)
                {
                    handleFreeplayPointerPress(tapPos.x, tapPos.y);
                }
            }
            #end

            var mouseOverPills:Bool = FlxG.mouse.y > 475 && FlxG.mouse.y < 515;

            if (FlxG.mouse.wheel != 0 && !mouseOverPills) {
                viewOffset -= FlxG.mouse.wheel;
                viewOffset = Math.max(0, Math.min(songs.length - 1, viewOffset));
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
            }

            if (FlxG.mouse.wheel != 0 && mouseOverPills) {
                diffViewOffset -= FlxG.mouse.wheel;
                diffViewOffset = Math.max(0, Math.min(Difficulty.list.length - 1, diffViewOffset));
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
            }

            if (
                FlxG.mouse.justPressed
                #if mobile
                && allowPointerClick
                #end
            ) {
                handleFreeplayPointerPress(FlxG.mouse.x, FlxG.mouse.y);
            }

            if(
                #if mobile
                allowSongDigitalNav
                #else
                true
                #end
            ) {
                var songUpPressed:Bool = controls.UI_UP_P;
                var songDownPressed:Bool = controls.UI_DOWN_P;
                var songUpHeld:Bool = controls.UI_UP;
                var songDownHeld:Bool = controls.UI_DOWN;

                if(songUpPressed) {
                    changeSelection(-shiftMult);
                    holdTime = 0;
                }
                if(songDownPressed) {
                    changeSelection(shiftMult);
                    holdTime = 0;
                }

                if(songDownHeld || songUpHeld) {
                    var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                    holdTime += elapsed;
                    var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

                    if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                        changeSelection((checkNewHold - checkLastHold) * (songUpHeld ? -shiftMult : shiftMult));
                }
            }

            if(
                #if mobile
                allowDiffDigitalNav
                #else
                true
                #end
            && controls.UI_LEFT_P) {
                changeDiff(-1);
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            }
            if(
                #if mobile
                allowDiffDigitalNav
                #else
                true
                #end
            && controls.UI_RIGHT_P) {
                changeDiff(1);
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            }
        }
        
        if (FlxG.keys.justPressed.TAB && !isTyping) {
            viewingOpponentScores = !viewingOpponentScores;
            FlxG.sound.play(Paths.sound('scrollMenu'));
            
            #if !switch
            intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
            intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
            #end
            
            if (viewingOpponentScores) {
                opponentModeText.text = "OPPONENT MODE";
                opponentModeText.visible = true;
            } else {
                opponentModeText.visible = false;
            }
        }

        if (controls.BACK && !isTyping) {
            goBackToMainMenu();
        }

        // Gameplay changers
        if(FlxG.keys.justPressed.CONTROL && !isTyping) {
            openGameplayChangersSubstate();
        }
        
        if(FlxG.keys.justPressed.SPACE && !isTyping) {
            if(instPlaying != curSelected) {
                playInstPreview();
            } else if (instPlaying == curSelected) {
                stopInstPreview();
            }
        }
        
        if (controls.ACCEPT && !isTyping) {
            playSong();
        }
        
        // Reset score
        if(controls.RESET && !isTyping) {
            openResetScoreSubstate();
        }
    }
    
    /**
     * Update dynamic data displays (scores, BPM, etc.)
     */
    function updateDynamicData():Void {
        if(songs.length == 0) return;
        
        var ratingPercent:Float = CoolUtil.floorDecimal(lerpRating * 100, 2);
        var ratingSplit:Array<String> = Std.string(Math.abs(ratingPercent)).split('.');
        if(ratingSplit.length < 2) ratingSplit.push('');
        while(ratingSplit[1].length < 2) ratingSplit[1] += '0';
        var ratingDisplay:String = ratingSplit.join('.');
        if(ratingPercent < 0) ratingDisplay = '-' + ratingDisplay;
        
        // Gate score/rating text rebuilds — FlxText redraws its bitmap every time .text is set.
        var scoreStr:String = Std.string(lerpScore);
        if(scoreData.text != scoreStr) scoreData.text = scoreStr;
        var accStr:String = ratingDisplay + '%';
        if(accuracyData.text != accStr) accuracyData.text = accStr;
        
        #if !switch
        var maxCombo:Int = 0;
        comboData.text = maxCombo + 'x';

        var ratingLetter:String = 'N/A';
        if(lerpRating >= 1.0) ratingLetter = 'S++';
        else if(lerpRating >= 0.95) ratingLetter = 'S+';
        else if(lerpRating >= 0.90) ratingLetter = 'S';
        else if(lerpRating >= 0.85) ratingLetter = 'A';
        else if(lerpRating >= 0.75) ratingLetter = 'B';
        else if(lerpRating >= 0.65) ratingLetter = 'C';
        else if(lerpRating >= 0.50) ratingLetter = 'D';
        else ratingLetter = 'F';
        if(ratingData.text != ratingLetter) ratingData.text = ratingLetter;
        #end

        var themeName:String = songs[curSelected].songName;
        if(themeText.text != themeName) themeText.text = themeName;
        var folderName:String = songs[curSelected].folder != '' ? songs[curSelected].folder : 'Friday Night Funkin\'';
        if(modText.text != folderName) modText.text = folderName;

        var totalStr:String = 'TOTAL SONGS\n' + songs.length;
        if(totalSongsText.text != totalStr) totalSongsText.text = totalStr;

        // Use cached mods count — computed once at create, no disk I/O per frame.
        var modsStr:String = 'MODS LOADED\n' + _cachedModsCount;
        if(modsLoadedText.text != modsStr) modsLoadedText.text = modsStr;

        var diffStr:String = 'Select Difficulty (' + Difficulty.list.length + '):';
        if(diffText.text != diffStr) diffText.text = diffStr;

        // Throttle clock to once per second — Date.now() every frame is wasteful.
        _timeAccum += FlxG.elapsed;
        if(_timeAccum >= 1.0 || todayText.text == '') {
            _timeAccum = 0.0;
            var now = Date.now();
            var hours = now.getHours();
            var minutes = now.getMinutes();
            var day = now.getDate();
            var month = now.getMonth() + 1;
            var year = now.getFullYear();
            var timeStr = (hours < 10 ? '0' : '') + hours + ':' + (minutes < 10 ? '0' : '') + minutes;
            var dateStr = (day < 10 ? '0' : '') + day + '/' + (month < 10 ? '0' : '') + month + '/' + year;
            todayText.text = timeStr + '\n' + dateStr;
        }
    }
    
    /**
     * Update difficulty icons display
     */
    function updateDifficultyDisplay():Void {
        if (Difficulty.list.length == 0) return;

        var listLen:Int = Difficulty.list.length;

        if (_lastDiffCurSelected != curSelected || _lastDiffListLen != listLen) {
            _lastDiffCurSelected = curSelected;
            _lastDiffListLen = listLen;

            for (m in diffsGroup.members) {
                if (m != null) m.destroy();
            }
            for (m in diffsTextGroup.members) {
                if (m != null) m.destroy();
            }
            diffsGroup.clear();
            diffsTextGroup.clear();

            for (i in 0...listLen) {
                var diffIcon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/freeplay/diff'));
                diffIcon.antialiasing = ClientPrefs.data.antialiasing;
                diffIcon.color = getDifficultyColorForIcon(Difficulty.getString(i));
                diffIcon.updateHitbox();
                diffIcon.ID = i;
                diffsGroup.add(diffIcon);

                var label:FlxText = new FlxText(0, 0, 0, Difficulty.getString(i));
                label.setFormat(Paths.font('inter-bold.otf'), 14, FlxColor.BLACK, 'center');
                label.ID = i;
                diffsTextGroup.add(label);
            }
        }

        for (i in 0...diffsGroup.members.length) {
            var pill = diffsGroup.members[i];
            var lbl = diffsTextGroup.members[i];
            if (pill == null) continue;

            var difference:Float = i - lerpDiffViewOffset;
            var targetX:Float = DIFF_CENTER_X + difference * DIFF_PILL_STEP;

            pill.x = targetX;
            pill.y = 485.2;

            var dist:Float = Math.abs(difference);
            var targetAlpha:Float = (dist > DIFF_DRAW_DIST) ? 0 : (i == curDifficulty ? 1.0 : 0.5);
            pill.alpha = targetAlpha;

            applyHorizontalClip(pill, PILL_CLIP_X_MIN, PILL_CLIP_X_MAX);
            if (targetAlpha <= 0) { pill.visible = false; pill.clipRect = null; }

            if (lbl != null) {
                lbl.x = targetX + (pill.width / 2) - (lbl.width / 2);
                lbl.y = 495.5;
                lbl.alpha = targetAlpha;
                // Gate setBorderStyle — each call forces a FlxText bitmap rebuild.
                if(_lastDiffForStyle != curDifficulty) {
                    if (i == curDifficulty) lbl.setBorderStyle(OUTLINE, FlxColor.YELLOW, 2);
                    else lbl.setBorderStyle(NONE);
                }
                applyHorizontalClip(lbl, PILL_CLIP_X_MIN, PILL_CLIP_X_MAX);
                if (targetAlpha <= 0) { lbl.visible = false; lbl.clipRect = null; }
            }
        }
    }
    
    /**
     * Get difficulty color for icon display
     */
    function getDifficultyColorForIcon(diffName:String):Int {
        var lowerName = diffName.toLowerCase();
        
        if (lowerName.contains('easy'))
            return 0x8FD9A8;
        else if (lowerName.contains('normal'))
            return 0xFFE69C;
        else if (lowerName.contains('hard'))
            return 0xFFB3BA;
        else if (lowerName.contains('erect'))
            return 0xFFB5E8;
        else if (lowerName.contains('nightmare'))
            return 0xC7A3FF;
        else
            return 0xCCCCCC; // Default gray
    }

    inline function imageExists(imageKey:String):Bool {
        return imageKey != null && imageKey.length > 0 && Paths.fileExists('images/$imageKey.png', IMAGE);
    }

    function getCurrentWeekDataForSelection():WeekData {
        if (songs == null || songs.length == 0 || curSelected < 0 || curSelected >= songs.length)
            return null;

        var weekIndex:Int = songs[curSelected].week;
        if (weekIndex < 0 || weekIndex >= WeekData.weeksList.length)
            return null;

        return WeekData.weeksLoaded.get(WeekData.weeksList[weekIndex]);
    }

    function resolveFreeplayBgAsset(song:SongMetadata, weekData:WeekData):String {
        return 'menuDesat';
    }

    inline function getSongFolderKey(song:SongMetadata):String {
        return (song != null && song.folder != null) ? Paths.formatToSongPath(song.folder) : '';
    }

    function transitionToBackground(assetKey:String):Void {
        if (bgFadeTween != null) {
            bgFadeTween.cancel();
            bgFadeTween = null;
        }

        bgTransition.loadGraphic(Paths.image(assetKey));
        bgTransition.antialiasing = ClientPrefs.data.antialiasing;
        #if !mobile
        bgTransition.shader = blurEffect.shader;
        #end
        bgTransition.alpha = 0;
        bgTransition.visible = true;
        bgTransition.scale.set(bgZoom, bgZoom);
        bgTransition.updateHitbox();
        bgTransition.screenCenter();

        bgFadeTween = FlxTween.tween(bgTransition, {alpha: 1}, 0.22, {
            onComplete: function(_:FlxTween) {
                bg.loadGraphic(Paths.image(assetKey));
                bg.antialiasing = ClientPrefs.data.antialiasing;
                #if !mobile
                bg.shader = blurEffect.shader;
                #end
                _lastAppliedBgZoom = -1;

                bgTransition.visible = false;
                bgTransition.alpha = 0;
                bgFadeTween = null;
            }
        });
    }

    function resolveAlbumArtFromJson(songKey:String):String {
        var jsonPath:String = 'images/albumRoll/$songKey.json';
        if (!Paths.fileExists(jsonPath, TEXT))
            return null;

        try {
            var raw:String = Paths.getTextFromFile(jsonPath, false);
            if (raw == null || raw.length == 0)
                return null;

            var parsed:Dynamic = Json.parse(raw);
            if (parsed == null)
                return null;

            var imageField:Dynamic = null;
            if (Reflect.hasField(parsed, 'image')) imageField = Reflect.field(parsed, 'image');
            else if (Reflect.hasField(parsed, 'album')) imageField = Reflect.field(parsed, 'album');
            else if (Reflect.hasField(parsed, 'art')) imageField = Reflect.field(parsed, 'art');
            else if (Reflect.hasField(parsed, 'key')) imageField = Reflect.field(parsed, 'key');

            if (imageField == null)
                return null;

            var imageKey:String = Std.string(imageField);
            if (imageKey == null || imageKey.length == 0)
                return null;

            if (!imageKey.startsWith('albumRoll/'))
                imageKey = 'albumRoll/' + Paths.formatToSongPath(imageKey);

            return imageExists(imageKey) ? imageKey : null;
        } catch (e:Dynamic) {
            trace('Failed to parse album JSON for $songKey: $e');
        }

        return null;
    }

    function resolveAlbumArtFromSongMetadata(songKey:String):String {
        var metadataPath:String = 'data/$songKey/metadata.json';
        if (!Paths.fileExists(metadataPath, TEXT))
            return null;

        try {
            var raw:String = Paths.getTextFromFile(metadataPath, false);
            if (raw == null || raw.length == 0)
                return null;

            var parsed:Dynamic = Json.parse(raw);
            if (parsed == null || !Reflect.hasField(parsed, 'albumId'))
                return null;

            var albumId:Dynamic = Reflect.field(parsed, 'albumId');
            if (albumId == null)
                return null;

            var albumKey:String = Paths.formatToSongPath(Std.string(albumId));
            if (albumKey == null || albumKey.length == 0)
                return null;

            var fullKey:String = 'albumRoll/$albumKey';
            return imageExists(fullKey) ? fullKey : null;
        } catch (e:Dynamic) {
            trace('Failed to parse song metadata for $songKey: $e');
        }

        return null;
    }

    function resolveAlbumArtAsset(song:SongMetadata, weekData:WeekData):String {
        var songKey:String = Paths.formatToSongPath(song.songName);

        var fromMetadata:String = resolveAlbumArtFromSongMetadata(songKey);
        if (fromMetadata != null)
            return fromMetadata;

        var directSong:String = 'albumRoll/$songKey';
        if (imageExists(directSong))
            return directSong;

        var fromJson:String = resolveAlbumArtFromJson(songKey);
        if (fromJson != null)
            return fromJson;

        if (weekData != null && weekData.songs != null && weekData.songs.length > 1) {
            var weekSongKeys:Array<String> = [];
            for (entry in weekData.songs) {
                if (entry != null && entry.length > 0 && entry[0] != null)
                    weekSongKeys.push(Paths.formatToSongPath(Std.string(entry[0])));
            }

            var curIndex:Int = weekSongKeys.indexOf(songKey);
            if (curIndex > -1) {
                if (curIndex < weekSongKeys.length - 1) {
                    var pairForward:String = 'albumRoll/' + songKey + '_' + weekSongKeys[curIndex + 1];
                    if (imageExists(pairForward))
                        return pairForward;
                }

                if (curIndex > 0) {
                    var pairBackward:String = 'albumRoll/' + weekSongKeys[curIndex - 1] + '_' + songKey;
                    if (imageExists(pairBackward))
                        return pairBackward;
                }
            }

            var groupedWeek:String = 'albumRoll/' + weekSongKeys.join('_');
            if (imageExists(groupedWeek))
                return groupedWeek;
        }

        if (weekData != null) {
            var weekFileKey:String = Paths.formatToSongPath(weekData.fileName);
            var weekNameKey:String = Paths.formatToSongPath(weekData.weekName);

            var weekCandidates:Array<String> = [
                'albumRoll/' + weekFileKey,
                'albumRoll/week-' + weekFileKey,
                'albumRoll/' + weekNameKey
            ];

            for (candidate in weekCandidates) {
                if (imageExists(candidate))
                    return candidate;
            }
        }

        return 'albumRoll/example';
    }

    function applySelectionVisualAssets():Void {
        if (songs == null || songs.length == 0 || curSelected < 0 || curSelected >= songs.length)
            return;

        var weekData:WeekData = getCurrentWeekDataForSelection();
        var selectedSong:SongMetadata = songs[curSelected];

        var bgAsset:String = resolveFreeplayBgAsset(selectedSong, weekData);
        var bgFolderKey:String = getSongFolderKey(selectedSong);
        if (bgAsset != currentBgAssetKey || bgFolderKey != currentBgFolderKey) {
            currentBgAssetKey = bgAsset;
            currentBgFolderKey = bgFolderKey;
            transitionToBackground(bgAsset);
        }

        var albumAsset:String = resolveAlbumArtAsset(selectedSong, weekData);
        if (albumAsset != currentAlbumAssetKey) {
            currentAlbumAssetKey = albumAsset;
            album.loadGraphic(Paths.image(albumAsset));
            album.antialiasing = ClientPrefs.data.antialiasing;
            album.setGraphicSize(100, 100);
            album.updateHitbox();
            _lastAppliedAlbumZoom = -1;
        }
    }

    inline function chartExistsForDifficulty(songName:String, diffName:String):Bool {
        var postfix:String = '';
        if (Paths.formatToSongPath(diffName) != Paths.formatToSongPath(Difficulty.getDefault()))
            postfix = '-' + Paths.formatToSongPath(diffName);

        var chartFile:String = songName + postfix;
        return Paths.fileExists('data/$songName/$chartFile.json', TEXT);
    }
    
    /**
     * Change song selection
     */
    function changeSelection(change:Int = 0, playSound:Bool = true, scrollView:Bool = true):Void {
        if (songs.length == 0)
            return;

        // Periodic GC for large song lists to prevent memory buildup
        #if MODS_ALLOWED
        if(change != 0 && songs.length > 100) {
            @:privateAccess
            openfl.system.System.gc();
        }
        #end

        var visibleIndices:Array<Int> = [];
        if(showingFavorites) {
            for(i in 0...songs.length) {
                if(songs[i].isFavorite) {
                    visibleIndices.push(i);
                }
            }
        } else {
            for(i in 0...songs.length) {
                visibleIndices.push(i);
            }
        }
        
        if(visibleIndices.length == 0) return;
        
        var currentVisibleIndex:Int = 0;
        for(vi in 0...visibleIndices.length) {
            if(visibleIndices[vi] == curSelected) {
                currentVisibleIndex = vi;
                break;
            }
        }
        
        currentVisibleIndex = FlxMath.wrap(currentVisibleIndex + change, 0, visibleIndices.length - 1);
        curSelected = visibleIndices[currentVisibleIndex];
        
        if (scrollView) viewOffset = currentVisibleIndex;
        
        _updateSongLastDifficulty();
        if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        var newColor:Int = songs[curSelected].color;
        if(newColor != intendedColor) {
            intendedColor = newColor;
            FlxTween.cancelTweensOf(bg);
            FlxTween.color(bg, 1, bg.color, intendedColor);
            FlxTween.cancelTweensOf(dinamic);
            FlxTween.color(dinamic, 1, dinamic.color, intendedColor);
        }

        for (i in 0...cardsGroup.members.length) {
            if(i < songs.length) {
                cardsGroup.members[i].color = songs[i].color;
                cardsGroup.members[i].alpha = (i == curSelected) ? 1.0 : 0.6;
            }
        }

        // Set proper mod directory for loading assets
        if (!songs[curSelected].isStepMania) {
            Mods.currentModDirectory = songs[curSelected].folder;
        } else {
            Mods.currentModDirectory = '';
        }

        applySelectionVisualAssets();
        
        // Clear bitmap cache of unused songs to reduce memory usage
        #if MODS_ALLOWED
        if(songs.length > 50) { // Only cleanup when there are many songs
            var currentSongName:String = songs[curSelected].songName;
            openfl.system.System.gc();
        }
        #end
        
        PlayState.storyWeek = songs[curSelected].week;
        
        if (!songs[curSelected].isStepMania) {
            Difficulty.loadFromWeek();
        }
        
        detectAndLoadAllDifficulties();
        
        if (Difficulty.list == null || Difficulty.list.length == 0) {
            Difficulty.list = ['Normal'];
        }
        
        var savedDiff:String = songs[curSelected].lastDifficulty;
        var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
        
        if(savedDiff != null && Difficulty.list.contains(savedDiff))
            curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
        else if(lastDiff > -1)
            curDifficulty = lastDiff;
        else if(Difficulty.list.contains(Difficulty.getDefault()))
            curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
        else
            curDifficulty = 0;

        changeDiff();
        _updateSongLastDifficulty();

        _lastDiffCurSelected = -1;
        
        if(previewTimer != null) {
            previewTimer.cancel();
            previewTimer = null;
        }
        
        if (songs[curSelected].isStepMania) {
            if (instPlaying != -1 || instSound != null)
                stopInstPreview();
        } else {
            previewTimer = new FlxTimer().start(0.5, function(tmr:FlxTimer) {
                playInstPreview();
                previewTimer = null;
            });
        }
        
        updateStarIcon();
    }
    
    /**
     * Change difficulty
     */
    function changeDiff(change:Int = 0):Void {
        if (Difficulty.list.length == 0)
            return;

        curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
        
        #if !switch
        intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
        intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
        #end

        lastDifficultyName = Difficulty.getString(curDifficulty, false);

        diffViewOffset = curDifficulty;

        missingText.visible = false;
        missingTextBG.visible = false;

        _lastDiffCurSelected = -1;
        
        loadChartMetadata();
    
    }

    function refreshSelectedScoreData(?immediate:Bool = false):Void {
        if (songs.length == 0) return;

        #if !switch
        intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
        intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty, viewingOpponentScores);
        #else
        intendedScore = 0;
        intendedRating = 0;
        #end

        if (immediate) {
            lerpScore = intendedScore;
            lerpRating = intendedRating;
            updateDynamicData();
        }
    }

    /**
     * Play selected song
     */
    function playSong():Void {
        persistentUpdate = false;
        var selectedSong = songs[curSelected];
        if (!selectedSong.isStepMania)
            Mods.currentModDirectory = selectedSong.folder;
        else
            Mods.currentModDirectory = '';

        var songLowercase:String = Paths.formatToSongPath(selectedSong.songName);
        var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
        PlayState.customAudioPath = null;
        
        try {
            if (selectedSong.isStepMania) {
                var smChart:SwagSong = loadStepManiaChart(selectedSong, curDifficulty);
                if (smChart == null)
                    throw 'Unable to convert StepMania chart.';

                PlayState.SONG = smChart;
                PlayState.customAudioPath = Path.addTrailingSlash(selectedSong.smFolder);
                trace('Loading StepMania song: ${selectedSong.smFilePath}');
            } else {
                PlayState.SONG = Song.loadFromJson(poop, songLowercase);
                trace('Loading song: $poop');
            }
            PlayState.isStoryMode = false;
            PlayState.storyDifficulty = curDifficulty;
            Cursor.hide();
        } catch(e:Dynamic) {
            PlayState.customAudioPath = null;
            trace('ERROR LOADING SONG: $e');
            missingText.text = 'ERROR WHILE LOADING CHART:\n$e';
            missingText.screenCenter(Y);
            missingText.visible = true;
            missingTextBG.visible = true;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            Cursor.show();
            return;
        }
        
        @:privateAccess
        if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory) {
            trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
            Paths.freeGraphicsFromMemory();
        }
        
        LoadingState.prepareToSong();
        LoadingState.returnState = new FreeplayState();
        LoadingState.loadAndSwitchState(new PlayState());
        #if !SHOW_LOADING_SCREEN 
        FlxG.sound.music.stop(); 
        #end
        stopMusicPlay = true;
        destroyFreeplayVocals();
    }

    function loadStepManiaChart(song:SongMetadata, difficultyIndex:Int):SwagSong {
        #if sys
        if (song == null || song.smFilePath == null || song.smFilePath.length == 0)
            return null;

        var smFile:SMFile = SMFile.loadFile(song.smFilePath);
        if (smFile == null || !smFile.isValid || smFile.difficulties == null || smFile.difficulties.length == 0)
            return null;

        var boundedDifficulty:Int = Std.int(FlxMath.bound(difficultyIndex, 0, smFile.difficulties.length - 1));
        return smFile.convertToFNF(song.songName, boundedDifficulty);
        #else
        return null;
        #end
    }
    
    /**
     * Detect all available difficulties for current song
     */
    public function detectAndLoadAllDifficulties():Void {
        if(songs.length == 0) return;
        
        if (songs[curSelected].isStepMania) {
            if (songs[curSelected].smDifficulties != null && songs[curSelected].smDifficulties.length > 0) {
                Difficulty.list = songs[curSelected].smDifficulties;
            } else {
                Difficulty.list = ['Normal'];
                trace('StepMania song has no difficulties, using default');
            }
            return;
        }
        
        var songName:String = Paths.formatToSongPath(songs[curSelected].songName);
        var availableDiffs:Array<String> = [];

        Difficulty.loadFromWeek();
        var weekDiffs:Array<String> = Difficulty.list.copy();
        if (weekDiffs == null || weekDiffs.length == 0)
            weekDiffs = Difficulty.defaultList.copy();

        for (diff in weekDiffs) {
            if (chartExistsForDifficulty(songName, diff))
                availableDiffs.push(diff);
        }
        
        // Only check for erect/nightmare in base game songs (not mods)
        var isBaseGame:Bool = (songs[curSelected].folder == null || songs[curSelected].folder == '');
        
        if(isBaseGame) {
            var erectDiffs:Array<String> = ['Erect', 'Nightmare'];
            for (diff in erectDiffs) {
                if (!availableDiffs.contains(diff) && chartExistsForDifficulty(songName, diff))
                    availableDiffs.push(diff);
            }
        }

        if (availableDiffs.length == 0) {
            if (chartExistsForDifficulty(songName, Difficulty.getDefault()))
                availableDiffs.push(Difficulty.getDefault());
            else
                availableDiffs.push('Normal');
        }
        
        Difficulty.list = availableDiffs;
    }
    
    inline private function _updateSongLastDifficulty():Void {
        if(songs.length > 0 && curSelected < songs.length)
            songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
    }
    
    function toggleFavorite():Void {
        if(songs.length == 0 || curSelected >= songs.length) return;
        
        songs[curSelected].isFavorite = !songs[curSelected].isFavorite;
        saveFavorites();
        updateStarIcon();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
    }
    
    function refreshSongList():Void {
        if(showingFavorites) {
            var hasFavorites:Bool = false;
            for(song in songs) {
                if(song.isFavorite) {
                    hasFavorites = true;
                    break;
                }
            }
            
            if(!hasFavorites) {
                trace('No favorite songs found');
                noFavoritesText.visible = true;
                return;
            } else {
                noFavoritesText.visible = false;
            }
            
            var favoriteIndices:Array<Int> = [];
            for(i in 0...songs.length) {
                if(songs[i].isFavorite) {
                    favoriteIndices.push(i);
                }
            }
            
            if(!songs[curSelected].isFavorite && favoriteIndices.length > 0) {
                curSelected = favoriteIndices[0];
            }
        
            var visibleIndex:Int = 0;
            for(vi in 0...favoriteIndices.length) {
                if(favoriteIndices[vi] == curSelected) {
                    visibleIndex = vi;
                    break;
                }
            }
            
            viewOffset = visibleIndex;
            lerpViewOffset = visibleIndex;
        } else {
            noFavoritesText.visible = false;
            curSelected = FlxMath.wrap(curSelected, 0, songs.length - 1);
            viewOffset = curSelected;
            lerpViewOffset = curSelected;
        }
        
        updateDifficultyDisplay();
        changeDiff();
    }
    
    function saveFavorites():Void {
        if(FlxG.save.data.favoriteSongs == null) {
            FlxG.save.data.favoriteSongs = [];
        }
        
        var favorites:Array<String> = [];
        for(song in songs) {
            if(song.isFavorite) {
                var key:String = song.songName + '|' + song.folder;
                favorites.push(key);
            }
        }
        
        FlxG.save.data.favoriteSongs = favorites;
        FlxG.save.flush();
    }
    
    function loadFavorites():Void {
        if(FlxG.save.data.favoriteSongs == null) return;
        
        var favorites:Array<String> = FlxG.save.data.favoriteSongs;
        for(song in songs) {
            var key:String = song.songName + '|' + song.folder;
            song.isFavorite = favorites.contains(key);
        }
    }
    
    function updateStarIcon():Void {
        if(songs.length == 0 || curSelected >= songs.length) return;
        
        if(songs[curSelected].isFavorite) {
            starIcon.visible = false;
            starFullIcon.visible = true;
            starFullIcon.color = _curAccentColor;
        } else {
            starIcon.visible = true;
            starFullIcon.visible = false;
            starIcon.color = _curAccentColor;
            starIcon.alpha = 0.5;
        }
    }
    
    /**
     * Filter songs based on search query
     */
    function filterSongs():Void {
        if(searchQuery == null || searchQuery == '') {
            // No filter, show all songs
            changeSelection(0, false);
            return;
        }
        
        // Find first matching song
        for(i in 0...songs.length) {
            var song = songs[i];
            var songLower = song.songName.toLowerCase();
            var folderLower = song.folder != null ? song.folder.toLowerCase() : '';
            
            if(songLower.contains(searchQuery) || folderLower.contains(searchQuery)) {
                curSelected = i;
                viewOffset = i;
                lerpViewOffset = i;
                changeSelection(0, false);
                return;
            }
        }
    }
    
    /**
     * Load chart metadata for the currently selected song and difficulty.
     * Updates BPM, duration, note count texts dynamically.
     */
    function loadChartMetadata():Void {
        if(songs.length == 0 || curSelected >= songs.length) return;
        var selectedSong = songs[curSelected];
        
        // Set mod context for proper asset loading
        var previousMod:String = Mods.currentModDirectory;
        if(!selectedSong.isStepMania && selectedSong.folder != null && selectedSong.folder != '') {
            Mods.currentModDirectory = selectedSong.folder;
        }
        
        var songName:String = Paths.formatToSongPath(selectedSong.songName);
        var chartPath:String = Highscore.formatSong(songName, curDifficulty);
        
        try {
            var chart:SwagSong = selectedSong.isStepMania ? loadStepManiaChart(selectedSong, curDifficulty) : Song.getChart(chartPath, songName);
            if(chart == null)
                throw selectedSong.isStepMania ? 'Chart not found for ${selectedSong.smFilePath}' : 'Chart not found for $songName - $chartPath';
            
            var chartBPM:Float = chart.bpm;
            if(Math.isNaN(chartBPM) || chartBPM <= 0) chartBPM = 100;
            currentBPM = chartBPM; 
            bpmText.text = Std.string(Math.floor(chartBPM)) + ' BPM';
            
            var noteCount:Int = 0;
            var lastNoteTime:Float = 0;
            var useV2Metadata:Bool = chart.format != null && chart.format.startsWith('psych_v2') && chart.notesV2 != null && chart.notesV2.length > 0;

            if(useV2Metadata)
            {
                for(v2Note in chart.notesV2)
                {
                    if(v2Note == null) continue;

                    var strumTime:Float = v2Note.t;
                    var noteData:Int = v2Note.d;
                    var holdLength:Float = v2Note.l;
                    if(Math.isNaN(holdLength) || holdLength < 0) holdLength = 0;

                    if(noteData < 0 || noteData > 7 || strumTime < 0) continue;

                    var noteEnd:Float = strumTime + holdLength;
                    if(noteEnd > lastNoteTime) {
                        lastNoteTime = noteEnd;
                    }

                    // psych_v2: 0-3 = player lanes, 4-7 = opponent lanes
                    if(noteData < 4) noteCount++;
                }
            }
            else
            {
                for(section in chart.notes) {
                    if(section == null || section.sectionNotes == null) continue;

                    for(note in section.sectionNotes) {
                        if(note == null || note.length < 2) continue;

                        var noteData:Int = Std.int(note[1]);
                        var strumTime:Float = note[0];

                        // Skip events (noteData < 0 or > 7) and invalid timestamps.
                        if(noteData < 0 || noteData > 7 || strumTime < 0) continue;

                        if(strumTime > lastNoteTime) {
                            lastNoteTime = strumTime;
                        }

                        // mustHitSection=true  → player owns lanes 0-3
                        // mustHitSection=false → player owns lanes 4-7
                        var isPlayerNote:Bool = section.mustHitSection ? (noteData < 4) : (noteData >= 4);

                        if(isPlayerNote) noteCount++;
                    }
                }
            }
            
            var durationSeconds:Int = Math.ceil(lastNoteTime / 1000);
            var minutes:Int = Math.floor(durationSeconds / 60);
            var seconds:Int = durationSeconds % 60;
            timerText.text = minutes + ':' + (seconds < 10 ? '0' : '') + seconds;
            
            var diffName:String = Difficulty.getString(curDifficulty);
            noteDiffText.text = '($diffName) $noteCount notes';
            
            var chartSpeed:Float = chart.speed;
            if(Math.isNaN(chartSpeed) || chartSpeed <= 0) chartSpeed = 1.0;
            speedText.text = Std.string(chartSpeed) + 'x';
            
            var sectionDensities:Array<Int> = [];
            var sectionDuration:Float = lastNoteTime / BAR_COUNT;
            if(sectionDuration <= 0 || Math.isNaN(sectionDuration)) sectionDuration = 1;
            
            for(i in 0...BAR_COUNT) {
                var sectionStart:Float = i * sectionDuration;
                var sectionEnd:Float = (i + 1) * sectionDuration;
                var sectionNoteCount:Int = 0;

                if(useV2Metadata)
                {
                    for(v2Note in chart.notesV2)
                    {
                        if(v2Note == null) continue;
                        var noteData:Int = v2Note.d;
                        var strumTime:Float = v2Note.t;

                        if(noteData < 0 || noteData > 7 || strumTime < 0) continue;
                        if(strumTime < sectionStart || strumTime >= sectionEnd) continue;

                        if(noteData < 4) sectionNoteCount++;
                    }
                }
                else
                {
                    for(section in chart.notes) {
                        if(section == null || section.sectionNotes == null) continue;

                        for(note in section.sectionNotes) {
                            if(note == null || note.length < 2) continue;

                            var noteData:Int = Std.int(note[1]);
                            var strumTime:Float = note[0];

                            // Skip events (noteData < 0 or > 7) and invalid timestamps.
                            if(noteData < 0 || noteData > 7 || strumTime < 0) continue;
                            if(strumTime < sectionStart || strumTime >= sectionEnd) continue;

                            var isPlayerNote:Bool = section.mustHitSection ? (noteData < 4) : (noteData >= 4);

                            if(isPlayerNote) sectionNoteCount++;
                        }
                    }
                }
                
                sectionDensities.push(sectionNoteCount);
            }
            
            updateNoteDensityBars(sectionDensities);
            
        } catch(e:Dynamic) {
            var chartLabel:String = selectedSong.isStepMania ? selectedSong.smFilePath : songName;
            trace('Error loading chart metadata for $chartLabel: $e');
            // Fallback to default/static values
            bpmText.text = '120 BPM';
            timerText.text = '0:00';
            speedText.text = '1.0x';
            noteDiffText.text = '(?) 0 notes';
            updateNoteDensityBars([for(_ in 0...BAR_COUNT) 0]);
        }
        
        // Restore previous mod context
        Mods.currentModDirectory = previousMod;
    }
    
    /**
     * Play instrumental preview for the currently selected song.
     * Uses FlxG.sound.playMusic so the audio stream always has a valid
     * __audioSource on native targets (required by SpectralAnalyzer).
     */
    function playInstPreview():Void {
        if(songs.length == 0 || curSelected >= songs.length) return;

        previewLoadToken++;
        var requestToken:Int = previewLoadToken;
        var requestedIndex:Int = curSelected;
        var songName:String = Paths.formatToSongPath(songs[requestedIndex].songName);

        if(previewLoadTimer != null) {
            previewLoadTimer.cancel();
            previewLoadTimer = null;
        }

        previewLoadTimer = new FlxTimer().start(PREVIEW_LOAD_DELAY, function(_:FlxTimer) {
            previewLoadTimer = null;

            if(requestToken != previewLoadToken || songs.length == 0 || requestedIndex != curSelected)
                return;

            _prevInstSongName = songName;

            #if (target.threaded && sys)
            // Resolve the file path on the main thread (safe, read-only) to avoid
            // touching shared Paths data from inside the worker thread.
            var filePath:String = Paths.getPath(
                Language.getFileTranslation('${songName}/Inst') + '.${Paths.SOUND_EXT}',
                SOUND, 'songs', true
            );
            var capturedBpm:Float = currentBPM;
            var capturedToken:Int = requestToken;
            var capturedIndex:Int = requestedIndex;

            // Cancel any stale pending result so update() ignores it.
            _instLoadMutex.acquire();
            _pendingInstSound = null;
            _instLoadMutex.release();

            ThreadUtil.execAsync(function() {
                var loadedSound:openfl.media.Sound = null;
                try {
                    // Sound.fromFile() is the slow, blocking part (disk read + OGG decode).
                    // It is safe to call from a non-main thread on native C++ targets because
                    // OpenAL buffer upload only happens on the first play() call.
                    #if MODS_ALLOWED
                    if(sys.FileSystem.exists(filePath))
                        loadedSound = openfl.media.Sound.fromFile(filePath);
                    else
                    #end
                    if(openfl.utils.Assets.exists(filePath, openfl.utils.AssetType.SOUND))
                        loadedSound = openfl.utils.Assets.getSound(filePath);
                } catch(e:Dynamic) {
                    trace('[FreePlay] Thread error loading inst "$songName": $e');
                }

                // Hand off to the main thread via mutex-protected fields.
                // update() will pick this up and call playMusic() safely.
                _instLoadMutex.acquire();
                if(capturedToken == previewLoadToken) {
                    _pendingInstSound = loadedSound;
                    _pendingInstToken = capturedToken;
                    _pendingInstIndex = capturedIndex;
                    _pendingInstBpm  = capturedBpm;
                }
                _instLoadMutex.release();
            });

            #else
            // Fallback for single-threaded targets (web, etc.): load synchronously.
            try {
                FlxG.sound.playMusic(Paths.inst(songName), 0, true);
                FlxG.sound.music.fadeIn(1.0, 0, 0.7);
                instSound = FlxG.sound.music;
                instPlaying = requestedIndex;

                Conductor.bpm = currentBPM;

                #if funkin.vis
                _analyzer = null;
                _analyzerLevels = null;
                _needsAnalyzerInit = true;
                #end
            } catch(e:Dynamic) {
                trace('Error loading inst for $songName: $e');
                FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7);
            }
            #end
        });
    }
    
    /**
     * Stop instrumental preview and return to freakyMenu.
     */
    function stopInstPreview():Void {
        previewLoadToken++;
        if(previewLoadTimer != null) {
            previewLoadTimer.cancel();
            previewLoadTimer = null;
        }

        instPlaying = -1;
        instSound = null;
        
        // Restore freeplay menu music — playMusic creates a fresh stream so
        // the SpectralAnalyzer can re-attach to it on the next frame.
        FlxG.sound.playMusic(Paths.music('freakyMenu'), 0, true);
        FlxG.sound.music.fadeIn(0.5, 0, 0.7);
        
        #if funkin.vis
        _analyzer = null;
        _analyzerLevels = null;
        _needsAnalyzerInit = true;
        #end
        
        Conductor.bpm = 102;
        currentBPM = 102;
    }
    
    /**
     * Update the note density visualization bars based on the note count.
     * Bars grow in both width and height, rising upward as they fill.
     * Inspired by material design visualizers but adapted for FNF chart density.
     */
    function updateNoteDensityBars(sectionDensities:Array<Int>):Void {
        if(barsGroup == null || barsGroup.members.length == 0) return;
        if(sectionDensities.length != BAR_COUNT) return;
        
        var maxDensity:Int = 1;
        for(density in sectionDensities) {
            if(density > maxDensity) maxDensity = density;
        }
        
        // BASELINE_Y: bottom anchor where all bars sit
        var BASELINE_Y:Float = BAR_BASELINE_Y;
        var minHeight:Float = BAR_MIN_H;
        var maxHeight:Float = BAR_MAX_H;
        
        for(i in 0...barsGroup.members.length) {
            var bar:FlxSprite = barsGroup.members[i];
            if(bar == null) continue;
            
            var density:Int = sectionDensities[i];
            var densityRatio:Float = density / maxDensity;
            var targetHeight:Float = minHeight + (densityRatio * (maxHeight - minHeight));
            
            // Cancel existing tween safely via stored reference
            if(i < _barTweens.length && _barTweens[i] != null) {
                _barTweens[i].cancel();
                _barTweens[i] = null;
            }
            
            var barIndex:Int = i;
            // Current visual height from hitbox (no bitmap alloc - uses scale internally)
            var currentHeight:Float = bar.height > 0 ? bar.height : minHeight;
            
            _barTweens[i] = FlxTween.num(currentHeight, targetHeight, 0.35, {
                ease: FlxEase.expoOut,
                onComplete: function(_) {
                    if(barIndex < _barTweens.length) _barTweens[barIndex] = null;
                }
            }, function(value:Float) {
                if(barsGroup == null || barsGroup.members[barIndex] == null) return;
                var b = barsGroup.members[barIndex];
                var h:Int = Std.int(Math.max(1, value));
                b.setGraphicSize(BAR_WIDTH, h);
                b.updateHitbox();
                b.x = BAR_START_X + (barIndex * BAR_STEP);
                b.y = BAR_BASELINE_Y - h;
            });
            
            // Alpha: inactive sections barely visible, max density fully opaque
            bar.alpha = density > 0 ? 0.50 + (densityRatio * 0.50) : 0.18;
        }
    }
    
    static inline var CARD_CLIP_Y_MIN:Float = 275;
    static inline var CARD_CLIP_Y_MAX:Float = 680;

    static inline var PILL_CLIP_X_MIN:Float = 42.5;
    static inline var PILL_CLIP_X_MAX:Float = 370;

    /**
     * Apply a vertical clip rect to a sprite so it doesn't bleed outside [yMin, yMax].
     * Hides the sprite entirely if there's nothing to show.
     */
    static function applyVerticalClip(spr:FlxSprite, yMin:Float, yMax:Float):Void {
        if (spr == null) return;
        var h:Float = spr.frameHeight;
        if (h <= 0) { spr.visible = false; return; }
        var topCut:Float  = Math.max(0, yMin - spr.y);
        var botCut:Float  = Math.max(0, (spr.y + h) - yMax);
        var visH:Float = h - topCut - botCut;
        if (visH <= 0) {
            spr.visible = false;
            spr.clipRect = null;
        } else {
            spr.visible = true;
            spr.clipRect = new FlxRect(0, topCut, spr.frameWidth, visH);
        }
    }

    /**
     * Apply a horizontal clip rect to a sprite so it doesn't bleed outside [xMin, xMax].
     */
    static function applyHorizontalClip(spr:FlxSprite, xMin:Float, xMax:Float):Void {
        if (spr == null) return;
        var w:Float = spr.frameWidth;
        if (w <= 0) { spr.visible = false; return; }
        var leftCut:Float  = Math.max(0, xMin - spr.x);
        var rightCut:Float = Math.max(0, (spr.x + w) - xMax);
        var visW:Float = w - leftCut - rightCut;
        if (visW <= 0) {
            spr.visible = false;
            spr.clipRect = null;
        } else {
            spr.visible = true;
            spr.clipRect = new FlxRect(leftCut, 0, visW, spr.frameHeight);
        }
    }

    /**
     * Update visual elements
     */
    public function updateTexts(elapsed:Float = 0.0):Void {
        lerpViewOffset = FlxMath.lerp(viewOffset, lerpViewOffset, Math.exp(-elapsed * 9.6));

        // Rebuild visible-index cache only when the list or filter mode changes.
        if(!_visCacheValid || _lastShowingFavorites != showingFavorites || _cachedVisibleIndices.length == 0) {
            _cachedVisibleIndices = [];
            if(showingFavorites) {
                for(i in 0...songs.length) {
                    if(songs[i].isFavorite) _cachedVisibleIndices.push(i);
                }
            } else {
                for(i in 0...songs.length) _cachedVisibleIndices.push(i);
            }
            _visCacheValid = true;
            _lastShowingFavorites = showingFavorites;
        }
        var visibleIndices:Array<Int> = _cachedVisibleIndices;
        
        for (i in 0...cardsGroup.members.length) {
            var card = cardsGroup.members[i];
            if(i < songs.length) {
                var visibleIndex:Int = -1;
                for(vi in 0...visibleIndices.length) {
                    if(visibleIndices[vi] == i) {
                        visibleIndex = vi;
                        break;
                    }
                }
                
                if(visibleIndex == -1) {
                    card.visible = false;
                    card.clipRect = null;
                    
                    if(i < cardSongText.members.length && cardSongText.members[i] != null) {
                        cardSongText.members[i].visible = false;
                    }
                    if(i < cardModText.members.length && cardModText.members[i] != null) {
                        cardModText.members[i].visible = false;
                    }
                    if(i < iconArray.length && iconArray[i] != null) {
                        iconArray[i].visible = false;
                    }
                    continue;
                }
                
                var difference:Float = visibleIndex - lerpViewOffset;
                card.y = 275 + (difference * 74);

                var distanceFade:Float = Math.abs(difference);
                if(distanceFade > _drawDistance) {
                    card.visible = false;
                    card.clipRect = null;
                } else {
                    card.alpha = (i == curSelected) ? 1.0 : 0.6;
                    applyVerticalClip(card, CARD_CLIP_Y_MIN, CARD_CLIP_Y_MAX);
                }

                if(i < cardSongText.members.length && cardSongText.members[i] != null) {
                    var st = cardSongText.members[i];
                    st.y = 290 + (difference * 74);
                    st.alpha = card.alpha;
                    if (!card.visible) { st.visible = false; }
                    else applyVerticalClip(st, CARD_CLIP_Y_MIN, CARD_CLIP_Y_MAX);
                }

                if(i < cardModText.members.length && cardModText.members[i] != null) {
                    var mt = cardModText.members[i];
                    mt.y = 310 + (difference * 74);
                    mt.alpha = card.alpha;
                    if (!card.visible) { mt.visible = false; }
                    else applyVerticalClip(mt, CARD_CLIP_Y_MIN, CARD_CLIP_Y_MAX);
                }

                if(i < iconArray.length && iconArray[i] != null) {
                    var ic = iconArray[i];
                    ic.y = 235 + (difference * 74);
                    ic.alpha = card.alpha;
                    if (!card.visible) { ic.visible = false; ic.clipRect = null; }
                    else applyVerticalClip(ic, CARD_CLIP_Y_MIN - 20, CARD_CLIP_Y_MAX - 5);
                }
            } else {
                card.visible = false;
                card.clipRect = null;
            }
        }
        
        var dinamicTarget:Int = FlxColor.interpolate(intendedColor, 0xFFFFFF, 0.18);
        dinamic.color = FlxColor.interpolate(dinamic.color, dinamicTarget, elapsed * 5);

        var targetTint:Int = FlxColor.interpolate(0xFFFFFF, intendedColor, 0.30);
        uiprincipal.color = FlxColor.interpolate(uiprincipal.color, targetTint, elapsed * 3.0);

        // Recompute HSL target colors only when intendedColor changes — fromHSL is expensive.
        if(_lastIntendedColor != intendedColor) {
            _lastIntendedColor = intendedColor;
            var hueColor:FlxColor = FlxColor.fromInt(intendedColor);
            _cachedTargetOnDark = FlxColor.fromHSL(hueColor.hue, 0.50, 0.92);
            _cachedTargetHeader = FlxColor.fromHSL(hueColor.hue, 0.90, 0.35);
            _cachedTargetAccent = FlxColor.fromHSL(hueColor.hue, 0.80, 0.65);
            _cachedTargetLabel  = FlxColor.fromHSL(hueColor.hue, 0.15, 0.45);
        }
        _curOnDarkColor = FlxColor.interpolate(_curOnDarkColor, _cachedTargetOnDark, elapsed * 3.0);
        _curHeaderColor = FlxColor.interpolate(_curHeaderColor, _cachedTargetHeader, elapsed * 3.0);
        _curAccentColor = FlxColor.interpolate(_curAccentColor, _cachedTargetAccent, elapsed * 3.0);
        _curLabelColor  = FlxColor.interpolate(_curLabelColor,  _cachedTargetLabel,  elapsed * 3.0);

        freeplayText.color    = _curOnDarkColor;

        diffText.color        = _curOnDarkColor;
        songsText.color       = _curHeaderColor;
        allLevels.color       = showingFavorites ? _curLabelColor : _curHeaderColor;
        favorites.color       = showingFavorites ? _curHeaderColor : _curLabelColor;
        totalSongsText.color  = _curOnDarkColor;
        modsLoadedText.color  = _curOnDarkColor;
        todayText.color       = _curHeaderColor;

        themeText.color      = _curOnDarkColor;
        modText.color        = _curOnDarkColor;

        playText.color    = _curAccentColor;
        speedText.color   = _curAccentColor;
        bpmText.color     = _curAccentColor;
        timerText.color   = _curAccentColor;

        playIcon.color    = _curAccentColor;
        speedIcon.color   = _curAccentColor;
        bpmIcon.color     = _curAccentColor;
        timerIcon.color   = _curAccentColor;
        starIcon.color    = _curAccentColor;
        starFullIcon.color = _curAccentColor;

        scoreText.color      = _curLabelColor;
        comboText.color      = _curLabelColor;
        accuracyText.color   = _curLabelColor;
        ratingText.color     = _curLabelColor;
        modText.color        = _curLabelColor;
        searchTipText.color  = _curLabelColor;
        trophyIcon.color     = _curLabelColor;
        accuracyIcon.color   = _curLabelColor;
        fireIcon.color       = _curLabelColor;
        medalIcon.color      = _curLabelColor;
        searchIcon.color     = _curLabelColor;
        
        // Data values use header color for prominence
        scoreData.color      = _curHeaderColor;
        accuracyData.color   = _curHeaderColor;
        comboData.color      = _curHeaderColor;
        ratingData.color     = _curHeaderColor;
        notesText.color      = _curHeaderColor;
        noteDiffText.color   = _curLabelColor;
        
        if(noFavoritesText != null) {
            noFavoritesText.color = _curLabelColor;
        }

        // Note density bars — always pure chart-data (no FFT, height managed by tweens).
        if(barsGroup != null) {
            for(i in 0...barsGroup.members.length) {
                var bar = barsGroup.members[i];
                if(bar != null) {
                    bar.color = _curAccentColor;
                    bar.x = BAR_START_X + (i * BAR_STEP);
                }
            }
        }

        // Full-width bottom spectral visualizer bars — driven exclusively by SpectralAnalyzer.
        #if funkin.vis
        // Lazy-init: attach to FlxG.sound.music as soon as __audioSource is ready.
        // Both inst preview and freeplay bg music go through FlxG.sound.music now.
        if(_needsAnalyzerInit && FlxG.sound.music != null && FlxG.sound.music.playing) {
            @:privateAccess
            if(FlxG.sound.music._channel != null && FlxG.sound.music._channel.__audioSource != null) {
                _analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, VIZ_BAR_COUNT, 0.08, 25);
                _analyzer.minFreq = 40;
                _analyzer.maxFreq = 18000;
                _analyzer.minDb = -80;
                _analyzer.maxDb = -15;
                #if mobile
                _analyzer.fftN = 256;
                #elseif !web
                _analyzer.fftN = 512;
                #end
                _needsAnalyzerInit = false;
            }
        }
        _vizUpdateAccum += elapsed;
        if(vizBarsGroup != null) {
            var vizBarW:Int = Std.int(FlxG.width / VIZ_BAR_COUNT);
            var vizOffsetX:Float = (vizBarW - Std.int(Math.max(1, vizBarW * VIZ_BAR_FILL))) * 0.5;

            if (_vizUpdateAccum >= VIZ_UPDATE_INTERVAL)
            {
                _vizUpdateAccum = 0;
                if(_analyzer != null) {
                    _analyzerLevels = _analyzer.getLevels(_analyzerLevels);
                    for(i in 0...vizBarsGroup.members.length) {
                        var level:Float = (i < _analyzerLevels.length) ? _analyzerLevels[i].value : 0.0;
                        _vizTargetHeights[i] = Math.max(VIZ_MIN_H, level * VIZ_BAR_MAX_H);
                    }
                } else {
                    for(i in 0...vizBarsGroup.members.length) {
                        _vizTargetHeights[i] = VIZ_MIN_H;
                    }
                }
            }

            var lerpFactor:Float = 1 - Math.exp(-elapsed * VIZ_SMOOTH_SPEED);
            for(i in 0...vizBarsGroup.members.length) {
                var vbar = vizBarsGroup.members[i];
                if(vbar == null) continue;

                var curH:Float = _vizCurrentHeights[i];
                var targetH:Float = _vizTargetHeights[i];
                curH = FlxMath.lerp(targetH, curH, 1 - lerpFactor);
                _vizCurrentHeights[i] = curH;

                vbar.scale.y = curH / VIZ_BAR_MAX_H;
                vbar.x = i * vizBarW + vizOffsetX;
                vbar.y = FlxG.height - curH;
                vbar.color = _curAccentColor;
                vbar.alpha = 1.0;
            }
        }
        #end

        lerpDiffViewOffset = FlxMath.lerp(diffViewOffset, lerpDiffViewOffset, Math.exp(-elapsed * 9.6));

        updateDifficultyDisplay();
        _lastDiffForStyle = curDifficulty;
    }
    
    /**
     * Load StepMania files from sm/ folder
     */
    function loadStepManiaFiles():Void {
        #if sys
        #if mobile
        var smDir = StorageUtil.getSMDirectory();
        #else
        var smDir = './sm/';
        #end
        
        if (!sys.FileSystem.exists(smDir)) {
            trace('SM folder not found, creating it...');
            sys.FileSystem.createDirectory(smDir);
            return;
        }
        
        trace('Scanning for StepMania files...');
        
        for (folder in sys.FileSystem.readDirectory(smDir)) {
            var folderPath = Path.addTrailingSlash(smDir + folder);
            
            if (!sys.FileSystem.isDirectory(folderPath)) continue;
            
            var smFile:String = null;
            for (file in sys.FileSystem.readDirectory(folderPath)) {
                if (file.toLowerCase().endsWith('.sm')) {
                    smFile = file;
                    break;
                }
            }
            
            if (smFile == null) {
                trace('No .sm file found in $folder');
                continue;
            }
            
            var fullPath = folderPath + smFile;
            
            try {
                var smData:SMFile = SMFile.loadFile(fullPath);
                if (smData == null || !smData.isValid || smData.header == null) {
                    trace('Skipping invalid SM file: $fullPath');
                    continue;
                }

                var title:String = smData.header.TITLE;
                if (title == null || title.length == 0)
                    title = folder;

                var smSong = new SongMetadata(title, -1, 'stepmania', FlxColor.fromRGB(88, 189, 255));
                smSong.isStepMania = true;
                smSong.folder = 'StepMania';
                smSong.smFolder = folderPath;
                smSong.smFilePath = fullPath;
                smSong.smMusicFile = smData.header.MUSIC;

                for (difficulty in smData.difficulties) {
                    if (difficulty != null && difficulty.name != null && difficulty.name.length > 0 && !smSong.smDifficulties.contains(difficulty.name))
                        smSong.smDifficulties.push(difficulty.name);
                }

                if (smSong.smDifficulties.length == 0)
                    smSong.smDifficulties.push('Normal');

                songs.push(smSong);
                trace('Loaded StepMania song: ${smSong.songName}');
            } catch (e:Dynamic) {
                trace('Error loading SM file $fullPath: $e');
            }
        }
        
        #else
        trace('StepMania support not available on this platform');
        #end
    }
    
    /**
     * Destroy freeplay vocals
     */
    public static function destroyFreeplayVocals():Void {
        if(vocals != null) vocals.stop();
        vocals = FlxDestroyUtil.destroy(vocals);

        if(opponentVocals != null) opponentVocals.stop();
        opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
    }
    
    /**
     * Close substate handler
     */
    override function closeSubState():Void {
        changeSelection(0, false);
        persistentUpdate = true;
        super.closeSubState();
        
        #if mobile
        if (touchScroll != null) touchScroll.reset();
        if (difficultyScroll != null) difficultyScroll.reset();
        #end
    }
    
    override public function beatHit():Void {
        super.beatHit();
        
        var bumpIntensity:Float = 0.045;
        if(currentBPM > 150) bumpIntensity = 0.030;
        else if(currentBPM < 80) bumpIntensity = 0.060;
        
        bgZoom += bumpIntensity;
        
        var albumBump:Float = bumpIntensity * 0.8;
        albumZoom = Math.min(albumZoom + albumBump, 1.1);
    }
    
    /**
     * Destroy handler
     */
    override function destroy():Void {
        if(previewTimer != null) {
            previewTimer.cancel();
            previewTimer = null;
        }

        if(previewLoadTimer != null) {
            previewLoadTimer.cancel();
            previewLoadTimer = null;
        }

        previewLoadToken++;
        
        if (instSound != null && instSound.playing) {
            instSound.stop();
        }
        instPlaying = -1;
        
        // Remove last previewed inst from Paths cache on exit
        if(_prevInstSongName != null) {
            var toRemove:Array<String> = [];
            for(key in Paths.currentTrackedSounds.keys()) {
                if(key.contains('/' + _prevInstSongName + '/')) {
                    toRemove.push(key);
                }
            }
            for(key in toRemove) {
                openfl.Assets.cache.clear(key);
                Paths.currentTrackedSounds.remove(key);
            }
            _prevInstSongName = null;
        }
        
        Conductor.bpm = 102;
        currentBPM = 102;
        
        if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7) {
            FlxG.sound.music.volume = 0.7;
        }
        
        // Cancel and clear bar tweens
        if(_barTweens != null) {
            for(t in _barTweens) {
                if(t != null) t.cancel();
            }
            _barTweens = null;
        }

        // Clean up search input
        if(searchInput != null) {
            searchInput.destroy();
            searchInput = null;
        }

        // Destroy full-width bottom spectral visualizer bars
        if(vizBarsGroup != null) {
            vizBarsGroup.destroy();
            vizBarsGroup = null;
        }
        
        // Kill spectral analyzer
        #if funkin.vis
        _analyzer = null;
        _analyzerLevels = null;
        _needsAnalyzerInit = false;
        #end
        
        // Clear icon array to free memory
        if(iconArray != null) {
            for(icon in iconArray) {
                if(icon != null) {
                    icon.destroy();
                }
            }
            iconArray = null;
        }
        
        // Clear songs array
        if(songs != null) {
            songs = null;
        }
        
        // Force garbage collection for large song lists
        #if MODS_ALLOWED
        @:privateAccess
        openfl.system.System.gc();
        #end
        
        #if mobile
        if (difficultyScroll != null) {
            difficultyScroll.destroy();
            difficultyScroll = null;
        }
        
        if (touchScroll != null) {
            touchScroll.destroy();
            touchScroll = null;
        }
        funkin.mobile.backend.TouchUtil.clearScrollHandler();
        #end
        
        super.destroy();

        FlxG.autoPause = ClientPrefs.data.autoPause;
        if (!FlxG.sound.music.playing && !stopMusicPlay)
            FlxG.sound.playMusic(Paths.music('freakyMenu'));
    }

    #if mobile
    function isAnyTouchInDifficultyArea():Bool {
        for (touch in FlxG.touches.list) {
            if (touch != null && (touch.pressed || touch.justPressed)) {
                if (touch.screenY >= 470 && touch.screenY <= 530 && touch.screenX >= PILL_CLIP_X_MIN && touch.screenX <= PILL_CLIP_X_MAX)
                    return true;
            }
        }
        return false;
    }
    #end

    function handleFreeplayPointerPress(x:Float, y:Float):Void {
        var point = new FlxPoint(x, y);

        #if mobile
        if (backChipHitbox != null && backChipHitbox.overlapsPoint(point)) {
            goBackToMainMenu();
            return;
        }

        if (gameplayChangersChipHitbox != null && gameplayChangersChipHitbox.overlapsPoint(point)) {
            openGameplayChangersSubstate();
            return;
        }

        if (resetScoreChipHitbox != null && resetScoreChipHitbox.overlapsPoint(point)) {
            openResetScoreSubstate();
            return;
        }
        #end

        var hitPlayTouchTarget:Bool = false;
        hitPlayTouchTarget = playTouchTarget != null && playTouchTarget.overlapsPoint(point);

        if (hitPlayTouchTarget || (playIcon != null && playIcon.overlapsPoint(point))) {
            playSong();
            return;
        }

        if ((starIcon != null && starIcon.overlapsPoint(point)) || (starFullIcon != null && starFullIcon.overlapsPoint(point))) {
            toggleFavorite();
            return;
        }

        if (allLevels != null && allLevels.overlapsPoint(point)) {
            if(showingFavorites) {
                showingFavorites = false;
                _visCacheValid = false;
                refreshSongList();
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            }
            return;
        }

        if (favorites != null && favorites.overlapsPoint(point)) {
            if(!showingFavorites) {
                showingFavorites = true;
                _visCacheValid = false;
                refreshSongList();
                FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            }
            return;
        }

        var clickedCard:Bool = false;
        for (i in 0...cardsGroup.members.length) {
            var card = cardsGroup.members[i];
            if (card != null && card.visible && card.alpha > 0.1 && card.overlapsPoint(point)) {
                if(i < songs.length && i != curSelected) {
                    var visibleIndices:Array<Int> = [];
                    if(showingFavorites) {
                        for(si in 0...songs.length) {
                            if(songs[si].isFavorite) {
                                visibleIndices.push(si);
                            }
                        }
                    } else {
                        for(si in 0...songs.length) {
                            visibleIndices.push(si);
                        }
                    }

                    var currentVisIndex:Int = 0;
                    var targetVisIndex:Int = 0;
                    for(vi in 0...visibleIndices.length) {
                        if(visibleIndices[vi] == curSelected) currentVisIndex = vi;
                        if(visibleIndices[vi] == i) targetVisIndex = vi;
                    }

                    var change:Int = targetVisIndex - currentVisIndex;
                    changeSelection(change, true, false);
                }
                clickedCard = true;
                break;
            }
        }

        if (!clickedCard) {
            for (i in 0...diffsGroup.members.length) {
                var diffIcon = diffsGroup.members[i];
                if (diffIcon != null && diffIcon.alpha > 0.1 && diffIcon.overlapsPoint(point)) {
                    var globalIdx:Int = diffIcon.ID;
                    if (curDifficulty != globalIdx) {
                        curDifficulty = globalIdx;
                        changeDiff();
                        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
                    }
                    break;
                }
            }
        }
    }

    #if mobile
    function createMobileActionHitbox(target:MaterialChip, paddingX:Float, paddingY:Float):FlxSprite {
        var hitboxWidth:Float = Math.max(target.width, 96) + (paddingX * 2);
        var hitboxHeight:Float = Math.max(target.height, 32) + (paddingY * 2);
        var hitbox = new FlxSprite(target.x - paddingX, target.y - paddingY);
        hitbox.makeGraphic(Std.int(hitboxWidth), Std.int(hitboxHeight), FlxColor.WHITE);
        hitbox.alpha = 0;
        add(hitbox);
        return hitbox;
    }
    #end

    function goBackToMainMenu():Void {
        if (PsychUIInputText.focusOn == searchInput)
            return;

        persistentUpdate = false;
        #if mobile
        if (touchScroll != null) touchScroll.stopScroll();
        if (difficultyScroll != null) difficultyScroll.stopScroll();
        #end
        FlxG.sound.play(Paths.sound('cancelMenu'));
        MusicBeatState.switchState(new funkin.ui.mainmenu.MainMenuState());
    }

    function openGameplayChangersSubstate():Void {
        persistentUpdate = false;
        #if mobile
        if (touchScroll != null) touchScroll.stopScroll();
        if (difficultyScroll != null) difficultyScroll.stopScroll();
        #end
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
        openSubState(new GameplayChangersSubstate());
    }

    function openResetScoreSubstate():Void {
        if (songs.length < 1) return;

        persistentUpdate = false;
        #if mobile
        if (touchScroll != null) touchScroll.stopScroll();
        if (difficultyScroll != null) difficultyScroll.stopScroll();
        #end
        openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter, -1, function() {
            refreshSelectedScoreData(true);
        }));
        FlxG.sound.play(Paths.sound('scrollMenu'));
    }
}

// Song Metadata Class
class SongMetadata {
    public var songName:String = "";
    public var week:Int = 0;
    public var songCharacter:String = "";
    public var color:Int = -7179779;
    public var folder:String = "";
    public var lastDifficulty:String = null;
    public var isStepMania:Bool = false;
    public var smFolder:String = "";
    public var smFilePath:String = "";
    public var smMusicFile:String = "";
    public var smDifficulties:Array<String> = [];
    public var isFavorite:Bool = false;

    public function new(song:String, week:Int, songCharacter:String, color:Int) {
        this.songName = song;
        this.week = week;
        this.songCharacter = songCharacter;
        this.color = color;
        this.folder = Mods.currentModDirectory;
        if(this.folder == null) this.folder = '';
    }
}

// Difficulty Selector Class
class DifficultySelector {
    public var items:FlxTypedGroup<FlxText>;
    public var cards:FlxTypedGroup<FlxSprite>;
    public var scoreTexts:FlxTypedGroup<FlxText>;
    public var curSelected:Int = 0;
    public var lerpSelected:Float = 0;
    public var enterProgress:Float = 0;
    
    private var baseXOffset:Float = 300;
    private var slideDistance:Float = 500;
    private var selectionTween:FlxTween;
    
    public function new() {
        items = new FlxTypedGroup<FlxText>();
        cards = new FlxTypedGroup<FlxSprite>();
        scoreTexts = new FlxTypedGroup<FlxText>();
    }
    
    public function loadDifficulties():Void {
        items.clear();
        cards.clear();
        scoreTexts.clear();
        
        if (FreeplayState.instance != null && FreeplayState.instance.songs[FreeplayState.curSelected] != null) {
            if (!FreeplayState.instance.songs[FreeplayState.curSelected].isStepMania) {
                Difficulty.loadFromWeek();
            }
            FreeplayState.instance.detectAndLoadAllDifficulties();
        }
        
        for (i in 0...Difficulty.list.length) {
            var diffText:FlxText = new FlxText(0, 0, 500, Difficulty.getString(i), 48);
            diffText.setFormat(Paths.font("inter-bold.otf"), 48, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
            diffText.borderSize = 2;
            diffText.ID = i;
            diffText.alpha = 0;
            items.add(diffText);
            
            var card:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ui/card'));
            card.setGraphicSize(470, 110);
            card.updateHitbox();
            card.alpha = 0;
            card.color = getDifficultyColor(Difficulty.getString(i));
            cards.add(card);
            
            var scoreInfoText:FlxText = new FlxText(0, 0, 450, "", 18);
            scoreInfoText.setFormat(Paths.font("inter-bold.otf"), 18, FlxColor.WHITE, CENTER);
            scoreInfoText.ID = i;
            scoreInfoText.alpha = 0;
            scoreTexts.add(scoreInfoText);
        }
        
        updateScoreTexts();
    }
    
    public function clearDifficulties():Void {
        items.clear();
        cards.clear();
        scoreTexts.clear();
    }
    
    public function updateScoreTexts():Void {
        if (FreeplayState.instance == null) return;
        
        for (i in 0...scoreTexts.members.length) {
            var scoreText:FlxText = scoreTexts.members[i];
            if (scoreText == null) continue;
            
            var diffIndex:Int = scoreText.ID;
            var songName:String = FreeplayState.instance.songs[FreeplayState.curSelected].songName;
            
            #if !switch
            var score:Int = Highscore.getScore(songName, diffIndex, FreeplayState.viewingOpponentScores);
            var accuracy:Float = Highscore.getRating(songName, diffIndex, FreeplayState.viewingOpponentScores);
            var accSystem:String = Highscore.getAccuracySystem(songName, diffIndex, FreeplayState.viewingOpponentScores);
            
            var accPercent:String = '';
            if (accuracy > 0) {
                var ratingPercent:Float = CoolUtil.floorDecimal(accuracy * 100, 2);
                accPercent = ' | ' + Std.string(ratingPercent) + '%';
            } else {
                accPercent = ' | 0.00%';
            }
            
            if (score > 0) {
                scoreText.text = 'Score: ' + score + accPercent;
            } else {
                scoreText.text = 'No record';
            }
            #else
            scoreText.text = '';
            #end
        }
    }
    
    private function getDifficultyColor(diffName:String):Int {
        var lowerName = diffName.toLowerCase();
        var normalizedName = normalizeDifficultyName(lowerName);
        
        if (normalizedName == 'easy')
            return 0x8FD9A8;
        else if (normalizedName == 'normal')
            return 0xFFE69C;
        else if (normalizedName == 'hard')
            return 0xFFB3BA;
        else if (normalizedName == 'erect')
            return 0xFFB5E8;
        else if (normalizedName == 'nightmare')
            return 0xC7A3FF;
        else {
            var hash:Int = 0;
            for (i in 0...diffName.length) {
                hash = diffName.charCodeAt(i) + ((hash << 5) - hash);
            }
            
            var r:Int = Std.int(Math.abs((hash >> 16) & 0xFF));
            var g:Int = Std.int(Math.abs((hash >> 8) & 0xFF));
            var b:Int = Std.int(Math.abs(hash & 0xFF));
            
            r = Std.int((r + 255) / 2);
            g = Std.int((g + 255) / 2);
            b = Std.int((b + 255) / 2);
            
            return FlxColor.fromRGB(r, g, b);
        }
    }
    
    private function normalizeDifficultyName(diffName:String):String {
        var lower = diffName.toLowerCase();
        
        var easyTranslated = Language.getPhrase('difficulty_Easy', 'Easy').toLowerCase();
        var normalTranslated = Language.getPhrase('difficulty_Normal', 'Normal').toLowerCase();
        var hardTranslated = Language.getPhrase('difficulty_Hard', 'Hard').toLowerCase();
        var erectTranslated = Language.getPhrase('difficulty_Erect', 'Erect').toLowerCase();
        var nightmareTranslated = Language.getPhrase('difficulty_Nightmare', 'Nightmare').toLowerCase();
        
        if (lower == easyTranslated || lower == 'easy')
            return 'easy';
        if (lower == normalTranslated || lower == 'normal')
            return 'normal';
        if (lower == hardTranslated || lower == 'hard')
            return 'hard';
        if (lower == erectTranslated || lower == 'erect')
            return 'erect';
        if (lower == nightmareTranslated || lower == 'nightmare')
            return 'nightmare';
        
        return lower;
    }
    
    public function changeSelection(change:Int = 0):Void {
        curSelected = FlxMath.wrap(curSelected + change, 0, Difficulty.list.length - 1);
        
        if (selectionTween != null) selectionTween.cancel();
        
        selectionTween = FlxTween.tween(this, {lerpSelected: curSelected}, 0.25, {
            ease: FlxEase.expoOut
        });
    }
    
    public function update(elapsed:Float):Void {
        for (i in 0...items.members.length) {
            var item:FlxText = items.members[i];
            var card:FlxSprite = cards.members[i];
            var scoreText:FlxText = scoreTexts.members[i];
            
            if(item == null || card == null) continue;
            
            var difference:Float = i - lerpSelected;
            var targetX:Float = FlxG.width / 2 + (difference * slideDistance) - baseXOffset;
            var targetY:Float = FlxG.height / 2 - 55;
            
            item.x = FlxMath.lerp(targetX, item.x, Math.exp(-elapsed * 12));
            item.y = targetY;
            
            card.x = item.x - 35;
            card.y = item.y - 10;
            
            if(scoreText != null) {
                scoreText.x = card.x + 10;
                scoreText.y = card.y + 80;
            }
            
            var targetAlpha:Float = enterProgress * (1.0 - (Math.abs(difference) * 0.3));
            if(Math.abs(difference) > 2) targetAlpha = 0;
            
            item.alpha = FlxMath.lerp(targetAlpha, item.alpha, Math.exp(-elapsed * 8));
            card.alpha = item.alpha;
            if(scoreText != null) scoreText.alpha = item.alpha;
            
            var targetScale:Float = (i == Math.round(lerpSelected)) ? 1.1 : 1.0;
            item.scale.set(targetScale, targetScale);
            card.scale.set(targetScale, targetScale);
        }
    }
    
    public function destroy():Void {
        if(selectionTween != null) {
            selectionTween.cancel();
            selectionTween = null;
        }
    }
}