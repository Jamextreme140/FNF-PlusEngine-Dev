package funkin.modding.scripting;

import funkin.play.character.Character;
import funkin.modding.scripting.psychlua.LuaUtils;
import funkin.modding.scripting.psychlua.CustomSubstate;
import funkin.modding.scripting.psychlua.ReflectionFunctions;
import funkin.util.StructureOld;
#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
#end


#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.hscript.Printer;
import crowplexus.iris.scripted.InterpEx;
import crowplexus.iris.scripted.ScriptClassManager;
import crowplexus.iris.scripted.AbstractScriptClass;

import funkin.modding.scripting.SScript.SScriptCompat;

import haxe.ValueException;

typedef HScriptInfos = {
	> haxe.PosInfos,
	var ?funcName:String;
	var ?showLine:Null<Bool>;
	#if LUA_ALLOWED
	var ?isLua:Null<Bool>;
	#end
}

class HScript extends Iris
{
	public var filePath:String;
	public var modFolder:String;
	public var returnValue:Dynamic;
	public var scriptName:String = '';

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	public static function initHaxeModule(parent:FunkinLua)
	{
		if(parent.hscript == null)
		{
			// Check if user wants SScript compatibility mode
			#if SSCRIPT_ALLOWED
			if (ClientPrefs.data.useSScriptCompat) {
				trace('SScript (Psych 0.7.x) initializing for: ${parent.scriptName}');
				SScriptCompat.initHaxeModule(parent);
				return;
			}
			#end
			
			trace('HScript (Psych 1.0.x) initializing for: ${parent.scriptName}');
			parent.hscript = new HScript(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
	{
		// Check if user wants SScript compatibility mode
		#if SSCRIPT_ALLOWED
		if (ClientPrefs.data.useSScriptCompat) {
			SScriptCompat.initHaxeModuleCode(parent, code, varsToBring);
			return;
		}
		#end
		
		var hs:HScript = try parent.hscript catch (e) null;
		if(hs == null)
		{
			trace('HScript (Psych 1.0.x) initializing for: ${parent.scriptName}');
			try {
				parent.hscript = new HScript(parent, code, varsToBring);
			}
			catch(e:IrisError) {
				var pos:HScriptInfos = cast {fileName: parent.scriptName, isLua: true};
				if(parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				Iris.error(Printer.errorToString(e, false), pos);
				parent.hscript = null;
			}
		}
		else
		{
			try
			{
				hs.scriptCode = code;
				hs.varsToBring = varsToBring;
				hs.parse(true);
				var ret:Dynamic = hs.execute();
				hs.returnValue = ret;
			}
			catch(e:IrisError)
			{
				var pos:HScriptInfos = cast hs.interp.posInfos();
				pos.isLua = true;
				if(parent.lastCalledFunction != '') pos.funcName = parent.lastCalledFunction;
				Iris.error(Printer.errorToString(e, false), pos);
				hs.returnValue = null;
			}
		}
	}
	#end

	public var origin:String;
	override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null, ?manualRun:Bool = false)
	{
		if (file == null)
			file = '';

		filePath = file;
		if (filePath != null && filePath.length > 0)
		{
			this.origin = filePath;
			#if MODS_ALLOWED
			var myFolder:Array<String> = filePath.split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1]))) //is inside mods folder
				this.modFolder = myFolder[1];
			#end
		}
		var scriptThing:String = file;
		var scriptName:String = null;
		if(parent == null && file != null)
		{
			var f:String = file.replace('\\', '/');
			if(f.contains('/') && !f.contains('\n')) {
				scriptThing = File.getContent(f);
				scriptName = f;
			}
		}
		#if LUA_ALLOWED
		if (scriptName == null && parent != null)
			scriptName = parent.scriptName;
		#end
		super(scriptThing, new IrisConfig(scriptName, false, false));
		var customInterp:CustomInterp = new CustomInterp();
		customInterp.parentInstance = FlxG.state;
		customInterp.scriptName = scriptName != null ? scriptName : "Unknown";
		customInterp.showPosOnLog = false;
		this.interp = customInterp;
		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null)
		{
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end
		preset();
		this.varsToBring = varsToBring;
		if (!manualRun) {
			try {
				var ret:Dynamic = execute();
				returnValue = ret;
			} catch(e:IrisError) {
				returnValue = null;
				// Show error in debug text
				if(PlayState.instance != null) {
					var errorMsg = Printer.errorToString(e, false);
					PlayState.instance.addTextToDebug(errorMsg, FlxColor.RED);
				}
				// Relanzar la excepción para que PlayState pueda manejarla correctamente
				throw e;
			}
			catch(e:Dynamic) {
				returnValue = null;
				// Show warning in debug text
				if(PlayState.instance != null) {
					PlayState.instance.addTextToDebug('WARNING: $e', FlxColor.YELLOW);
				}
				// Relanzar la excepción para que PlayState pueda manejarla correctamente
				throw e;
			}
		}
	}

	var varsToBring(default, set):Any = null;
	override function preset() {
		super.preset();

		// Some very commonly used classes
		set('Type', Type);
		set('Map', haxe.ds.StringMap);
		#if sys
		set('File', File);
		set('FileSystem', FileSystem);
		#end
		set('FlxG', CustomFlxG);
		set('FlxMath', CustomFlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxText', flixel.text.FlxText);
		set('FlxTextAlign', CustomFlxTextAlign);
		set('FlxTextBorderStyle', CustomFlxTextBorderStyle);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', funkin.graphics.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);

		// Backwards compatibility: older mods expect a global `modchartTweens` map
		// that stores tweens by tag. Use the shared PlayState instance so all
		// scripts access the same map across the game (matches legacy behaviour).
		#if LUA_ALLOWED
		set('modchartTweens', PlayState.instance != null ? PlayState.instance.modchartTweens : null);
		#else
		set('modchartTweens', null);
		#end
		set('FlxFlicker', flixel.effects.FlxFlicker);
		set('FlxColor', CustomFlxColor);
		set('FlxAxes', CustomFlxAxes);
		set('FlxSpriteGroup', flixel.group.FlxSpriteGroup);
		set('FlxTypedGroup', flixel.group.FlxTypedGroup);
		set('FlxGroup', flixel.group.FlxGroup);
		set('Capabilities', openfl.system.Capabilities);
		set('RatioScaleMode', flixel.system.scaleModes.RatioScaleMode);
		set('Lib', openfl.Lib);
		#if windows
		set('WindowTweens', funkin.modding.scripting.psychlua.WindowTweens);
		#end
		set('Alphabet', funkin.ui.Alphabet);
		set('AlphaCharacter', funkin.ui.AlphaCharacter);
		set('Countdown', funkin.play.stage.BaseStage.Countdown);
		set('Language', funkin.ui.Language);
		set('Difficulty', funkin.data.Difficulty);
		set('WeekData', funkin.data.story.level.WeekData);
		#if DISCORD_ALLOWED
		set('Discord', funkin.api.discord.DiscordClient);
		#end
		set('ModState', funkin.modding.ModState);
		set('PlayState', PlayState);
		set('TitleState', funkin.ui.title.TitleState);
		set('MainMenuState', funkin.ui.mainmenu.MainMenuState);
		set('FreeplayState', funkin.ui.freeplay.FreeplayState);
		set('StoryMenuState', funkin.ui.story.StoryMenuState);
		set('LoadingState', funkin.ui.LoadingState);
		set('CreditsState', funkin.ui.credits.CreditsState);
		set('AchievementsMenuState', funkin.ui.AchievementsMenuState);
		set('MusicBeatState', MusicBeatState);
		set('GameplayChangersSubstate', funkin.ui.options.GameplayChangersSubstate);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
		set('Highscore', funkin.save.Highscore);
		set('Song', funkin.data.song.Song);
		#if ACHIEVEMENTS_ALLOWED
		set('Achievements', Achievements);
		#end
		set('Character', Character);
		set('Alphabet', Alphabet);
		set('Note', funkin.play.notes.Note);
		set('CustomSubstate', CustomSubstate);
		#if (!flash && sys)
		set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		set('ErrorHandledRuntimeShader', funkin.graphics.shaders.ErrorHandledShader.ErrorHandledRuntimeShader);
		#end
		set('ShaderFilter', openfl.filters.ShaderFilter);
		set('StringTools', StringTools);
		#if flxanimate
		set('FlxAnimate', FlxAnimate);
		#end
		#if (hxvlc)
		set('VideoSprite', funkin.graphics.VideoSprite);
		set('FlxVideoSprite', hxvlc.flixel.FlxVideoSprite);
		set('FlxVideo', hxvlc.flixel.FlxVideo);
		// Compatibilidad con versiones anteriores
		set('VideoHandler', funkin.graphics.video.v2.VideoHandler);
		set('MP4Handler', funkin.graphics.video.v3.MP4Handler);
		#end
		// Functions & Variables
		set('setVar', function(name:String, value:Dynamic) {
			MusicBeatState.getVariables().set(name, value);
			
			return value;
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			
			if(exists(name)) {
				result = get(name);
			}
			else if(MusicBeatState.getVariables().exists(name)) {
				result = MusicBeatState.getVariables().get(name);
			}
			return result;
		});
		set('removeVar', function(name:String)
		{
			var removed = false;
			if(MusicBeatState.getVariables().exists(name))
			{
				MusicBeatState.getVariables().remove(name);
				removed = true;
				trace('HScript: Removed variable: $name');
			}
			return removed;
		});
		set('debugPrint', function(text:String, ?color:FlxColor = null) {
			if(color == null) color = FlxColor.WHITE;
			PlayState.instance.addTextToDebug(text, color);
		});
		set('getModSetting', function(saveTag:String, ?modName:String = null) {
			if(modName == null)
			{
				if(this.modFolder == null)
				{
					Iris.error('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', this.interp.posInfos());
					return null;
				}
				modName = this.modFolder;
			}
			return LuaUtils.getModSetting(saveTag, modName);
		});

		// Keyboard & Gamepads
		set('keyboardJustPressed', function(name:String) return Reflect.getProperty(FlxG.keys.justPressed, name));
		set('keyboardPressed', function(name:String) return Reflect.getProperty(FlxG.keys.pressed, name));
		set('keyboardReleased', function(name:String) return Reflect.getProperty(FlxG.keys.justReleased, name));

		set('anyGamepadJustPressed', function(name:String) return FlxG.gamepads.anyJustPressed(name));
		set('anyGamepadPressed', function(name:String) FlxG.gamepads.anyPressed(name));
		set('anyGamepadReleased', function(name:String) return FlxG.gamepads.anyJustReleased(name));

		set('gamepadAnalogX', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadAnalogY', function(id:Int, ?leftStick:Bool = true)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return 0.0;

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});
		set('gamepadJustPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justPressed, name) == true;
		});
		set('gamepadPressed', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.pressed, name) == true;
		});
		set('gamepadReleased', function(id:Int, name:String)
		{
			var controller = FlxG.gamepads.getByID(id);
			if (controller == null) return false;

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		set('keyJustPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_P;
				case 'down': return Controls.instance.NOTE_DOWN_P;
				case 'up': return Controls.instance.NOTE_UP_P;
				case 'right': return Controls.instance.NOTE_RIGHT_P;
				default: return Controls.instance.justPressed(name);
			}
			return false;
		});
		set('keyPressed', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT;
				case 'down': return Controls.instance.NOTE_DOWN;
				case 'up': return Controls.instance.NOTE_UP;
				case 'right': return Controls.instance.NOTE_RIGHT;
				default: return Controls.instance.pressed(name);
			}
			return false;
		});
		set('keyReleased', function(name:String = '') {
			name = name.toLowerCase();
			switch(name) {
				case 'left': return Controls.instance.NOTE_LEFT_R;
				case 'down': return Controls.instance.NOTE_DOWN_R;
				case 'up': return Controls.instance.NOTE_UP_R;
				case 'right': return Controls.instance.NOTE_RIGHT_R;
				default: return Controls.instance.justReleased(name);
			}
			return false;
		});

		// For adding your own callbacks
		// not very tested but should work
		#if LUA_ALLOWED
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);

			FunkinLua.customFunctions.set(name, func);
		});

		// this one was tested
		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			
			if(funk != null) funk.addLocalCallback(name, func);
			else Iris.error('createCallback ($name): 3rd argument is null', this.interp.posInfos());
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';
		
				var className = str + libName;
				var resolvedClass = StructureOld.resolveClass(className);
				set(libName, resolvedClass);
			}
			catch (e:IrisError) {
				Iris.error(Printer.errorToString(e, false), this.interp.posInfos());
			}
		});
		#if LUA_ALLOWED
		set('parentLua', parentLua);

		set("addTouchPad", (DPadMode:String, ActionMode:String) -> {
			PlayState.instance.makeLuaTouchPad(DPadMode, ActionMode);
			PlayState.instance.addLuaTouchPad();
		  });
  
		set("removeTouchPad", () -> {
			PlayState.instance.removeLuaTouchPad();
		});
  
		set("addTouchPadCamera", () -> {
			if(PlayState.instance.luaTouchPad == null){
				FunkinLua.luaTrace('addTouchPadCamera: TPAD does not exist.');
				return;
			}
			PlayState.instance.addLuaTouchPadCamera();
		});
  
		set("touchPadJustPressed", function(button:Dynamic):Bool {
			if(PlayState.instance.luaTouchPad == null){
			  //FunkinLua.luaTrace('touchPadJustPressed: TPAD does not exist.');
			  return false;
			}
		  return PlayState.instance.luaTouchPadJustPressed(button);
		});
  
		set("touchPadPressed", function(button:Dynamic):Bool {
			if(PlayState.instance.luaTouchPad == null){
				//FunkinLua.luaTrace('touchPadPressed: TPAD does not exist.');
				return false;
			}
			return PlayState.instance.luaTouchPadPressed(button);
		});
  
		set("touchPadJustReleased", function(button:Dynamic):Bool {
			if(PlayState.instance.luaTouchPad == null){
				//FunkinLua.luaTrace('touchPadJustReleased: TPAD does not exist.');
				return false;
			}
			return PlayState.instance.luaTouchPadJustReleased(button);
		});
		#else
		set('parentLua', null);
		#end
		set('this', this);
		set('game', FlxG.state);
		set('state', FlxG.state);
		set('controls', Controls.instance);

		set('buildTarget', LuaUtils.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('Function_StopLua', LuaUtils.Function_StopLua); //doesnt do much cuz HScript has a lower priority than Lua
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		
		// Auto-resolution configuration functions
		set('addAutoImportPackage', function(packageName:String) {
			if(!CustomInterp.autoImportPackages.contains(packageName)) {
				CustomInterp.autoImportPackages.push(packageName);
			}
		});
		set('removeAutoImportPackage', function(packageName:String) {
			CustomInterp.autoImportPackages.remove(packageName);
		});
		set('addClassBlacklist', function(className:String) {
			if(!CustomInterp.classBlacklist.contains(className)) {
				CustomInterp.classBlacklist.push(className);
			}
		});
		set('removeClassBlacklist', function(className:String) {
			CustomInterp.classBlacklist.remove(className);
		});
		set('setAutoResolveClasses', function(enabled:Bool) {
			CustomInterp.autoResolveClasses = enabled;
		});
		set('clearClassCache', function() {
			CustomInterp._classCache.clear();
		});
		
		// Scripted classes support functions
		set('registerScriptClass', function(path:String) {
			try {
				ScriptClassManager.registerScriptClassByPath(path);
				debugPrint('Registered scripted class from: $path', FlxColor.GREEN);
			} catch(e:Dynamic) {
				debugPrint('Error registering scripted class: $e', FlxColor.RED);
			}
		});
		set('registerScriptClassCode', function(code:String, ?name:String = 'ScriptedClass') {
			try {
				ScriptClassManager.registerScriptClassByString(code, name);
				debugPrint('Registered scripted class: $name', FlxColor.GREEN);
			} catch(e:Dynamic) {
				debugPrint('Error registering scripted class: $e', FlxColor.RED);
			}
		});
		set('addScriptClassImport', function(className:String, classRef:Class<Dynamic>) {
			ScriptClassManager.defaultImports.set(className, classRef);
		});
		set('addScriptClassOverride', function(className:String, classRef:Class<Dynamic>) {
			ScriptClassManager.scriptClassOverrides.set(className, classRef);
		});
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			initHaxeModuleCode(funk, codeToRun, varsToBring);
			if (funk.hscript != null)
			{
				final retVal:IrisCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null)
				{
					return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
				}
				else if (funk.hscript.returnValue != null)
				{
					return funk.hscript.returnValue;
				}
			}
			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			if (funk.hscript != null)
			{
				final retVal:IrisCall = funk.hscript.call(funcToRun, funcArgs);
				if (retVal != null)
				{
					return (LuaUtils.isLuaSupported(retVal.returnValue)) ? retVal.returnValue : null;
				}
			}
			else
			{
				var pos:HScriptInfos = cast {fileName: funk.scriptName, showLine: false};
				if (funk.lastCalledFunction != '') pos.funcName = funk.lastCalledFunction;
				Iris.error("runHaxeFunction: HScript has not been initialized yet! Use \"runHaxeCode\" to initialize it", pos);
			}
			return null;
		});
		// This function is unnecessary because import already exists in HScript as a native feature
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if (libPackage.length > 0)
				str = libPackage + '.';
			else if (libName == null)
				libName = '';

			var className = str + libName;
			var c:Dynamic = StructureOld.resolveClass(className);

			if (c == null)
				c = Type.resolveEnum(className);
			

			if (funk.hscript == null)
				initHaxeModule(funk);

			var pos:HScriptInfos = cast funk.hscript.interp.posInfos();
			pos.showLine = false;
			if (funk.lastCalledFunction != '')
				 pos.funcName = funk.lastCalledFunction;

			try {
				if (c != null)
					funk.hscript.set(libName, c);
			}
			catch (e:IrisError) {
				Iris.error(Printer.errorToString(e, false), pos);
			}
			FunkinLua.lastCalledScript = funk;
			if (FunkinLua.getBool('luaDebugMode') && FunkinLua.getBool('luaDeprecatedWarnings'))
				Iris.warn("addHaxeLibrary is deprecated! Import classes through \"import\" in HScript!", pos);
		});
	}
	#end

	override function call(funcToRun:String, ?args:Array<Dynamic>):IrisCall {
		if (funcToRun == null || interp == null) return null;

		if (!exists(funcToRun)) {
			Iris.error('No function named: $funcToRun', this.interp.posInfos());
			return null;
		}

		try {
			var func:Dynamic = interp.variables.get(funcToRun); // function signature
			final ret = Reflect.callMethod(null, func, args ?? []);
			return {funName: funcToRun, signature: func, returnValue: ret};
		}
		catch(e:IrisError) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			#if LUA_ALLOWED
			if (parentLua != null)
			{
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			#end
			Iris.error(Printer.errorToString(e, false), pos);
		}
		catch (e:ValueException) {
			var pos:HScriptInfos = cast this.interp.posInfos();
			pos.funcName = funcToRun;
			#if LUA_ALLOWED
			if (parentLua != null)
			{
				pos.isLua = true;
				if (parentLua.lastCalledFunction != '') pos.funcName = parentLua.lastCalledFunction;
			}
			#end
			Iris.error('$e', pos);
		}
		return null;
	}

	override public function destroy()
	{
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end
		super.destroy();
	}

	function set_varsToBring(values:Any) {
		if (varsToBring != null)
			for (key in Reflect.fields(varsToBring))
				if (exists(key.trim()))
					interp.variables.remove(key.trim());

		if (values != null)
		{
			for (key in Reflect.fields(values))
			{
				key = key.trim();
				set(key, Reflect.field(values, key));
			}
		}

		return varsToBring = values;
	}
}

