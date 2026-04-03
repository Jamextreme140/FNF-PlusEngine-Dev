// Default engine implementation of ModsMenuState -- loaded by ScriptableState.
// Mods can override by placing their own at:  mods/{yourMod}/scripts/states/ModsMenuState.hx

// ---- State variables -------------------------------------------------------
var bg:FlxSprite;
var icon:FlxSprite;
var modName;           // Alphabet
var modDesc;           // FlxText
var modRestartText;    // FlxText

var bgList:FlxSprite;
var buttonReload;      // MenuButton
var buttonEnableAll;   // MenuButton
var buttonDisableAll;  // MenuButton
var settingsButton;    // MenuButton
var buttons:Array = [];

var bgTitle:FlxSprite;
var bgDescription:FlxSprite;
var bgButtons:FlxSprite;

var modsGroup;         // FlxTypedGroup<ModItem>
var modsList = null;

var curSelectedMod:Int = 0;
var hoveringOnMods:Bool = true;
var curSelectedButton:Int = 0;
var modNameInitialY:Float = 0;

var noModsSine:Float = 0;
var noModsTxt;         // FlxText
var nextAttempt:Float = 1;

var holdTime:Float = 0;
var holdingMod:Bool = false;
var mouseOffsets:FlxPoint = new FlxPoint();
var holdingElapsed:Float = 0;
var gottaClickAgain:Bool = false;
var _lastControllerMode:Bool = false;

var exiting:Bool = false;
var waitingToRestart:Bool = false;
var toggleButtonsInitialized:Bool = false;

// Y positions for the animated toggle buttons
var buttonToggleMainY:Float = 0;
var buttonToggleSecondY:Float = 0;
var buttonToggleHiddenY:Float = 0;

var centerMod:Int = 2;

