package funkin.modding;

import flixel.FlxState;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.debug.TraceDisplay;
import funkin.ui.mainmenu.MainMenuState;

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.Iris;
#end

import funkin.modding.scripting.psychlua.LuaUtils;

#if sys
import sys.FileSystem;
#end

class ModState extends MusicBeatState
{
    #if LUA_ALLOWED
    public var luaArray:Array<FunkinLua> = [];
    #end
    
    #if HSCRIPT_ALLOWED
    public var hscriptArray:Array<HScript> = [];
    #end
    
    public static var nextState:FlxState = null;
    public var stateName:String = '';
    
    public var errorText:FlxText;
    public var hasError:Bool = false;
    public var bgSprite:FlxSprite;
    
    public static function hasScript(stateName:String):Bool
    {
        #if (HSCRIPT_ALLOWED && sys)
        #if MODS_ALLOWED
        Mods.loadTopMod();
        #end
        var scriptPath:String = Paths.hx(stateName);
        return FileSystem.exists(scriptPath);
        #else
        return false;
        #end
    }
    
    public function new(?stateName:String = '')
    {
        super();
        this.stateName = stateName;
    }

    override function create()
    {
        persistentDraw = true;

        var ohnou = new FlxText(0, 0, FlxG.width, "It appears the ModState did not load, due to an error or a previous incorrect configuration between States. Just press 1 and choose NONE.", 16);
        ohnou.color = 0xFF6C6C;
        ohnou.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        ohnou.screenCenter();
        ohnou.visible = true;
        add(ohnou);
        
        errorText = new FlxText(10, 50, FlxG.width - 20, "ERROR!", 16);
        errorText.color = FlxColor.RED;
        errorText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
        errorText.visible = false;
        add(errorText);
        
        #if HSCRIPT_ALLOWED
        // Clear public variables for new state
        MusicBeatState.publicVariables.clear();
        #end
        
        if(stateName != null && stateName.length > 0)
            loadStateScripts(stateName);
            
        MusicBeatState.callOnGlobalScript('onStateCreate', [stateName]);
        callOnScripts('onCreate');
        super.create();
        callOnScripts('onCreatePost');
        MusicBeatState.callOnGlobalScript('onStateCreatePost', [stateName]);
        var plusVer:FlxText = new FlxText(12, FlxG.height - 24, 0, "Plus Engine v" + MainMenuState.plusEngineVersion, 12);
        plusVer.scrollFactor.set();
        plusVer.alpha = 0.8;
        plusVer.setFormat(Paths.font("phantom.ttf"), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        add(plusVer);
    }

    override function update(elapsed:Float)
    {   
        MusicBeatState.callOnGlobalScript('onStateUpdate', [stateName, elapsed]);
        callOnScripts('onUpdate', [elapsed]);
        super.update(elapsed);
        callOnScripts('onUpdatePost', [elapsed]);
        MusicBeatState.callOnGlobalScript('onStateUpdatePost', [stateName, elapsed]);

        if (FlxG.keys.justPressed.F12) {
            MusicBeatState.switchState(new ModsMenuState());
        }
    }

    override function destroy()
    {
        MusicBeatState.callOnGlobalScript('onStateDestroy', [stateName]);
        callOnScripts('onDestroy');
        
        #if LUA_ALLOWED
        for(script in luaArray)
        {
            if(script != null)
            {
                script.call('onDestroy', []);
                script.stop();
            }
        }
        luaArray = [];
        #end
        
        #if HSCRIPT_ALLOWED
        for(script in hscriptArray)
        {
            if(script != null)
                script.destroy();
        }
        hscriptArray = [];
        #end
        
        super.destroy();
        callOnScripts('onDestroyPost');
    }
    
    override function stepHit():Void
    {
        callOnScripts('onStepHit', [curStep]);
        super.stepHit();
    }
    
    override function beatHit():Void
    {
        callOnScripts('onBeatHit', [curBeat]);
        super.beatHit();
    }
    
    override function sectionHit():Void
    {
        callOnScripts('onSectionHit', [curSection]);
        super.sectionHit();
    }
    
    public function loadStateScripts(stateName:String)
    {
        #if sys
        #if MODS_ALLOWED
        Mods.loadTopMod(); 
        var currentMod:String = Mods.currentModDirectory;
        #else
        var currentMod:String = '';
        #end
        
        #if HSCRIPT_ALLOWED
        var savedModDir:String = MusicBeatState.globalVariables.exists('currentModDirectory') ? MusicBeatState.globalVariables.get('currentModDirectory') : null;
        if(savedModDir != null && savedModDir != currentMod)
        {
            trace('ModState: Mod changed from "$savedModDir" to "$currentMod" - Clearing shared vars');
            MusicBeatState.globalVariables.clear(); 
        }
        
        // Sync global variables with current state's variables
        for(key in MusicBeatState.globalVariables.keys())
        {
            variables.set(key, MusicBeatState.globalVariables.get(key));
        }
        #end
        
        var scriptPath:String = Paths.hx(stateName);
        var scriptFolder:String = haxe.io.Path.directory(scriptPath);
        // Use only the file name to avoid loading the main script twice due to path separator differences
        var mainFileName:String = haxe.io.Path.withoutDirectory(scriptPath);
        var foundScripts:Bool = false;
        
        // Load Lua scripts first
        #if LUA_ALLOWED
        var luaPath:String = scriptPath.replace('.hx', '.lua');
        if(FileSystem.exists(luaPath))
        {
            new FunkinLua(luaPath);
            trace('Loaded main Lua script for state: $stateName');
            foundScripts = true;
        }
        
        // Load additional .lua scripts in the folder
        if(FileSystem.exists(scriptFolder) && FileSystem.isDirectory(scriptFolder))
        {
            var files:Array<String> = FileSystem.readDirectory(scriptFolder);
            for(file in files)
            {
                if(file.endsWith('.lua'))
                {
                    var fullPath:String = haxe.io.Path.join([scriptFolder, file]);
                    if(fullPath != luaPath)
                    {
                        new FunkinLua(fullPath);
                        trace('Loaded additional Lua script: $file for state: $stateName');
                        foundScripts = true;
                    }
                }
            }
        }
        #end
        
        // Load HScript scripts
        #if HSCRIPT_ALLOWED
        if(FileSystem.exists(scriptPath))
        {
            initHScript(scriptPath);
            trace('Loaded main HScript for state: $stateName');
            foundScripts = true;
        }
        
        // Load all other .hx scripts in the same folder
        if(FileSystem.exists(scriptFolder) && FileSystem.isDirectory(scriptFolder))
        {
            var files:Array<String> = FileSystem.readDirectory(scriptFolder);
            for(file in files)
            {
                if(file.endsWith('.hx'))
                {
                    // Avoid loading the main script twice (different path separators, same file)
                    if(file == mainFileName) continue;
                    var fullPath:String = haxe.io.Path.join([scriptFolder, file]);
                    initHScript(fullPath);
                    trace('Loaded additional HScript: $file for state: $stateName');
                    foundScripts = true;
                }
            }
        }
        #end
        
        if(!foundScripts)
        {
            trace('No scripts found for state: $stateName');
        }
        
        #if MODS_ALLOWED
        if(currentMod != null && currentMod.length > 0)
        {
            #if HSCRIPT_ALLOWED
            MusicBeatState.globalVariables.set('currentModDirectory', currentMod);
            #end
            variables.set('currentModDirectory', currentMod);
        }
        #end
        #end
    }

    #if HSCRIPT_ALLOWED
    public function initHScript(file:String)
    {
        var newScript:HScript = null;
        try
        {
            newScript = new HScript(null, file);
            
            // Shared variables functions (persist across state changes)
            newScript.set('setSharedVar', function(name:String, value:Dynamic) {
                MusicBeatState.globalVariables.set(name, value);
                variables.set(name, value);
                trace('ModState: Shared var set - $name = $value');
                return value;
            });
            
            newScript.set('getSharedVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
                // Check global variables first for persistence
                if (MusicBeatState.globalVariables.exists(name)) {
                    var value = MusicBeatState.globalVariables.get(name);
                    trace('ModState: Shared var get (global) - $name = $value');
                    return value;
                }
                // Fallback to state variables
                if (variables.exists(name)) {
                    var value = variables.get(name);
                    trace('ModState: Shared var get (state) - $name = $value');
                    return value;
                }
                trace('ModState: Shared var $name not found');
                return defaultValue;
            });
            
            newScript.set('hasSharedVar', function(name:String):Bool {
                return MusicBeatState.globalVariables.exists(name) || variables.exists(name);
            });
            
            newScript.set('removeSharedVar', function(name:String):Bool {
                var removed = false;
                if (MusicBeatState.globalVariables.exists(name)) {
                    MusicBeatState.globalVariables.remove(name);
                    removed = true;
                }
                if (variables.exists(name)) {
                    variables.remove(name);
                    removed = true;
                }
                return removed;
            });
            
            newScript.set('clearSharedVars', function() {
                MusicBeatState.globalVariables.clear();
                variables.clear();
                trace('ModState: All shared vars cleared');
            });
            
            // Public variables (shared between scripts in same state)
            newScript.set('setPublicVar', function(name:String, value:Dynamic) {
                MusicBeatState.publicVariables.set(name, value);
                return value;
            });
            
            newScript.set('getPublicVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
                return MusicBeatState.publicVariables.exists(name) ? MusicBeatState.publicVariables.get(name) : defaultValue;
            });
            
            // Static variables (persist across all states and mods)
            newScript.set('setStaticVar', function(name:String, value:Dynamic) {
                MusicBeatState.staticVariables.set(name, value);
                return value;
            });
            
            newScript.set('getStaticVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
                return MusicBeatState.staticVariables.exists(name) ? MusicBeatState.staticVariables.get(name) : defaultValue;
            });
            
