// Example State Script for MainMenuState
// This script demonstrates how to add custom functionality to the main menu

function onCreate() {
    trace("MainMenuState script loaded!");
    
    // You can create custom sprites/text
    var myText = new FlxText(10, 10, 0, "Custom State Script Active", 16);
    myText.setFormat(null, 16, FlxColor.WHITE, LEFT, OUTLINE, FlxColor.BLACK);
    FlxG.state.add(myText);
    
    // Store reference for later use
    setVar("customText", myText);
}

function onUpdate(elapsed:Float) {
    // Access stored variables
    var myText = getVar("customText");
    if (myText != null) {
        // Make text pulse
        myText.alpha = 0.5 + Math.sin(FlxG.game.ticks / 500) * 0.5;
    }
    
    // Custom keyboard shortcuts
    if (keyboardJustPressed("F1")) {
        trace("F1 pressed in MainMenuState!");
        // Do something
    }
}

function onBeatHit() {
    // This only works if music is playing with BPM sync
    trace("Beat hit in MainMenuState! Beat: " + curBeat);
}

function onDestroy() {
    trace("MainMenuState script destroyed!");
    // Cleanup if needed
}