// ---- create() --------------------------------------------------------------
function create() {
    var daButton:String = __isMobile ? 'B' : 'BACKSPACE';
    persistentUpdate = false;

    modsList = Mods.parseList();
    Mods.loadTopMod();

    bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    bg.color = 0xFF665AFF;
    bg.antialiasing = ClientPrefs.data.antialiasing;
    bg.screenCenter();
    add(bg);

    // Left panel — rounded rectangle background
    bgList = FlxSpriteUtil.drawRoundRect(new FlxSprite(40, 40).makeGraphic(340, 440, FlxColor.TRANSPARENT), 0, 0, 340, 440, 15, 15, FlxColor.BLACK);
    bgList.alpha = 0.6;

    modsGroup = new FlxTypedGroup();

    // startMod is passed via staticVar by reload() since tryOverride() strips constructor args
    var startMod:String = getStaticVar('modsMenu_startMod', null);
    setStaticVar('modsMenu_startMod', null); // consume it
    for (i in 0...modsList.all.length) {
        var mod:String = modsList.all[i];
        if (startMod == mod) curSelectedMod = i;
        var modItem = new ModItem(mod);
        if (modsList.disabled.contains(mod)) {
            modItem.icon.color = 0xFFFF6666;
            modItem.text.color = FlxColor.GRAY;
        }
        modsGroup.add(modItem);
    }

    var firstMod = modsGroup.members[curSelectedMod];
    if (firstMod != null) bg.color = firstMod.bgColor;

    // Buttons on the left panel
    var buttonX:Float  = bgList.x;
    var buttonWidth:Int  = Std.int(bgList.width);
    var buttonHeight:Int = 80;
    var buttonDaY:Int  = __isMobile ? 70 : 20;

    buttonReload = new MenuButton(buttonX, bgList.y + bgList.height + buttonDaY, buttonWidth, buttonHeight, Language.getPhrase('reload_button', 'RELOAD'), null, reload);
    add(buttonReload);

    buttonToggleMainY   = buttonReload.y + buttonReload.bg.height + 20;
    buttonToggleSecondY = buttonToggleMainY + buttonHeight + 20;
    buttonToggleHiddenY = FlxG.height + buttonHeight + 40;

    buttonEnableAll = new MenuButton(buttonX, buttonToggleMainY, buttonWidth, buttonHeight, Language.getPhrase('enable_all_button', 'ENABLE ALL'), null, function() {
        buttonEnableAll.ignoreCheck = false;
        setAllModsState(true);
        updateModDisplayData();
        checkToggleButtons();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
    });
    buttonEnableAll.bg.color  = FlxColor.GREEN;
    buttonEnableAll.focusChangeCallback = function(focus:Bool) if (!focus) buttonEnableAll.bg.color = FlxColor.GREEN;
    add(buttonEnableAll);

    buttonDisableAll = new MenuButton(buttonX, buttonToggleSecondY, buttonWidth, buttonHeight, Language.getPhrase('disable_all_button', 'DISABLE ALL'), null, function() {
        buttonDisableAll.ignoreCheck = false;
        setAllModsState(false);
        updateModDisplayData();
        checkToggleButtons();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
    });
    buttonDisableAll.bg.color = 0xFFFF6666;
    buttonDisableAll.focusChangeCallback = function(focus:Bool) if (!focus) buttonDisableAll.bg.color = 0xFFFF6666;
    add(buttonDisableAll);
    checkToggleButtons();

    // ---- No mods case -------------------------------------------------------
    if (modsList.all.length < 1) {
        buttonDisableAll.visible = buttonDisableAll.enabled = false;
        buttonEnableAll.visible = true;

        var myX:Float = bgList.x + bgList.width + 20;
        noModsTxt = new FlxText(myX, 0, FlxG.width - myX - 20, Language.getPhrase('no_mods_installed', 'NO MODS INSTALLED\nPRESS {1} TO EXIT OR INSTALL A MOD', [daButton]), 48);
        if (FlxG.random.bool(0.1)) noModsTxt.text += '\nBITCH.';
        noModsTxt.setFormat(Paths.font('phantom.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        noModsTxt.borderSize = 2;
        add(noModsTxt);
        noModsTxt.screenCenter(Y);

        var txt = new FlxText(bgList.x + 15, bgList.y + 15, bgList.width - 30, Language.getPhrase('no_mods_found', 'z found.'), 16);
        txt.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE);
        add(txt);

        FlxG.autoPause = false;
        changeSelectedMod(0);
        addTouchPad('NONE', 'B');
        return;
    }

    // ---- Right panel — mod info area ----------------------------------------
    bgTitle = FlxSpriteUtil.drawRoundRectComplex(
        new FlxSprite(bgList.x + bgList.width + 20, 40).makeGraphic(840, 180, FlxColor.TRANSPARENT),
        0, 0, 840, 180, 15, 15, 0, 0, FlxColor.BLACK);
    bgTitle.alpha = 0.6;
    add(bgTitle);

    icon = new FlxSprite(bgTitle.x + 15, bgTitle.y + 15);
    add(icon);

    modNameInitialY = icon.y + 80;
    modName = new Alphabet(icon.x + 165, modNameInitialY, '', true);
    modName.scaleY = 0.8;
    add(modName);

    bgDescription = FlxSpriteUtil.drawRoundRectComplex(
        new FlxSprite(bgTitle.x, bgTitle.y + 200).makeGraphic(840, 450, FlxColor.TRANSPARENT),
        0, 0, 840, 450, 0, 0, 15, 15, FlxColor.BLACK);
    bgDescription.alpha = 0.6;
    add(bgDescription);

    modDesc = new FlxText(bgDescription.x + 15, bgDescription.y + 15, bgDescription.width - 30, '', 24);
    modDesc.setFormat(Paths.font('phantom.ttf'), 24, FlxColor.WHITE, LEFT);
    add(modDesc);

    var myHeight:Int = 100;
    modRestartText = new FlxText(bgDescription.x + 15, bgDescription.y + bgDescription.height - myHeight - 25, bgDescription.width - 30,
        Language.getPhrase('mod_restart', '* Moving or Toggling On/Off this Mod will restart the game.'), 16);
    modRestartText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, RIGHT);
    add(modRestartText);

    bgButtons = FlxSpriteUtil.drawRoundRectComplex(
        new FlxSprite(bgDescription.x, bgDescription.y + bgDescription.height - myHeight).makeGraphic(840, myHeight, FlxColor.TRANSPARENT),
        0, 0, 840, myHeight, 0, 0, 15, 15, FlxColor.WHITE);
    bgButtons.color = FlxColor.BLACK;
    bgButtons.alpha = 0.2;
    add(bgButtons);

    // ---- Action buttons (move top/up/down, settings, toggle) ----------------
    var buttonsX:Float = bgButtons.x + 320;
    var buttonsY:Float = bgButtons.y + 10;

    var btn0 = new MenuButton(buttonsX,       buttonsY, 80, 80, null, Paths.image('modsMenuButtons'), function() moveModToPosition(0),                       54, 54);
    btn0.icon.animation.add('icon', [0]); btn0.icon.animation.play('icon', true);
    add(btn0); buttons.push(btn0);

    var btn1 = new MenuButton(buttonsX + 100,  buttonsY, 80, 80, null, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod - 1), 54, 54);
    btn1.icon.animation.add('icon', [1]); btn1.icon.animation.play('icon', true);
    add(btn1); buttons.push(btn1);

    var btn2 = new MenuButton(buttonsX + 200,  buttonsY, 80, 80, null, Paths.image('modsMenuButtons'), function() moveModToPosition(curSelectedMod + 1), 54, 54);
    btn2.icon.animation.add('icon', [2]); btn2.icon.animation.play('icon', true);
    add(btn2); buttons.push(btn2);

    if (modsList.all.length < 2) {
        for (b in buttons) b.enabled = false;
    }

    settingsButton = new MenuButton(buttonsX + 300, buttonsY, 80, 80, null, Paths.image('modsMenuButtons'), function() {
        var curMod = modsGroup.members[curSelectedMod];
        if (curMod != null && curMod.settings != null && curMod.settings.length > 0) {
            openSubState(new ModSettingsSubState(curMod.settings, curMod.folder, curMod.name));
        }
    }, 54, 54);
    settingsButton.icon.animation.add('icon', [3]); settingsButton.icon.animation.play('icon', true);
    add(settingsButton); buttons.push(settingsButton);

    var firstModForSettings = modsGroup.members[curSelectedMod];
    if (firstModForSettings == null || firstModForSettings.settings == null || firstModForSettings.settings.length < 1)
        settingsButton.enabled = false;

    var toggleBtn = new MenuButton(buttonsX + 400, buttonsY, 80, 80, null, Paths.image('modsMenuButtons'), function() {
        var curMod = modsGroup.members[curSelectedMod];
        var mod:String = curMod.folder;
        var wasDisabled:Bool = modsList.disabled.contains(mod);
        if (!wasDisabled) {
            modsList.enabled.remove(mod);
            modsList.disabled.push(mod);
        } else {
            modsList.disabled.remove(mod);
            modsList.enabled.push(mod);
        }
        var nowDisabled:Bool = modsList.disabled.contains(mod);
        curMod.icon.color = nowDisabled ? 0xFFFF6666 : FlxColor.WHITE;
        curMod.text.color = nowDisabled ? FlxColor.GRAY  : FlxColor.WHITE;
        if (curMod.mustRestart) waitingToRestart = true;
        updateModDisplayData();
        checkToggleButtons();
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
    }, 54, 54);
    toggleBtn.icon.animation.add('icon', [4]); toggleBtn.icon.animation.play('icon', true);
    add(toggleBtn); buttons.push(toggleBtn);
    toggleBtn.focusChangeCallback = function(focus:Bool) {
        if (!focus)
            toggleBtn.bg.color = modsList.enabled.contains(modsGroup.members[curSelectedMod].folder) ? FlxColor.GREEN : 0xFFFF6666;
    };

    // ---- Assemble list + items ----------------------------------------------
    add(bgList);
    add(modsGroup);
    _lastControllerMode = controls.controllerMode;

    changeSelectedMod(0);

    // Bottom bar
    var bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
    bottomBG.alpha = 0.6;
    add(bottomBG);

    var bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width,
        Language.getPhrase('mods_leave', 'Press {1} To Leave', [daButton]), 16);
    bottomText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, CENTER);
    bottomText.scrollFactor.set();
    add(bottomText);

    addTouchPad('UP_DOWN', 'B');
    touchPad.y -= 215;
    if (__isMobile) touchPad.alpha = 0.3;
}