class CustomFlxG {
	// Propiedades principales de FlxG
	public static var state(get, never):Dynamic;
	public static var game(get, never):Dynamic;
	public static var sound(get, never):Dynamic;
	public static var stage(get, never):Dynamic;
	public static var cameras(get, never):Dynamic;
	public static var camera(get, never):Dynamic;
	public static var keys(get, never):Dynamic;
	public static var mouse(get, never):Dynamic;
	public static var gamepads(get, never):Dynamic;
	public static var width(get, never):Int;
	public static var height(get, never):Int;
	public static var autoPause(get, set):Bool;
	public static var signals(get, never):Dynamic;
	public static var random(get, never):Dynamic;
	
	// Getters para propiedades
	static function get_state():Dynamic return FlxG.state;
	static function get_game():Dynamic return FlxG.game;
	static function get_sound():Dynamic return FlxG.sound;
	static function get_stage():Dynamic return FlxG.stage;
	static function get_cameras():Dynamic return FlxG.cameras;
	static function get_camera():Dynamic return FlxG.camera;
	static function get_keys():Dynamic return FlxG.keys;
	static function get_mouse():Dynamic return FlxG.mouse;
	static function get_gamepads():Dynamic return FlxG.gamepads;
	static function get_width():Int return FlxG.width;
	static function get_height():Int return FlxG.height;
	static function get_autoPause():Bool return FlxG.autoPause;
	static function set_autoPause(value:Bool):Bool return FlxG.autoPause = value;
	static function get_signals():Dynamic return FlxG.signals;
	static function get_random():Dynamic return FlxG.random;
	
