// _statePreset.hx — Shared preset injected before every state script by ScriptableState.
//
// This file runs in the SAME interpreter as the state script, so everything
// defined here is directly available without any import or prefix.
//
// ─── How it works ──────────────────────────────────────────────────────────────
//
//   ScriptableState calls HScript.executeFile("…/_statePreset.hx") BEFORE
//   running your state script.  Any var / function you define here is visible
//   to the state script as a plain variable or function.
//
//   Mods can supply their own preset at:
//     mods/{yourMod}/scripts/states/_statePreset.hx
//   The engine's copy (this file) is used when no mod override exists.
//
// ─── Injected by ScriptableState (always available, no need to redeclare) ──────
//   game            — ScriptableState instance (the host FlxState)
//   add / remove    — FlxState.add/remove shortcuts
//   insert          — FlxState.insert
//   openSubState    — FlxState.openSubState
//   stateName       — name of the current state (e.g. "TitleState")
//   controls        — Controls.instance
//   FlxG, FlxSprite, FlxText, FlxColor, FlxTween, FlxTimer, FlxMath, FlxEase …
//   Paths, ClientPrefs, Conductor, MusicBeatState, Language, Mods …
//   (and every class registered in HScript.preset())
//
// ─── Extra helpers defined below ───────────────────────────────────────────────

// Shorter aliases for the most-used transition helpers.
function switchState(newState:Dynamic) {
    MusicBeatState.switchState(newState);
}

function resetState() {
    MusicBeatState.resetState();
}

// randomObject: picks a random element from an array (wraps FlxG.random.int).
function randomObject(arr:Array<Dynamic>):Dynamic {
    if (arr == null || arr.length == 0) return null;
    return arr[FlxG.random.int(0, arr.length - 1)];
}

// Handy wrappers so scripts can write `playSound(...)` instead of `FlxG.sound.play(...)`.
function playSound(key:String, ?vol:Float = 1.0):Dynamic {
    return FlxG.sound.play(Paths.sound(key), vol);
}
function playMusic(key:String, ?vol:Float = 0.7):Void {
    FlxG.sound.playMusic(Paths.music(key), vol, true);
}

// Screen-center helpers.
function screenCenterX(spr:Dynamic):Void { spr.screenCenter(X); }
function screenCenterY(spr:Dynamic):Void { spr.screenCenter(Y); }
function screenCenter(spr:Dynamic):Void  { spr.screenCenter();  }

// Simple anti-aliasing helper that respects the user preference.
function setAA(spr:Dynamic):Void {
    spr.antialiasing = ClientPrefs.data.antialiasing;
}

// Load a graphic respecting antialiasing preference in one call.
function makeSprite(?x:Float = 0, ?y:Float = 0, ?imagePath:String = null):Dynamic {
    var spr = new FlxSprite(x, y);
    if (imagePath != null) spr.loadGraphic(Paths.image(imagePath));
    spr.antialiasing = ClientPrefs.data.antialiasing;
    return spr;
}

// Touch-pad shortcuts exposed on the state.
function addTouchPad(dirs:String, actions:String):Void { game.addTouchPad(dirs, actions); }
function removeTouchPad():Void                         { game.removeTouchPad(); }
function addTouchPadCamera(?top:Bool = false):Void     { game.addTouchPadCamera(top); }

// Shared variable helpers (already injected by ScriptableState, these are just
// aliases so scripts can write the shorter names).
// setSharedVar / getSharedVar / hasSharedVar / removeSharedVar are already available.

// Beat / step helpers (read-only mirrors of the host state fields).
function getCurBeat():Int    return game.curBeat;
function getCurStep():Int    return game.curStep;
function getCurSection():Int return game.curSection;

// persistentUpdate / persistentDraw as readable/writable helpers.
function getPersistentUpdate():Bool       return game.persistentUpdate;
function setPersistentUpdate(v:Bool):Bool { game.persistentUpdate = v; return v; }
function getPersistentDraw():Bool         return game.persistentDraw;
function setPersistentDraw(v:Bool):Bool   { game.persistentDraw   = v; return v; }
