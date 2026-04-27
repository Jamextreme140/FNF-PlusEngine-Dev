// Default engine implementation of TitleState — loaded by ScriptableState.
// Mods can override this by placing their own copy at:
//   mods/{yourMod}/scripts/states/TitleState.hx
//
// Variables injected by ScriptableState:
//   add / remove / insert / openSubState — FlxState helpers
//   game     — the ScriptableState host
//   controls — Controls.instance

var credGroup;
var textGroup;
var blackScreen;
var credTextShit;
var ngSpr;
var updateNotificationText;

var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
var titleTextAlphas:Array<Float> = [1, .64];
var curWacky:Array<String> = [];

var logoBl;
var gfDance;
var titleText;
var danceLeft:Bool = false;
var swagShader = null;

// JSON data
var characterImage:String     = 'gfDanceTitle';
var animationName:String      = 'gfDance';
var gfPosition                = FlxPoint.get(512, 40);
var logoPosition              = FlxPoint.get(-150, -100);
var enterPosition             = FlxPoint.get(100, 576);
var useIdle:Bool              = false;
var musicBPM:Float            = 102;
var danceLeftFrames:Array<Int>  = [15,16,17,18,19,20,21,22,23,24,25,26,27,28,29];
var danceRightFrames:Array<Int> = [30,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14];

var transitioning:Bool = false;
var skippedIntro:Bool  = false;
var newTitle:Bool      = false;
var titleTimer:Float   = 0;
var sickBeats:Int      = 0;
var isMobile:Bool      = false;

function create() {
    isMobile = (__isMobile == true);
    // Memory clearing is handled by ScriptableState before super.create(),
    // so transition assets are never accidentally destroyed here.
    if (!TitleState.initialized)
        ColorblindFilter.UpdateColors();

    if (FlxG.save.data.introFinished == null)
        FlxG.save.data.introFinished = false;

    curWacky = randomObject(getIntroTextShit());

    if (!TitleState.initialized) {
        if (FlxG.save.data != null && FlxG.save.data.fullscreen)
            WindowMode.setBorderlessFullscreen(FlxG.save.data.fullscreen);
    }
    // Always enable updates/draws so beats fire even when a transition substate is open.
    persistentUpdate = true;
    persistentDraw  = true;

    if (FlxG.save.data.weekCompleted != null)
        StoryMenuState.weekCompleted = FlxG.save.data.weekCompleted;

    Cursor.hide();

    if (FlxG.save.data.flashing == null && !FlashingState.leftState) {
        controls.isInSubstate = false;
        FlxTransitionableState.skipNextTransIn  = true;
        FlxTransitionableState.skipNextTransOut = true;
        MusicBeatState.switchState(new FlashingState());
    } else {
        credGroup = new FlxGroup();
        textGroup = new FlxGroup();
        startIntro();
    }
}

function getIntroTextShit():Array<Array<String>> {
    try {
        var localized = Language.getLocalizedIntroTexts();
        if (localized != null && localized.length > 0) return localized;
    } catch(e:Dynamic) {}
    var firstArray:Array<String> = Mods.mergeAllTextsNamed('data/introText.txt');
    var swagGoodArray:Array<Array<String>> = [];
    for (i in firstArray)
        swagGoodArray.push(i.split('--'));
    return swagGoodArray;
}

function loadJsonData() {
    if (Paths.fileExists('images/gfDanceTitle.json', TEXT)) {
        var titleRaw:String = Paths.getTextFromFile('images/gfDanceTitle.json');
        if (titleRaw != null && titleRaw.length > 0) {
            try {
                var titleJSON = TJSON.parse(titleRaw);
                gfPosition.set(titleJSON.gfx, titleJSON.gfy);
                logoPosition.set(titleJSON.titlex, titleJSON.titley);
                enterPosition.set(titleJSON.startx, titleJSON.starty);
                musicBPM = titleJSON.bpm;
                if (titleJSON.animation != null && titleJSON.animation.length > 0) animationName = titleJSON.animation;
                if (titleJSON.dance_left  != null && titleJSON.dance_left.length  > 0) danceLeftFrames  = titleJSON.dance_left;
                if (titleJSON.dance_right != null && titleJSON.dance_right.length > 0) danceRightFrames = titleJSON.dance_right;
                useIdle = (titleJSON.idle == true);
                if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.trim().length > 0) {
                    var bg = new FlxSprite().loadGraphic(Paths.image(titleJSON.backgroundSprite));
                    bg.antialiasing = ClientPrefs.data.antialiasing;
                    add(bg);
                }
            } catch (e:Dynamic) {
                trace('[TitleState] Title JSON parse error: ' + e);
            }
        }
    }
}

