#if PY_ALLOWED
package pao_py;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.FlxBasic;
import flixel.FlxObject;

import cutscenes.DialogueBoxPsych;

import objects.StrumNote;
import objects.Note;
import objects.NoteSplash;

import states.MainMenuState;
import states.StoryMenuState;
import states.FreeplayState;

import substates.PauseSubState;
import substates.GameOverSubstate;

import pao_py.PythonUtils;

import paopao.hython.Parser;
import paopao.hython.Interp;

class FunkinPython {
	public var interp:Interp = null;
	public var parser:Parser = null;
	public var scriptName:String = '';
	public var modFolder:String = null;
	public var closed:Bool = false;
	
	// Error counter for statistics
	public static var py_Errors:Int = 0;

	public var callbacks:Map<String, Dynamic> = new Map<String, Dynamic>();
	public static var customFunctions:Map<String, Dynamic> = new Map<String, Dynamic>();

	public function new(scriptName:String) {
		parser = new Parser();
		interp = new Interp();

		// Configure error handler
		interp.errorHandler = function(error:Dynamic) {
			var errorMsg:String = 'ERROR (${this.scriptName}): $error';
			trace(errorMsg);
			py_Errors++;
		};

		// Set recursion limit (optimization for Android)
		#if android
		interp.maxDepth = 50;
		#else
		interp.maxDepth = 100;
		#end

		this.scriptName = scriptName.trim();
		var game:PlayState = PlayState.instance;
		if(game != null) game.pythonArray.push(this);

		var myFolder:Array<String> = this.scriptName.split('/');
		#if MODS_ALLOWED
		if(myFolder[0] + '/' == Paths.mods() && (Mods.currentModDirectory == myFolder[1] || Mods.getGlobalMods().contains(myFolder[1])))
			this.modFolder = myFolder[1];
		#end

		// Python constants
		set('Function_StopPy', PythonUtils.Function_StopPy);
		set('Function_Stop', PythonUtils.Function_Stop);
		set('Function_Continue', PythonUtils.Function_Continue);
		set('pyDebugMode', false);

		set('PsychVersion', MainMenuState.psychEngineVersion.trim());
		set('version', MainMenuState.psychEngineVersion.trim());
		set('PlusVersion', MainMenuState.plusEngineVersion.trim());
		set('modFolder', this.modFolder);

		// Song/Week data
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('songPath', Paths.formatToSongPath(PlayState.SONG.song));
		set('loadedSongName', Song.loadedSongName);
		set('loadedSongPath', Paths.formatToSongPath(Song.loadedSongName));
		set('chartPath', Song.chartPath);
		set('startedCountdown', false);
		set('curStage', PlayState.SONG.stage);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);

