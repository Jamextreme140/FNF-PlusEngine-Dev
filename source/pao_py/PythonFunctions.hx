#if PY_ALLOWED
package pao_py;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import openfl.display.BlendMode;
import openfl.Lib;

class PythonFunctions
{
	public static function implement(script:FunkinPython) {
		var game = PlayState.instance;
		
		// Basic utility functions
		script.set('debugPrint', function(text:String, ?color:String = 'WHITE') {
			if(game != null) game.addTextToDebug(text, FlxColor.fromString(color));
			else trace(text);
		});

		script.set('getRunningScripts', function() {
			var runningScripts:Array<String> = [];
			#if LUA_ALLOWED
			if(game.luaArray != null)
				for (luaScript in game.luaArray)
					runningScripts.push(luaScript.scriptName);
			#end
			#if PY_ALLOWED
			if(game.pythonArray != null)
				for (pyScript in game.pythonArray)
					runningScripts.push(pyScript.scriptName);
			#end
			return runningScripts;
		});

		script.set('setVar', function(varName:String, value:Dynamic) {
			MusicBeatState.getVariables().set(varName, value);
			return value;
		});

		script.set('getVar', function(varName:String) {
			return MusicBeatState.getVariables().get(varName);
		});

		script.set('removeVar', function(varName:String) {
			if(MusicBeatState.getVariables().exists(varName)) {
				MusicBeatState.getVariables().remove(varName);
				return true;
			}
			return false;
		});

		// Property getters/setters
		script.set('getProperty', function(variable:String) {
			return PythonUtils.getVarInArray(game, variable);
		});

		script.set('setProperty', function(variable:String, value:Dynamic) {
			return PythonUtils.setVarInArray(game, variable, value);
		});

		script.set('getPropertyFromClass', function(className:String, variable:String) {
			var myClass:Dynamic = Type.resolveClass(className);
			if(myClass == null) return null;
			return PythonUtils.getVarInArray(myClass, variable);
		});

		script.set('setPropertyFromClass', function(className:String, variable:String, value:Dynamic) {
			var myClass:Dynamic = Type.resolveClass(className);
			if(myClass == null) return null;
			return PythonUtils.setVarInArray(myClass, variable, value);
		});

		script.set('getPropertyFromGroup', function(group:String, index:Int, variable:String) {
			var obj:Dynamic = Reflect.getProperty(game, group);
			if(obj == null) return null;
			var result:Dynamic = obj.members[index];
			if(result == null) return null;
			return PythonUtils.getVarInArray(result, variable);
		});

		script.set('setPropertyFromGroup', function(group:String, index:Int, variable:String, value:Dynamic) {
			var obj:Dynamic = Reflect.getProperty(game, group);
			if(obj == null) return;
			var result:Dynamic = obj.members[index];
			if(result == null) return;
			PythonUtils.setVarInArray(result, variable, value);
		});

		// Sound functions
		script.set('playSound', function(sound:String, ?volume:Float = 1.0, ?tag:String = null) {
			FlxG.sound.play(Paths.sound(sound), volume);
		});

		script.set('playMusic', function(sound:String, ?volume:Float = 1.0, ?loop:Bool = false) {
			FlxG.sound.playMusic(Paths.music(sound), volume, loop);
		});

		script.set('pauseSound', function(tag:String) {
			// Reserved for future implementation
		});

		script.set('resumeSound', function(tag:String) {
			// Reserved for future implementation
		});

		script.set('stopSound', function(tag:String) {
			// Reserved for future implementation
		});

		script.set('getSoundVolume', function(tag:String):Float {
			return 0; // Reserved for future implementation
		});

		script.set('setSoundVolume', function(tag:String, volume:Float) {
			// Reserved for future implementation
		});

		script.set('getSoundTime', function(tag:String):Float {
			return 0; // Reserved for future implementation
		});

		script.set('setSoundTime', function(tag:String, time:Float) {
			// Reserved for future implementation
		});

		// Character functions
		script.set('characterPlayAnim', function(character:String, anim:String, ?forced:Bool = false) {
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent':
					if(game.dad != null) game.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if(game.gf != null) game.gf.playAnim(anim, forced);
				default:
					if(game.boyfriend != null) game.boyfriend.playAnim(anim, forced);
			}
		});