// ---- update() --------------------------------------------------------------
function update(elapsed:Float) {
    if ((controls.BACK || (touchPad != null && touchPad.buttonB.justPressed)) && hoveringOnMods && !exiting) {
        exiting = true;
        saveTxt();

        var hasModStates:Bool = FileSystem.exists(Paths.modFolders('scripts/states/TitleState.hx'))
                             || FileSystem.exists(Paths.modFolders('scripts/states/FlashingState.hx'));
        FlxG.sound.play(Paths.sound('cancelMenu'));

        if (waitingToRestart || hasModStates) {
            TitleState.initialized = false;
            TitleState.closedState  = false;
            FlxG.sound.music.fadeOut(0.3);
            if (FreeplayState.vocals != null) {
                FreeplayState.vocals.fadeOut(0.3);
                FreeplayState.vocals = null;
            }
            FlxG.camera.fade(FlxColor.BLACK, 0.5, false, FlxG.resetGame, false);
        } else {
            MusicBeatState.switchState(new MainMenuState());
        }

        persistentUpdate = false;
        FlxG.autoPause = ClientPrefs.data.autoPause;
        Cursor.hide();
        return;
    }

    if (Math.abs(FlxG.mouse.deltaX) > 10 || Math.abs(FlxG.mouse.deltaY) > 10) {
        controls.controllerMode = false;
        if (!FlxG.mouse.visible) Cursor.show();
    }

    if (controls.controllerMode != _lastControllerMode) {
        if (controls.controllerMode) Cursor.hide();
        else Cursor.show();
    }
    _lastControllerMode = controls.controllerMode;

    if (controls.UI_DOWN_R || controls.UI_UP_R ||
        (touchPad != null && (touchPad.buttonDown.justReleased || touchPad.buttonUp.justReleased)))
        holdTime = 0;

    if (modsList.all.length > 0) {
        if (controls.controllerMode && holdingMod) {
            holdingMod = false;
            holdingElapsed = 0;
            updateItemPositions();
        }

        var lastMode:Bool = hoveringOnMods;
        if (modsList.all.length > 1) {
            if (!__isMobile && FlxG.mouse.justPressed) {
                for (i in (centerMod - 2)...(centerMod + 3)) {
                    var mod = modsGroup.members[i];
                    if (mod != null && mod.visible && FlxG.mouse.overlaps(mod)) {
                        hoveringOnMods = true;
                        var btn = getButton();
                        btn.ignoreCheck = btn.onFocus = false;
                        mouseOffsets.x = FlxG.mouse.x - mod.x;
                        mouseOffsets.y = FlxG.mouse.y - mod.y;
                        curSelectedMod = i;
                        changeSelectedMod(0);
                        break;
                    }
                }
                hoveringOnMods = true;
                var btn = getButton();
                btn.ignoreCheck = btn.onFocus = false;
                gottaClickAgain = false;
            }

            if (hoveringOnMods) {
                var shiftMult:Int = (FlxG.keys.pressed.SHIFT ||
                    FlxG.gamepads.anyPressed(FlxGamepadInputID.LEFT_SHOULDER) ||
                    FlxG.gamepads.anyPressed(FlxGamepadInputID.RIGHT_SHOULDER)) ? 4 : 1;

                if      (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed))  changeSelectedMod(shiftMult);
                else if (controls.UI_UP_P   || (touchPad != null && touchPad.buttonUp.justPressed))    changeSelectedMod(-shiftMult);
                else if (FlxG.mouse.wheel != 0) changeSelectedMod(-FlxG.mouse.wheel * shiftMult, true);
                else if (FlxG.keys.justPressed.HOME || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.LEFT_TRIGGER)) {
                    curSelectedMod = 0;
                    changeSelectedMod(0);
                } else if (FlxG.keys.justPressed.END || FlxG.gamepads.anyJustPressed(FlxGamepadInputID.RIGHT_TRIGGER)) {
                    curSelectedMod = modsList.all.length - 1;
                    changeSelectedMod(0);
                } else if (controls.UI_UP || controls.UI_DOWN ||
                           (touchPad != null && (touchPad.buttonUp.pressed || touchPad.buttonDown.pressed))) {
                    var lastHoldTime:Float = holdTime;
                    holdTime += elapsed;
                    if (holdTime > 0.5 && Math.floor(lastHoldTime * 8) != Math.floor(holdTime * 8)) {
                        var isUp:Bool = controls.UI_UP || (touchPad != null && touchPad.buttonUp.pressed);
                        changeSelectedMod(shiftMult * (isUp ? -1 : 1));
                    }
                } else if (FlxG.mouse.pressed && !__isMobile && !gottaClickAgain) {
                    var curMod = modsGroup.members[curSelectedMod];
                    if (curMod != null) {
                        if (!holdingMod && FlxG.mouse.justMoved && FlxG.mouse.overlaps(curMod)) holdingMod = true;
                        if (holdingMod) {
                            var moved:Bool = false;
                            for (i in (centerMod - 2)...(centerMod + 3)) {
                                var mod = modsGroup.members[i];
                                if (mod != null && mod.visible && FlxG.mouse.overlaps(mod) && curSelectedMod != i) {
                                    moveModToPosition(i);
                                    moved = true;
                                    break;
                                }
                            }
                            if (!moved) {
                                var factor:Float = -1;
                                if (FlxG.mouse.y < bgList.y)
                                    factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (bgList.y - FlxG.mouse.y) / 100)));
                                else if (FlxG.mouse.y > bgList.y + bgList.height)
                                    factor = Math.abs(Math.max(0.2, Math.min(0.5, 0.5 - (FlxG.mouse.y - bgList.y - bgList.height) / 100)));
                                if (factor >= 0) {
                                    holdingElapsed += elapsed;
                                    if (holdingElapsed >= factor) {
                                        holdingElapsed = 0;
                                        var newPos:Int = curSelectedMod + (FlxG.mouse.y < bgList.y ? -1 : 1);
                                        moveModToPosition(Std.int(Math.max(0, Math.min(modsGroup.length - 1, newPos))));
                                    }
                                }
                            }
                            curMod.x = FlxG.mouse.x - mouseOffsets.x;
                            curMod.y = FlxG.mouse.y - mouseOffsets.y;
                        }
                    }
                } else if (FlxG.mouse.justReleased && !__isMobile && holdingMod) {
                    holdingMod    = false;
                    holdingElapsed = 0;
                    updateItemPositions();
                }
            }
        }

        if (lastMode == hoveringOnMods) {
            if (hoveringOnMods) {
                if (controls.UI_RIGHT_P || controls.ACCEPT || (touchPad != null && touchPad.buttonB.justPressed)) {
                    hoveringOnMods = false;
                    var btn = getButton();
                    btn.ignoreCheck = btn.onFocus = false;
                    curSelectedButton = 0;
                    changeSelectedButton(0);
                }
            } else {
                if (controls.BACK || (touchPad != null && touchPad.buttonB.pressed && !hoveringOnMods)) {
                    hoveringOnMods = true;
                    var btn = getButton();
                    btn.ignoreCheck = btn.onFocus = false;
                    changeSelectedMod(0);
                } else if (controls.ACCEPT) {
                    var btn = getButton();
                    if (btn.onClick != null) btn.onClick();
                } else if (curSelectedButton < 0) {
                    if (controls.UI_UP_P || (touchPad != null && touchPad.buttonUp.justPressed)) {
                        if (curSelectedButton == -2) changeSelectedButton(1);
                        else { // -1 → go back to mod list top
                            curSelectedMod = 0;
                            hoveringOnMods = true;
                            var btn = getButton();
                            btn.ignoreCheck = btn.onFocus = false;
                            changeSelectedMod(0);
                        }
                    } else if (controls.UI_DOWN_P || (touchPad != null && touchPad.buttonDown.justPressed)) {
                        if (curSelectedButton == -2) changeSelectedButton(1);
                        else {
                            curSelectedMod = 0;
                            hoveringOnMods = true;
                            var btn = getButton();
                            btn.ignoreCheck = btn.onFocus = false;
                            changeSelectedMod(0);
                        }
                    } else if (controls.UI_RIGHT_P) {
                        var btn = getButton();
                        btn.ignoreCheck = btn.onFocus = false;
                        curSelectedButton = 0;
                        changeSelectedButton(0);
                    }
                } else {
                    if      (controls.UI_LEFT_P)  changeSelectedButton(-1);
                    else if (controls.UI_RIGHT_P) changeSelectedButton(1);
                }
            }
        }
    } else {
        // No mods — pulse animation
        noModsSine += 180 * elapsed;
        noModsTxt.alpha = 1 - Math.sin((Math.PI * noModsSine) / 180);

        nextAttempt -= elapsed;
        if (nextAttempt < 0) {
            nextAttempt = 1;
            @:privateAccess
            Mods.updateModList();
            modsList = Mods.parseList();
            if (modsList.all.length > 0) reload();
        }
    }
}