function startIntro() {
    persistentUpdate = true;

    if (!TitleState.initialized) {
        if (FlxG.sound.music == null) {
            FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.7);
        } else {
            FlxG.sound.music.stop();
            FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
            FlxG.sound.music.fadeIn(4, 0, 0.7);
        }
    }

    loadJsonData();
    Conductor.bpm = musicBPM;

    logoBl = new FlxSprite(
        logoPosition.x,
        logoPosition.y + (isMobile ? MobileScaleMode.getVerticalOffset() : 0)
    );
    logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
    logoBl.antialiasing = ClientPrefs.data.antialiasing;
    logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
    logoBl.animation.play('bump');
    logoBl.updateHitbox();

    gfDance = new FlxSprite(
        gfPosition.x,
        gfPosition.y + (isMobile ? MobileScaleMode.getVerticalOffset() : 0)
    );
    gfDance.antialiasing = ClientPrefs.data.antialiasing;
    if (ClientPrefs.data.shaders) {
        swagShader = new ColorSwap();
        gfDance.shader  = swagShader.shader;
        logoBl.shader   = swagShader.shader;
    }
    gfDance.frames = Paths.getSparrowAtlas(characterImage);
    if (!useIdle) {
        gfDance.animation.addByIndices('danceLeft',  animationName, danceLeftFrames,  '', 24, false);
        gfDance.animation.addByIndices('danceRight', animationName, danceRightFrames, '', 24, false);
        gfDance.animation.play('danceRight');
    } else {
        gfDance.animation.addByPrefix('idle', animationName, 24, false);
        gfDance.animation.play('idle');
    }

    titleText = new FlxSprite(
        enterPosition.x,
        enterPosition.y + (isMobile ? MobileScaleMode.getVerticalOffset() : 0)
    );
    titleText.frames = Paths.getSparrowAtlas(isMobile ? 'mobile/titleEnter' : 'titleEnter');
    var animFrames = [];
    titleText.animation.findByPrefix(animFrames, 'ENTER IDLE');
    titleText.animation.findByPrefix(animFrames, 'ENTER FREEZE');
    if (newTitle = animFrames.length > 0) {
        titleText.animation.addByPrefix('idle',  'ENTER IDLE',   24);
        titleText.animation.addByPrefix('press', ClientPrefs.data.flashing ? 'ENTER PRESSED' : 'ENTER FREEZE', 24);
    } else {
        titleText.animation.addByPrefix('idle',  'Press Enter to Begin', 24);
        titleText.animation.addByPrefix('press', 'ENTER PRESSED',        24);
    }
    titleText.animation.play('idle');
    titleText.updateHitbox();

    blackScreen = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
    blackScreen.scale.set(FlxG.width, FlxG.height);
    blackScreen.updateHitbox();
    credGroup.add(blackScreen);

    credTextShit = new Alphabet(0, 0, '', true);
    credTextShit.screenCenter();
    credTextShit.visible = false;

    ngSpr = new FlxSprite(0,
        isMobile ? (MobileScaleMode.BASE_GAME_HEIGHT * 0.52 + MobileScaleMode.getVerticalOffset()) : (FlxG.height * 0.52)
    ).loadGraphic(Paths.image('newgrounds_logo'));
    ngSpr.visible = false;
    ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
    ngSpr.updateHitbox();
    if (isMobile)
        ngSpr.x = (MobileScaleMode.BASE_GAME_WIDTH - ngSpr.width) * 0.5;
    else
        ngSpr.screenCenter(X);
    ngSpr.antialiasing = ClientPrefs.data.antialiasing;

    add(gfDance);
    add(logoBl);
    add(titleText);
    add(credGroup);
    add(ngSpr);

    updateNotificationText = new FlxText(0, 10, 0, 'Checking Updates...', 20);
    updateNotificationText.setFormat('PhantomMuff 1.5', 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    updateNotificationText.borderSize = 2;
    updateNotificationText.scrollFactor.set();
    updateNotificationText.x = FlxG.width + 50;
    updateNotificationText.cameras = [FlxG.camera];
    add(updateNotificationText);
    updateNotificationText.visible = false;

    if (TitleState.initialized)
        skipIntro();
    else
        TitleState.initialized = true;
}

