package funkin.modding.scripting.psychlua;

import funkin.play.character.Character;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

/**
 * Character Functions for Lua Scripts
 * Provides functions to create, manage, and control Characters from Lua without runHaxeCode
 */
class CharacterFunctions
{
	static var attachedCharacterGroups:Map<String, String> = [];

	static function getNamedGroup(game:PlayState, groupName:String):FlxSpriteGroup
	{
		if (game == null || groupName == null)
			return null;

		return switch (groupName.toLowerCase())
		{
			case 'boyfriend' | 'bf' | 'player': game.boyfriendGroup;
			case 'dad' | 'opponent': game.dadGroup;
			case 'gf' | 'girlfriend': game.gfGroup;
			default: null;
		};
	}

	static function getCharacterParentGroup(game:PlayState, char:Character):FlxSpriteGroup
	{
		if (game == null || char == null)
			return null;

		if (game.boyfriendGroup != null && game.boyfriendGroup.members != null && game.boyfriendGroup.members.indexOf(char) != -1)
			return game.boyfriendGroup;
		if (game.dadGroup != null && game.dadGroup.members != null && game.dadGroup.members.indexOf(char) != -1)
			return game.dadGroup;
		if (game.gfGroup != null && game.gfGroup.members != null && game.gfGroup.members.indexOf(char) != -1)
			return game.gfGroup;

		return null;
	}

	static function detachCharacter(game:PlayState, char:Character):Void
	{
		if (game == null || char == null)
			return;

		if (game.boyfriendGroup != null)
			game.boyfriendGroup.remove(char, true);
		if (game.dadGroup != null)
			game.dadGroup.remove(char, true);
		if (game.gfGroup != null)
			game.gfGroup.remove(char, true);
		if (game.members != null && game.members.indexOf(char) != -1)
			game.remove(char, true);
	}

	public static function bopAttachedCharacters(beat:Int):Void
	{
		var game = PlayState.instance;
		if (game == null || attachedCharacterGroups == null || attachedCharacterGroups.keys() == null)
			return;

		var variables = MusicBeatState.getVariables();
		var staleTags:Array<String> = [];
		for (tag in attachedCharacterGroups.keys())
		{
			var char:Character = variables.get(tag);
			if (char == null || !Std.isOfType(char, Character))
			{
				staleTags.push(tag);
				continue;
			}

			if (char == game.boyfriend || char == game.dad || char == game.gf)
				continue;

			var animName:String = char.getAnimationName();
			if (beat % char.danceEveryNumBeats == 0 && !animName.startsWith('sing') && !char.stunned && !char.specialAnim)
				char.dance();
		}

		for (tag in staleTags)
			attachedCharacterGroups.remove(tag);
	}

	public static function implement(funk:FunkinLua)
	{
		var lua = funk.lua;
		var game = PlayState.instance;

		// Create a new character
		Lua_helper.add_callback(lua, "makeCharacter", function(tag:String, character:String, x:Float, y:Float, ?isPlayer:Bool = false) {
			tag = tag.replace('.', '');
			
			// Check if file exists
			if(!Paths.fileExists('characters/$character.json', TEXT)) {
				FunkinLua.luaTrace('makeCharacter: Character file "$character.json" not found!', false, false, FlxColor.RED);
				return false;
			}

			// Check if already exists
			if(MusicBeatState.getVariables().exists(tag)) {
				FunkinLua.luaTrace('makeCharacter: Character $tag already exists!', false, false, FlxColor.YELLOW);
				return false;
			}

			// Create the character
			var char:Character = new Character(x, y, character, isPlayer);
			MusicBeatState.getVariables().set(tag, char);
			
			return true;
		});

		// Add character to the game
		Lua_helper.add_callback(lua, "addCharacter", function(tag:String, ?insertBefore:String = null) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				FunkinLua.luaTrace('addCharacter: Character $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			if(game == null) {
				FunkinLua.luaTrace('addCharacter: PlayState instance not found!', false, false, FlxColor.RED);
				return false;
			}

			var targetGroup:FlxSpriteGroup = null;
			if(insertBefore != null)
				targetGroup = getNamedGroup(game, insertBefore);

			if (targetGroup != null)
			{
				detachCharacter(game, char);
				targetGroup.add(char);
				char.scrollFactor.set(targetGroup.scrollFactor.x, targetGroup.scrollFactor.y);
				attachedCharacterGroups.set(tag, insertBefore.toLowerCase());
				char.dance();
				return true;
			}

			attachedCharacterGroups.remove(tag);

			// Determine insertion point
			var insertIndex:Int = -1;
			
			if(insertBefore != null) {
				// Insert before a specific group or object
				switch(insertBefore.toLowerCase()) {
					case 'boyfriend' | 'bf' | 'player':
						insertIndex = game.members.indexOf(game.boyfriendGroup);
					case 'dad' | 'opponent':
						insertIndex = game.members.indexOf(game.dadGroup);
					case 'gf' | 'girlfriend':
						insertIndex = game.members.indexOf(game.gfGroup);
					default:
						// Try to find custom object
						var obj:FlxBasic = LuaUtils.getObjectDirectly(insertBefore);
						if(obj != null) {
							insertIndex = game.members.indexOf(obj);
						}
				}
			} else {
				// Default: insert before appropriate group based on isPlayer
				if(char.isPlayer) {
					insertIndex = game.members.indexOf(game.boyfriendGroup);
				} else {
					insertIndex = game.members.indexOf(game.dadGroup);
				}
			}

			// Insert character
			detachCharacter(game, char);
			if(insertIndex >= 0) {
				game.insert(insertIndex, char);
			} else {
				game.add(char);
			}

			return true;
		});