	// Funciones de compatibilidad para mods antiguos
	public static function addChildBelowMouse(object:Dynamic, ?IndexModifier:Int = 0):Void {
		funkin.util.FlxGUtils.addChildBelowMouse(object, IndexModifier);
	}
	
	public static function removeChild(object:Dynamic):Void {
		funkin.util.FlxGUtils.removeChild(object);
	}
	
	// Delegación de métodos principales de FlxG
	public static function switchState(nextState:flixel.FlxState):Void {
		FlxG.switchState(nextState);
	}
	
	public static function resetState():Void {
		FlxG.resetState();
	}
}

class CustomFlxMath {
	// Funciones matemáticas más usadas
	public static inline function lerp(a:Float, b:Float, ratio:Float):Float
		return flixel.math.FlxMath.lerp(a, b, ratio);
	
	public static inline function bound(value:Float, min:Float, max:Float):Float
		return flixel.math.FlxMath.bound(value, min, max);
	
	public static inline function wrap(value:Int, min:Int, max:Int):Int
		return flixel.math.FlxMath.wrap(value, min, max);
	
	public static inline function remapToRange(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
		return flixel.math.FlxMath.remapToRange(value, start1, stop1, start2, stop2);
	
	public static inline function roundDecimal(value:Float, precision:Int):Float
		return flixel.math.FlxMath.roundDecimal(value, precision);
	
	public static inline function isDistanceWithin(spriteA:flixel.FlxSprite, spriteB:flixel.FlxSprite, distance:Float, ?includeScale:Bool = false):Bool
		return flixel.math.FlxMath.isDistanceWithin(spriteA, spriteB, distance, includeScale);
	
	public static inline function distanceBetween(spriteA:flixel.FlxSprite, spriteB:flixel.FlxSprite):Float
		return flixel.math.FlxMath.distanceBetween(spriteA, spriteB);
	
	public static inline function equal(a:Float, b:Float, precision:Float = 0.0000001):Bool
		return flixel.math.FlxMath.equal(a, b, precision);
	
	public static inline function min(a:Float, b:Float):Float
		return flixel.math.FlxMath.MIN_VALUE_FLOAT;
	
	public static inline function max(a:Float, b:Float):Float
		return flixel.math.FlxMath.MAX_VALUE_FLOAT;
	
	public static inline function minInt(a:Int, b:Int):Int
		return flixel.math.FlxMath.minInt(a, b);
	
	public static inline function maxInt(a:Int, b:Int):Int
		return flixel.math.FlxMath.maxInt(a, b);
	
	public static inline function absInt(value:Int):Int
		return flixel.math.FlxMath.absInt(value);
	
	public static inline function signOf(value:Float):Int
		return flixel.math.FlxMath.signOf(value);
	
	public static inline function inBounds(value:Float, min:Float, max:Float):Bool
		return flixel.math.FlxMath.inBounds(value, min, max);
}

class CustomFlxColor {
	public static var TRANSPARENT(default, null):Int = FlxColor.TRANSPARENT;
	public static var BLACK(default, null):Int = FlxColor.BLACK;
	public static var WHITE(default, null):Int = FlxColor.WHITE;
	public static var GRAY(default, null):Int = FlxColor.GRAY;

