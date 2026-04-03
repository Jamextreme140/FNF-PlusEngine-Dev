// Default engine implementation of StoryMenuState -- loaded by ScriptableState.
// Mods can override by placing their own at:  mods/{yourMod}/scripts/states/StoryMenuState.hx

var scoreText;
var txtWeekTitle;
var bgSprite;
var txtTracklist;
var grpWeekText;
var grpWeekCharacters;
var grpLocks;
var difficultySelectors;
var sprDifficulty;
var leftArrow;
var rightArrow;

var curWeek:Int = 0;
var curDifficulty:Int = 1;
var lastDifficultyName:String = '';
var lerpScore:Int = 0;
var intendedScore:Int = 0;
var loadedWeeks:Array<Dynamic> = [];
var movedBack:Bool = false;
var selectedWeek:Bool = false;
var stopSpamming:Bool = false;
var isMobile:Bool = false;
var touchScroll = null;

function weekIsLocked(name:String):Bool {
    var leWeek = WeekData.weeksLoaded.get(name);
    return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0
        && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
}

function create() {
    isMobile = (__isMobile == true);
    // Memory clearing is handled by ScriptableState before super.create().
    persistentUpdate = persistentDraw = true;
    PlayState.isStoryMode = true;
    WeekData.reloadWeekFiles(true);

    if (WeekData.weeksList.length < 1) {
        FlxTransitionableState.skipNextTransIn = true;
        persistentUpdate = false;
        MusicBeatState.switchState(new MainMenuState());
        return;
    }

    if (curWeek >= WeekData.weeksList.length) curWeek = 0;

    scoreText = new FlxText(10, 10, 0,
        Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]), 36);
    scoreText.setFormat(Paths.font('phantom.ttf'), 32);

    txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, '', 32);
    txtWeekTitle.setFormat(Paths.font('phantom.ttf'), 32, FlxColor.WHITE, RIGHT);
    txtWeekTitle.alpha = 0.7;

    var ui_tex = Paths.getSparrowAtlas('campaign_menu_UI_assets');
    var bgYellow = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
    bgSprite = new FlxSprite(0, 56);

    grpWeekText = new FlxTypedGroup();
    add(grpWeekText);

    var blackBar = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
    add(blackBar);

    grpWeekCharacters = new FlxTypedGroup();
    grpLocks = new FlxTypedGroup();
    add(grpLocks);

    var num:Int = 0;
    var itemTargetY:Float = 0;
    for (i in 0...WeekData.weeksList.length) {
        var weekFile:Dynamic = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
        var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
        if (!isLocked || !weekFile.hiddenUntilUnlocked) {
            loadedWeeks.push(weekFile);
            WeekData.setDirectoryFromWeek(weekFile);
            var weekThing = new MenuItem(0, bgSprite.y + 396, WeekData.weeksList[i]);
            weekThing.y += ((weekThing.height + 20) * num);
            weekThing.ID = num;
            weekThing.targetY = itemTargetY;
            itemTargetY += Math.max(weekThing.height, 110) + 10;
            grpWeekText.add(weekThing);
            weekThing.screenCenter(X);

            if (isLocked) {
                var lock = new FlxSprite(weekThing.width + 10 + weekThing.x);
                lock.antialiasing = ClientPrefs.data.antialiasing;
                lock.frames = ui_tex;
                lock.animation.addByPrefix('lock', 'lock');
                lock.animation.play('lock');
                lock.ID = i;
                grpLocks.add(lock);
            }
            num++;
        }
    }

    WeekData.setDirectoryFromWeek(loadedWeeks[0]);
    var charArray = loadedWeeks[0].weekCharacters;
    for (c in 0...3) {
        var ch = new MenuCharacter((FlxG.width * 0.25) * (1 + c) - 150, charArray[c]);
        ch.y += 70;
        grpWeekCharacters.add(ch);
    }

    difficultySelectors = new FlxGroup();
    add(difficultySelectors);

    leftArrow = new FlxSprite(850, grpWeekText.members[0].y + 10);
    leftArrow.antialiasing = ClientPrefs.data.antialiasing;
    leftArrow.frames = ui_tex;
    leftArrow.animation.addByPrefix('idle', 'arrow left');
    leftArrow.animation.addByPrefix('press', 'arrow push left');
    leftArrow.animation.play('idle');
    difficultySelectors.add(leftArrow);

    Difficulty.resetList();
    if (lastDifficultyName == '') lastDifficultyName = Difficulty.getDefault();
    curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

    sprDifficulty = new FlxSprite(0, leftArrow.y);
    sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;
    difficultySelectors.add(sprDifficulty);

    rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
    rightArrow.antialiasing = ClientPrefs.data.antialiasing;
    rightArrow.frames = ui_tex;
    rightArrow.animation.addByPrefix('idle', 'arrow right');
    rightArrow.animation.addByPrefix('press', 'arrow push right', 24, false);
    rightArrow.animation.play('idle');
    difficultySelectors.add(rightArrow);

    add(bgYellow);
    add(bgSprite);
    add(grpWeekCharacters);

    var tracksSprite = new FlxSprite(FlxG.width * 0.07 + 100, bgSprite.y + 425)
        .loadGraphic(Paths.image('Menu_Tracks'));
    tracksSprite.antialiasing = ClientPrefs.data.antialiasing;
    tracksSprite.x -= tracksSprite.width / 2;
    add(tracksSprite);

    txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, '', 32);
    txtTracklist.alignment = CENTER;
    txtTracklist.font = Paths.font('phantom.ttf');
    txtTracklist.color = 0xFFe55777;
    add(txtTracklist);
    add(scoreText);
    add(txtWeekTitle);

    changeWeek();
    changeDifficulty();

    addTouchPad('NONE', 'B_X_Y');

    if (isMobile) {
        touchScroll = new TouchScroll(true);
        TouchUtil.setScrollHandler(touchScroll);
    }
}