            // Access to MusicBeatState variables
            newScript.set('setStateVar', function(name:String, value:Dynamic) {
                variables.set(name, value);
                return value;
            });
            
            newScript.set('getStateVar', function(name:String, ?defaultValue:Dynamic = null):Dynamic {
                return variables.exists(name) ? variables.get(name) : defaultValue;
            });
            
            if (newScript.exists('onCreate')) newScript.call('onCreate');
            trace('initialized hscript interp successfully: $file');
            hscriptArray.push(newScript);
        }
        catch(e:IrisError)
        {
            var pos:HScriptInfos = cast {fileName: file, showLine: false};
            var errorMsg = Printer.errorToString(e, false);
            
            showError('HScript Error in ${extractFileName(file)}:\n$errorMsg');
            
            TraceDisplay.addHScriptError(errorMsg, file);
            
            Iris.error(errorMsg, pos);
            var newScript:HScript = cast (Iris.instances.get(file), HScript);
            if(newScript != null)
                newScript.destroy();
        }
    }

    public function addHScript(scriptFile:String):Bool
    {
        #if sys
        var scriptToLoad:String = Paths.modFolders(scriptFile);
        if(!FileSystem.exists(scriptToLoad))
            scriptToLoad = Paths.getSharedPath(scriptFile);

        if(FileSystem.exists(scriptToLoad))
        {
            if (Iris.instances.exists(scriptToLoad)) return false;

            initHScript(scriptToLoad);
            return true;
        }
        #end
        return false;
    }
    #end
    
    public function showError(text:String):Void
    {
        hasError = true;
        
        if (bgSprite == null) {
            bgSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
            add(bgSprite);
        }
        
        errorText.text = text;
        errorText.visible = true;
        
        remove(errorText);
        add(errorText);
        
        trace('ModState Error: $text');
    }
    
    private function extractFileName(fileName:String):String
    {
        if (fileName == null) return "unknown";
        
        if (fileName.indexOf("/") != -1) {
            fileName = fileName.substr(fileName.lastIndexOf("/") + 1);
        }
        if (fileName.indexOf("\\") != -1) {
            fileName = fileName.substr(fileName.lastIndexOf("\\") + 1);
        }
        if (fileName.indexOf(".") != -1) {
            fileName = fileName.substr(0, fileName.lastIndexOf("."));
        }
        
        return fileName;
    }

    public function callOnScripts(funcToCall:String, args:Array<Dynamic> = null, ignoreStops = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
    {
        var returnVal:Dynamic = callOnLuas(funcToCall, args, ignoreStops, exclusions, excludeValues);
        if(returnVal == LuaUtils.Function_StopHScript || returnVal == LuaUtils.Function_StopAll)
            return returnVal;
        
        var value:Dynamic = callOnHScript(funcToCall, args, ignoreStops, exclusions, excludeValues);
        if(value != null && value != LuaUtils.Function_Continue)
            returnVal = value;
        
        return returnVal;
    }
    
    public function callOnLuas(funcToCall:String, args:Array<Dynamic> = null, ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
    {
        var returnVal:Dynamic = LuaUtils.Function_Continue;
        
        #if LUA_ALLOWED
        if(exclusions == null) exclusions = [];
        if(excludeValues == null) excludeValues = [];
        if(args == null) args = [];
        excludeValues.push(LuaUtils.Function_Continue);
        
        for(script in luaArray)
        {
            if(script == null || script.closed || exclusions.contains(script.scriptName))
                continue;
            
            var myValue:Dynamic = script.call(funcToCall, args);
            if((myValue == LuaUtils.Function_StopLua || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
            {
                returnVal = myValue;
                break;
            }
            
            if(myValue != null && !excludeValues.contains(myValue))
                returnVal = myValue;
        }
        #end
        
        return returnVal;
    }

    public function callOnHScript(funcToCall:String, args:Array<Dynamic> = null, ?ignoreStops:Bool = false, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
    {
        var returnVal:Dynamic = LuaUtils.Function_Continue;

        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = new Array();
        if(excludeValues == null) excludeValues = new Array();
        excludeValues.push(LuaUtils.Function_Continue);

        var len:Int = hscriptArray.length;
        if (len < 1)
            return returnVal;

        for(script in hscriptArray)
        {
            @:privateAccess
            if(script == null || !script.exists(funcToCall) || exclusions.contains(script.origin))
                continue;

            try {
                var callValue = script.call(funcToCall, args);
                if(callValue != null)
                {
                    var myValue:Dynamic = callValue.returnValue;

                    if((myValue == LuaUtils.Function_StopHScript || myValue == LuaUtils.Function_StopAll) && !excludeValues.contains(myValue) && !ignoreStops)
                    {
                        returnVal = myValue;
                        break;
                    }

                    if(myValue != null && !excludeValues.contains(myValue))
                        returnVal = myValue;
                }
            }
            catch(e:Dynamic) {
                @:privateAccess
                var fileName = script.origin != null ? script.origin : "unknown";
                var errorMsg = 'Error calling function "$funcToCall": $e';
                
                showError('HScript Runtime Error in ${extractFileName(fileName)}:\nFunction: $funcToCall\nError: $e');
                
                TraceDisplay.addHScriptError('Runtime error in $funcToCall: $e', fileName);
                
                trace('HScript Runtime Error in $fileName: $e');
            }
        }
        #end

        return returnVal;
    }

    public function setOnScripts(variable:String, arg:Dynamic, exclusions:Array<String> = null)
    {
        setOnLuas(variable, arg, exclusions);
        setOnHScript(variable, arg, exclusions);
    }
    
    public function setOnLuas(variable:String, arg:Dynamic, exclusions:Array<String> = null)
    {
        #if LUA_ALLOWED
        if(exclusions == null) exclusions = [];
        for (script in luaArray)
        {
            if (script == null || script.closed || exclusions.contains(script.scriptName))
                continue;
            
            script.set(variable, arg);
        }
        #end
    }

    public function setOnHScript(variable:String, arg:Dynamic, exclusions:Array<String> = null)
    {
        #if HSCRIPT_ALLOWED
        if(exclusions == null) exclusions = [];
        for (script in hscriptArray)
        {
            @:privateAccess
            if (exclusions.contains(script.origin))
                continue;

            script.set(variable, arg);
        }
        #end
    }
}