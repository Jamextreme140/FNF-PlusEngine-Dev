// Default engine implementation of MainMenuState -- loaded by ScriptableState.
// Mods can override by placing their own at:  mods/{yourMod}/scripts/states/MainMenuState.hx

var optionShit:Array<String> = ['story_mode', 'freeplay', 'mods', 'credits'];
var leftOption:String  = 'achievements';
var rightOption:String = 'options';

var menuItems;
var leftItem;
var rightItem;
var magenta;
var camFollow;

var curSelected:Int = MainMenuState.curSelected;
// column: 0 = CENTER, 1 = LEFT, 2 = RIGHT
var curColumn:Int = 0;
var selectedSomethin:Bool = false;
var isMobile:Bool = false;

// Spectral visualizer state
var vizEnabled:Bool = false;
var vizBars = null;
var vizBarCount:Int = 160;
var vizBarMaxH:Int = 240;
var vizBarFill:Float = 0.62;
var vizMinH:Float = 2;
var vizSmoothSpeed:Float = 18;
var vizUpdateInterval:Float = 1 / 60;
var vizUpdateAccum:Float = 0;
var vizTargetHeights:Array<Float> = [];
var vizCurrentHeights:Array<Float> = [];
var vizAnalyzer = null;
var vizAnalyzerLevels = null;
var vizNeedsInit:Bool = false;

function create() {
    isMobile = (__isMobile == true);
    vizEnabled = Type.resolveClass('funkin.vis.dsp.SpectralAnalyzer') != null;

    if (isMobile) {
        vizBarCount = 96;
        vizUpdateInterval = 1 / 45;
    }

    Mods.pushGlobalMods();
    Mods.loadTopMod();
    persistentUpdate = persistentDraw = true;

    var bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.scrollFactor.set(0, 0.25);
    bg.setGraphicSize(Std.int(bg.width * 1.175));
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    // Spectral visualizer bars (behind all UI)
    if (vizEnabled) {
        vizBars = new FlxTypedGroup();
        var vizBarW:Int = Std.int(FlxG.width / vizBarCount);
        var vizDrawW:Int = Std.int(Math.max(1, vizBarW * vizBarFill));
        var vizOffsetX:Float = (vizBarW - vizDrawW) * 0.5;
        for (i in 0...vizBarCount) {
            var vbar = new FlxSprite();
            vbar.makeGraphic(vizDrawW, vizBarMaxH, FlxColor.WHITE);
            vbar.x = i * vizBarW + vizOffsetX;
            vbar.y = FlxG.height - 2;
            vbar.scale.y = 2 / vizBarMaxH;
            vbar.alpha = 0.0;
            vbar.scrollFactor.set();
            vizBars.add(vbar);
            vizTargetHeights.push(vizMinH);
            vizCurrentHeights.push(vizMinH);
        }
        add(vizBars);
        vizNeedsInit = true;
    }

    camFollow = new FlxObject(0, 0, 1, 1);
    add(camFollow);

    magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
    magenta.antialiasing = ClientPrefs.data.antialiasing;
    magenta.scrollFactor.set(0, 0.25);
    magenta.setGraphicSize(Std.int(magenta.width * 1.175));
    magenta.updateHitbox();
    magenta.screenCenter();
    magenta.visible = false;
    magenta.color = 0xFFfd719b;
    add(magenta);

    menuItems = new FlxTypedGroup();
    add(menuItems);

    for (i in 0...optionShit.length) {
        var item = createMenuItem(optionShit[i], 0, (i * 140) + 90);
        item.y += (4 - optionShit.length) * 70;
        item.screenCenter(X);
    }

    if (leftOption != null)
        leftItem = createMenuItem(leftOption, 60, 490);

    if (rightOption != null) {
        rightItem = createMenuItem(rightOption, FlxG.width - 60, 490);
        rightItem.x -= rightItem.width;
    }

    var psychVer = new FlxText(12, FlxG.height - 44, 0, 'Psych Engine v' + MainMenuState.psychEngineVersion, 12);
    psychVer.scrollFactor.set();
    psychVer.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(psychVer);

    var fnfVer = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + MainMenuState.fnfVersion, 12);
    fnfVer.scrollFactor.set();
    fnfVer.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    add(fnfVer);

    changeItem(0);
    FlxG.camera.follow(camFollow, null, 0.15);

    // E = debug editor, X = exit (mobile only)
    addTouchPad('NONE', 'E_X');
}

