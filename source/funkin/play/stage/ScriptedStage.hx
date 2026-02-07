package funkin.play.stage;

import funkin.play.stage.BaseStage;

/**
 * Scripted Stage - Allows mods to create custom stage classes in scripts.
 * 
 * Usage:
 * 1. Register the script: registerScriptClass('mods/mymod/scripts/MyStage.hx')
 * 2. List available: ScriptedStage.listScriptClasses()
 * 3. Create instance: ScriptedStage.init('MyStage', stageId)
 * 
 * Example script (scripts/MyStage.hx):
 * ```haxe
 * import funkin.play.stage.BaseStage;
 * import flixel.FlxSprite;
 * 
 * class MyStage extends BaseStage {
 *     var background:FlxSprite;
 *     var foreground:FlxSprite;
 *     
 *     public function new(stageId:String) {
 *         super(stageId);
 *     }
 *     
 *     override function onCreate(event) {
 *         super.onCreate(event);
 *         
 *         background = new FlxSprite(0, 0);
 *         background.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLUE);
 *         add(background);
 *         
 *         foreground = new FlxSprite(0, 0);
 *         foreground.loadGraphic(Paths.image('myStage/foreground'));
 *         add(foreground);
 *     }
 *     
 *     override function update(elapsed:Float) {
 *         super.update(elapsed);
 *         // Animate background
 *         background.alpha = 0.5 + Math.sin(Conductor.songPosition / 1000) * 0.3;
 *     }
 * }
 * ```
 */
@:hscriptClass
class ScriptedStage extends BaseStage implements crowplexus.iris.scripted.HScriptedClass {}