// ---- Helper functions ------------------------------------------------------

function getButton() {
    switch (curSelectedButton) {
        case -2: return buttonReload;
        case -1: return buttonEnableAll.enabled ? buttonEnableAll : buttonDisableAll;
    }
    if (modsList.all.length < 1) return buttonReload;
    return buttons[Std.int(Math.max(0, Math.min(buttons.length - 1, curSelectedButton)))];
}

function changeSelectedButton(add:Int = 0) {
    var btn = getButton();
    btn.ignoreCheck = btn.onFocus = false;

    curSelectedButton += add;
    if      (curSelectedButton < -2)           curSelectedButton = -2;
    else if (curSelectedButton > buttons.length - 1) curSelectedButton = buttons.length - 1;

    var btn = getButton();
    btn.ignoreCheck = btn.onFocus = true;

    var curMod = modsGroup.members[curSelectedMod];
    if (curMod != null) curMod.selectBg.visible = false;

    if (curSelectedButton < 0) {
        bgButtons.color = FlxColor.BLACK;
        bgButtons.alpha = 0.2;
    } else {
        bgButtons.color = FlxColor.WHITE;
        bgButtons.alpha = 0.8;
    }
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
}

function changeSelectedMod(add:Int = 0, isMouseWheel:Bool = false) {
    var max:Int = modsList.all.length - 1;
    if (max < 0) return;

    if (hoveringOnMods) {
        var btn = getButton();
        btn.ignoreCheck = btn.onFocus = false;
    }

    var lastSelected:Int = curSelectedMod;
    curSelectedMod += add;

    var limited:Bool = false;
    if (curSelectedMod < 0)   { curSelectedMod = 0;   limited = true; }
    else if (curSelectedMod > max) { curSelectedMod = max; limited = true; }

    if (!__isMobile && !isMouseWheel && limited && Math.abs(add) == 1) {
        curSelectedMod = lastSelected;
        hoveringOnMods  = false;
        curSelectedButton = (add < 0) ? -1 : -2;
        changeSelectedButton(0);
        return;
    }

    holdingMod    = false;
    holdingElapsed = 0;
    gottaClickAgain = true;
    updateModDisplayData();
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);

    if (hoveringOnMods) {
        var curMod = modsGroup.members[curSelectedMod];
        if (curMod != null) curMod.selectBg.visible = true;
        bgButtons.color = FlxColor.BLACK;
        bgButtons.alpha = 0.2;
    }
}