function createMenuItem(name:String, x:Float, y:Float) {
    var menuItem = new FlxSprite(x, y);
    menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + name);
    menuItem.animation.addByPrefix('idle',     name + ' idle',     24, true);
    menuItem.animation.addByPrefix('selected', name + ' selected', 24, true);
    menuItem.animation.play('idle');
    menuItem.updateHitbox();
    menuItem.antialiasing = ClientPrefs.data.antialiasing;
    menuItem.scrollFactor.set();
    menuItems.add(menuItem);
    return menuItem;
}

function changeItem(change:Int = 0) {
    if (change != 0) curColumn = 0;
    curSelected = FlxMath.wrap(curSelected + change, 0, optionShit.length - 1);
    FlxG.sound.play(Paths.sound('scrollMenu'));

    for (item in menuItems.members) {
        item.animation.play('idle');
        item.centerOffsets();
    }

    var selectedItem;
    if      (curColumn == 1) selectedItem = leftItem;
    else if (curColumn == 2) selectedItem = rightItem;
    else                     selectedItem = menuItems.members[curSelected];

    if (selectedItem != null) {
        selectedItem.animation.play('selected');
        selectedItem.centerOffsets();
        camFollow.y = selectedItem.getGraphicMidpoint().y;
    }
}

function selectOption(option:String, item) {
    MainMenuState.curSelected = curSelected;
    FlxG.sound.play(Paths.sound('confirmMenu'));
    selectedSomethin = true;
    Cursor.hide();
    if (ClientPrefs.data.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

    FlxFlicker.flicker(item, 1, 0.06, false, false, function(flick) {
        switch (option) {
            case 'story_mode':   MusicBeatState.switchState(new StoryMenuState());
            case 'freeplay':     MusicBeatState.switchState(new FreeplayState());
            case 'mods':         MusicBeatState.switchState(new ModsMenuState());
            case 'achievements': MusicBeatState.switchState(new AchievementsMenuState());
            case 'credits':      MusicBeatState.switchState(new CreditsState());
            case 'options':
                MusicBeatState.switchState(new OptionsState());
                OptionsState.onPlayState = false;
                if (PlayState.SONG != null) {
                    PlayState.SONG.arrowSkin  = null;
                    PlayState.SONG.splashSkin = null;
                    PlayState.stageUI = 'normal';
                }
            default:
                selectedSomethin = false;
                item.visible = true;
        }
    });

    for (memb in menuItems.members)
        if (memb != item) FlxTween.tween(memb, {alpha: 0}, 0.4, {ease: FlxEase.quadOut});
}

function update(elapsed:Float) {
    if (FlxG.sound.music.volume < 0.8)
        FlxG.sound.music.volume = Math.min(FlxG.sound.music.volume + 0.5 * elapsed, 0.8);

    // Spectral visualizer update
    if (vizEnabled && vizBars != null) {
        if (vizNeedsInit && FlxG.sound.music != null && FlxG.sound.music.playing) {
            try {
                var SpectralAnalyzer = Type.resolveClass('funkin.vis.dsp.SpectralAnalyzer');
                if (SpectralAnalyzer != null) {
                    vizAnalyzer = Type.createInstance(SpectralAnalyzer, [FlxG.sound.music._channel.__audioSource, vizBarCount, 0.08, 25]);
                    Reflect.setProperty(vizAnalyzer, 'minFreq', 40);
                    Reflect.setProperty(vizAnalyzer, 'maxFreq', 18000);
                    Reflect.setProperty(vizAnalyzer, 'minDb', -80);
                    Reflect.setProperty(vizAnalyzer, 'maxDb', -15);
                    Reflect.setProperty(vizAnalyzer, 'fftN', isMobile ? 256 : 512);
                    vizNeedsInit = false;
                }
            } catch(e:Dynamic) { vizNeedsInit = false; }
        }

        var vizBarW:Int = Std.int(FlxG.width / vizBarCount);
        var vizOffsetX:Float = (vizBarW - Std.int(Math.max(1, vizBarW * vizBarFill))) * 0.5;
        vizUpdateAccum += elapsed;
        if (vizUpdateAccum >= vizUpdateInterval) {
            vizUpdateAccum = 0;
            if (vizAnalyzer != null) {
                vizAnalyzerLevels = vizAnalyzer.getLevels(vizAnalyzerLevels);
                for (i in 0...vizBars.members.length) {
                    var level:Float = (vizAnalyzerLevels != null && i < vizAnalyzerLevels.length) ? vizAnalyzerLevels[i].value : 0.0;
                    vizTargetHeights[i] = Math.max(vizMinH, level * vizBarMaxH);
                }
            } else {
                for (i in 0...vizBars.members.length) vizTargetHeights[i] = vizMinH;
            }
        }
        var lerpFactor:Float = 1 - Math.exp(-elapsed * vizSmoothSpeed);
        for (i in 0...vizBars.members.length) {
            var vbar = vizBars.members[i];
            if (vbar == null) continue;
            var curH:Float = FlxMath.lerp(vizTargetHeights[i], vizCurrentHeights[i], 1 - lerpFactor);
            vizCurrentHeights[i] = curH;
            vbar.scale.y = curH / vizBarMaxH;
            vbar.x = i * vizBarW + vizOffsetX;
            vbar.y = FlxG.height - curH;
            vbar.alpha = 1.0;
        }
    }

    if (!selectedSomethin) {
        if (controls.UI_UP_P)   changeItem(-1);
        if (controls.UI_DOWN_P) changeItem(1);

        // Mouse hover
        if (FlxG.mouse.deltaScreenX != 0 || FlxG.mouse.deltaScreenY != 0 || FlxG.mouse.justPressed) {
            Cursor.show();
            if (leftItem != null && FlxG.mouse.overlaps(leftItem)) {
                if (curColumn != 1) { curColumn = 1; changeItem(0); }
            } else if (rightItem != null && FlxG.mouse.overlaps(rightItem)) {
                if (curColumn != 2) { curColumn = 2; changeItem(0); }
            } else {
                for (i in 0...optionShit.length) {
                    if (FlxG.mouse.overlaps(menuItems.members[i])) {
                        if (curColumn != 0 || curSelected != i) { curColumn = 0; curSelected = i; changeItem(0); }
                        break;
                    }
                }
            }
        }

        switch (curColumn) {
            case 0:
                if (controls.UI_LEFT_P  && leftOption  != null) { curColumn = 1; changeItem(0); }
                else if (controls.UI_RIGHT_P && rightOption != null) { curColumn = 2; changeItem(0); }
            case 1: if (controls.UI_RIGHT_P) { curColumn = 0; changeItem(0); }
            case 2: if (controls.UI_LEFT_P)  { curColumn = 0; changeItem(0); }
        }

        if (controls.BACK) {
            selectedSomethin = true;
            Cursor.hide();
            FlxG.sound.play(Paths.sound('cancelMenu'));
            MusicBeatState.switchState(new TitleState());
        } else if (controls.ACCEPT || (FlxG.mouse.overlaps(menuItems, FlxG.camera) && FlxG.mouse.justPressed)) {
            var option:String;
            var item;
            if      (curColumn == 1) { option = leftOption;              item = leftItem; }
            else if (curColumn == 2) { option = rightOption;             item = rightItem; }
            else                     { option = optionShit[curSelected]; item = menuItems.members[curSelected]; }
            selectOption(option, item);
        }

        // Debug master editor (keyboard debug_1 OR touchpad E button)
        if (controls.justPressed('debug_1') || (touchPad != null && touchPad.buttonE != null && touchPad.buttonE.justPressed)) {
            selectedSomethin = true;
            Cursor.hide();
            MusicBeatState.switchState(new MasterEditorMenu());
        }

        // Mobile exit button
        if (isMobile && touchPad != null && touchPad.buttonX != null && touchPad.buttonX.justPressed) {
            lime.system.System.exit(0);
        }
    }
}

function destroy() {
    vizAnalyzer = null;
    vizAnalyzerLevels = null;
}

