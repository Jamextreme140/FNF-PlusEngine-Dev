package backend;

import flixel.FlxG;
import sys.FileSystem;
import backend.Paths;
import backend.Mods;

#if HSCRIPT_ALLOWED
import psychlua.HScript;
import crowplexus.iris.Iris;
import scripting.SCScript;
import codenameengine.scripting.HScriptCode;
import codenameengine.scripting.ScriptPack;
#end

/**
 * Handles loading and management of state-specific scripts
 * Scripts are loaded from:
 * - scripts/states/[StateName]/ (Psych HScript & SC)
 * - scripts/states/[StateName]/advanced/ (CodeName HScript)
 */
class StateScriptHandler
{
	#if HSCRIPT_ALLOWED
	public static var stateHScripts:Array<HScript> = [];
	public static var stateSCScripts:Array<SCScript> = [];
	public static var stateCodeNameScripts:ScriptPack = new ScriptPack("StateScripts");
	#end
	
	/**
	 * Loads all scripts for a specific state
	 * @param stateName Name of the state (e.g., "MainMenuState", "FreeplayState")
	 */
	public static function loadStateScripts(stateName:String):Void
	{
		#if HSCRIPT_ALLOWED
		clearStateScripts();
		
		var stateFolder:String = 'scripts/states/$stateName/';
		var advancedFolder:String = 'scripts/states/$stateName/advanced/';
		
		// Load Psych HScript & SC from main folder
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), stateFolder))
		{
			if (!FileSystem.exists(folder)) continue;
			
			for (file in FileSystem.readDirectory(folder))
			{
				var fullPath:String = folder + file;
				
				// Skip advanced subfolder
				if (FileSystem.isDirectory(fullPath)) continue;
				
				// Check for HScript files
				for (ext in CoolUtil.haxeExtensions)
				{
					if (file.toLowerCase().endsWith('.$ext'))
					{
						// Check if it should be SC script (has /sc/ in path or .sc. in name)
						if (folder.contains('/sc/') || file.contains('.sc.'))
							loadSCScript(fullPath, stateName);
						else
							loadHScript(fullPath, stateName);
						break;
					}
				}
			}
		}
		
		// Load SC scripts from sc/ subfolder
		var scFolder:String = 'scripts/states/$stateName/sc/';
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), scFolder))
		{
			if (!FileSystem.exists(folder)) continue;
			
			for (file in FileSystem.readDirectory(folder))
			{
				var fullPath:String = folder + file;
				if (FileSystem.isDirectory(fullPath)) continue;
				
				for (ext in CoolUtil.haxeExtensions)
				{
					if (file.toLowerCase().endsWith('.$ext'))
					{
						loadSCScript(fullPath, stateName);
						break;
					}
				}
			}
		}
		
		// Load CodeName HScript from advanced/ folder
		for (folder in Mods.directoriesWithFile(Paths.getSharedPath(), advancedFolder))
		{
			if (!FileSystem.exists(folder)) continue;
			
			for (file in FileSystem.readDirectory(folder))
			{
				var fullPath:String = folder + file;
				if (FileSystem.isDirectory(fullPath)) continue;
				
				for (ext in CoolUtil.haxeExtensions)
				{
					if (file.toLowerCase().endsWith('.$ext'))
					{
						loadCodeNameScript(fullPath, stateName);
						break;
					}
				}
			}
		}
		
		// Call onCreate on all loaded scripts
		callOnStateScripts('onCreate', []);
		#end
	}
	
	#if HSCRIPT_ALLOWED
	private static function loadHScript(path:String, stateName:String):Void
	{
		try
		{
			if (Iris.instances.exists(path))
			{
				trace('State HScript already loaded: $path');
				return;
			}
			
			var script:HScript = new HScript(null, path);
			if (script != null)
			{
				stateHScripts.push(script);
				trace('Loaded State HScript: $path for $stateName');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error loading State HScript ($path): $e');
		}
	}
	
	private static function loadSCScript(path:String, stateName:String):Void
	{
		try
		{
			var script:SCScript = new SCScript();
			script.loadScript(path);
			stateSCScripts.push(script);
			trace('Loaded State SC Script: $path for $stateName');
		}
		catch (e:Dynamic)
		{
			trace('Error loading State SC Script ($path): $e');
		}
	}
	
	private static function loadCodeNameScript(path:String, stateName:String):Void
	{
		try
		{
			var script = HScriptCode.create(path);
			if (!(script is codenameengine.scripting.DummyScript))
			{
				stateCodeNameScripts.add(script);
				script.load();
				trace('Loaded State CodeName Script: $path for $stateName');
			}
		}
		catch (e:Dynamic)
		{
			trace('Error loading State CodeName Script ($path): $e');
		}
	}
	#end
	
	/**
	 * Calls a function on all loaded state scripts
	 */
	public static function callOnStateScripts(funcName:String, args:Array<Dynamic> = null):Dynamic
	{
		#if HSCRIPT_ALLOWED
		if (args == null) args = [];
		var returnVal:Dynamic = psychlua.LuaUtils.Function_Continue;
		
		// Call on Psych HScripts
		for (script in stateHScripts)
		{
			if (script == null || !script.exists(funcName)) continue;
			
			try
			{
				var ret:Dynamic = script.call(funcName, args);
				if (ret != null && ret != psychlua.LuaUtils.Function_Continue)
					returnVal = ret;
			}
			catch (e:Dynamic)
			{
				trace('Error calling $funcName on State HScript: $e');
			}
		}
		
		// Call on SC Scripts
		for (script in stateSCScripts)
		{
			if (script == null || !script.active || !script.exists) continue;
			
			try
			{
				var ret:Dynamic = script.callFunc(funcName, args);
				if (ret != null && ret != psychlua.LuaUtils.Function_Continue)
					returnVal = ret;
			}
			catch (e:Dynamic)
			{
				trace('Error calling $funcName on State SC Script: $e');
			}
		}
		
		// Call on CodeName Scripts
		if (stateCodeNameScripts != null)
		{
			try
			{
				var ret:Dynamic = stateCodeNameScripts.call(funcName, args);
				if (ret != null && ret != psychlua.LuaUtils.Function_Continue)
					returnVal = ret;
			}
			catch (e:Dynamic)
			{
				trace('Error calling $funcName on State CodeName Scripts: $e');
			}
		}
		
		return returnVal;
		#else
		return psychlua.LuaUtils.Function_Continue;
		#end
	}
	
	/**
	 * Sets a variable on all loaded state scripts
	 */
	public static function setOnStateScripts(varName:String, value:Dynamic):Void
	{
		#if HSCRIPT_ALLOWED
		// Set on Psych HScripts
		for (script in stateHScripts)
		{
			if (script != null)
				script.set(varName, value);
		}
		
		// Set on SC Scripts
		for (script in stateSCScripts)
		{
			if (script != null && script.active && script.exists)
				script.setVar(varName, value);
		}
		
		// Set on CodeName Scripts
		if (stateCodeNameScripts != null)
			stateCodeNameScripts.set(varName, value);
		#end
	}
	
	/**
	 * Clears all loaded state scripts
	 */
	public static function clearStateScripts():Void
	{
		#if HSCRIPT_ALLOWED
		// Destroy Psych HScripts
		for (script in stateHScripts)
		{
			if (script != null)
				script.destroy();
		}
		stateHScripts = [];
		
		// Destroy SC Scripts
		for (script in stateSCScripts)
		{
			if (script != null)
				script.destroy();
		}
		stateSCScripts = [];
		
		// Destroy CodeName Scripts
		if (stateCodeNameScripts != null)
		{
			for (script in stateCodeNameScripts.scripts)
			{
				if (script != null)
					script.destroy();
			}
			stateCodeNameScripts.scripts = [];
		}
		#end
	}
	
	/**
	 * Updates all state scripts
	 */
	public static function updateStateScripts(elapsed:Float):Void
	{
		callOnStateScripts('onUpdate', [elapsed]);
		callOnStateScripts('onUpdatePost', [elapsed]);
	}
}