function closeSubState() {
    persistentUpdate = true;
    changeWeek();
    removeTouchPad();
    addTouchPad('NONE', 'B_X_Y');
    if (isMobile && touchScroll != null)
        touchScroll.reset();
}

function update(elapsed:Float) {
    if (WeekData.weeksList.length < 1) {
        if (controls.BACK || (touchPad != null && touchPad.buttonB != null && touchPad.buttonB.justPressed)) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            movedBack = true;
            MusicBeatState.switchState(new MainMenuState());
        }
        return;
    }

    if (intendedScore != lerpScore) {
        lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
        if (Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
        scoreText.text = Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]);
    }

    if (!movedBack && !selectedWeek) {
        var changeDiff:Bool = false;

        if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp != null && touchPad.buttonUp.justPressed)) {
            changeWeek(-1);
            FlxG.sound.play(Paths.sound('scrollMenu'));
            changeDiff = true;
        }
        if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown != null && touchPad.buttonDown.justPressed)) {
            changeWeek(1);
            FlxG.sound.play(Paths.sound('scrollMenu'));
            changeDiff = true;
        }

        // Mouse wheel scrolling
        if (FlxG.mouse.wheel != 0) {
            FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
            changeWeek(-FlxG.mouse.wheel);
            changeDiff = true;
        }

        // Touch scroll handling
        if (isMobile && touchScroll != null) {
            var delta:Float = touchScroll.update();
            if (Math.abs(delta) > 0.5) {
                var lerpWeekFloat:Float = curWeek + (-delta / 150.0);
                lerpWeekFloat = FlxMath.bound(lerpWeekFloat, 0, loadedWeeks.length - 1);
                var newWeek:Int = Math.round(lerpWeekFloat);
                if (newWeek != curWeek) {
                    changeWeek(newWeek - curWeek);
                    changeDiff = true;
                }
            }
            if (touchScroll.wasTapped()) {
                var tapPos = touchScroll.getTapPosition();
                if (tapPos != null) {
                    if (leftArrow.overlapsPoint(tapPos))
                        changeDifficulty(-1);
                    else if (rightArrow.overlapsPoint(tapPos))
                        changeDifficulty(1);
                    else {
                        for (i in 0...grpWeekText.members.length) {
                            var item = grpWeekText.members[i];
                            if (item != null && item.visible && item.overlapsPoint(tapPos)) {
                                if (i == curWeek) selectWeek();
                                else { changeWeek(i - curWeek); changeDiff = true; }
                                break;
                            }
                        }
                    }
                }
            }
        }

        // Difficulty arrow animations
        if (controls.UI_RIGHT || (touchPad != null && touchPad.buttonRight != null && touchPad.buttonRight.pressed))
            rightArrow.animation.play('press');
        else
            rightArrow.animation.play('idle');

        if (controls.UI_LEFT || (touchPad != null && touchPad.buttonLeft != null && touchPad.buttonLeft.pressed))
            leftArrow.animation.play('press');
        else
            leftArrow.animation.play('idle');

        if (controls.UI_RIGHT_P || (touchPad != null && touchPad.buttonRight != null && touchPad.buttonRight.justPressed))
            changeDifficulty(1);
        else if (controls.UI_LEFT_P || (touchPad != null && touchPad.buttonLeft != null && touchPad.buttonLeft.justPressed))
            changeDifficulty(-1);
        else if (changeDiff)
            changeDifficulty();

        // Gameplay changers substate (CTRL / X button)
        if (FlxG.keys.justPressed.CONTROL || (touchPad != null && touchPad.buttonX != null && touchPad.buttonX.justPressed)) {
            persistentUpdate = false;
            openSubState(new GameplayChangersSubstate());
            removeTouchPad();
        }
        // Reset score substate (RESET / Y button)
        else if (controls.RESET || (touchPad != null && touchPad.buttonY != null && touchPad.buttonY.justPressed)) {
            persistentUpdate = false;
            openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
            removeTouchPad();
        }
        else if (controls.ACCEPT || (touchPad != null && touchPad.buttonA != null && touchPad.buttonA.justPressed))
            selectWeek();

        if ((controls.BACK || (touchPad != null && touchPad.buttonB != null && touchPad.buttonB.justPressed))
                && !movedBack && !selectedWeek) {
            FlxG.sound.play(Paths.sound('cancelMenu'));
            movedBack = true;
            MusicBeatState.switchState(new MainMenuState());
        }
    }

    var offY:Float = grpWeekText.members[curWeek].targetY;
    for (i in 0...grpWeekText.members.length) {
        var item = grpWeekText.members[i];
        item.y = FlxMath.lerp(item.targetY - offY + 480, item.y, Math.exp(-elapsed * 10.2));
    }
    for (i in 0...grpLocks.members.length) {
        var lock = grpLocks.members[i];
        var parent = grpWeekText.members[lock.ID];
        lock.y = parent.y + parent.height / 2 - lock.height / 2;
    }
}

