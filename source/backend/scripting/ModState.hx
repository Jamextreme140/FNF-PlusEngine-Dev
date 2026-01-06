package backend.scripting;

import backend.MusicBeatState;
import backend.Paths;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
#end

#if sys
import sys.FileSystem;
#end

/**
 * ModState - State completamente controlado por script
 * Inspirado en el sistema de Codename Engine
 * 
 * Uso:
 *   FlxG.switchState(new ModState("CustomMenuState"));
 *   // Busca el script en: mods/yourmod/data/states/CustomMenuState.hx
 * 
 * El script tendrá acceso a:
 *   - this: El state actual
 *   - add(obj): Agregar objetos al state
 *   - remove(obj): Remover objetos del state
 *   - insert(pos, obj): Insertar en posición específica
 *   - All FlxG functions
 * 
 * Ejemplo de script (data/states/CustomMenuState.hx):
 * 
 *   var bg:FlxSprite;
 *   var menuItems:Array<String> = ['Play', 'Options', 'Exit'];
 *   
 *   function onCreate() {
 *       trace('Custom menu loading...');
 *   }
 *   
 *   function create() {
 *       bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
 *       this.add(bg);
 *       
 *       for (i in 0...menuItems.length) {
 *           var text = new FlxText(0, 100 + (i * 50), 0, menuItems[i]);
 *           text.setFormat(Paths.font('vcr.ttf'), 32);
 *           text.screenCenter(X);
 *           this.add(text);
 *       }
 *   }
 *   
 *   function update(elapsed:Float) {
 *       if (FlxG.keys.justPressed.ESCAPE) {
 *           FlxG.switchState(new MainMenuState());
 *       }
 *   }
 */
class ModState extends MusicBeatState {
    
    /**
     * Name of the last loaded HScript file
     */
    public static var lastName:String = null;
    
    /**
     * Last optional data passed between states
     */
    public static var lastData:Dynamic = null;
    
    /**
     * Optional extra data accessible in the script
     */
    public var data:Dynamic = null;

    #if HSCRIPT_ALLOWED
    /** Internal HScript instance for this state */
    var hscript:HScript = null;
    #end
    
    /**
     * Constructor
     * @param _stateName Name of the script file in data/states/ (without extension)
     * @param _data Optional dynamic data to pass to the script (accessible as 'data' variable)
     */
    public function new(_stateName:String, ?_data:Dynamic) {
        // Update static variables
        if(_stateName != null && _stateName != lastName) {
            lastName = _stateName;
            lastData = null;
        }
        
        if(_data != null) {
            lastData = _data;
        }
        
        data = lastData;

        // Call parent constructor with script support enabled
        super(true, lastName);
    }
    
    /**
     * Helper function to switch to another ModState.
     * Use this instead of FlxState.switchTo to avoid name conflicts.
     * @param stateName Name of the target state script
     * @param data Optional data to pass
     */
    public static function goTo(stateName:String, ?data:Dynamic) {
        MusicBeatState.switchState(new ModState(stateName, data));
    }

    /**
     * Checks if there is a script for the given state name.
     * Looks in mods (top/global) first and then in shared assets.
     */
    public static function hasScript(stateName:String):Bool {
        if (stateName == null || stateName == '') return false;

        #if HSCRIPT_ALLOWED
        var relPath:String = 'data/states/' + stateName + '.hx';

        var scriptFile:String = null;

        #if MODS_ALLOWED
        var modPath:String = Paths.modFolders(relPath);
        #if sys
        if (FileSystem.exists(modPath)) {
            scriptFile = modPath;
        }
        #end
        #end

        if (scriptFile == null) {
            var sharedPath:String = Paths.getSharedPath(relPath);
            #if sys
            if (FileSystem.exists(sharedPath)) {
                scriptFile = sharedPath;
            }
            #end
        }

        return scriptFile != null;
        #else
        return false;
        #end
    }

    // === Script loading & lifecycle ===

    #if HSCRIPT_ALLOWED
    function loadScript():Void {
        if (hscript != null || lastName == null || lastName == '')
            return;

        // Expected relative path inside mods or assets: data/states/<StateName>.hx
        var relPath:String = 'data/states/' + lastName + '.hx';

        var scriptFile:String = null;

        #if MODS_ALLOWED
        // Prefer current mod / global mods
        var modPath:String = Paths.modFolders(relPath);
        #if sys
        if (FileSystem.exists(modPath)) {
            scriptFile = modPath;
        }
        #end
        #end

        // Fallback to shared assets folder
        if (scriptFile == null) {
            var sharedPath:String = Paths.getSharedPath(relPath);
            #if sys
            if (FileSystem.exists(sharedPath)) {
                scriptFile = sharedPath;
            }
            #end
        }

        if (scriptFile == null) {
            trace('ModState: script file not found for state "' + lastName + '" (looked for ' + relPath + ')');
            return;
        }

        // Provide some handy variables directly to the script
        var initialVars:Dynamic = {
            state: this,
            add: add,
            remove: remove,
            insert: insert,
            data: data
        };

        try {
            hscript = new HScript(null, scriptFile, initialVars);
        } catch (e:Dynamic) {
            trace('ModState: error while loading script ' + scriptFile + ' -> ' + Std.string(e));
            hscript = null;
        }
    }

    function callFunc(name:String, ?args:Array<Dynamic>):Dynamic {
        if (hscript == null || name == null || name == '')
            return null;
        if (!hscript.exists(name))
            return null;
        try {
            return hscript.call(name, args);
        } catch (e:Dynamic) {
            trace('ModState: error calling function "' + name + '" -> ' + Std.string(e));
        }
        return null;
    }
    #end

    override function create() {
        #if HSCRIPT_ALLOWED
        loadScript();
        // Optional early callback
        callFunc('onCreate');
        #end

        super.create();

        #if HSCRIPT_ALLOWED
        // Main creation callbacks
        callFunc('create');
        callFunc('postCreate');
        #end
    }

    override function update(elapsed:Float) {
        #if HSCRIPT_ALLOWED
        // Only call script updates if the state is active (respects autoPause and focus loss)
        if (active) {
            callFunc('preUpdate', [elapsed]);
        }
        #end

        super.update(elapsed);

        #if HSCRIPT_ALLOWED
        // Only call script updates if the state is active
        if (active) {
            callFunc('update', [elapsed]);
            callFunc('postUpdate', [elapsed]);
        }
        #end

        #if MODS_ALLOWED
        // Default shortcut to open the Mods menu from any ModState
        if (FlxG.keys.justPressed.F12) {
            MusicBeatState.switchState(new states.ModsMenuState());
            return;
        }
        #end
    }

    override function stepHit():Void {
        super.stepHit();
        #if HSCRIPT_ALLOWED
        callFunc('stepHit', [curStep]);
        #end
    }

    override function beatHit():Void {
        super.beatHit();
        #if HSCRIPT_ALLOWED
        callFunc('beatHit', [curBeat]);
        #end
    }

    override function destroy() {
        #if HSCRIPT_ALLOWED
        callFunc('destroy');
        hscript = null;
        #end

        super.destroy();
    }
}