		script.set('characterDance', function(character:String) {
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent':
					if(game.dad != null) game.dad.dance();
				case 'gf' | 'girlfriend':
					if(game.gf != null) game.gf.dance();
				default:
					if(game.boyfriend != null) game.boyfriend.dance();
			}
		});

		script.set('setCharacterX', function(character:String, value:Float) {
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent':
					if(game.dad != null) game.dad.x = value;
				case 'gf' | 'girlfriend':
					if(game.gf != null) game.gf.x = value;
				default:
					if(game.boyfriend != null) game.boyfriend.x = value;
			}
		});

		script.set('setCharacterY', function(character:String, value:Float) {
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent':
					if(game.dad != null) game.dad.y = value;
				case 'gf' | 'girlfriend':
					if(game.gf != null) game.gf.y = value;
				default:
					if(game.boyfriend != null) game.boyfriend.y = value;
			}
		});

		script.set('getCharacterX', function(character:String):Float {
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dad != null ? game.dad.x : 0;
				case 'gf' | 'girlfriend':
					return game.gf != null ? game.gf.x : 0;
				default:
					return game.boyfriend != null ? game.boyfriend.x : 0;
			}
		});

		script.set('getCharacterY', function(character:String):Float {
			switch(character.toLowerCase()) {
				case 'dad' | 'opponent':
					return game.dad != null ? game.dad.y : 0;
				case 'gf' | 'girlfriend':
					return game.gf != null ? game.gf.y : 0;
				default:
					return game.boyfriend != null ? game.boyfriend.y : 0;
			}
		});

		// Camera functions
		script.set('cameraShake', function(camera:String, intensity:Float, duration:Float) {
			var cam:FlxCamera = getCameraByName(camera);
			if(cam != null) cam.shake(intensity, duration);
		});

		script.set('cameraFlash', function(camera:String, color:String, duration:Float, ?forced:Bool = false) {
			var cam:FlxCamera = getCameraByName(camera);
			if(cam != null) cam.flash(FlxColor.fromString(color), duration, null, forced);
		});

		script.set('cameraFade', function(camera:String, color:String, duration:Float, ?fadeOut:Bool = false) {
			var cam:FlxCamera = getCameraByName(camera);
			if(cam != null) cam.fade(FlxColor.fromString(color), duration, fadeOut);
		});

		script.set('setCamera', function(tag:String, camera:String) {
			var obj:FlxSprite = game.getLuaObject(tag);
			if(obj != null) {
				obj.cameras = [getCameraByName(camera)];
			}
		});

		script.set('getCameraX', function(camera:String):Float {
			var cam:FlxCamera = getCameraByName(camera);
			return cam != null ? cam.scroll.x : 0;
		});

		script.set('getCameraY', function(camera:String):Float {
			var cam:FlxCamera = getCameraByName(camera);
			return cam != null ? cam.scroll.y : 0;
		});

		script.set('setCameraScroll', function(camera:String, x:Float, y:Float) {
			var cam:FlxCamera = getCameraByName(camera);
			if(cam != null) {
				cam.scroll.set(x, y);
			}
		});

		script.set('getCameraZoom', function(camera:String):Float {
			var cam:FlxCamera = getCameraByName(camera);
			return cam != null ? cam.zoom : 1.0;
		});

		script.set('setCameraZoom', function(camera:String, zoom:Float) {
			var cam:FlxCamera = getCameraByName(camera);
			if(cam != null) cam.zoom = zoom;
		});

		// Health functions
		script.set('getHealth', function():Float {
			return game.health;
		});

		script.set('setHealth', function(health:Float) {
			game.health = health;
		});

		script.set('addHealth', function(health:Float) {
			game.health += health;
		});

		// Score functions
		script.set('getScore', function():Int {
			return game.songScore;
		});

		script.set('setScore', function(score:Int) {
			game.songScore = score;
			game.RecalculateRating();
		});

		script.set('addScore', function(score:Int) {
			game.songScore += score;
			game.RecalculateRating();
		});

		// Sprite creation (basic - simplified)
		script.set('makeLuaSprite', function(tag:String, ?image:String = null, ?x:Float = 0, ?y:Float = 0) {
			// Reserved for future full implementation
			return tag;
		});

		script.set('addLuaSprite', function(tag:String, ?inFront:Bool = false) {
			// Reserved for future full implementation
			return false;
		});

		script.set('removeLuaSprite', function(tag:String, ?destroy:Bool = true) {
			// Reserved for future full implementation
			return false;
		});

		// Tween functions (simplified for now)
		script.set('doTweenX', function(tag:String, vars:String, value:Float, duration:Float, ?ease:String = 'linear') {
			// Reserved for future full implementation
		});

		script.set('doTweenY', function(tag:String, vars:String, value:Float, duration:Float, ?ease:String = 'linear') {
			// Reserved for future full implementation
		});

		script.set('doTweenAlpha', function(tag:String, vars:String, value:Float, duration:Float, ?ease:String = 'linear') {
			// Reserved for future full implementation
		});

		script.set('doTweenZoom', function(tag:String, camera:String, zoom:Float, duration:Float, ?ease:String = 'linear') {
			// Reserved for future full implementation
		});

		script.set('cancelTween', function(tag:String) {
			// Reserved for future full implementation
		});

		// Timer functions (simplified)
		script.set('runTimer', function(tag:String, time:Float, ?loops:Int = 1) {
			// Reserved for future full implementation
		});

		script.set('cancelTimer', function(tag:String) {
			// Reserved for future full implementation
		});

		// Misc functions
		script.set('getRandomInt', function(min:Int, max:Int):Int {
			return FlxG.random.int(min, max);
		});

		script.set('getRandomFloat', function(min:Float, max:Float):Float {
			return FlxG.random.float(min, max);
		});

		script.set('getRandomBool', function(?chance:Float = 50):Bool {
			return FlxG.random.bool(chance);
		});

		script.set('close', function() {
			script.closed = true;
			return PythonUtils.Function_StopPy;
		});
	}

	static function getCameraByName(camera:String):FlxCamera {
		switch(camera.toLowerCase()) {
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}
		return PlayState.instance.camGame;
	}
}
#end