function selectWeek() {
    if (!weekIsLocked(loadedWeeks[curWeek].fileName)) {
        var songArray:Array<String> = [];
        var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
        for (i in 0...leWeek.length) songArray.push(leWeek[i][0]);

        try {
            PlayState.storyPlaylist = songArray;
            PlayState.isStoryMode = true;
            selectedWeek = true;

            var diffic = Difficulty.getFilePath(curDifficulty);
            if (diffic == null) diffic = '';

            PlayState.storyDifficulty = curDifficulty;
            Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
            PlayState.campaignScore = 0;
            PlayState.campaignMisses = 0;
            PlayState.campaignFlawlesss = 0;
            PlayState.campaignSicks = 0;
            PlayState.campaignGoods = 0;
            PlayState.campaignBads = 0;
            PlayState.campaignShits = 0;
            PlayState.campaignMaxCombo = 0;
            PlayState.campaignTotalNotes = 0;
            PlayState.campaignSongsPlayed = [];
            PlayState.campaignAccuracySum = 0;
            PlayState.campaignSongsCount = 0;
        } catch(e:Dynamic) {
            trace('ERROR! $e');
            return;
        }

        if (!stopSpamming) {
            FlxG.sound.play(Paths.sound('confirmMenu'));
            grpWeekText.members[curWeek].isFlashing = true;
            for (i in 0...grpWeekCharacters.members.length) {
                var ch = grpWeekCharacters.members[i];
                if (ch.character != '' && ch.hasConfirmAnimation)
                    ch.animation.play('confirm');
            }
            stopSpamming = true;
        }

        var directory = StageData.forceNextDirectory;
        LoadingState.loadNextDirectory();
        StageData.forceNextDirectory = directory;

        LoadingState.prepareToSong();
        new FlxTimer().start(1, function(tmr:FlxTimer) {
            FlxG.sound.music.stop();
            LoadingState.returnState = new StoryMenuState();
            LoadingState.loadAndSwitchState(new PlayState(), true);
            FreeplayState.destroyFreeplayVocals();
        });
    } else {
        FlxG.sound.play(Paths.sound('cancelMenu'));
    }
}

