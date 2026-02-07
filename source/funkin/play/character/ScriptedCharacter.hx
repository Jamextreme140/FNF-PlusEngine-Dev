package funkin.play.character;

import funkin.play.character.Character;

/**
 * Scripted Character - Allows mods to create custom character classes in scripts.
 * 
 * Usage:
 * 1. Register the script: registerScriptClass('mods/mymod/scripts/MyCharacter.hx')
 * 2. List available: ScriptedCharacter.listScriptClasses()
 * 3. Create instance: ScriptedCharacter.init('MyCharacter', x, y, character)
 * 
 * Example script (scripts/MyCharacter.hx):
 * ```haxe
 * import funkin.play.character.Character;
 * 
 * class MyCharacter extends Character {
 *     public function new(x:Float, y:Float, character:String) {
 *         super(x, y, character);
 *         this.alpha = 0.8;
 *     }
 *     
 *     override function update(elapsed:Float) {
 *         super.update(elapsed);
 *         // Custom behavior
 *         this.angle = Math.sin(Conductor.songPosition / 500) * 5;
 *     }
 * }
 * ```
 */
@:hscriptClass
class ScriptedCharacter extends Character implements crowplexus.iris.scripted.HScriptedClass {}