function updateModDisplayData() {
    var curMod = modsGroup.members[curSelectedMod];
    if (curMod == null) return;

    FlxTween.cancelTweensOf(bg);
    FlxTween.color(bg, 1, bg.color, curMod.bgColor);

    if (Math.abs(centerMod - curSelectedMod) > 2) {
        centerMod = (centerMod < curSelectedMod) ? curSelectedMod - 2 : curSelectedMod + 2;
    }
    updateItemPositions();

    icon.loadGraphic(curMod.icon.graphic, true, 150, 150);
    icon.antialiasing = curMod.icon.antialiasing;

    if (curMod.totalFrames > 0) {
        icon.animation.add('icon', [for (i in 0...curMod.totalFrames) i], curMod.iconFps);
        icon.animation.play('icon');
        icon.animation.curAnim.curFrame = curMod.icon.animation.curAnim.curFrame;
    }

    if (modName.scaleX != 0.8) modName.setScale(0.8);
    modName.text   = curMod.name;
    var newScale:Float = Math.min(620 / (modName.width / 0.8), 0.8);
    modName.setScale(newScale, Math.min(newScale * 1.35, 0.8));
    modName.y = modNameInitialY - (modName.height / 2);

    modRestartText.visible = curMod.mustRestart;
    modDesc.text           = curMod.desc;

    for (b in buttons) if (b.focusChangeCallback != null) b.focusChangeCallback(b.onFocus);
    settingsButton.enabled = (curMod.settings != null && curMod.settings.length > 0);
}

