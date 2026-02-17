package funkin.modding.scripting;

import funkin.play.character.Character;
import funkin.modding.scripting.psychlua.LuaUtils;
import funkin.modding.scripting.psychlua.CustomSubstate;
import funkin.modding.scripting.psychlua.ReflectionFunctions;
import funkin.util.StructureOld;

#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
#end

#if sys
import sys.FileSystem;
import sys.io.File;
#end

// Wrapper de compatibilidad para mods de Psych Engine 0.6.x - 0.7.3 que usan tea.SScript
#if SSCRIPT_ALLOWED
import tea.SScript;
import tea.SScript.TeaCall;

/**
 * Clase de compatibilidad para mods antiguos que usan SScript (0.6.x - 0.7.3)
 * Los mods nuevos deben usar HScript.hx que usa hscript-iris
 */
class SScriptCompat extends SScript
{
	public var modFolder:String;
	public var origin:String;

	// Handlers globales para warnings y errores de SScript
	public static var sscriptWarnHandler:Dynamic = null;
	public static var sscriptErrorHandler:Dynamic = null;
	// Contador de errores de SScript para estadísticas
	public static var sscript_Errors:Int = 0;

	#if LUA_ALLOWED
	public var parentLua:FunkinLua;
	
	public static function initHaxeModule(parent:FunkinLua)
	{
		if(parent.sscript == null)
		{
			trace('SScript (Psych 0.7.x) initializing for: ${parent.scriptName}');
			parent.sscript = new SScriptCompat(parent);
		}
	}

	public static function initHaxeModuleCode(parent:FunkinLua, code:String, ?varsToBring:Any = null)
	{
		var ss:SScriptCompat = try parent.sscript catch (e) null;
		if(ss == null)
		{
			trace('SScript (Psych 0.7.x) initializing for: ${parent.scriptName}');
			parent.sscript = new SScriptCompat(parent, code, varsToBring);
		}
		else
		{
			ss.doString(code);
			@:privateAccess
			if(ss.parsingException != null)
			{
				var errorMsg = ss.parsingException.message;
				PlayState.instance.addTextToDebug('ERROR ON LOADING (${ss.origin}): $errorMsg', FlxColor.RED);
				sscript_Errors++;
				if(sscriptErrorHandler != null) {
					sscriptErrorHandler(errorMsg, ss.origin);
				}
			}
		}
	}
	#end

	override public function new(?parent:Dynamic, ?file:String, ?varsToBring:Any = null)
	{
		if (file == null)
			file = '';

		this.varsToBring = varsToBring;
		
		super(file, false, false);

		#if LUA_ALLOWED
		parentLua = parent;
		if (parent != null)
		{
			this.origin = parent.scriptName;
			this.modFolder = parent.modFolder;
		}
		#end

		// Si es una ruta de archivo, cargar el contenido
		if (scriptFile != null && scriptFile.length > 0)
		{
			this.origin = scriptFile;
			
			#if MODS_ALLOWED
			var myFolder:Array<String> = scriptFile.split('/');
			if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
				this.modFolder = myFolder[1];
			#end
		}

		preset();
		execute();
	}

