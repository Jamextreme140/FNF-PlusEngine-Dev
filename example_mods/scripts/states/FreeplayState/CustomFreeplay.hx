// Example FreeplayState Script
// Shows how to customize the freeplay menu

var customDifficulty:String = "Hard";
var customBG:FlxSprite = null;

function onCreate() {
    trace("FreeplayState custom script loaded!");
    
    // Add a custom background overlay
    customBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
    customBG.alpha = 0.3;
    state.insert(0, customBG);
    
    // Add custom info text
    var infoText = new FlxText(10, FlxG.height - 30, 0, "Press TAB for custom features!", 12);
    infoText.setFormat(null, 12, FlxColor.YELLOW, LEFT, OUTLINE, FlxColor.BLACK);
    state.add(infoText);
    setVar("infoText", infoText);
}

function onUpdate(elapsed:Float) {
    // Custom controls
    if (keyboardJustPressed("TAB")) {
        trace("TAB pressed in Freeplay!");
        // Toggle custom difficulty
        customDifficulty = (customDifficulty == "Hard") ? "Easy" : "Hard";
        trace("Custom difficulty set to: " + customDifficulty);
    }
    
    // Animate background
    if (customBG != null) {
        customBG.alpha = 0.2 + Math.sin(FlxG.game.ticks / 1000) * 0.1;
    }
}

function onBeatHit() {
    // Make info text bounce on beat
    var infoText = getVar("infoText");
    if (infoText != null) {
        FlxTween.cancelTweensOf(infoText.scale);
        infoText.scale.set(1.2, 1.2);
        FlxTween.tween(infoText.scale, {x: 1, y: 1}, 0.3, {ease: FlxEase.quadOut});
    }
}

function onDestroy() {
    trace("FreeplayState custom script destroyed");
}
