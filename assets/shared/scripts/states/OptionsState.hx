// Default engine implementation of OptionsState — loaded by ScriptableState.
// Mods can override this by placing their own copy at:
//   mods/{yourMod}/scripts/states/OptionsState.hx

var options:Array<String> = [];
var grpOptions;
var curSelected:Int = 0;
var lerpSelected:Float = 0;
var selectorLeft;
var selectorRight;
var exiting:Bool = false;

// Mobile touch scroll handler (null on non-mobile builds)
var touchScroll = null;
var isMobile:Bool = false;

function create() {
    isMobile = Type.resolveClass('funkin.mobile.backend.TouchScroll') != null;

    options = [];
    if (!ClientPrefs.data.colorQuantization) options.push('Note Colors');
    options.push('Controls');
    options.push('Adjust Delay and Combo');
    options.push('Graphics');
    options.push('Visuals');
    options.push('Gameplay');
    options.push('Legacy');
    if (Type.resolveClass('funkin.ui.options.ModchartSettingsSubState') != null)
        options.push('Modchart');
    if (Type.resolveClass('funkin.ui.options.LanguageSubState') != null)
        options.push('Language');
    if (__isMobile == true)
        options.push('Mobile');

    var bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.color = 0xFFea71fd;
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    grpOptions = new FlxTypedGroup();
    add(grpOptions);

    for (i in 0...options.length) {
        var optionText = new Alphabet(0, 0, Language.getPhrase('options_' + options[i], options[i]), true);
        optionText.targetY = i;
        optionText.isMenuItem = true;
        optionText.changeX = false;
        optionText.changeY = false;
        grpOptions.add(optionText);
    }

    selectorLeft = new Alphabet(0, 0, '>', true);
    add(selectorLeft);
    selectorRight = new Alphabet(0, 0, '<', true);
    add(selectorRight);

    if (isMobile) {
        touchScroll = new TouchScroll(true);
        TouchUtil.setScrollHandler(touchScroll);

        var tipText = new FlxText(150, FlxG.height - 24, 0, Language.getPhrase('mobile_controls_tip', 'Press {1} to Go Mobile Controls Menu', [FlxG.onMobile ? 'C' : 'CTRL or C']), 16);
        tipText.setFormat(Paths.font('phantom.ttf'), 17, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        tipText.borderSize = 1.25;
        tipText.scrollFactor.set();
        tipText.antialiasing = ClientPrefs.data.antialiasing;
        add(tipText);
    }

    lerpSelected = curSelected;
    changeSelection(0);
    ClientPrefs.saveSettings();

    var maxScroll:Float = Math.max(0, (options.length - 1) * 100 - FlxG.height * 0.7);
    var scrollY:Float = FlxMath.bound(lerpSelected * 100 - FlxG.height * 0.3, 0, maxScroll);
    for (i in 0...grpOptions.members.length) {
        var item = grpOptions.members[i];
        item.screenCenter(X);
        item.y = (FlxG.height * 0.15) + item.targetY * 100 - scrollY;
        item.alpha = 0.6;
        if (item.targetY == curSelected) {
            item.alpha = 1;
            selectorLeft.x = item.x - 63;
            selectorLeft.y = item.y;
            selectorRight.x = item.x + item.width + 15;
            selectorRight.y = item.y;
        }
    }

    addTouchPad('UP_DOWN', 'A_B_C');
}

function openSelectedSubstate(label:String) {
    persistentUpdate = false;
    if (isMobile && touchScroll != null) touchScroll.reset();
    switch (label) {
        case 'Note Colors':
            openSubState(new NotesColorSubState());
        case 'Controls':
            openSubState(new ControlsSubState());
        case 'Graphics':
            openSubState(new GraphicsSettingsSubState());
        case 'Visuals':
            openSubState(new VisualsSettingsSubState());
        case 'Gameplay':
            openSubState(new GameplaySettingsSubState());
        case 'Legacy':
            openSubState(new LegacySettingsSubState());
        case 'Modchart':
            openSubState(new ModchartSettingsSubState());
        case 'Language':
            openSubState(new LanguageSubState());
        case 'Mobile':
            openSubState(new MobileSettingsSubState());
        case 'Adjust Delay and Combo':
            MusicBeatState.switchState(new NoteOffsetState());
    }
}

function changeSelection(change:Int = 0) {
    curSelected = FlxMath.wrap(curSelected + change, 0, options.length - 1);
    for (i in 0...grpOptions.members.length)
        grpOptions.members[i].targetY = i;
    if (change != 0) FlxG.sound.play(Paths.sound('scrollMenu'));
}

function closeSubState() {
    ClientPrefs.saveSettings();
    controls.isInSubstate = false;
    persistentUpdate = true;
    if (isMobile && touchScroll != null) touchScroll.reset();
    removeTouchPad();
    addTouchPad('NONE', 'B_C');
    changeSelection(0);
}

function update(elapsed:Float) {
    lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.5));

    var maxScroll:Float = Math.max(0, (options.length - 1) * 100 - FlxG.height * 0.7);
    var scrollY:Float = FlxMath.bound(lerpSelected * 100 - FlxG.height * 0.3, 0, maxScroll);
    for (i in 0...grpOptions.members.length) {
        var item = grpOptions.members[i];
        item.screenCenter(X);
        item.y = FlxMath.lerp((FlxG.height * 0.15) + item.targetY * 100 - scrollY, item.y, Math.exp(-elapsed * 10.2));
        item.alpha = 0.6;
        if (item.targetY == curSelected) {
            item.alpha = 1;
            selectorLeft.x = item.x - 63;
            selectorLeft.y = item.y;
            selectorRight.x = item.x + item.width + 15;
            selectorRight.y = item.y;
        }
    }

    if (!exiting) {
        if (controls.UI_UP_P)   changeSelection(-1);
        if (controls.UI_DOWN_P) changeSelection(1);

        // Mobile touch scroll and tap
        if (isMobile && touchScroll != null) {
            var scrollDelta:Float = touchScroll.update();
            if (Math.abs(scrollDelta) > 0.5) {
                lerpSelected += -scrollDelta / 150;
                lerpSelected = FlxMath.bound(lerpSelected, 0, options.length - 1);
                var newSelected:Int = Math.round(lerpSelected);
                if (newSelected != curSelected)
                    changeSelection(newSelected - curSelected);
            }
            if (touchScroll.wasTapped()) {
                var tapPos = touchScroll.getTapPosition();
                if (tapPos != null) {
                    for (i in 0...grpOptions.members.length) {
                        var item = grpOptions.members[i];
                        if (item != null && item.visible && item.overlapsPoint(tapPos)) {
                            if (i == curSelected)
                                openSelectedSubstate(options[curSelected]);
                            else {
                                curSelected = i;
                                lerpSelected = i;
                                for (j in 0...grpOptions.members.length)
                                    grpOptions.members[j].targetY = j;
                                FlxG.sound.play(Paths.sound('scrollMenu'));
                            }
                            break;
                        }
                    }
                }
            }
        }

        // Mobile controls layout button (C / CTRL)
        if (isMobile && (
            (touchPad != null && touchPad.buttonC != null && touchPad.buttonC.justPressed) ||
            (FlxG.keys.justPressed.CONTROL && controls.mobileC)
        )) {
            persistentUpdate = false;
            openSubState(new MobileControlSelectSubState());
        }

        if (controls.BACK) {
            exiting = true;
            FlxG.sound.play(Paths.sound('cancelMenu'));
            if (OptionsState.onPlayState) {
                StageData.loadDirectory(PlayState.SONG);
                LoadingState.loadAndSwitchState(new PlayState());
                FlxG.sound.music.volume = 0;
            } else {
                MusicBeatState.switchState(new MainMenuState());
            }
        } else if (controls.ACCEPT) {
            openSelectedSubstate(options[curSelected]);
        }
    }
}

function destroy() {
    if (isMobile && touchScroll != null) {
        touchScroll.destroy();
        touchScroll = null;
        TouchUtil.clearScrollHandler();
    }
    ClientPrefs.loadPrefs();
}