		// Remove character from the game
		Lua_helper.add_callback(lua, "removeCharacter", function(tag:String, ?destroy:Bool = true) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				FunkinLua.luaTrace('removeCharacter: Character $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			if(game != null)
				detachCharacter(game, char);

			attachedCharacterGroups.remove(tag);

			if(destroy) {
				char.kill();
				char.destroy();
				MusicBeatState.getVariables().remove(tag);
			}

			return true;
		});

		// Play character animation
		Lua_helper.add_callback(lua, "characterPlayAnim", function(tag:String, anim:String, ?forced:Bool = false, ?reversed:Bool = false, ?startFrame:Int = 0) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				FunkinLua.luaTrace('characterPlayAnim: Character $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			char.playAnim(anim, forced, reversed, startFrame);
			return true;
		});

		// Make character dance
		Lua_helper.add_callback(lua, "characterDance", function(tag:String) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				FunkinLua.luaTrace('characterDance: Character $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			char.dance();
			return true;
		});

		// Set character position
		Lua_helper.add_callback(lua, "setCharacterPos", function(tag:String, x:Float, y:Float) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				return false;
			}

			var parentGroup = getCharacterParentGroup(game, char);
			if (parentGroup != null)
				char.setPosition(x - parentGroup.x, y - parentGroup.y);
			else
				char.setPosition(x, y);
			return true;
		});

		// Reset character to group position (like resetExtraCharPos)
		Lua_helper.add_callback(lua, "resetCharacterPos", function(tag:String, ?whichGroup:String = null) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				return false;
			}

			if(game == null) return false;

			var targetGroup:FlxSprite = null;
			
			if(whichGroup == null) {
				// Auto-detect based on isPlayer
				targetGroup = char.isPlayer ? game.boyfriendGroup : game.dadGroup;
			} else {
				switch(whichGroup.toLowerCase()) {
					case 'bf' | 'boyfriend' | 'player':
						targetGroup = game.boyfriendGroup;
					case 'dad' | 'opponent':
						targetGroup = game.dadGroup;
					case 'gf' | 'girlfriend':
						targetGroup = game.gfGroup;
				}
			}

			if(targetGroup != null) {
				var mult:Float = char.isPlayer ? -1 : 1;
				if (getCharacterParentGroup(game, char) == targetGroup)
				{
					char.x = char.positionArray[0] * mult;
					char.y = char.positionArray[1];
				}
				else
				{
					char.x = targetGroup.x + (char.positionArray[0] * mult);
					char.y = targetGroup.y + char.positionArray[1];
				}
				return true;
			}

			return false;
		});

		// Add animation offset
		Lua_helper.add_callback(lua, "addCharacterOffset", function(tag:String, anim:String, x:Float, y:Float) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				return false;
			}

			char.addOffset(anim, x, y);
			return true;
		});

		// Check if character has animation
		Lua_helper.add_callback(lua, "characterHasAnim", function(tag:String, anim:String):Bool {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				return false;
			}

			return char.hasAnimation(anim);
		});

		// Get current animation name
		Lua_helper.add_callback(lua, "getCharacterAnim", function(tag:String):String {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				return '';
			}

			return char.getAnimationName();
		});

		// Set character properties
		Lua_helper.add_callback(lua, "setCharacterX", function(tag:String, x:Float) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.x = x;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "setCharacterY", function(tag:String, y:Float) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.y = y;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterX", function(tag:String):Float {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if (char == null || !Std.isOfType(char, Character))
				return 0;

			var parentGroup = getCharacterParentGroup(game, char);
			return parentGroup != null ? parentGroup.x + char.x : char.x;
		});

		Lua_helper.add_callback(lua, "getCharacterY", function(tag:String):Float {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if (char == null || !Std.isOfType(char, Character))
				return 0;

			var parentGroup = getCharacterParentGroup(game, char);
			return parentGroup != null ? parentGroup.y + char.y : char.y;
		});

		// Character state properties
		Lua_helper.add_callback(lua, "setCharacterStunned", function(tag:String, stunned:Bool) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.stunned = stunned;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterStunned", function(tag:String):Bool {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.stunned : false;
		});

		Lua_helper.add_callback(lua, "setCharacterSpecialAnim", function(tag:String, special:Bool) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.specialAnim = special;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterSpecialAnim", function(tag:String):Bool {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.specialAnim : false;
		});

		Lua_helper.add_callback(lua, "setCharacterHoldTimer", function(tag:String, time:Float) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.holdTimer = time;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterHoldTimer", function(tag:String):Float {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.holdTimer : 0;
		});

		Lua_helper.add_callback(lua, "setCharacterIdleSuffix", function(tag:String, suffix:String) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.idleSuffix = suffix;
				char.recalculateDanceIdle();
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterIdleSuffix", function(tag:String):String {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.idleSuffix : '';
		});

		// Dance properties
		Lua_helper.add_callback(lua, "setCharacterDanceEveryNumBeats", function(tag:String, beats:Int) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.danceEveryNumBeats = beats;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterDanceEveryNumBeats", function(tag:String):Int {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.danceEveryNumBeats : 1;
		});

		// Character flip
		Lua_helper.add_callback(lua, "setCharacterFlipX", function(tag:String, flip:Bool) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.flipX = flip;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterFlipX", function(tag:String):Bool {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.flipX : false;
		});

		// Character color
		Lua_helper.add_callback(lua, "setCharacterColor", function(tag:String, color:String) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.color = CoolUtil.colorFromString(color);
				return true;
			}
			return false;
		});

		// Character alpha
		Lua_helper.add_callback(lua, "setCharacterAlpha", function(tag:String, alpha:Float) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.alpha = alpha;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterAlpha", function(tag:String):Float {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.alpha : 1;
		});

		// Character scale
		Lua_helper.add_callback(lua, "setCharacterScale", function(tag:String, x:Float, y:Float) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.scale.set(x, y);
				char.updateHitbox();
				return true;
			}
			return false;
		});

		// Character visibility
		Lua_helper.add_callback(lua, "setCharacterVisible", function(tag:String, visible:Bool) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char != null && Std.isOfType(char, Character)) {
				char.visible = visible;
				return true;
			}
			return false;
		});

		Lua_helper.add_callback(lua, "getCharacterVisible", function(tag:String):Bool {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.visible : false;
		});

		// Character icon
		Lua_helper.add_callback(lua, "getCharacterIcon", function(tag:String):String {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.healthIcon : 'face';
		});

		// Character name
		Lua_helper.add_callback(lua, "getCharacterName", function(tag:String):String {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.curCharacter : '';
		});

		// Check if character exists
		Lua_helper.add_callback(lua, "characterExists", function(tag:String):Bool {
			var char:Dynamic = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character));
		});

		// Set character camera
		Lua_helper.add_callback(lua, "setCharacterCamera", function(tag:String, ?camera:String = 'game') {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				return false;
			}

			var cam:FlxCamera = LuaUtils.cameraFromString(camera);
			char.cameras = [cam];
			return true;
		});

		// Change character (swap to different character file)
		Lua_helper.add_callback(lua, "changeCharacter", function(tag:String, newCharacter:String) {
			var char:Character = MusicBeatState.getVariables().get(tag);
			if(char == null || !Std.isOfType(char, Character)) {
				FunkinLua.luaTrace('changeCharacter: Character $tag does not exist!', false, false, FlxColor.RED);
				return false;
			}

			if(!Paths.fileExists('characters/$newCharacter.json', TEXT)) {
				FunkinLua.luaTrace('changeCharacter: Character file "$newCharacter.json" not found!', false, false, FlxColor.RED);
				return false;
			}

			char.changeCharacter(newCharacter);
			return true;
		});

		// Get character isPlayer
		Lua_helper.add_callback(lua, "getCharacterIsPlayer", function(tag:String):Bool {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.isPlayer : false;
		});

		// Animation finished check
		Lua_helper.add_callback(lua, "characterAnimFinished", function(tag:String):Bool {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.isAnimationFinished() : false;
		});

		// Get character width/height
		Lua_helper.add_callback(lua, "getCharacterWidth", function(tag:String):Float {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.width : 0;
		});

		Lua_helper.add_callback(lua, "getCharacterHeight", function(tag:String):Float {
			var char:Character = MusicBeatState.getVariables().get(tag);
			return (char != null && Std.isOfType(char, Character)) ? char.height : 0;
		});
	}
}