		set('difficultyName', Difficulty.getString(false));
		set('difficultyPath', Difficulty.getFilePath());
		set('difficultyNameTranslation', Difficulty.getString(true));
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.weeksList[PlayState.storyWeek]);
		set('seenCutscene', PlayState.seenCutscene);
		set('hasVocals', PlayState.SONG.needsVoices);

		// Screen data
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState-only variables
		if(game != null)
		@:privateAccess
		{
			var curSection:SwagSection = PlayState.SONG.notes[game.curSection];
			set('curSection', game.curSection);
			set('curBeat', game.curBeat);
			set('curStep', game.curStep);
			set('curDecBeat', game.curDecBeat);
			set('curDecStep', game.curDecStep);

			set('score', game.songScore);
			set('misses', game.songMisses);
			set('hits', game.songHits);
			set('combo', game.combo);
			set('deaths', PlayState.deathCounter);

			set('rating', game.ratingPercent);
			set('ratingName', game.ratingName);
			set('ratingFC', game.ratingFC);
			set('totalPlayed', game.totalPlayed);
			set('totalNotesHit', game.totalNotesHit);

			set('inGameOver', GameOverSubstate.instance != null);
			set('mustHitSection', curSection != null ? (curSection.mustHitSection == true) : false);
			set('altAnim', curSection != null ? (curSection.altAnim == true) : false);
			set('gfSection', curSection != null ? (curSection.gfSection == true) : false);

			set('healthGainMult', game.healthGain);
			set('healthLossMult', game.healthLoss);

			#if FLX_PITCH
			set('playbackRate', game.playbackRate);
			#else
			set('playbackRate', 1);
			#end

			set('guitarHeroSustains', game.guitarHeroSustains);
			set('instakillOnMiss', game.instakillOnMiss);
			set('botPlay', game.cpuControlled);
			set('practice', game.practiceMode);

			for (i in 0...4) {
				set('defaultPlayerStrumX' + i, 0);
				set('defaultPlayerStrumY' + i, 0);
				set('defaultOpponentStrumX' + i, 0);
				set('defaultOpponentStrumY' + i, 0);
			}

			// Default character positions
			set('defaultBoyfriendX', game.BF_X);
			set('defaultBoyfriendY', game.BF_Y);
			set('defaultOpponentX', game.DAD_X);
			set('defaultOpponentY', game.DAD_Y);
			set('defaultGirlfriendX', game.GF_X);
			set('defaultGirlfriendY', game.GF_Y);

			set('boyfriendName', game.boyfriend != null ? game.boyfriend.curCharacter : PlayState.SONG.player1);
			set('dadName', game.dad != null ? game.dad.curCharacter : PlayState.SONG.player2);
			set('gfName', game.gf != null ? game.gf.curCharacter : PlayState.SONG.gfVersion);
		}

		// Client settings
		set('downscroll', ClientPrefs.data.downScroll);
		set('middlescroll', ClientPrefs.data.middleScroll);
		set('framerate', ClientPrefs.data.framerate);
		set('ghostTapping', ClientPrefs.data.ghostTapping);
		set('hideHud', ClientPrefs.data.hideHud);
		set('timeBarType', ClientPrefs.data.timeBarType);
		set('scoreZoom', ClientPrefs.data.scoreZoom);
		set('cameraZoomOnBeat', ClientPrefs.data.camZooms);
		set('flashingLights', ClientPrefs.data.flashing);
		set('noteOffset', ClientPrefs.data.noteOffset);
		set('healthBarAlpha', ClientPrefs.data.healthBarAlpha);
		set('noResetButton', ClientPrefs.data.noReset);
		set('lowQuality', ClientPrefs.data.lowQuality);
		set('shadersEnabled', ClientPrefs.data.shaders);
		set('scriptName', this.scriptName);
		set('currentModDirectory', Mods.currentModDirectory);

		// Expose basic functions
		PythonFunctions.implement(this);
	}

	public function set(variable:String, data:Dynamic) {
		if(interp == null) return;
		@:privateAccess
		interp.variables.set(variable, data);
	}

	public function get(variable:String):Dynamic {
		if(interp == null) return null;
		@:privateAccess
		return interp.variables.get(variable);
	}

	public function call(func:String, args:Array<Dynamic> = null):Dynamic {
		if(interp == null || closed) return PythonUtils.Function_Continue;
		
		try {
			if(args == null) args = [];
			return interp.calldef(func, args);
		} catch(e:Dynamic) {
			trace('ERROR calling Python function "$func" (${this.scriptName}): $e');
			py_Errors++;
		}
		return PythonUtils.Function_Continue;
	}

	public function executeCode(code:String):Dynamic {
		if(interp == null || closed) return null;
		
		try {
			var expr = parser.parseString(code);
			return interp.execute(expr);
		} catch(e:Dynamic) {
			var errorMsg = 'ERROR executing Python code (${this.scriptName}): $e';
			trace(errorMsg);
			py_Errors++;
		}
		return null;
	}

	public function executeFile(path:String):Void {
		if(interp == null || closed) return;
		
		#if MODS_ALLOWED
		var filePath:String = Paths.modFolders(path);
		if(!FileSystem.exists(filePath))
			filePath = Paths.getSharedPath(path);

		if(!FileSystem.exists(filePath)) {
			trace('ERROR: Python file not found: $path');
			return;
		}

		try {
			var code:String = File.getContent(filePath);
			var expr = parser.parseString(code);
			interp.execute(expr);
		} catch(e:Dynamic) {
			trace('ERROR executing Python file "$path" (${this.scriptName}): $e');
			py_Errors++;
		}
		#end
	}

	public function stop() {
		closed = true;
		
		if(interp != null) {
			interp = null;
		}
		
		if(parser != null) {
			parser = null;
		}
	}

	public static function resetErrors():Void {
		py_Errors = 0;
	}
}
#end
