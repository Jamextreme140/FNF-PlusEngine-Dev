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

	// Companion script — loaded automatically alongside any hardcoded substate.
	// Path: scripts/substates/{ClassName}.hx (or .lua), searched in mod → global mods → assets/shared.
	// Callbacks: onCreate / onCreatePost / onUpdate / onUpdatePost / onDestroy
	// and beat/step/section hooks — same pattern as MusicBeatState companion scripts.
	#if HSCRIPT_ALLOWED
	public var companionScript:HScript = null;
	#end
	#if LUA_ALLOWED
	public var companionLuaScript:FunkinLua = null;
	#end

	public function new()
	{
		super();
	}

	override function create()
	{
		instance = this;
		controls.isInSubstate = true;
		super.create();
		#if (HSCRIPT_ALLOWED && MODS_ALLOWED && sys)
		// Skip companion for CustomSubstate (Lua-driven substates handle their own scripts)
		if (!(this is funkin.modding.scripting.psychlua.CustomSubstate) && MusicBeatState.stateScriptOverridesEnabled())
			_loadCompanionScript();
		callOnCompanionScript('onCreate', []);
		#end
	}
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
		// Companion pre-update
		callOnCompanionScript('onUpdate', [elapsed]);

		super.update(elapsed);

		// Companion post-update
		callOnCompanionScript('onUpdatePost', [elapsed]);
	}

	override public function stepHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateStepHit', [curStep]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onStepHit', [curStep]);
		callOnCompanionScript('onStepHit', [curStep]);

		super.stepHit();

		callOnCompanionScript('onStepHitPost', [curStep]);
	}

	override public function beatHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateBeatHit', [curBeat]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onBeatHit', [curBeat]);
		callOnCompanionScript('onBeatHit', [curBeat]);

		super.beatHit();

		callOnCompanionScript('onBeatHitPost', [curBeat]);
	}

	override public function sectionHit():Void
	{
		// Call global script
		MusicBeatState.callOnGlobalScript('onSubstateSectionHit', [curSection]);
		// Call MusicBeatSubstate-specific script
		callOnMusicBeatSubstateScript('onSectionHit', [curSection]);
		callOnCompanionScript('onSectionHit', [curSection]);

		super.sectionHit();

		callOnCompanionScript('onSectionHitPost', [curSection]);
	}

	override function destroy()
	{
		if (instance == this)
		{
			controls.isInSubstate = false;
			instance = null;
		}
		#if HSCRIPT_ALLOWED
		if (companionScript != null)
		{
			callOnCompanionScript('onDestroy', []);
			companionScript.destroy();
			companionScript = null;
		}
		#end
		#if LUA_ALLOWED
		if (companionLuaScript != null)
		{
			companionLuaScript.call('onDestroy', []);
			companionLuaScript.stop();
			companionLuaScript = null;
		}
		#end
		super.destroy();
	}
	
	// ── Companion script helpers ─────────────────────────────────────────────────

	#if (HSCRIPT_ALLOWED && sys)
	function _loadCompanionScript():Void
	{
		var fullName:String = Type.getClassName(Type.getClass(this));
		var parts = fullName.split('.');
		var clsName:String = parts[parts.length - 1];
		var rel:String = 'scripts/substates/$clsName.hx';

		var path:String = null;

		#if MODS_ALLOWED
		var modded:String = Paths.modFolders(rel);
		if (FileSystem.exists(modded)) path = modded;
		#end

		if (path == null)
		{
			var shared:String = Paths.getSharedPath(rel);
			if (FileSystem.exists(shared)) path = shared;
		}

		#if LUA_ALLOWED
		var luaRel:String = 'scripts/substates/$clsName.lua';
		var luaPath:String = null;
		#if MODS_ALLOWED
		var moddedLua:String = Paths.modFolders(luaRel);
		if (FileSystem.exists(moddedLua)) luaPath = moddedLua;
		#end
		if (luaPath == null)
		{
			var sharedLua:String = Paths.getSharedPath(luaRel);
			if (FileSystem.exists(sharedLua)) luaPath = sharedLua;
		}
		if (luaPath != null)
		{
			try { companionLuaScript = new FunkinLua(luaPath); }
			catch(e:Dynamic) { trace('[CompanionSubstate] Lua error in $luaPath: $e'); }
		}
		#end

		if (path == null) return;

		try
		{
			companionScript = new HScript(null, path);

			// Expose the substate itself and its parent state
			companionScript.set('game',           this);
			companionScript.set('parentState',    getParentState());
			companionScript.set('add',            this.add);
			companionScript.set('remove',         this.remove);
			companionScript.set('close',          this.close);

			companionScript.set('setSharedVar', function(n:String, v:Dynamic) {
				MusicBeatState.globalVariables.set(n, v);
				variables.set(n, v);
				return v;
			});
			companionScript.set('getSharedVar', function(n:String, ?def:Dynamic = null):Dynamic {
				if (MusicBeatState.globalVariables.exists(n)) return MusicBeatState.globalVariables.get(n);
				if (variables.exists(n)) return variables.get(n);
				return def;
			});
			companionScript.set('setStaticVar', function(n:String, v:Dynamic) {
				MusicBeatState.staticVariables.set(n, v); return v;
			});
			companionScript.set('getStaticVar', function(n:String, ?def:Dynamic = null):Dynamic
				return MusicBeatState.staticVariables.exists(n) ? MusicBeatState.staticVariables.get(n) : def);

			trace('[CompanionSubstate] Loaded for "$clsName": $path');
		}
		catch(e:crowplexus.hscript.Expr.Error)
		{
			var msg = crowplexus.hscript.Printer.errorToString(e, false);
			trace('[CompanionSubstate] HScript error in $path:\n$msg');
			if (funkin.ui.debug.TraceDisplay.instance != null)
				funkin.ui.debug.TraceDisplay.addHScriptError(msg, path);
		}
		catch(e:Dynamic)
		{
			trace('[CompanionSubstate] Failed to load $path: $e');
		}
	}
	#end

	public function callOnCompanionScript(funcName:String, args:Array<Dynamic> = null):Dynamic
	{
		if (args == null) args = [];
		var ret:Dynamic = LuaUtils.Function_Continue;
		if (!MusicBeatState.stateScriptOverridesEnabled()) return ret;

		#if LUA_ALLOWED
		if (companionLuaScript != null)
		{
			var v = companionLuaScript.call(funcName, args);
			if (v != null && v != LuaUtils.Function_Continue) ret = v;
		}
		#end

		#if HSCRIPT_ALLOWED
		if (companionScript != null)
		{
			try
			{
				var fn:String = companionScript.exists(funcName) ? funcName : null;
				if (fn == null && funcName.startsWith('on'))
				{
					var bare = funcName.charAt(2).toLowerCase() + funcName.substr(3);
					if (companionScript.exists(bare)) fn = bare;
				}
				if (fn != null)
				{
					var callValue = companionScript.call(fn, args);
					if (callValue != null && callValue.returnValue != null && callValue.returnValue != LuaUtils.Function_Continue)
						ret = callValue.returnValue;
				}
			}
			catch(e:Dynamic)
			{
				trace('[CompanionSubstate] Runtime error calling $funcName: $e');
			}
		}
		#end

		return ret;
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
