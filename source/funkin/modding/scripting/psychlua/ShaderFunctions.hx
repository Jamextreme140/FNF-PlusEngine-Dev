package funkin.modding.scripting.psychlua;

import flixel.FlxCamera;

#if (!flash && sys)
import flixel.addons.display.FlxRuntimeShader;
import openfl.filters.ShaderFilter;
#end

class ShaderFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		// Shader initialization - supports both legacy (0.7.3) and modern modes
		funk.addLocalCallback("initLuaShader", function(name:String, ?glslVersion:Int = 120) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return funk.initLuaShader(name, glslVersion);
			#else
			FunkinLua.luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		
		funk.addLocalCallback("setSpriteShader", function(obj:String, shader:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && sys)
			if(!funk.runtimeShaders.exists(shader) && !funk.initLuaShader(shader))
			{
				FunkinLua.luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				var arr:Array<String> = funk.runtimeShaders.get(shader);
				
				// Check if using legacy shader mode (Psych 0.7.3)
				if (ClientPrefs.data.legacyShaderInit) {
					// Psych 0.7.3 style: Direct FlxRuntimeShader, no error handling (crashes if fails, just like 0.7.3)
					leObj.shader = new flixel.addons.display.FlxRuntimeShader(arr[0], arr[1]);
				} else {
					// Modern mode: ErrorHandledRuntimeShader with ShaderCompatibility
					var adapted = funkin.graphics.shaders.ShaderCompatibility.adaptShaderCode(arr[0], arr[1]);
					leObj.shader = new funkin.graphics.shaders.ErrorHandledShader.ErrorHandledRuntimeShader(shader, adapted[0], adapted[1]);
				}
				return true;
			}
			#else
			FunkinLua.luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
			return false;
		});
		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String) {
			var split:Array<String> = obj.split('.');
			var leObj:FlxSprite = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				leObj = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(leObj != null) {
				leObj.shader = null;
				return true;
			}
			return false;
		});


		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBool(prop);
			#else
			FunkinLua.luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getBoolArray(prop);
			#else
			FunkinLua.luaTrace("getShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getInt(prop);
			#else
			FunkinLua.luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getIntArray(prop);
			#else
			FunkinLua.luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloat(prop);
			#else
			FunkinLua.luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});
		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null)
			{
				FunkinLua.luaTrace("getShaderFloatArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return null;
			}
			return shader.getFloatArray(prop);
			#else
			FunkinLua.luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});


		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBool: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBool(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderBoolArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setBoolArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderInt: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setInt(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderIntArray: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setIntArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderFloat: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}
			shader.setFloat(prop, value);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				// Silently return false instead of spamming errors
				return false;
			}

			shader.setFloatArray(prop, values);
			return true;
			#else
			FunkinLua.luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return true;
			#end
		});

		// Camera Shader Management Functions
		// Adds a shader to camera's filter array without replacing existing filters
		funk.addLocalCallback("addCameraShader", function(camera:String, shaderName:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if(cam == null)
			{
				FunkinLua.luaTrace('addCameraShader: Camera "$camera" not found!', false, false, FlxColor.RED);
				return false;
			}

			var game = PlayState.instance;
			if(game == null || !game.runtimeShaders.exists(shaderName))
			{
				FunkinLua.luaTrace('addCameraShader: Shader "$shaderName" not initialized! Use initLuaShader first.', false, false, FlxColor.RED);
				return false;
			}

			try
			{
				var arr:Array<String> = game.runtimeShaders.get(shaderName);
				var newShader:FlxRuntimeShader = null;

				// Check legacy mode
				if(ClientPrefs.data.legacyShaderInit)
				{
					newShader = new FlxRuntimeShader(arr[0], arr[1]);
				}
				else
				{
					var adapted = funkin.graphics.shaders.ShaderCompatibility.adaptShaderCode(arr[0], arr[1]);
					newShader = new funkin.graphics.shaders.ErrorHandledShader.ErrorHandledRuntimeShader(shaderName, adapted[0], adapted[1]);
				}

				if(newShader == null)
				{
					FunkinLua.luaTrace('addCameraShader: Failed to create shader "$shaderName"!', false, false, FlxColor.RED);
					return false;
				}

				// Get current filters or create new array
				var filters:Array<openfl.filters.BitmapFilter> = cam.filters != null ? cam.filters.copy() : [];
				filters.push(new ShaderFilter(newShader));
				cam.setFilters(filters);
				
				return true;
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('addCameraShader: Error adding shader - $e', false, false, FlxColor.RED);
				return false;
			}
			#else
			FunkinLua.luaTrace("addCameraShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		// Sets a single shader to camera, replacing all existing filters
		funk.addLocalCallback("setCameraShader", function(camera:String, shaderName:String) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if(cam == null)
			{
				FunkinLua.luaTrace('setCameraShader: Camera "$camera" not found!', false, false, FlxColor.RED);
				return false;
			}

			var game = PlayState.instance;
			if(game == null || !game.runtimeShaders.exists(shaderName))
			{
				FunkinLua.luaTrace('setCameraShader: Shader "$shaderName" not initialized! Use initLuaShader first.', false, false, FlxColor.RED);
				return false;
			}

			try
			{
				var arr:Array<String> = game.runtimeShaders.get(shaderName);
				var newShader:FlxRuntimeShader = null;

				// Check legacy mode
				if(ClientPrefs.data.legacyShaderInit)
				{
					newShader = new FlxRuntimeShader(arr[0], arr[1]);
				}
				else
				{
					var adapted = funkin.graphics.shaders.ShaderCompatibility.adaptShaderCode(arr[0], arr[1]);
					newShader = new funkin.graphics.shaders.ErrorHandledShader.ErrorHandledRuntimeShader(shaderName, adapted[0], adapted[1]);
				}

				if(newShader == null)
				{
					FunkinLua.luaTrace('setCameraShader: Failed to create shader "$shaderName"!', false, false, FlxColor.RED);
					return false;
				}

				cam.setFilters([new ShaderFilter(newShader)]);
				return true;
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('setCameraShader: Error setting shader - $e', false, false, FlxColor.RED);
				return false;
			}
			#else
			FunkinLua.luaTrace("setCameraShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		// Removes a specific shader from camera's filter array by index
		funk.addLocalCallback("removeCameraShader", function(camera:String, index:Int) {
			if(!ClientPrefs.data.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if(cam == null)
			{
				FunkinLua.luaTrace('removeCameraShader: Camera "$camera" not found!', false, false, FlxColor.RED);
				return false;
			}

			if(cam.filters == null || cam.filters.length == 0)
			{
				FunkinLua.luaTrace('removeCameraShader: Camera has no shaders to remove!', false, false, FlxColor.YELLOW);
				return false;
			}

			if(index < 0 || index >= cam.filters.length)
			{
				FunkinLua.luaTrace('removeCameraShader: Index $index out of bounds (0-${cam.filters.length - 1})!', false, false, FlxColor.RED);
				return false;
			}

			try
			{
				var filters = cam.filters.copy();
				filters.splice(index, 1);
				cam.setFilters(filters);
				return true;
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('removeCameraShader: Error removing shader - $e', false, false, FlxColor.RED);
				return false;
			}
			#else
			FunkinLua.luaTrace("removeCameraShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});

		// Clears all shaders from a camera
		funk.addLocalCallback("clearCameraShaders", function(camera:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if(cam == null)
			{
				FunkinLua.luaTrace('clearCameraShaders: Camera "$camera" not found!', false, false, FlxColor.RED);
				return false;
			}

			try
			{
				cam.setFilters([]);
				return true;
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('clearCameraShaders: Error clearing shaders - $e', false, false, FlxColor.RED);
				return false;
			}
			#else
			FunkinLua.luaTrace("clearCameraShaders: Platform unsupported for camera filter management!", false, false, FlxColor.RED);
			return false;
			#end
		});

		// Gets the number of shaders applied to a camera
		funk.addLocalCallback("getCameraShaderCount", function(camera:String):Int {
			#if (!flash && MODS_ALLOWED && sys)
			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			if(cam == null)
			{
				FunkinLua.luaTrace('getCameraShaderCount: Camera "$camera" not found!', false, false, FlxColor.RED);
				return 0;
			}

			return cam.filters != null ? cam.filters.length : 0;
			#else
			FunkinLua.luaTrace("getCameraShaderCount: Platform unsupported for camera filter management!", false, false, FlxColor.RED);
			return 0;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String) {
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if(shader == null)
			{
				FunkinLua.luaTrace("setShaderSampler2D: Shader is not FlxRuntimeShader!", false, false, FlxColor.RED);
				return false;
			}

			// trace('bitmapdatapath: $bitmapdataPath');
			var value = Paths.image(bitmapdataPath);
			if(value != null && value.bitmap != null)
			{
				// trace('Found bitmapdata. Width: ${value.bitmap.width} Height: ${value.bitmap.height}');
				shader.setSampler2D(prop, value.bitmap);
				return true;
			}
			return false;
			#else
			FunkinLua.luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return false;
			#end
		});
	}
	
	#if (!flash && MODS_ALLOWED && sys)
	public static function getShader(obj:String):FlxRuntimeShader
	{
		var split:Array<String> = obj.split('.');
		var target:FlxSprite = null;
		if(split.length > 1) target = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
		else target = LuaUtils.getObjectDirectly(split[0]);

		if(target == null)
		{
			// Silently return null instead of spamming errors
			return null;
		}
		
		if(target.shader == null)
		{
			// Silently return null instead of spamming errors
			return null;
		}
		
		// Support both FlxRuntimeShader (legacy) and ErrorHandledRuntimeShader (modern)
		// ErrorHandledRuntimeShader extends FlxRuntimeShader, so this should work for both
		if (Std.isOfType(target.shader, FlxRuntimeShader)) {
			return cast target.shader;
		}
		
		// If not a FlxRuntimeShader, silently return null
		return null;
	}
	#end
}
