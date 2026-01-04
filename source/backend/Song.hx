package backend;

import haxe.Json;
import lime.utils.Assets;

import objects.Note;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var offset:Float;

	var player1:String;
	var player2:String;
	var gfVersion:String;
	var stage:String;
	var format:String;

	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	
	@:optional var disableNoteRGB:Bool;

	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
	@:optional var isAnimated:Bool; // Soporte para íconos animados en el chart
}

typedef SwagSection =
{
	var sectionNotes:Array<Dynamic>;
	var sectionBeats:Float;
	var mustHitSection:Bool;
	@:optional var altAnim:Bool;
	@:optional var gfSection:Bool;
	@:optional var bpm:Float;
	@:optional var changeBPM:Bool;
}

class Song
{
	public var song:String;
	public var notes:Array<SwagSection>;
	public var events:Array<Dynamic>;
	public var bpm:Float;
	public var needsVoices:Bool = true;
	public var arrowSkin:String;
	public var splashSkin:String;
	public var gameOverChar:String;
	public var gameOverSound:String;
	public var gameOverLoop:String;
	public var gameOverEnd:String;
	public var disableNoteRGB:Bool = false;
	public var speed:Float = 1;
	public var stage:String;
	public var player1:String = 'bf';
	public var player2:String = 'dad';
	public var gfVersion:String = 'gf';
	public var format:String = 'psych_v1';

