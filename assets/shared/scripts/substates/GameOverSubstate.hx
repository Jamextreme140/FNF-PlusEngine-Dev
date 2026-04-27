// Companion script for GameOverSubstate.
// This script runs ALONGSIDE the hardcoded GameOverSubstate (not as a replacement).
// `game` here refers to the GameOverSubstate instance.
//
// Available variables injected by the companion system:
//   game         - the GameOverSubstate instance
//   parentState  - the PlayState that opened this substate
//   add(obj)     - shortcut for game.add(obj)
//   remove(obj)  - shortcut for game.remove(obj)
//   close()      - close this substate
//   FlxG, Paths, ClientPrefs, controls, etc.
//
// Useful properties exposed on GameOverSubstate:
//   game.boyfriend       - the dead boyfriend character sprite
//   game.characterName   - the character name string
//   game.loopSoundName   - name of the audio that loops on game-over
//   game.deathDelay      - how long before the death animation starts
//   game.isEnding        - true while the "game over" end sequence is playing
//
// Uncomment and fill in the functions you want to use.

/*
function onCreate() {
    // Called after the hardcoded substate's create() runs.
    // Great for adding overlay sprites or custom death screen effects.
}

function onUpdate(elapsed:Float) {
    // Called every frame.
    // You can check game.isEnding to know if the retry sequence started.
}

function onDestroy() {
    // Called right before the substate is destroyed.
}

function onBeatHit(curBeat:Int) {
    // Called on every beat during the game-over screen.
}
*/