function updateItemPositions() {
    var maxVisible:Int = Std.int(Math.max(4, centerMod + 2));
    var minVisible:Int = Std.int(Math.max(0, centerMod - 2));
    var baseX:Float = bgList.x + 5;
    var baseY:Float = bgList.y + 5;
    for (i in 0...modsGroup.members.length) {
        var mod = modsGroup.members[i];
        if (mod == null) continue;
        mod.visible = (i >= minVisible && i <= maxVisible);
        mod.x = baseX;
        mod.y = baseY + 86 * (i - centerMod + 2);
        mod.alpha = (i == curSelectedMod) ? 1.0 : 0.6;
        mod.selectBg.visible = (i == curSelectedMod && hoveringOnMods);
    }
}

function moveModToPosition(?position:Int = 0) {
    if (position >= modsList.all.length) position = 0;
    else if (position < 0) position = modsList.all.length - 1;

    var mod:String  = modsList.all[curSelectedMod];
    var id:Int      = modsList.all.indexOf(mod);
    if (position == id) return;

    var curMod = modsGroup.members[id];
    if (curMod == null) return;

    if (curMod.mustRestart || modsGroup.members[position].mustRestart) waitingToRestart = true;

    modsGroup.remove(curMod, true);
    modsList.all.remove(mod);
    modsGroup.insert(position, curMod);
    modsList.all.insert(position, mod);

    curSelectedMod = position;
    updateModDisplayData();
    updateItemPositions();

    if (!hoveringOnMods) {
        var cm = modsGroup.members[curSelectedMod];
        if (cm != null) cm.selectBg.visible = false;
    }
    FlxG.sound.play(Paths.sound('scrollMenu'), 0.6);
}

