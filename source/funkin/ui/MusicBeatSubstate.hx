package funkin.ui;

import flixel.FlxSubState;
import funkin.ui.debug.TraceDisplay;

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
#end

#if HSCRIPT_ALLOWED
import funkin.modding.scripting.HScript;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
#end

import funkin.modding.scripting.psychlua.LuaUtils;

#if sys
import sys.FileSystem;
#end

// Script layer on top of BaseMusicBeatSubstate.
// Adds GlobalScript forwarding and per-substate HScript/Lua callbacks.
//
// Hierarchy:
//   BaseMusicBeatSubstate (beat, mobile controls)
//   └── MusicBeatSubstate (this file — + script hooks)

class MusicBeatSubstate extends BaseMusicBeatSubstate
{
	public static var instance:MusicBeatSubstate;
	
	// Variables map for substate-specific data
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	
	// MusicBeatSubstate specific scripts (run on all MusicBeatSubstate instances)
	#if LUA_ALLOWED
	public static var musicBeatSubstateLuaScript:FunkinLua = null;
	#end
	
	#if HSCRIPT_ALLOWED
	public static var musicBeatSubstateScript:HScript = null;
	#end

	public function new()
	{
		instance = this;
		controls.isInSubstate = true;
		super();
	}

	// Get the current substate instance
	public static function getSubstate():MusicBeatSubstate
	{
		return instance;
	}

	// Get the parent MusicBeatState (shadows Base version which returns BaseMusicBeatState)
	public function getParentState():MusicBeatState
	{
		if (FlxG.state != null && Std.isOfType(FlxG.state, MusicBeatState))
			return cast(FlxG.state, MusicBeatState);
		return null;
	}

	override function update(elapsed:Float)
	{
		// Call global script update
		MusicBeatState.callOnGlobalScript('onSubstateUpdate', [elapsed]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onUpdate', [elapsed]);

		super.update(elapsed);
	}

	override public function stepHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateStepHit', [curStep]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onStepHit', [curStep]);

		super.stepHit();
	}

	override public function beatHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateBeatHit', [curBeat]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onBeatHit', [curBeat]);

		super.beatHit();
	}

	override public function sectionHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateSectionHit', [curSection]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onSectionHit', [curSection]);

		super.sectionHit();
	}
	
	public static function initMusicBeatSubstateScript():Void
	{
		// Try to load Lua MusicBeatSubstate script first
		#if (LUA_ALLOWED && sys)
		if(musicBeatSubstateLuaScript == null)
		{
			#if MODS_ALLOWED
			var luaPath:String = Paths.modFolders('scripts/MusicBeatSubState.lua');
			if(!FileSystem.exists(luaPath))
				luaPath = Paths.getSharedPath('scripts/MusicBeatSubState.lua');
			#else
			var luaPath:String = Paths.getSharedPath('scripts/MusicBeatSubState.lua');
			#end
			
			if(FileSystem.exists(luaPath))
			{
				trace('Loading MusicBeatSubState Lua Script from: $luaPath');
				musicBeatSubstateLuaScript = new FunkinLua(luaPath);
				trace('MusicBeatSubState (Lua) initialized successfully');
			}
		}
		#end
		
		// Then load HScript MusicBeatSubstate script
		if(musicBeatSubstateScript != null) return; // Already initialized
		
		#if MODS_ALLOWED
		var scriptPath:String = Paths.modFolders('scripts/MusicBeatSubState.hx');
		if(scriptPath == null || !FileSystem.exists(scriptPath))
			scriptPath = Paths.getSharedPath('scripts/MusicBeatSubState.hx');
		#else
		var scriptPath:String = Paths.getSharedPath('scripts/MusicBeatSubState.hx');
		#end
		
		if(scriptPath == null || !FileSystem.exists(scriptPath))
		{
			trace('No MusicBeatSubState script found');
			return;
		}
		
		#if HSCRIPT_ALLOWED
		try
		{
			trace('MusicBeatSubState: Loading script from: $scriptPath');
			musicBeatSubstateScript = new HScript(null, scriptPath, null, true);
			
			if(musicBeatSubstateScript == null)
			{
				trace('MusicBeatSubState: Failed to create HScript instance');
				return;
			}
			
			// Set up helper functions
			musicBeatSubstateScript.set('import', function(className:String) {
				trace('MusicBeatSubState: Import is built-in, $className should already be available');
			});
			
			// Parse and execute
			musicBeatSubstateScript.parse(true);
			musicBeatSubstateScript.execute();
			
			// Call onCreate if it exists
			if (musicBeatSubstateScript.exists('onCreate'))
			{
				musicBeatSubstateScript.call('onCreate');
				trace('MusicBeatSubState: onCreate() called successfully');
			}
			
			trace('MusicBeatSubState script initialized successfully');
		}
		catch(e:IrisError)
		{
			try {
				var errorMsg = Printer.errorToString(e, false);
				trace('MusicBeatSubState Script Error: $errorMsg');
				if(TraceDisplay.instance != null)
					TraceDisplay.addHScriptError(errorMsg, scriptPath);
			} catch(printerError:Dynamic) {
				trace('MusicBeatSubState: Error while processing IrisError: $printerError');
			}
		}
		catch(e:Dynamic)
		{
			trace('MusicBeatSubState Script Error (unexpected): $e');
			#if HSCRIPT_ALLOWED
			if(TraceDisplay.instance != null)
				TraceDisplay.addHScriptError('Unexpected error: $e', scriptPath);
			#end
		}
		#end
	}
	
	public static function callOnMusicBeatSubstateScript(funcToCall:String, args:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = LuaUtils.Function_Continue;
		
		// Call on Lua script first
		#if LUA_ALLOWED
		if(musicBeatSubstateLuaScript != null)
		{
			var ret:Dynamic = musicBeatSubstateLuaScript.call(funcToCall, args != null ? args : []);
			if(ret != null && ret != LuaUtils.Function_Continue)
				returnVal = ret;
		}
		#end
		
		// Then call on HScript
		#if HSCRIPT_ALLOWED
		if(musicBeatSubstateScript != null && musicBeatSubstateScript.exists(funcToCall))
		{
			try {
				var callValue = musicBeatSubstateScript.call(funcToCall, args);
				if(callValue != null && callValue.returnValue != null)
				{
					var myValue:Dynamic = callValue.returnValue;
					if(myValue != LuaUtils.Function_Continue)
						returnVal = myValue;
				}
			}
			catch(e:Dynamic) {
				trace('MusicBeatSubState Script Error calling $funcToCall: $e');
				@:privateAccess
				var fileName = musicBeatSubstateScript.origin != null ? musicBeatSubstateScript.origin : "MusicBeatSubState";
				TraceDisplay.addHScriptError('Runtime error in $funcToCall: $e', fileName);
			}
		}
		#end
		
		return returnVal;
	}
}
