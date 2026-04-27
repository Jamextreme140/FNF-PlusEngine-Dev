// Default engine implementation of ResultsState -- loaded by ScriptableState.
// NOTE: ResultsState receives a `params` object from PlayState with all score data.
// Because ScriptableState creates states fresh, the engine passes the data via
// ResultsState.pendingParams before switching states.
// Mods can override by placing their own at:  mods/{yourMod}/scripts/states/ResultsState.hx

var menuBG;
var backdropImage;
var flxGroupImage;
var scoreText;
var flawlesssText;
var sicksText;
var goodsText;
var badsText;
var shitsText;
var missesText;
var comboText;
var accText;

var params:Dynamic = null;
var animatedScore:Int = 0;
var animatedFlawlesss:Int = 0;
var animatedSicks:Int = 0;
var animatedGoods:Int = 0;
var animatedBads:Int = 0;
var animatedShits:Int = 0;
var animatedMisses:Int = 0;
var animatedCombo:Int = 0;
var animatedAccuracy:Float = 0;

function create() {
    // Retrieve params passed from PlayState (via static field)
    params = ResultsState.pendingParams;
    if (params == null) params = {};

    menuBG = new FlxSprite().loadGraphic(Paths.image('menuBG'));
    menuBG.setGraphicSize(FlxG.width, FlxG.height);
    menuBG.updateHitbox();
    add(menuBG);

    backdropImage = new FlxSprite();
    if (Paths.fileExists('images/ui/results/backdrop.png', IMAGE))
        backdropImage.loadGraphic(Paths.image('ui/results/backdrop'));
    else
        backdropImage.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    backdropImage.setGraphicSize(FlxG.width, FlxG.height);
    backdropImage.updateHitbox();
    backdropImage.alpha = 0.8;
    add(backdropImage);

    if (!FlxG.sound.music.playing)
        FlxG.sound.playMusic(Paths.music('freakyMenu'), 0.7, true);

    var infoWidth:Int = 700;
    var songAndDiff:String = '${params.songName != null ? params.songName : "???"} [${params.difficulty != null ? params.difficulty : "???"}]';
    var modOrGame:String = (params.isMod != null && params.isMod && params.modFolder != null && params.modFolder != '')
        ? params.modFolder : "Friday Night Funkin'";

    var resultsLabel = new FlxText(500, 12, infoWidth, Language.getPhrase('results_title', 'Results'), 60);
    resultsLabel.setFormat(Paths.font('aller.ttf'), 60, FlxColor.WHITE, RIGHT);
    add(resultsLabel);

    var topText = new FlxText(10, 5, infoWidth, songAndDiff, 28);
    topText.setFormat(Paths.font('aller.ttf'), 28, FlxColor.WHITE, LEFT);
    add(topText);

    var modText = new FlxText(10, 39, infoWidth, modOrGame, 22);
    modText.setFormat(Paths.font('aller.ttf'), 22, FlxColor.WHITE, LEFT);
    add(modText);

    var scoreY:Int = 130;
    var scoreLabel = new FlxText(60, scoreY, 400, Language.getPhrase('results_score', 'Score') + ':', 34);
    scoreLabel.setFormat(Paths.font('aller.ttf'), 34, FlxColor.WHITE, LEFT);
    add(scoreLabel);

    scoreText = new FlxText(240, scoreY - 10, 400, StringTools.lpad('0', '0', 8), 44);
    scoreText.setFormat(Paths.font('aller.ttf'), 44, FlxColor.WHITE, LEFT);
    add(scoreText);

    var leftX:Int = 30;
    var rightX:Int = 300;
    var judgY:Int = 235;
    var spc:Int = 90;

    flawlesssText = new FlxText(leftX, judgY,         340, Language.getPhrase('judgement_flawlesss', 'Flawlesss') + ': 0', 32);
    flawlesssText.setFormat(Paths.font('aller.ttf'), 32, 0xFFA17FFF, LEFT);
    add(flawlesssText);

    sicksText     = new FlxText(rightX, judgY,         340, Language.getPhrase('judgement_sicks', 'Sicks') + ': 0',     32);
    sicksText.setFormat(Paths.font('aller.ttf'), 32, 0xFF7FC9FF, LEFT);
    add(sicksText);

    goodsText     = new FlxText(leftX,  judgY + spc,  340, Language.getPhrase('judgement_goods', 'Goods') + ': 0',     32);
    goodsText.setFormat(Paths.font('aller.ttf'), 32, 0xFF7FFF8E, LEFT);
    add(goodsText);

    badsText      = new FlxText(rightX, judgY + spc,  340, Language.getPhrase('judgement_bads', 'Bads') + ': 0',      32);
    badsText.setFormat(Paths.font('aller.ttf'), 32, 0xFF888888, LEFT);
    add(badsText);

    shitsText     = new FlxText(leftX,  judgY + spc * 2, 340, Language.getPhrase('judgement_shits', 'Shits') + ': 0', 32);
    shitsText.setFormat(Paths.font('aller.ttf'), 32, 0xFFFF7F7F, LEFT);
    add(shitsText);

    missesText    = new FlxText(rightX, judgY + spc * 2, 340, Language.getPhrase('judgement_misses', 'Misses') + ': 0', 32);
    missesText.setFormat(Paths.font('aller.ttf'), 32, FlxColor.RED, LEFT);
    add(missesText);

    comboText = new FlxText(leftX, judgY + spc * 3 - 14, 700, Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': 0', 32);
    comboText.setFormat(Paths.font('aller.ttf'), 32, FlxColor.WHITE, LEFT);
    add(comboText);

    accText = new FlxText(leftX, judgY + spc * 3 + 20, 700, Language.getPhrase('results_accuracy', 'Accuracy') + ': 0%', 32);
    accText.setFormat(Paths.font('aller.ttf'), 32, FlxColor.WHITE, LEFT);
    add(accText);

    if (params.isPractice != null && params.isPractice) {
        var practiceText = new FlxText(0, FlxG.height - 138, FlxG.width,
            Language.getPhrase('results_practice_mode', 'Played in practice mode'), 22);
        practiceText.setFormat(Paths.font('aller.ttf'), 22, FlxColor.YELLOW, CENTER);
        add(practiceText);
    }

    var engineInfo:String = Language.getPhrase('psych_engine_version', 'Psych Engine v')
        + MainMenuState.psychEngineVersion + '\n'
        + Language.getPhrase('fnf_version', "Friday Night Funkin' v") + '0.2.8';
    var engineText = new FlxText(0, FlxG.height - 100, FlxG.width, engineInfo, 25);
    engineText.setFormat(Paths.font('aller.ttf'), 25, FlxColor.CYAN, CENTER);
    add(engineText);

    var continueText = new FlxText(50, FlxG.height - 75, 0,
        Language.getPhrase('results_press_enter', 'Press Enter\nto Continue'), 26);
    continueText.setFormat(Paths.font('aller.ttf'), 26, FlxColor.WHITE, CENTER);
    add(continueText);
}