function checkToggleButtons() {
    var hasDisabled:Bool = modsList.disabled.length > 0;
    var hasEnabled:Bool  = modsList.enabled.length  > 0;
    var showEnable:Bool  = hasDisabled;
    var showDisable:Bool = !showEnable && hasEnabled;

    buttonEnableAll.visible  = true;
    buttonDisableAll.visible = true;
    buttonEnableAll.alpha    = 1;
    buttonDisableAll.alpha   = 1;

    buttonEnableAll.enabled  = buttonEnableAll.active  = showEnable;
    buttonDisableAll.enabled = buttonDisableAll.active = showDisable;

    if (!buttonEnableAll.enabled)  { buttonEnableAll.ignoreCheck  = false; buttonEnableAll.onFocus  = false; }
    if (!buttonDisableAll.enabled) { buttonDisableAll.ignoreCheck = false; buttonDisableAll.onFocus = false; }

    animateToggleButtons(showEnable, !toggleButtonsInitialized);
    toggleButtonsInitialized = true;
}

function animateToggleButtons(showEnableAll:Bool, instant:Bool = false) {
    var duration:Float = instant ? 0 : 0.2;
    var enableTargetY:Float  = showEnableAll ? buttonToggleMainY   : buttonToggleHiddenY;
    var disableTargetY:Float = showEnableAll ? buttonToggleHiddenY : buttonToggleMainY;

    FlxTween.cancelTweensOf(buttonEnableAll);
    FlxTween.cancelTweensOf(buttonDisableAll);

    if (instant) {
        buttonEnableAll.y  = enableTargetY;
        buttonDisableAll.y = disableTargetY;
    } else {
        FlxTween.tween(buttonEnableAll,  {y: enableTargetY},  duration, {ease: FlxEase.quadOut});
        FlxTween.tween(buttonDisableAll, {y: disableTargetY}, duration, {ease: FlxEase.quadOut});
    }
}

