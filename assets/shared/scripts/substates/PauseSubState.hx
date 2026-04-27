// Companion script for PauseSubState.
// This script runs ALONGSIDE the hardcoded PauseSubState (not as a replacement).
// `game` here refers to the PauseSubState instance.
//
// Available variables injected by the companion system:
//   game         - the PauseSubState instance
//   parentState  - the PlayState that opened this substate
//   add(obj)     - shortcut for game.add(obj)
//   remove(obj)  - shortcut for game.remove(obj)
//   close()      - close this substate
//   FlxG, Paths, ClientPrefs, controls, etc.
//
// Useful properties exposed on PauseSubState:
//   game.grpMenuShit   - FlxTypedGroup of Alphabet menu items
//   game.menuItems     - Array<String> of menu option names
//   game.curSelected   - currently selected index
//   game.pauseMusic    - the FlxSound playing pause music
//
// Uncomment and fill in the functions you want to use.

/*
function onCreate() {
    // Called after the hardcoded substate's create() runs.
    // Add custom sprites, text, or override visuals here.
}

function onUpdate(elapsed:Float) {
    // Called every frame after the hardcoded substate's update().
}

function onDestroy() {
    // Called right before the substate is destroyed.
}

function onBeatHit(curBeat:Int) {
    // Called on every beat while paused.
}
*/
