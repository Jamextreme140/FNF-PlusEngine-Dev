package funkin.modding.scripting.psychlua;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;

/**
 * Camera Functions for Lua Scripts
 * Provides functions to create, manage, and manipulate FlxCameras from Lua
 */
class CameraFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		var game = PlayState.instance;

		// Create a new camera
		Lua_helper.add_callback(lua, "makeCamera", function(tag:String, ?x:Int = 0, ?y:Int = 0, ?width:Int = 0, ?height:Int = 0) {
			tag = tag.replace('.', '');
			
			// Check if camera already exists
			var existingCam:FlxCamera = MusicBeatState.getVariables().get(tag);
			if(existingCam != null && Std.isOfType(existingCam, FlxCamera)) {
				FunkinLua.luaTrace('makeCamera: Camera $tag already exists!', false, false, FlxColor.RED);
				return false;
			}

			// Create new camera with specified dimensions or full screen
			var newCam:FlxCamera = null;
			if(width > 0 && height > 0) {
				newCam = new FlxCamera(x, y, width, height);
			} else {
				newCam = new FlxCamera();
			}
			
			newCam.bgColor.alpha = 0; // Transparent by default
			MusicBeatState.getVariables().set(tag, newCam);
			return true;
		});

		// Add camera to the camera stack
		Lua_helper.add_callback(lua, "addCamera", function(tag:String, ?defaultDrawTarget:Bool = false) {
			var camera:FlxCamera = MusicBeatState.getVariables().get(tag);
			if(camera == null || !Std.isOfType(camera, FlxCamera)) {
				FunkinLua.luaTrace('addCamera: Camera $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			// Check if camera is already in the list
			if(FlxG.cameras.list.contains(camera)) {
				FunkinLua.luaTrace('addCamera: Camera $tag is already added!', false, false, FlxColor.YELLOW);
				return false;
			}

			FlxG.cameras.add(camera, defaultDrawTarget);
			return true;
		});

		// Remove camera from the camera stack
		Lua_helper.add_callback(lua, "removeCamera", function(tag:String, ?destroy:Bool = false) {
			var camera:FlxCamera = MusicBeatState.getVariables().get(tag);
			if(camera == null || !Std.isOfType(camera, FlxCamera)) {
				FunkinLua.luaTrace('removeCamera: Camera $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			// Check if camera is in the list
			if(!FlxG.cameras.list.contains(camera)) {
				FunkinLua.luaTrace('removeCamera: Camera $tag is not in the camera list!', false, false, FlxColor.YELLOW);
				return false;
			}

			FlxG.cameras.remove(camera, destroy);
			if(destroy) {
				MusicBeatState.getVariables().remove(tag);
			}
			return true;
		});

		// Set camera position
		Lua_helper.add_callback(lua, "setCameraPosition", function(tag:String, x:Float, y:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.x = x;
				camera.y = y;
				return true;
			}
			return false;
		});

		// Set camera scroll
		Lua_helper.add_callback(lua, "setCameraScroll", function(tag:String, x:Float, y:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.scroll.set(x, y);
				return true;
			}
			return false;
		});

		// Set camera zoom
		Lua_helper.add_callback(lua, "setCameraZoom", function(tag:String, zoom:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.zoom = zoom;
				return true;
			}
			return false;
		});

		// Set camera angle
		Lua_helper.add_callback(lua, "setCameraAngle", function(tag:String, angle:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.angle = angle;
				return true;
			}
			return false;
		});

		// Set camera alpha (transparency)
		Lua_helper.add_callback(lua, "setCameraAlpha", function(tag:String, alpha:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.alpha = alpha;
				return true;
			}
			return false;
		});

		// Set camera background color and alpha
		Lua_helper.add_callback(lua, "setCameraBgColor", function(tag:String, color:String, ?alpha:Float = 1.0) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.bgColor = CoolUtil.colorFromString(color);
				camera.bgColor.alpha = Std.int(alpha * 255);
				return true;
			}
			return false;
		});

		// Set camera background alpha only
		Lua_helper.add_callback(lua, "setCameraBgAlpha", function(tag:String, alpha:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.bgColor.alpha = Std.int(alpha * 255);
				return true;
			}
			return false;
		});

		// Get camera properties
		Lua_helper.add_callback(lua, "getCameraX", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.x : 0;
		});

		Lua_helper.add_callback(lua, "getCameraY", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.y : 0;
		});

		Lua_helper.add_callback(lua, "getCameraScrollX", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.scroll.x : 0;
		});

		Lua_helper.add_callback(lua, "getCameraScrollY", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.scroll.y : 0;
		});

		Lua_helper.add_callback(lua, "getCameraZoom", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.zoom : 1;
		});

		Lua_helper.add_callback(lua, "getCameraAngle", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.angle : 0;
		});

		Lua_helper.add_callback(lua, "getCameraAlpha", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.alpha : 1;
		});

		Lua_helper.add_callback(lua, "getCameraWidth", function(tag:String):Int {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.width : 0;
		});

		Lua_helper.add_callback(lua, "getCameraHeight", function(tag:String):Int {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.height : 0;
		});

		// Camera visibility
		Lua_helper.add_callback(lua, "setCameraVisible", function(tag:String, visible:Bool) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.visible = visible;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCameraVisible", function(tag:String):Bool {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.visible : false;
		});

		// Camera follow target
		Lua_helper.add_callback(lua, "setCameraFollowTarget", function(tag:String, target:String, ?lerp:Float = 0) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			var targetObj:FlxObject = LuaUtils.getObjectDirectly(target);
			
			if(camera == null) {
				FunkinLua.luaTrace('setCameraFollowTarget: Camera $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}
			
			if(targetObj == null) {
				FunkinLua.luaTrace('setCameraFollowTarget: Target $target does not exist!', false, false, FlxColor.RED);
				return false;
			}

			camera.follow(targetObj);
			if(lerp > 0) camera.followLerp = lerp;
			return true;
		});

		// Set camera follow point (for custom follow positions)
		Lua_helper.add_callback(lua, "setCameraFollowPoint", function(tag:String, x:Float, y:Float, ?lerp:Float = 0) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera == null) {
				FunkinLua.luaTrace('setCameraFollowPoint: Camera $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			// Create or update follow point
			var followPoint:FlxObject = new FlxObject(x, y, 1, 1);
			camera.follow(followPoint);
			if(lerp > 0) camera.followLerp = lerp;
			return true;
		});

		// Unfollow (stop following any target)
		Lua_helper.add_callback(lua, "cameraUnfollow", function(tag:String) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.target = null;
				return true;
			}
			return false;
		});

		// Set camera follow lerp
		Lua_helper.add_callback(lua, "setCameraFollowLerp", function(tag:String, lerp:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.followLerp = lerp;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCameraFollowLerp", function(tag:String):Float {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			return (camera != null) ? camera.followLerp : 0;
		});

		// Set sprite camera(s)
		Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, ?camera:String = '') {
			var split:Array<String> = obj.split('.');
			var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(object != null) {
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
				if(Std.isOfType(object, FlxSprite)) {
					var sprite:FlxSprite = cast object;
					sprite.cameras = [cam];
					return true;
				}
			}
			FunkinLua.luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		// Add camera to sprite's camera list (allows rendering on multiple cameras)
		Lua_helper.add_callback(lua, "addObjectCamera", function(obj:String, camera:String) {
			var split:Array<String> = obj.split('.');
			var object:FlxBasic = LuaUtils.getObjectDirectly(split[0]);
			if(split.length > 1) {
				object = LuaUtils.getVarInArray(LuaUtils.getPropertyLoop(split), split[split.length-1]);
			}

			if(object != null && Std.isOfType(object, FlxSprite)) {
				var sprite:FlxSprite = cast object;
				var cam:FlxCamera = LuaUtils.cameraFromString(camera);
				
				if(sprite.cameras == null) sprite.cameras = [];
				if(!sprite.cameras.contains(cam)) {
					sprite.cameras.push(cam);
					return true;
				}
			}
			return false;
		});

		// Reset camera
		Lua_helper.add_callback(lua, "resetCamera", function(tag:String) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.scroll.set(0, 0);
				camera.target = null;
				camera.zoom = 1;
				camera.angle = 0;
				camera.alpha = 1;
				return true;
			}
			return false;
		});

		// Check if camera exists
		Lua_helper.add_callback(lua, "cameraExists", function(tag:String):Bool {
			var camera:Dynamic = MusicBeatState.getVariables().get(tag);
			return (camera != null && Std.isOfType(camera, FlxCamera));
		});

		// Get camera index in the stack
		Lua_helper.add_callback(lua, "getCameraIndex", function(tag:String):Int {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				return FlxG.cameras.list.indexOf(camera);
			}
			return -1;
		});

		// Reorder camera in the stack
		Lua_helper.add_callback(lua, "setCameraIndex", function(tag:String, index:Int) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera == null) {
				FunkinLua.luaTrace('setCameraIndex: Camera $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			if(!FlxG.cameras.list.contains(camera)) {
				FunkinLua.luaTrace('setCameraIndex: Camera $tag is not in the camera list!', false, false, FlxColor.YELLOW);
				return false;
			}

			var currentIndex = FlxG.cameras.list.indexOf(camera);
			if(currentIndex == index) return true; // Already at desired index

			// Remove and re-insert at new index
			FlxG.cameras.list.remove(camera);
			FlxG.cameras.list.insert(index, camera);
			return true;
		});

		// Snap camera to position (instant movement)
		Lua_helper.add_callback(lua, "snapCamera", function(tag:String, x:Float, y:Float) {
			var camera:FlxCamera = LuaUtils.cameraFromString(tag);
			if(camera != null) {
				camera.scroll.set(x, y);
				camera.target = null; // Clear follow target
				return true;
			}
			return false;
		});
	}
}