	public static function convert(songJson:Dynamic) // Convert old charts to psych_v1 format
	{
		if(songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			if(Reflect.hasField(songJson, 'player3')) Reflect.deleteField(songJson, 'player3');
		}

		if(songJson.events == null)
		{
			songJson.events = [];
			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;
				while(i < len)
				{
					var note:Array<Dynamic> = notes[i];
					if(note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);
						len = notes.length;
					}
					else i++;
				}
			}
		}

		var sectionsData:Array<SwagSection> = songJson.notes;
		if(sectionsData == null) return;

		for (section in sectionsData)
		{
			var beats:Null<Float> = cast section.sectionBeats;
			if (beats == null || Math.isNaN(beats))
			{
				section.sectionBeats = 4;
				if(Reflect.hasField(section, 'lengthInSteps')) Reflect.deleteField(section, 'lengthInSteps');
			}

			for (note in section.sectionNotes)
			{
				var gottaHitNote:Bool = (note[1] < 4) ? section.mustHitSection : !section.mustHitSection;
				note[1] = (note[1] % 4) + (gottaHitNote ? 0 : 4);

				if(!Std.isOfType(note[3], String))
					note[3] = Note.defaultNoteTypes[note[3]]; //compatibility with Week 7 and 0.1-0.3 psych charts
			}
		}
	}

	public static var chartPath:String;
	public static var loadedSongName:String;
	public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		PlayState.SONG = getChart(jsonInput, folder);
		loadedSongName = folder;
		chartPath = _lastPath;
		#if windows
		// prevent any saving errors by fixing the path on Windows (being the only OS to ever use backslashes instead of forward slashes for paths)
		chartPath = chartPath.replace('/', '\\');
		#end
		StageData.loadDirectory(PlayState.SONG);
		return PlayState.SONG;
	}

	static var _lastPath:String;
	public static function getChart(jsonInput:String, ?folder:String):SwagSong
	{
		if(folder == null) folder = jsonInput;
		var rawData:String = null;
		
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);
		_lastPath = Paths.json('$formattedFolder/$formattedSong');

		#if MODS_ALLOWED
		// Psych 0.7.3 compatibility: if chart doesn't exist,
		// try loading with "-normal" suffix for older mods
		var pathExists:Bool = FileSystem.exists(_lastPath);
		if(!pathExists)
		{
			// Check if jsonInput already has a difficulty suffix
			var hasDifficultySuffix:Bool = false;
			for(diff in Difficulty.list)
			{
				var diffSuffix:String = '-' + Paths.formatToSongPath(diff);
				if(formattedSong.endsWith(diffSuffix))
				{
					hasDifficultySuffix = true;
					break;
				}
			}
			
			// If it doesn't have suffix, try "-normal" (0.7.3 compatibility)
			if(!hasDifficultySuffix)
			{
				var normalDiff:String = Paths.formatToSongPath(Difficulty.getDefault()); // "normal"
				var altPath:String = Paths.json('$formattedFolder/$formattedSong-$normalDiff');
				if(FileSystem.exists(altPath))
				{
					_lastPath = altPath;
					pathExists = true;
					trace('Psych 0.7.3 Compatibility: Using "$formattedSong-$normalDiff" chart');
				}
			}

			// Fallback for engines/mods that store difficulty charts in a suffixed folder
			// Example: data/bopeebo-erect/bopeebo-erect.json instead of data/bopeebo/bopeebo-erect.json
			if(!pathExists)
			{
				var suffixedFolder:String = formattedSong; // use the song+difficulty as folder
				var altPath2:String = Paths.json('$suffixedFolder/$formattedSong');
				if(FileSystem.exists(altPath2))
				{
					_lastPath = altPath2;
					pathExists = true;
					trace('Chart fallback: Using suffixed folder "$suffixedFolder/$formattedSong"');
				}
			}

			// P-Slice style: charts stored inside "<base>-erect" folder with filenames like "<base>-erect-erect.json" or "<base>-erect-nightmare.json"
			if(!pathExists && formattedSong.indexOf('-') > -1)
			{
				var baseName:String = formattedFolder; // folder param is the base song name
				var diffSuffix:String = formattedSong.substr(baseName.length + 1);
				var erectFolder:String = baseName + '-erect';
				var pSlicePath:String = Paths.json('$erectFolder/$baseName-erect-$diffSuffix');
				if(FileSystem.exists(pSlicePath))
				{
					_lastPath = pSlicePath;
					pathExists = true;
					trace('Chart fallback: Using P-Slice style path "$erectFolder/$baseName-erect-$diffSuffix"');
				}
			}

			// Additional fallback for double-suffix charts (e.g., base-erect-nightmare)
			if(!pathExists && formattedSong.indexOf('-') > -1)
			{
				var baseName:String = formattedSong.substr(0, formattedSong.indexOf('-'));
				var diffSuffix:String = formattedSong.substr(baseName.length + 1);
				var doubleSuffixedFolder:String = baseName + '-erect-' + diffSuffix;
				var altPath3:String = Paths.json('$doubleSuffixedFolder/$baseName-erect-$diffSuffix');
				if(FileSystem.exists(altPath3))
				{
					_lastPath = altPath3;
					pathExists = true;
					trace('Chart fallback: Using double-suffixed folder "$doubleSuffixedFolder/$baseName-erect-$diffSuffix"');
				}
			}
		}
		
		if(pathExists)
			rawData = File.getContent(_lastPath);
		else
		#end
		{
			// Non-mods build: use OpenFL assets and try suffixed-folder fallback if needed
			var openflPath:String = _lastPath;
			if(!Assets.exists(openflPath))
			{
				var suffixedFolder:String = formattedSong;
				var altPath2:String = Paths.json('$suffixedFolder/$formattedSong');
				if(Assets.exists(altPath2))
				{
					_lastPath = altPath2;
					trace('Chart fallback (OpenFL): Using suffixed folder "$suffixedFolder/$formattedSong"');
				}

				// P-Slice style: charts stored inside "<base>-erect" folder with filenames like "<base>-erect-erect.json" or "<base>-erect-nightmare.json"
				if(_lastPath == openflPath && formattedSong.indexOf('-') > -1)
				{
					var baseName:String = formattedFolder; // folder param is the base song name
					var diffSuffix:String = formattedSong.substr(baseName.length + 1);
					var erectFolder:String = baseName + '-erect';
					var pSlicePath:String = Paths.json('$erectFolder/$baseName-erect-$diffSuffix');
					if(Assets.exists(pSlicePath))
					{
						_lastPath = pSlicePath;
						trace('Chart fallback (OpenFL): Using P-Slice style path "$erectFolder/$baseName-erect-$diffSuffix"');
					}
				}

				// Additional fallback for double-suffix charts (e.g., base-erect-nightmare)
				if(_lastPath == openflPath && formattedSong.indexOf('-') > -1)
				{
					var baseName:String = formattedSong.substr(0, formattedSong.indexOf('-'));
					var diffSuffix:String = formattedSong.substr(baseName.length + 1);
					var doubleSuffixedFolder:String = baseName + '-erect-' + diffSuffix;
					var altPath3:String = Paths.json('$doubleSuffixedFolder/$baseName-erect-$diffSuffix');
					if(Assets.exists(altPath3))
					{
						_lastPath = altPath3;
						trace('Chart fallback (OpenFL): Using double-suffixed folder "$doubleSuffixedFolder/$baseName-erect-$diffSuffix"');
					}
				}
			}
			rawData = Assets.getText(_lastPath);
		}

		return rawData != null ? parseJSON(rawData, jsonInput) : null;
	}

	public static function parseJSON(rawData:String, ?nameForError:String = null, ?convertTo:String = 'psych_v1'):SwagSong
	{
		var songJson:SwagSong = cast Json.parse(rawData);
		if(Reflect.hasField(songJson, 'song'))
		{
			var subSong:SwagSong = Reflect.field(songJson, 'song');
			if(subSong != null && Type.typeof(subSong) == TObject)
				songJson = subSong;
		}

		if(convertTo != null && convertTo.length > 0)
		{
			var fmt:String = songJson.format;
			if(fmt == null) fmt = songJson.format = 'unknown';

			switch(convertTo)
			{
				case 'psych_v1':
					if(!fmt.startsWith('psych_v1')) //Convert to Psych 1.0 format
					{
						trace('converting chart $nameForError with format $fmt to psych_v1 format...');
						songJson.format = 'psych_v1_convert';
						convert(songJson);
					}
			}
		}
		return songJson;
	}
}