	var varsToBring:Any = null;
	override function preset() {
		super.preset();
		
		// Add Psych 0.7.3 style global imports using SScript.globalVariables
		// This makes these classes available to all SScript instances
		SScript.globalVariables.set('FlxG', flixel.FlxG);
		SScript.globalVariables.set('FlxSprite', flixel.FlxSprite);
		SScript.globalVariables.set('FlxCamera', flixel.FlxCamera);
		SScript.globalVariables.set('FlxTimer', flixel.util.FlxTimer);
		SScript.globalVariables.set('FlxTween', flixel.tweens.FlxTween);
		SScript.globalVariables.set('FlxEase', flixel.tweens.FlxEase);
		SScript.globalVariables.set('FlxSound', flixel.system.FlxSound);
		SScript.globalVariables.set('StringTools', StringTools);
		SScript.globalVariables.set('Math', Math);
		SScript.globalVariables.set('Std', Std);
		SScript.globalVariables.set('Reflect', Reflect);
		SScript.globalVariables.set('Type', Type);
		SScript.globalVariables.set('Paths', Paths);
		SScript.globalVariables.set('Conductor', Conductor);
		SScript.globalVariables.set('PlayState', PlayState);
		SScript.globalVariables.set('Character', Character);
		SScript.globalVariables.set('Alphabet', Alphabet);
		SScript.globalVariables.set('ClientPrefs', ClientPrefs);
		#if (!flash && sys)
		SScript.globalVariables.set('FlxRuntimeShader', flixel.addons.display.FlxRuntimeShader);
		SScript.globalVariables.set('ShaderFilter', openfl.filters.ShaderFilter);
		#end
		
		// Some very commonly used classes
		set('FlxG', flixel.FlxG);
		set('FlxMath', flixel.math.FlxMath);
		set('FlxSprite', flixel.FlxSprite);
		set('FlxCamera', flixel.FlxCamera);
		set('PsychCamera', funkin.graphics.PsychCamera);
		set('FlxTimer', flixel.util.FlxTimer);
		set('FlxTween', flixel.tweens.FlxTween);
		set('FlxEase', flixel.tweens.FlxEase);
		set('FlxColor', SScriptFlxColor);
		set('Countdown', funkin.play.stage.BaseStage.Countdown);
		set('PlayState', PlayState);
		set('Paths', Paths);
		set('Conductor', Conductor);
		set('ClientPrefs', ClientPrefs);
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
			try {
				MusicBeatState.getVariables().set(name, value);
				
			} catch(e:Dynamic) {
				var warnMsg = 'Null reference in setVar("$name"): ${e}';
				if(PlayState.instance != null)
					PlayState.instance.addTextToDebug('WARNING (${this.origin}): $warnMsg', FlxColor.YELLOW);
				trace('WARNING (${this.origin}): $warnMsg');
			}
			return value;
		});
		set('getVar', function(name:String) {
			var result:Dynamic = null;
			// Luego en variables globales
			if(MusicBeatState.getVariables().exists(name)) {
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
					PlayState.instance.addTextToDebug('getModSetting: Argument #2 is null and script is not inside a packed Mod folder!', FlxColor.RED);
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
		#if LUA_ALLOWED
		set('createGlobalCallback', function(name:String, func:Dynamic)
		{
			for (script in PlayState.instance.luaArray)
				if(script != null && script.lua != null && !script.closed)
					Lua_helper.add_callback(script.lua, name, func);

			FunkinLua.customFunctions.set(name, func);
		});

		set('createCallback', function(name:String, func:Dynamic, ?funk:FunkinLua = null)
		{
			if(funk == null) funk = parentLua;
			
			if(funk != null) funk.addLocalCallback(name, func);
			else PlayState.instance.addTextToDebug('createCallback ($name): 3rd argument is null', FlxColor.RED);
		});
		#end

		set('addHaxeLibrary', function(libName:String, ?libPackage:String = '') {
			try {
				var str:String = '';
				if(libPackage.length > 0)
					str = libPackage + '.';
				else if(libName == null)
					libName = '';

				var className = str + libName;
				var resolvedClass = StructureOld.resolveClass(className);
				set(libName, resolvedClass);
			}
			catch (e:Dynamic) {
				var msg:String = e.message.substr(0, e.message.indexOf('\n'));
				#if LUA_ALLOWED
				if(parentLua != null)
				{
					FunkinLua.lastCalledScript = parentLua;
					FunkinLua.luaTrace('$origin: ${parentLua.lastCalledFunction} - $msg', false, false, FlxColor.RED);
					return;
				}
				#end
				if(PlayState.instance != null) PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
				else trace('$origin - $msg');
			}
		});
		
		#if LUA_ALLOWED
		set('parentLua', parentLua);
		#else
		set('parentLua', null);
		#end
		set('this', this);
		set('game', FlxG.state);
		set('controls', Controls.instance);

		set('buildTarget', LuaUtils.getBuildTarget());
		set('customSubstate', CustomSubstate.instance);
		set('customSubstateName', CustomSubstate.name);

		set('Function_Stop', LuaUtils.Function_Stop);
		set('Function_Continue', LuaUtils.Function_Continue);
		set('Function_StopLua', LuaUtils.Function_StopLua);
		set('Function_StopHScript', LuaUtils.Function_StopHScript);
		set('Function_StopAll', LuaUtils.Function_StopAll);
		
		set('add', FlxG.state.add);
		set('insert', FlxG.state.insert);
		set('remove', FlxG.state.remove);

		if(PlayState.instance == FlxG.state)
		{
			set('addBehindGF', PlayState.instance.addBehindGF);
			set('addBehindDad', PlayState.instance.addBehindDad);
			set('addBehindBF', PlayState.instance.addBehindBF);
			setSpecialObject(PlayState.instance, false, []);
			
			// Psych 0.7.3 compatibility: Add camGame with null-safe wrappers
			set('camGame', PlayState.instance.camGame);
			set('camHUD', PlayState.instance.camHUD);
			set('camOther', PlayState.instance.camOther);
			
			// Add null-safe helper for old mods that expect canvas property
			set('addBehindBar', function(?spr:FlxSprite) {
				if(spr != null && PlayState.instance != null) {
					PlayState.instance.addBehindGF(spr);
				}
			});
		}

		if(varsToBring != null) {
			for (key in Reflect.fields(varsToBring)) {
				key = key.trim();
				var value = Reflect.field(varsToBring, key);
				set(key, Reflect.field(varsToBring, key));
			}
			varsToBring = null;
		}
	}

	/**
	 * Executes a function in this SScript instance.
	 * Simplified error handling based on Psych 0.7.3 style.
	 * @param funcToRun Function name to execute
	 * @param funcArgs Arguments to pass to the function
	 * @return TeaCall with execution result
	 */
	public function executeCode(?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):TeaCall {
		if (funcToRun == null) return null;

		if(!exists(funcToRun)) {
			// Silently ignore missing functions like Psych 0.7.3
			#if LUA_ALLOWED
			if(parentLua != null)
				FunkinLua.luaTrace('$origin - No HScript function named: $funcToRun', false, false, FlxColor.RED);
			else
			#end
				if(PlayState.instance != null)
					PlayState.instance.addTextToDebug('$origin - No HScript function named: $funcToRun', FlxColor.RED);
			
			return {
				succeeded: true,
				calledFunction: funcToRun,
				returnValue: null,
				exceptions: []
			};
		}

		// Wrap in try-catch to handle exceptions that occur before TeaCall is generated
		try {
			// Simplified error handling based on Psych 0.7.3
			if(funcArgs == null) funcArgs = [];
			
			final callValue = call(funcToRun, funcArgs);
			
			// Check if call succeeded (Psych 0.7.3 style)
			if (!callValue.succeeded && callValue.exceptions.length > 0)
			{
				final e = callValue.exceptions[0];
				if (e != null) {
					// Simple error message formatting like Psych 0.7.3
					var msg:String = e.toString();
					// Truncate to first line for cleaner output
					if(msg.indexOf('\n') != -1) {
						msg = msg.substr(0, msg.indexOf('\n'));
					}
					
					sscript_Errors++;
					
					#if LUA_ALLOWED
					if(parentLua != null) {
						final calledFunc:String = if(origin == parentLua.lastCalledFunction) funcToRun else parentLua.lastCalledFunction;
						FunkinLua.luaTrace('$origin:$calledFunc - $msg', false, false, FlxColor.RED);
						if(sscriptErrorHandler != null) {
							sscriptErrorHandler('$calledFunc - $msg', origin);
						}
					}
					else
					#end
					{
						if(PlayState.instance != null)
							PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
						if(sscriptErrorHandler != null) {
							sscriptErrorHandler(msg, origin);
						}
					}
				}
				return null;
			}
			
			return callValue;
		} catch(e:Dynamic) {
			// Catch exceptions that occur during call() itself (like null references)
			var msg:String = Std.string(e);
			
			// Handle SScript's crash messages (null references)
			if(msg.indexOf("sight imma head out") != -1 || msg.indexOf("Null references are stored") != -1) {
				// Extract more useful information from the stack if possible
				msg = "Null object reference - tried to access property/method on null object";
				if(funcToRun != null) {
					msg += " in function '" + funcToRun + "'";
				}
			}
			
			sscript_Errors++;
			
			#if LUA_ALLOWED
			if(parentLua != null) {
				final calledFunc:String = if(origin == parentLua.lastCalledFunction) funcToRun else parentLua.lastCalledFunction;
				FunkinLua.luaTrace('$origin:$calledFunc - $msg', false, false, FlxColor.RED);
				if(sscriptErrorHandler != null) {
					sscriptErrorHandler('$calledFunc - $msg', origin);
				}
			}
			else
			#end
			{
				if(PlayState.instance != null)
					PlayState.instance.addTextToDebug('$origin - $msg', FlxColor.RED);
				if(sscriptErrorHandler != null) {
					sscriptErrorHandler(msg, origin);
				}
			}
			
			return null;
		}
	}

	public function executeFunction(funcToRun:String = null, funcArgs:Array<Dynamic>):TeaCall {
		if (funcToRun == null) return null;
		return call(funcToRun, funcArgs);
	}

	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			initHaxeModuleCode(funk, codeToRun, varsToBring);
			if (funk.sscript != null)
			{
				final retVal:TeaCall = funk.sscript.executeCode(funcToRun, funcArgs);
				if (retVal != null) {
					if(retVal.succeeded)
						return (retVal.returnValue == null || LuaUtils.isOfTypes(retVal.returnValue, [Bool, Int, Float, String, Array])) ? retVal.returnValue : null;

					final e = retVal.exceptions[0];
					final calledFunc:String = if(funk.sscript.origin == funk.lastCalledFunction) funcToRun else funk.lastCalledFunction;
					if (e != null)
						FunkinLua.luaTrace(funk.sscript.origin + ":" + calledFunc + " - " + e.message.substr(0, e.message.indexOf('\n')), false, false, FlxColor.RED);
					return null;
				}
			}
			return null;
		});
		
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			if (funk.sscript != null)
			{
				try {
					var callValue = funk.sscript.executeFunction(funcToRun, funcArgs);
					if (callValue == null) return null;
					
					if (!callValue.succeeded)
					{
						var e = callValue.exceptions[0];
						if (e != null) {
							var msg = e.message;
							if(msg.indexOf('\n') != -1) {
								msg = msg.substr(0, msg.indexOf('\n'));
							}
							FunkinLua.luaTrace('ERROR (${funk.sscript.origin}: ${callValue.calledFunction}) - $msg', false, false, FlxColor.RED);
						}
						return null;
					}
					else
						return callValue.returnValue;
				} catch(e:Dynamic) {
					var msg:String = Std.string(e);
					// Handle SScript crash messages
					if(msg.indexOf("sight imma head out") != -1 || msg.indexOf("Null references are stored") != -1) {
						msg = "Null object reference in function '$funcToRun'";
					}
					FunkinLua.luaTrace('EXCEPTION (${funk.sscript.origin}:$funcToRun) - $msg', false, false, FlxColor.RED);
					return null;
				}
			}
			return null;
		});
		
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			var str:String = '';
			if(libPackage.length > 0)
				str = libPackage + '.';
			else if(libName == null)
				libName = '';

			var className = str + libName;
			var c:Dynamic = StructureOld.resolveClass(className);
			if (c == null)
				c = Type.resolveEnum(className);

			if (c != null)
				SScript.globalVariables[libName] = c;

			if (funk.sscript != null)
			{
				try {
					if (c != null)
						funk.sscript.set(libName, c);
				}
				catch (e:Dynamic) {
					FunkinLua.luaTrace(funk.sscript.origin + ":" + funk.lastCalledFunction + " - " + e, false, false, FlxColor.RED);
				}
			}
		});
	}
	#end

	override public function destroy()
	{
		origin = null;
		#if LUA_ALLOWED parentLua = null; #end

		super.destroy();
	}
}

class SScriptFlxColor {
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
#else
class SScriptCompat
{
	#if LUA_ALLOWED
	public static function implement(funk:FunkinLua) {
		funk.addLocalCallback("runHaxeCode", function(codeToRun:String, ?varsToBring:Any = null, ?funcToRun:String = null, ?funcArgs:Array<Dynamic> = null):Dynamic {
			PlayState.instance.addTextToDebug('SScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("runHaxeFunction", function(funcToRun:String, ?funcArgs:Array<Dynamic> = null) {
			PlayState.instance.addTextToDebug('SScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
		funk.addLocalCallback("addHaxeLibrary", function(libName:String, ?libPackage:String = '') {
			PlayState.instance.addTextToDebug('SScript is not supported on this platform!', FlxColor.RED);
			return null;
		});
	}
	#end
}
#end