function setAllModsState(enableAll:Bool) {
    modsList.enabled  = [];
    modsList.disabled = [];
    for (mod in modsGroup.members) {
        if (mod == null || mod.folder == null || mod.folder.trim().length < 1) continue;
        if (enableAll) modsList.enabled.push(mod.folder);
        else           modsList.disabled.push(mod.folder);
    }
    syncAllModVisualStates();
}

function syncAllModVisualStates() {
    for (mod in modsGroup.members) {
        if (mod == null) continue;
        var isDisabled:Bool = modsList.disabled.contains(mod.folder);
        mod.icon.color = isDisabled ? 0xFFFF6666 : FlxColor.WHITE;
        mod.text.color = isDisabled ? FlxColor.GRAY  : FlxColor.WHITE;
    }
}

function reload() {
    saveTxt();
    FlxG.autoPause = ClientPrefs.data.autoPause;
    FlxTransitionableState.skipNextTransIn  = true;
    FlxTransitionableState.skipNextTransOut = true;
    var curMod = modsGroup.members[curSelectedMod];
    // Store startMod so create() can pick it up after tryOverride() strips constructor args
    setStaticVar('modsMenu_startMod', curMod != null ? curMod.folder : null);
    MusicBeatState.switchState(new ModsMenuState(curMod != null ? curMod.folder : null));
}

function saveTxt() {
    var fileStr:String = '';
    for (mod in modsList.all) {
        if (mod.trim().length < 1) continue;
        if (fileStr.length > 0) fileStr += '\n';
        fileStr += mod + '|' + (modsList.disabled.contains(mod) ? '0' : '1');
    }

    #if android
    StorageUtil.saveContent('modsList.txt', fileStr, false);
    #else
    var path:String = Sys.getCwd() + 'modsList.txt';
    try { File.saveContent(path, fileStr); }
    catch (e:Dynamic) {}
    #end

    Mods.parseList();
    Mods.loadTopMod();
}

function destroy() {
    mouseOffsets = null;
}