function update(elapsed:Float) {
    var p:Dynamic = params;
    var score:Int    = p.score    != null ? p.score    : 0;
    var flawlesss:Int = p.flawlesss != null ? p.flawlesss : 0;
    var sicks:Int    = p.sicks    != null ? p.sicks    : 0;
    var goods:Int    = p.goods    != null ? p.goods    : 0;
    var bads:Int     = p.bads     != null ? p.bads     : 0;
    var shits:Int    = p.shits    != null ? p.shits    : 0;
    var misses:Int   = p.misses   != null ? p.misses   : 0;
    var maxCombo:Int = p.maxCombo != null ? p.maxCombo : 0;
    var accuracy:Float = p.accuracy != null ? p.accuracy : 0.0;

    if (animatedScore < score) {
        animatedScore += Math.ceil((score - animatedScore) * 0.2 + 1);
        if (animatedScore > score) animatedScore = score;
        scoreText.text = StringTools.lpad(Std.string(animatedScore), '0', 8);
        return;
    }
    scoreText.text = StringTools.lpad(Std.string(animatedScore), '0', 8);

    if (animatedFlawlesss < flawlesss) {
        animatedFlawlesss += Math.ceil((flawlesss - animatedFlawlesss) * 0.2 + 1);
        if (animatedFlawlesss > flawlesss) animatedFlawlesss = flawlesss;
        flawlesssText.text = Language.getPhrase('judgement_flawlesss', 'Flawlesss') + ': $animatedFlawlesss';
        return;
    }
    flawlesssText.text = Language.getPhrase('judgement_flawlesss', 'Flawlesss') + ': $animatedFlawlesss';

    if (animatedSicks < sicks) {
        animatedSicks += Math.ceil((sicks - animatedSicks) * 0.2 + 1);
        if (animatedSicks > sicks) animatedSicks = sicks;
        sicksText.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';
        return;
    }
    sicksText.text = Language.getPhrase('judgement_sicks', 'Sicks') + ': $animatedSicks';

    if (animatedGoods < goods) {
        animatedGoods += Math.ceil((goods - animatedGoods) * 0.2 + 1);
        if (animatedGoods > goods) animatedGoods = goods;
        goodsText.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';
        return;
    }
    goodsText.text = Language.getPhrase('judgement_goods', 'Goods') + ': $animatedGoods';

    if (animatedBads < bads) {
        animatedBads += Math.ceil((bads - animatedBads) * 0.2 + 1);
        if (animatedBads > bads) animatedBads = bads;
        badsText.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';
        return;
    }
    badsText.text = Language.getPhrase('judgement_bads', 'Bads') + ': $animatedBads';

    if (animatedShits < shits) {
        animatedShits += Math.ceil((shits - animatedShits) * 0.2 + 1);
        if (animatedShits > shits) animatedShits = shits;
        shitsText.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';
        return;
    }
    shitsText.text = Language.getPhrase('judgement_shits', 'Shits') + ': $animatedShits';

    if (animatedMisses < misses) {
        animatedMisses += Math.ceil((misses - animatedMisses) * 0.2 + 1);
        if (animatedMisses > misses) animatedMisses = misses;
        missesText.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';
        return;
    }
    missesText.text = Language.getPhrase('judgement_misses', 'Misses') + ': $animatedMisses';

    if (animatedCombo < maxCombo) {
        animatedCombo += Math.ceil((maxCombo - animatedCombo) * 0.2 + 1);
        if (animatedCombo > maxCombo) animatedCombo = maxCombo;
        comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';
        return;
    }
    comboText.text = Language.getPhrase('judgement_max_combo', 'Highest Combo') + ': $animatedCombo';

    if (animatedAccuracy < accuracy) {
        animatedAccuracy += (accuracy - animatedAccuracy) * 0.2 + 0.1;
        if (animatedAccuracy > accuracy) animatedAccuracy = accuracy;
        accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': '
            + Std.string(Math.round(animatedAccuracy * 1000) / 10) + '%';
        return;
    }
    accText.text = Language.getPhrase('results_accuracy', 'Accuracy') + ': '
        + Std.string(Math.round(animatedAccuracy * 1000) / 10) + '%';

    if (controls.ACCEPT || FlxG.keys.justPressed.ENTER) {
        Mods.currentModDirectory = '';
        if (p.isWeek != null && p.isWeek) MusicBeatState.switchState(new StoryMenuState());
        else MusicBeatState.switchState(new FreeplayState());
    }
}