function createCoolText(textArray:Array<String>, ?offset:Float = 0) {
    if (offset == null) offset = 0;
    for (i in 0...textArray.length) {
        var money = new Alphabet(0, 0, textArray[i], true);
        money.screenCenter(X);
        money.y += (i * 60) + 200 + offset;
        if (credGroup != null && textGroup != null) {
            credGroup.add(money);
            textGroup.add(money);
        }
    }
}

function addMoreText(text:String, ?offset:Float = 0) {
    if (offset == null) offset = 0;
    if (textGroup == null || credGroup == null) return;
    var coolText = new Alphabet(0, 0, text, true);
    coolText.screenCenter(X);
    coolText.y += (textGroup.length * 60) + 200 + offset;
    credGroup.add(coolText);
    textGroup.add(coolText);
}

function deleteCoolText() {
    while (textGroup.members.length > 0) {
        credGroup.remove(textGroup.members[0], true);
        textGroup.remove(textGroup.members[0], true);
    }
}

function skipIntro() {
    if (!skippedIntro) {
        remove(ngSpr);
        remove(credGroup);
        FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 4);
        skippedIntro = true;
    }
}

function update(elapsed:Float) {
    if (CoolUtil.executeUpdateCallback != null) CoolUtil.executeUpdateCallback();

    if (FlxG.sound.music != null)
        Conductor.songPosition = FlxG.sound.music.time;

    var pressedEnter:Bool = FlxG.keys.justPressed.ENTER || controls.ACCEPT;
    if (isMobile && TouchUtil.justPressed) pressedEnter = true;
    var gamepad = FlxG.gamepads.lastActive;
    if (gamepad != null && gamepad.justPressed.START) pressedEnter = true;

    if (newTitle) {
        titleTimer += FlxMath.bound(elapsed, 0, 1);
        if (titleTimer > 2) titleTimer -= 2;
    }

    if (TitleState.initialized && !transitioning && skippedIntro) {
        if (newTitle && !pressedEnter) {
            var timer:Float = titleTimer;
            if (timer >= 1) timer = (-timer) + 2;
            timer = FlxEase.quadInOut(timer);
            titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
            titleText.alpha  = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
        }

        if (pressedEnter) {
            titleText.color = FlxColor.WHITE;
            titleText.alpha = 1;
            if (titleText != null) titleText.animation.play('press');

            FlxG.camera.flash(ClientPrefs.data.flashing ? FlxColor.WHITE : 0x4CFFFFFF, 1);
            FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
            transitioning = true;

            new FlxTimer().start(1, function(tmr) {
                MusicBeatState.switchState(new MainMenuState());
                TitleState.closedState = true;
            });
        }
    }

    if (TitleState.initialized && pressedEnter && !skippedIntro)
        skipIntro();

    if (swagShader != null) {
        if (controls.UI_LEFT)  swagShader.hue -= elapsed * 0.1;
        if (controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
    }
}

function beatHit(curBeat:Int) {
    if (logoBl != null) logoBl.animation.play('bump', true);

    if (gfDance != null) {
        danceLeft = !danceLeft;
        if (!useIdle) {
            gfDance.animation.play(danceLeft ? 'danceRight' : 'danceLeft');
        } else if (curBeat % 2 == 0) {
            gfDance.animation.play('idle', true);
        }
    }

    if (!TitleState.closedState) {
        sickBeats++;
        switch (sickBeats) {
            case 1:
                FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
                FlxG.sound.music.fadeIn(4, 0, 0.7);
            case 2:  createCoolText(['Psych Engine by\n Shadow Mario'], -30);
            case 4:  addMoreText('Plus Engine by\n   Lenin Asto', 130);
            case 5:  deleteCoolText();
            case 6:  createCoolText(['Not associated', 'with'], -40);
            case 8:  addMoreText('newgrounds', -40); ngSpr.visible = true;
            case 9:  deleteCoolText(); ngSpr.visible = false;
            case 10: createCoolText([curWacky != null ? curWacky[0] : '...'], 0);
            case 12: addMoreText(curWacky != null ? curWacky[1] : '...', 0);
            case 13: deleteCoolText();
            case 14: addMoreText('Friday', 0);
            case 15: addMoreText('Night', 0);
            case 16: addMoreText('Funkin', 0);
            case 17: skipIntro();
        }
    }
}
