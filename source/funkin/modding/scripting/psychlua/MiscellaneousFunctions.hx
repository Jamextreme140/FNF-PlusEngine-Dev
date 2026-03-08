package funkin.modding.scripting.psychlua;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import Type.ValueType;

/**
 * Miscellaneous utility functions for Lua scripting
 * Handles sprite ordering, group insertion, and other utility operations
 */
class MiscellaneousFunctions
{
	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		
		// NOTE: Some functions like getObjectOrder, setObjectOrder, addToGroup, removeFromGroup
		// already exist in FunkinLua.hx and ReflectionFunctions.hx
		// This class provides additional utility functions that don't exist yet
		
		// Get group/array length
		Lua_helper.add_callback(lua, "getGroupLength", function(group:String) {
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null)
			{
				FunkinLua.luaTrace('getGroupLength: Group "$group" doesn\'t exist!', false, false, FlxColor.RED);
				return 0;
			}
			
			try
			{
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): // Is Array
						return groupOrArray.length;
					default: // Is Group
						if(Reflect.hasField(groupOrArray, 'length'))
							return Reflect.getProperty(groupOrArray, 'length');
						else if(Reflect.hasField(groupOrArray, 'members'))
							return Reflect.getProperty(groupOrArray, 'members').length;
						else
						{
							FunkinLua.luaTrace('getGroupLength: Group "$group" doesn\'t have length property!', false, false, FlxColor.RED);
							return 0;
						}
				}
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('getGroupLength: Error getting length of "$group" - ${e}', false, false, FlxColor.RED);
				return 0;
			}
		});
		
		// Check if object exists in a group
		Lua_helper.add_callback(lua, "objectExistsInGroup", function(tag:String, group:String) {
			var obj:FlxBasic = LuaUtils.getObjectDirectly(tag);
			if(obj == null) return false;
			
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null) return false;
			
			try
			{
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): // Is Array
						return groupOrArray.indexOf(obj) != -1;
					default: // Is Group
						if(Reflect.hasField(groupOrArray, 'members'))
							return Reflect.getProperty(groupOrArray, 'members').indexOf(obj) != -1;
						else
							return false;
				}
			}
			catch(e:Dynamic)
			{
				return false;
			}
		});
		
		// Swap two objects' positions in a group
		Lua_helper.add_callback(lua, "swapObjects", function(tag1:String, tag2:String, group:String) {
			var obj1:FlxBasic = LuaUtils.getObjectDirectly(tag1);
			var obj2:FlxBasic = LuaUtils.getObjectDirectly(tag2);
			
			if(obj1 == null)
			{
				FunkinLua.luaTrace('swapObjects: Object "$tag1" doesn\'t exist!', false, false, FlxColor.RED);
				return false;
			}
			if(obj2 == null)
			{
				FunkinLua.luaTrace('swapObjects: Object "$tag2" doesn\'t exist!', false, false, FlxColor.RED);
				return false;
			}
			
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null)
			{
				FunkinLua.luaTrace('swapObjects: Group "$group" doesn\'t exist!', false, false, FlxColor.RED);
				return false;
			}
			
			try
			{
				var members:Array<Dynamic> = null;
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): // Is Array
						members = groupOrArray;
					default: // Is Group
						if(Reflect.hasField(groupOrArray, 'members'))
							members = Reflect.getProperty(groupOrArray, 'members');
						else
						{
							FunkinLua.luaTrace('swapObjects: Group "$group" doesn\'t have members!', false, false, FlxColor.RED);
							return false;
						}
				}
				
				var idx1 = members.indexOf(obj1);
				var idx2 = members.indexOf(obj2);
				
				if(idx1 == -1 || idx2 == -1)
				{
					FunkinLua.luaTrace('swapObjects: One or both objects not found in "$group"!', false, false, FlxColor.RED);
					return false;
				}
				
				// Swap
				members[idx1] = obj2;
				members[idx2] = obj1;
				
				return true;
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('swapObjects: Error swapping "$tag1" and "$tag2" in "$group" - ${e}', false, false, FlxColor.RED);
				return false;
			}
		});
		
		// Get object at specific index in group
		Lua_helper.add_callback(lua, "getObjectAt", function(group:String, index:Int) {
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null)
			{
				FunkinLua.luaTrace('getObjectAt: Group "$group" doesn\'t exist!', false, false, FlxColor.RED);
				return null;
			}
			
			try
			{
				var obj:Dynamic = null;
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): // Is Array
						if(index >= 0 && index < groupOrArray.length)
							obj = groupOrArray[index];
					default: // Is Group
						if(Reflect.hasField(groupOrArray, 'members'))
						{
							var members = Reflect.getProperty(groupOrArray, 'members');
							if(index >= 0 && index < members.length)
								obj = members[index];
						}
				}
				
				if(obj != null && Reflect.hasField(obj, 'ID'))
				{
					// Try to find a tag for this object
					var vars = MusicBeatState.getVariables();
					for(key in vars.keys())
					{
						if(vars.get(key) == obj)
							return key;
					}
				}
				
				return null;
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('getObjectAt: Error getting object at index $index in "$group" - ${e}', false, false, FlxColor.RED);
				return null;
			}
		});
		
		// Clear all objects from group (with optional destroy)
		Lua_helper.add_callback(lua, "clearGroup", function(group:String, ?destroy:Bool = true) {
			var groupOrArray:Dynamic = Reflect.getProperty(LuaUtils.getTargetInstance(), group);
			if(groupOrArray == null)
			{
				FunkinLua.luaTrace('clearGroup: Group "$group" doesn\'t exist!', false, false, FlxColor.RED);
				return false;
			}
			
			try
			{
				switch(Type.typeof(groupOrArray))
				{
					case TClass(Array): // Is Array
						var arr:Array<Dynamic> = cast groupOrArray;
						if(destroy)
						{
							while(arr.length > 0)
							{
								var obj = arr[0];
								arr.remove(obj);
								if(obj != null && Reflect.hasField(obj, 'destroy'))
									Reflect.callMethod(obj, Reflect.field(obj, 'destroy'), []);
							}
						}
						else
						{
							#if (haxe_ver >= 4.0)
							arr.resize(0);
							#else
							arr.splice(0, arr.length);
							#end
						}
					default: // Is Group
						if(Reflect.hasField(groupOrArray, 'clear'))
						{
							Reflect.callMethod(groupOrArray, Reflect.field(groupOrArray, 'clear'), []);
						}
						else if(Reflect.hasField(groupOrArray, 'members'))
						{
							var members:Array<Dynamic> = cast Reflect.getProperty(groupOrArray, 'members');
							if(destroy)
							{
								while(members.length > 0)
								{
									var obj = members[0];
									members.remove(obj);
									if(obj != null && Reflect.hasField(obj, 'destroy'))
										Reflect.callMethod(obj, Reflect.field(obj, 'destroy'), []);
								}
							}
							else
							{
								#if (haxe_ver >= 4.0)
								members.resize(0);
								#else
								members.splice(0, members.length);
								#end
							}
						}
						else
						{
							FunkinLua.luaTrace('clearGroup: Group "$group" doesn\'t support clear operation!', false, false, FlxColor.RED);
							return false;
						}
				}
				return true;
			}
			catch(e:Dynamic)
			{
				FunkinLua.luaTrace('clearGroup: Error clearing "$group" - ${e}', false, false, FlxColor.RED);
				return false;
			}
		});
	}
}