	public static var GREEN(default, null):Int = FlxColor.GREEN;
	public static var LIME(default, null):Int = FlxColor.LIME;
	public static var YELLOW(default, null):Int = FlxColor.YELLOW;
	public static var ORANGE(default, null):Int = FlxColor.ORANGE;
	public static var RED(default, null):Int = FlxColor.RED;
	public static var PURPLE(default, null):Int = FlxColor.PURPLE;
	public static var BLUE(default, null):Int = FlxColor.BLUE;
	public static var BROWN(default, null):Int = FlxColor.BROWN;
	public static var PINK(default, null):Int = FlxColor.PINK;
	public static var MAGENTA(default, null):Int = FlxColor.MAGENTA;
	public static var CYAN(default, null):Int = FlxColor.CYAN;

	public static function fromInt(Value:Int):Int 
		return cast FlxColor.fromInt(Value);

	public static function fromRGB(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255):Int
		return cast FlxColor.fromRGB(Red, Green, Blue, Alpha);

	public static function fromRGBFloat(Red:Float, Green:Float, Blue:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromRGBFloat(Red, Green, Blue, Alpha);

	public static inline function fromCMYK(Cyan:Float, Magenta:Float, Yellow:Float, Black:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromCMYK(Cyan, Magenta, Yellow, Black, Alpha);

	public static function fromHSB(Hue:Float, Sat:Float, Brt:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSB(Hue, Sat, Brt, Alpha);

	public static function fromHSL(Hue:Float, Sat:Float, Light:Float, Alpha:Float = 1):Int
		return cast FlxColor.fromHSL(Hue, Sat, Light, Alpha);

	public static function fromString(str:String):Int
		return cast FlxColor.fromString(str);
	
	public static function interpolate(Color1:Int, Color2:Int, Factor:Float = 0.5):Int
		return cast FlxColor.interpolate(Color1, Color2, Factor);
	
	public static function gradient(Color1:Int, Color2:Int, Steps:Int, ?Ease:Float->Float):Array<Int>
		return cast FlxColor.gradient(Color1, Color2, Steps, Ease);
}

class CustomFlxAxes {
	public static var X(default, null):flixel.util.FlxAxes = flixel.util.FlxAxes.X;
	public static var Y(default, null):flixel.util.FlxAxes = flixel.util.FlxAxes.Y;
	public static var XY(default, null):flixel.util.FlxAxes = flixel.util.FlxAxes.XY;
}

class CustomFlxTextAlign {
	public static var LEFT(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.LEFT;
	public static var CENTER(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.CENTER;
	public static var RIGHT(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.RIGHT;
	public static var JUSTIFY(default, null):flixel.text.FlxText.FlxTextAlign = flixel.text.FlxText.FlxTextAlign.JUSTIFY;
}

class CustomFlxTextBorderStyle {
	public static var NONE(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.NONE;
	public static var SHADOW(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.SHADOW;
	public static var OUTLINE(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.OUTLINE;
	public static var OUTLINE_FAST(default, null):flixel.text.FlxText.FlxTextBorderStyle = flixel.text.FlxText.FlxTextBorderStyle.OUTLINE_FAST;
}

class CustomInterp extends InterpEx
{
	public var parentInstance(default, set):Dynamic = [];
	public var scriptName:String = "Unknown";
	private var _instanceFields:Array<String>;
	
	// Auto-resolution settings
	public static var autoResolveClasses:Bool = true; // Enable automatic class resolution
	public static var autoImportPackages:Array<String> = [
		"flixel",
		"flixel.util",
		"flixel.tweens",
		"flixel.text",
		"flixel.group",
		"flixel.effects",
		"flixel.addons",
		"flixel.math",
		"flixel.system",
		"openfl",
		"openfl.filters",
		"openfl.system",
		"funkin",
		"funkin.play",
		"funkin.ui",
		"funkin.data",
		"funkin.graphics",
		"funkin.modding",
		"funkin.util",
		"funkin.save"
	];
	
	// Blacklist for security: packages/classes that should NOT be auto-resolved
	public static var classBlacklist:Array<String> = [
		"sys.io",
		"sys.FileSystem",
		"Sys",
		"haxe.macro",
		"polymod",
		"hscript"
	];
	
	// Cache for resolved classes to improve performance
	private static var _classCache:Map<String, Class<Dynamic>> = new Map();
	
	function set_parentInstance(inst:Dynamic):Dynamic
	{
		parentInstance = inst;
		if(parentInstance == null)
		{
			_instanceFields = [];
			return inst;
		}
		_instanceFields = Type.getInstanceFields(Type.getClass(inst));
		return inst;
	}

	public function new()
	{
		// Initialize InterpEx with null target class and proxy
		// This allows scripted classes to work while maintaining compatibility
		super(null, null);
	}
	
	/**
	 * Override to resolve classes with backwards compatibility support.
	 * Handles: scripted classes, backwards compatibility, and regular classes.
	 */
	override function cnew(className:String, args:Array<Dynamic>):Dynamic {
		// First, try InterpEx (scripted classes)
		// This will check if className is a registered scripted class
		try {
			var scriptedInstance = super.cnew(className, args);
			if (scriptedInstance != null) {
				return scriptedInstance;
			}
		} catch(e:Dynamic) {
			// Not a scripted class, continue with regular resolution
		}
		
		// Try to resolve with backwards compatibility
		var resolvedClass = StructureOld.resolveClass(className);
		if (resolvedClass != null) {
			return Type.createInstance(resolvedClass, args);
		}
		
		// Try direct Type.resolveClass as last resort
		var directClass = Type.resolveClass(className);
		if (directClass != null) {
			return Type.createInstance(directClass, args);
		}
		
		// If nothing works, throw error
		error(EUnknownVariable(className));
		return null;
	}
	
	/**
	 * Automatically resolve a class by name.
	 * Tries to find the class in common packages and handles backwards compatibility.
	 */
	private function autoResolveClass(className:String):Class<Dynamic> {
		if(!autoResolveClasses) return null;
		
		// Check cache first
		if(_classCache.exists(className)) {
			return _classCache.get(className);
		}
		
		// Check blacklist
		for(blacklisted in classBlacklist) {
			if(className.indexOf(blacklisted) == 0) {
				return null; // Blacklisted package/class
			}
		}
		
		// Try to resolve with StructureOld (handles backwards compatibility)
		var resolvedClass = StructureOld.resolveClass(className);
		if(resolvedClass != null) {
			_classCache.set(className, resolvedClass);
			return resolvedClass;
		}
		
		// Try direct resolution
		var directClass = Type.resolveClass(className);
		if(directClass != null) {
			_classCache.set(className, directClass);
			return directClass;
		}
		
		// Try with auto-import packages
		for(pkg in autoImportPackages) {
			var fullClassName = pkg + "." + className;
			
			// Check blacklist for full path
			var isBlacklisted = false;
			for(blacklisted in classBlacklist) {
				if(fullClassName.indexOf(blacklisted) == 0) {
					isBlacklisted = true;
					break;
				}
			}
			if(isBlacklisted) continue;
			
			// Try with StructureOld first (backwards compatibility)
			var pkgClass = StructureOld.resolveClass(fullClassName);
			if(pkgClass != null) {
				_classCache.set(className, pkgClass);
				return pkgClass;
			}
			
			// Try direct resolution
			pkgClass = Type.resolveClass(fullClassName);
			if(pkgClass != null) {
				_classCache.set(className, pkgClass);
				return pkgClass;
			}
		}
		
		return null;
	}

	override function fcall(o:Dynamic, funcToRun:String, args:Array<Dynamic>):Dynamic {
		// Capturar null reference antes de continuar
		if (o == null) {
			// Silently return null to avoid spam
			return null;
		}

		for (_using in usings) {
			var v = _using.call(o, funcToRun, args);
			if (v != null)
				return v;
		}

		var f = get(o, funcToRun);

		if (f == null) {
			// Silently return null to avoid spam
			return null;
		}

		// Manejo especial para Maps y sus métodos
		if (Std.isOfType(o, haxe.Constraints.IMap)) {
			var map:haxe.Constraints.IMap<Dynamic, Dynamic> = cast o;
			// Llamar directamente a los métodos del Map para evitar problemas de binding
			switch(funcToRun) {
				case "exists":
					return map.exists(args[0]);
				case "get":
					return map.get(args[0]);
				case "set":
					map.set(args[0], args[1]);
					return args[1];
				case "remove":
					return map.remove(args[0]);
				case "keys":
					return map.keys();
				case "iterator":
					return map.iterator();
				case "clear":
					map.clear();
					return null;
				case "toString":
					return map.toString();
			}
		}

		// Para otros objetos, usar Reflect.callMethod normalmente
		return Reflect.callMethod(o, f, args);
	}

	override function resolve(id: String): Dynamic {
		if (locals.exists(id)) {
			var l = locals.get(id);
			return l.r;
		}

		if (variables.exists(id)) {
			var v = variables.get(id);
			return v;
		}

		if (imports.exists(id)) {
			var v = imports.get(id);
			return v;
		}

		if(parentInstance != null && _instanceFields.contains(id)) {
			var v = Reflect.getProperty(parentInstance, id);
			return v;
		}

		// Compatibilidad: buscar en variables globales antes de dar error
		if(MusicBeatState.getVariables().exists(id)) {
			return MusicBeatState.getVariables().get(id);
		}
		
		if(MusicBeatState.getVideoHandlers().exists(id)) {
			return MusicBeatState.getVideoHandlers().get(id);
		}
		
		// Auto-resolve classes if enabled
		if(autoResolveClasses) {
			var resolvedClass = autoResolveClass(id);
			if(resolvedClass != null) {
				// Cache it in variables for next access
				variables.set(id, resolvedClass);
				return resolvedClass;
			}
			
			// Try to resolve as enum
			var resolvedEnum = Type.resolveEnum(id);
			if(resolvedEnum != null) {
				// Check blacklist
				var isBlacklisted = false;
				for(blacklisted in classBlacklist) {
					if(id.indexOf(blacklisted) == 0) {
						isBlacklisted = true;
						break;
					}
				}
				if(!isBlacklisted) {
					variables.set(id, resolvedEnum);
					return resolvedEnum;
				}
			}
		}

		error(EUnknownVariable(id));

		return null;
	}
	
	override function get(o:Dynamic, field:String):Dynamic {
		// Si el objeto es null, mostrar warning en lugar de crashear
		if (o == null) {
			// Fallback: buscar en variables globales como última opción
			if(MusicBeatState.getVariables().exists(field)) {
				return MusicBeatState.getVariables().get(field);
			}
			if(MusicBeatState.getVideoHandlers().exists(field)) {
				return MusicBeatState.getVideoHandlers().get(field);
			}
			// Mostrar warning en lugar de error
			var warnMsg = 'Null reference: trying to access "$field" on null object';
			if(PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING ($scriptName): $warnMsg', FlxColor.YELLOW);
			trace('WARNING ($scriptName): $warnMsg');
			return null;
		}
		
		// Verificar si es un Map primero (compatible con SScript)
		// Importante: Acceder a métodos del Map como 'exists', 'get', 'set', etc.
		if (Std.isOfType(o, haxe.Constraints.IMap)) {
			// Si se busca un método del Map, devolverlo usando Reflect.field directamente
			if (field == "exists" || field == "get" || field == "set" || field == "remove" || 
			    field == "keys" || field == "iterator" || field == "toString" || field == "clear" ||
			    field == "copy") {
				// IMPORTANTE: Usar Reflect.field para métodos de Maps
				var method = Reflect.field(o, field);
				if (method != null) return method;
			}
			// Si no es un método, tratar como acceso a key del Map
			var map:haxe.Constraints.IMap<String, Dynamic> = cast o;
			if (map.exists(field))
				return map.get(field);
			return null; // Maps devuelven null si no existe la key
		}
		
		// Intentar acceso directo primero (más rápido y funciona con fields privados como _cache)
		try {
			var value = Reflect.field(o, field);
			if (value != null) return value;
		} catch(e:Dynamic) {}
		
		// Verificar si el objeto tiene el field declarado (incluyendo privados)
		if (Reflect.hasField(o, field)) {
			try {
				return Reflect.field(o, field);
			} catch(e:Dynamic) {
				// Si falla field, intentar property
				try {
					return Reflect.getProperty(o, field);
				} catch(e2:Dynamic) {}
			}
		}
		
		// Verificar si es una propiedad o método de la clase
		var classType = Type.getClass(o);
		if (classType != null) {
			var instanceFields = Type.getInstanceFields(classType);
			if (instanceFields != null && instanceFields.contains(field)) {
				// El field/método existe en la clase
				try {
					// Intentar field directo primero
					var value = Reflect.field(o, field);
					if (value != null) return value;
					
					// Si es null, intentar getProperty (para getters)
					return Reflect.getProperty(o, field);
				} catch(e:Dynamic) {
					// Si falla, buscar en variables globales como fallback
					if(MusicBeatState.getVariables().exists(field))
						return MusicBeatState.getVariables().get(field);
					
					if(MusicBeatState.getVideoHandlers().exists(field))
						return MusicBeatState.getVideoHandlers().get(field);
					
					return null; // Devolver null en lugar de error para compatibilidad
				}
			}
		}
		
		// Si llegamos aquí, el field no existe en la clase
		// Compatibilidad: buscar en variables globales antes de dar error
		if(MusicBeatState.getVariables().exists(field)) {
			return MusicBeatState.getVariables().get(field);
		}
		
		if(MusicBeatState.getVideoHandlers().exists(field)) {
			return MusicBeatState.getVideoHandlers().get(field);
		}
		
		// Para compatibilidad con objetos dinámicos/anónimos, intentar getProperty
		try {
			var value = Reflect.getProperty(o, field);
			if (value != null) return value;
		} catch(e:Dynamic) {}
		
		// Último intento: acceso a fields privados/dinámicos con Reflect.field
		try {
			var value = Reflect.field(o, field);
			if (value != null) return value;
		} catch(e:Dynamic) {}
		
		// Si todo falla, devolver null para compatibilidad (no lanzar error)
		return null;
	}
	
	override function set(o:Dynamic, field:String, value:Dynamic):Dynamic {
		// Si el objeto es null, mostrar warning y guardar en variables globales
		if (o == null) {
			// Silently save to global variables to avoid spam
			
			// Fallback: guardar en variables globales
			var className = try Type.getClassName(Type.getClass(value)) catch(e:Dynamic) null;
			if (className == "objects.VideoHandler" || className == "objects.MP4Handler") {
				MusicBeatState.getVideoHandlers().set(field, value);
			} else {
				MusicBeatState.getVariables().set(field, value);
			}
			return value;
		}
		
		// Verificar si es un Map primero (compatible con SScript)
		if (Std.isOfType(o, haxe.Constraints.IMap)) {
			var map:haxe.Constraints.IMap<String, Dynamic> = cast o;
			map.set(field, value);
			return value;
		}
		
		// Verificar si el field ya existe como field directo
		if (Reflect.hasField(o, field)) {
			try {
				Reflect.setField(o, field, value);
				return value;
			} catch(e:Dynamic) {
				// Si falla setField, intentar setProperty
				try {
					Reflect.setProperty(o, field, value);
					return value;
				} catch(e2:Dynamic) {}
			}
		}
		
		// Verificar si es una propiedad (setter) de la clase
		var classType = Type.getClass(o);
		if (classType != null) {
			var instanceFields = Type.getInstanceFields(classType);
			if (instanceFields != null && instanceFields.contains(field)) {
				// El field existe en la clase, usar setProperty para manejar setters
				try {
					Reflect.setProperty(o, field, value);
					return value;
				} catch(e:Dynamic) {
					// Si setProperty falla, intentar setField
					try {
						Reflect.setField(o, field, value);
						return value;
					} catch(e2:Dynamic) {
						// Guardar en variables globales como fallback
						var className = try Type.getClassName(Type.getClass(value)) catch(e:Dynamic) null;
						if (className == "objects.VideoHandler" || className == "objects.MP4Handler") {
							MusicBeatState.getVideoHandlers().set(field, value);
						} else {
							MusicBeatState.getVariables().set(field, value);
						}
						return value;
					}
				}
			}
		}
		
		// Si llegamos aquí, el field no existe en la clase
		// Para objetos dinámicos/anónimos, intentar setProperty
		try {
			Reflect.setProperty(o, field, value);
			return value;
		} catch(e:Dynamic) {
			// Si falla, intentar setField
			try {
				Reflect.setField(o, field, value);
				return value;
			} catch(e2:Dynamic) {}
		}
		
		// Si todo falla, guardar en variables globales como fallback
		var className = try Type.getClassName(Type.getClass(value)) catch(e:Dynamic) null;
		if (className == "objects.VideoHandler" || className == "objects.MP4Handler") {
			MusicBeatState.getVideoHandlers().set(field, value);
		} else {
			MusicBeatState.getVariables().set(field, value);
		}
		return value;
	}
}
#else
class HScript
{
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			PlayState.instance.addTextToDebug('HScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}
	#end
}
#end