function changeDifficulty(?change:Int = 0) {
    if (change == null) change = 0;
    curDifficulty += change;
    if (curDifficulty < 0) curDifficulty = Difficulty.list.length - 1;
    if (curDifficulty >= Difficulty.list.length) curDifficulty = 0;

    WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

    var diff:String = Difficulty.getString(curDifficulty, false);
    var newImage = Paths.image('menudifficulties/' + Paths.formatToSongPath(diff));

    if (sprDifficulty.graphic != newImage) {
        sprDifficulty.loadGraphic(newImage);
        sprDifficulty.x = leftArrow.x + 60;
        sprDifficulty.x += (308 - sprDifficulty.width) / 3;
        sprDifficulty.y = leftArrow.y;

        FlxTween.cancelTweensOf(sprDifficulty);
        sprDifficulty.alpha = 0;
        sprDifficulty.y = leftArrow.y - sprDifficulty.height;
        FlxTween.tween(sprDifficulty, {y: leftArrow.y + 13, alpha: 1}, 0.07);
    }
    lastDifficultyName = diff;
    intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
}

function changeWeek(?change:Int = 0) {
    if (change == null) change = 0;
    curWeek += change;
    if (curWeek >= loadedWeeks.length) curWeek = 0;
    if (curWeek < 0) curWeek = loadedWeeks.length - 1;

    var leWeek:Dynamic = loadedWeeks[curWeek];
    WeekData.setDirectoryFromWeek(leWeek);

    var leName:String = Language.getPhrase('storyname_${leWeek.fileName}', leWeek.storyName);
    txtWeekTitle.text = leName.toUpperCase();
    txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

    var unlocked:Bool = !weekIsLocked(leWeek.fileName);
    for (i in 0...grpWeekText.members.length) {
        grpWeekText.members[i].alpha = (i == curWeek && unlocked) ? 1 : 0.6;
    }

    bgSprite.visible = leWeek.weekBackground != null && leWeek.weekBackground.length > 0;
    if (bgSprite.visible) bgSprite.loadGraphic(Paths.image('menubackgrounds/menu_' + leWeek.weekBackground));

    PlayState.storyWeek = curWeek;
    Difficulty.loadFromWeek();
    difficultySelectors.visible = unlocked;

    if (Difficulty.list.contains(Difficulty.getDefault()))
        curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
    else
        curDifficulty = 0;

    var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
    if (newPos > -1) curDifficulty = newPos;
    updateText();
}

function updateText() {
    var weekArray = loadedWeeks[curWeek].weekCharacters;
    for (i in 0...grpWeekCharacters.members.length)
        grpWeekCharacters.members[i].changeCharacter(weekArray[i]);

    var leWeek:Dynamic = loadedWeeks[curWeek];
    var stringThing:Array<String> = [];
    for (i in 0...leWeek.songs.length) stringThing.push(leWeek.songs[i][0]);

    txtTracklist.text = '';
    for (i in 0...stringThing.length) txtTracklist.text += stringThing[i] + '\n';
    txtTracklist.text = txtTracklist.text.toUpperCase();
    txtTracklist.screenCenter(X);
    txtTracklist.x -= FlxG.width * 0.35;
    intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
}

function beatHit(curBeat:Int) {
    for (i in 0...grpWeekCharacters.members.length) {
        var ch = grpWeekCharacters.members[i];
        if (ch.character != '') ch.dance();
    }
}

function destroy() {
    if (isMobile && touchScroll != null) {
        touchScroll.destroy();
        touchScroll = null;
    }
    if (isMobile) TouchUtil.clearScrollHandler();
}

