package funkin.data.song;

import haxe.Json;
import lime.utils.Assets;

import funkin.play.notes.Note;
import funkin.data.stage.StageData;
import funkin.ui.debug.charting.components.PsychJsonPrinter;

typedef SwagSong =
{
	var song:String;
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
	@:optional var notesV2:Array<SongNoteV2>;
	@:optional var eventsV2:Array<SongEventV2>;
	@:optional var bpmChangesV2:Array<BpmChangeV2>;
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
	@:optional var useModcharts:Bool; // If true, the modchart manager is activated automatically without needing onInitModchart in scripts
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

// ── psych_v2 typedefs ────────────────────────────────────────────────────────

/** Flat note entry used in the psych_v2 format. */
typedef SongNoteV2 =
{
	var t:Float;               // strumTime (ms)
	var d:Int;                 // 0-3 = player, 4-7 = opponent (absolute, no mustHitSection)
	var l:Float;               // sustainLength in ms (0 = tap note)
	@:optional var type:String; // note type string; omit for default
}

/** Flat event entry used in the psych_v2 format. */
typedef SongEventV2 =
{
	var t:Float;               // time in ms
	var name:String;           // event name
	var v:Dynamic;             // arbitrary value payload
}

/** BPM change entry used in the psych_v2 format. */
typedef BpmChangeV2 =
{
	var time:Float;            // time in ms at which the new BPM takes effect
	var bpm:Float;
}

/** Full psych_v2 chart structure (serialization format; runtime uses SwagSong). */
typedef SwagSongV2 =
{
	var format:String;         // always "psych_v2"
	var song:String;
	var bpm:Float;
	var speed:Float;
	var needsVoices:Bool;
	var offset:Float;
	var stage:String;
	var characters:SongCharactersV2;
	var bpmChanges:Array<BpmChangeV2>;
	var notes:Array<SongNoteV2>;
	var events:Array<SongEventV2>;
	@:optional var arrowSkin:String;
	@:optional var splashSkin:String;
	@:optional var disableNoteRGB:Bool;
	@:optional var gameOverChar:String;
	@:optional var gameOverSound:String;
	@:optional var gameOverLoop:String;
	@:optional var gameOverEnd:String;
	@:optional var useModcharts:Bool;
}

/** Character names used in the psych_v2 format. */
typedef SongCharactersV2 =
{
	var player:String;
	var opponent:String;
	var girlfriend:String;
}

// ────────────────────────────────────────────────────────────────────────────

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

	/**
	 * Converts a runtime psych_v1 SwagSong to the psych_v2 serialization format.
	 * The returned object is meant to be JSON-serialized and saved to disk.
	 * - Sections are eliminated; notes become a flat sorted array.
	 * - mustHitSection / changeBPM are extracted into events and bpmChanges.
	 */
	public static function upgradeToV2(song:SwagSong):SwagSongV2
	{
		var bpmChanges:Array<BpmChangeV2> = [{time: 0.0, bpm: song.bpm}];
		var curBpm:Float = song.bpm;
		var curTime:Float = 0.0;

		var flatNotes:Array<SongNoteV2> = [];
		var cameraEvents:Array<SongEventV2> = [];
		var lastMustHit:Null<Bool> = null;

		if (song.notes != null)
		{
			for (section in song.notes)
			{
				if (section == null) continue;
				var beatsRaw:Null<Float> = cast section.sectionBeats;
			var beats:Float = (beatsRaw != null && !Math.isNaN(beatsRaw)) ? beatsRaw : 4.0;

				// Emit a Camera Focus event whenever mustHitSection changes
				if (lastMustHit == null || lastMustHit != section.mustHitSection)
				{
					cameraEvents.push({
						t:    curTime,
						name: 'Camera Focus',
						v:    { target: section.mustHitSection ? 'player' : 'opponent' }
					});
					lastMustHit = section.mustHitSection;
				}

				// BPM change: record new entry in bpmChanges (avoid duplicate at t=0)
				if (section.changeBPM == true && section.bpm != null && section.bpm != curBpm)
				{
					curBpm = section.bpm;
					if (curTime > 0)
						bpmChanges.push({ time: curTime, bpm: curBpm });
					else
						bpmChanges[0] = { time: 0.0, bpm: curBpm };
				}

				// Flatten notes
				if (section.sectionNotes != null)
				{
					for (note in section.sectionNotes)
					{
						if (note == null) continue;
						var noteObj:SongNoteV2 = { t: note[0], d: note[1], l: note[2] != null ? note[2] : 0.0 };
						var noteType:Dynamic = note[3];
						if (noteType != null && Std.isOfType(noteType, String) && (noteType:String).length > 0)
							noteObj.type = noteType;
						flatNotes.push(noteObj);
					}
				}

				curTime += (60000.0 / curBpm) * beats;
			}
		}

		// Convert v1 events [[time, [[name, val1, val2], ...]], ...] to flat SongEventV2 array
		var flatEvents:Array<SongEventV2> = [];
		if (song.events != null)
		{
			for (ev in song.events)
			{
				if (ev == null) continue;
				var subEvents:Array<Dynamic> = cast ev[1];
				if (subEvents == null) continue;
				for (sub in subEvents)
					flatEvents.push({ t: ev[0], name: sub[0], v: { val1: sub[1], val2: sub[2] } });
			}
		}
		// Merge camera events with song events and sort by time
		for (ce in cameraEvents) flatEvents.push(ce);
		flatEvents.sort(function(a, b) return Std.int(a.t - b.t));
		flatNotes.sort(function(a, b) return Std.int(a.t - b.t));

		var v2:SwagSongV2 = {
			format:      'psych_v2',
			song:        song.song,
			bpm:         song.bpm,
			speed:       song.speed,
			needsVoices: song.needsVoices,
			offset:      song.offset,
			stage:       song.stage != null ? song.stage : 'stage',
			characters: {
				player:    song.player1 != null ? song.player1 : 'bf',
				opponent:  song.player2 != null ? song.player2 : 'dad',
				girlfriend: song.gfVersion != null ? song.gfVersion : 'gf'
			},
			bpmChanges: bpmChanges,
			notes:       flatNotes,
			events:      flatEvents
		};

		if (song.arrowSkin  != null) v2.arrowSkin  = song.arrowSkin;
		if (song.splashSkin != null) v2.splashSkin = song.splashSkin;
		if (song.disableNoteRGB == true) v2.disableNoteRGB = true;
		if (song.gameOverChar  != null) v2.gameOverChar  = song.gameOverChar;
		if (song.gameOverSound != null) v2.gameOverSound = song.gameOverSound;
		if (song.gameOverLoop  != null) v2.gameOverLoop  = song.gameOverLoop;
		if (song.gameOverEnd   != null) v2.gameOverEnd   = song.gameOverEnd;
		if (song.useModcharts  == true) v2.useModcharts  = true;

		return v2;
	}

	/**
	 * Converts a psych_v2 JSON object back to a runtime SwagSong with sections.
	 * Called automatically by parseJSON when it detects format = "psych_v2".
	 */
	public static function downgradeFromV2(v2:Dynamic):SwagSong
	{
		var rawChanges:Array<Dynamic> = v2.bpmChanges != null ? cast v2.bpmChanges : [];
		var baseBpm:Float = v2.bpm != null ? v2.bpm : 100.0;
		var bpmChanges:Array<Dynamic> = rawChanges.copy();
		bpmChanges.sort(function(a, b) return Std.int(a.time - b.time));
		if (bpmChanges.length == 0 || bpmChanges[0].time > 0)
			bpmChanges.unshift({ time: 0.0, bpm: baseBpm });

		// Returns the active BPM at time t
		var getBpmAt = function(t:Float):Float
		{
			var bpm:Float = baseBpm;
			for (change in bpmChanges)
			{
				if (change.time <= t + 1) bpm = change.bpm;
				else break;
			}
			return bpm;
		};

		var flatNotes:Array<Dynamic>  = v2.notes  != null ? cast v2.notes  : [];
		var flatEvents:Array<Dynamic> = v2.events != null ? cast v2.events : [];

		// Find the time of the last note
		var lastTime:Float = 0;
		for (note in flatNotes)
		{
			var end:Float = note.t + (note.l != null && note.l > 0 ? note.l : 0.0);
			if (end > lastTime) lastTime = end;
		}
		if (lastTime <= 0) lastTime = (60000.0 / baseBpm) * 4;

		// Build section start times (4 beats per section in v2)
		var sectionTimes:Array<Float> = [];
		var t:Float = 0;
		while (t <= lastTime + 1)
		{
			sectionTimes.push(t);
			t += (60000.0 / getBpmAt(t)) * 4;
		}

		// Separate Camera Focus events to reconstruct mustHitSection
		var cameraEvents:Array<Dynamic> = flatEvents.filter(function(e) return e.name == 'Camera Focus');
		var otherEvents:Array<Dynamic>  = flatEvents.filter(function(e) return e.name != 'Camera Focus');
		cameraEvents.sort(function(a, b) return Std.int(a.t - b.t));

		var sectionMustHits:Array<Bool> = [];
		var camIdx:Int = 0;
		var lastMustHit:Bool = false;
		for (i in 0...sectionTimes.length)
		{
			var secStart:Float = sectionTimes[i];
			var secEnd:Float   = (i + 1 < sectionTimes.length) ? sectionTimes[i + 1] : Math.POSITIVE_INFINITY;
			while (camIdx < cameraEvents.length && cameraEvents[camIdx].t < secEnd)
			{
				var cam:Dynamic = cameraEvents[camIdx++];
				if (cam.t >= secStart)
					lastMustHit = Std.string(cam.v.target) == 'player';
			}
			sectionMustHits.push(lastMustHit);
		}

		// Build sections
		var sections:Array<SwagSection> = [];
		var lastBpm:Float = baseBpm;
		for (i in 0...sectionTimes.length)
		{
			var bpm:Float = getBpmAt(sectionTimes[i]);
			var sec:SwagSection = {
				sectionNotes:   [],
				sectionBeats:   4.0,
				mustHitSection: sectionMustHits[i]
			};
			if (bpm != lastBpm)
			{
				sec.changeBPM = true;
				sec.bpm = bpm;
				lastBpm = bpm;
			}
			sections.push(sec);
		}

		// Distribute flat notes into the correct section
		for (note in flatNotes)
		{
			var secIdx:Int = sectionTimes.length - 1;
			for (i in 0...sectionTimes.length - 1)
			{
				if (sectionTimes[i + 1] > note.t) { secIdx = i; break; }
			}
			if (secIdx >= 0 && secIdx < sections.length)
			{
				var noteArr:Array<Dynamic> = [note.t, note.d, note.l != null ? note.l : 0.0];
				var noteType:Dynamic = note.type;
				if (noteType != null && Std.string(noteType).length > 0)
					noteArr.push(Std.string(noteType));
				sections[secIdx].sectionNotes.push(noteArr);
			}
		}

		// Rebuild v1 events from other events: group by time → [[time, [[name,v1,v2], ...]], ...]
		var evGroups:Map<String, Array<Array<Dynamic>>> = [];
		var evTimes:Array<Float> = [];
		for (ev in otherEvents)
		{
			var key:String = Std.string(ev.t);
			var val1:String = (ev.v != null && ev.v.val1 != null) ? Std.string(ev.v.val1) : '';
			var val2:String = (ev.v != null && ev.v.val2 != null) ? Std.string(ev.v.val2) : '';
			if (!evGroups.exists(key)) { evGroups.set(key, []); evTimes.push(ev.t); }
			evGroups.get(key).push([ev.name, val1, val2]);
		}
		evTimes.sort(function(a, b) return Std.int(a - b));
		var builtEvents:Array<Dynamic> = [];
		for (et in evTimes) builtEvents.push([et, evGroups.get(Std.string(et))]);

		var chars:Dynamic = v2.characters != null ? v2.characters : {};
		var song:SwagSong = {
			song:        v2.song,
			notes:       sections,
			events:      builtEvents,
			bpm:         baseBpm,
			needsVoices: v2.needsVoices != null  ? v2.needsVoices : true,
			speed:       v2.speed != null        ? v2.speed       : 1.0,
			offset:      v2.offset != null       ? v2.offset      : 0.0,
			player1:     chars.player   != null  ? chars.player    : 'bf',
			player2:     chars.opponent != null  ? chars.opponent  : 'dad',
			gfVersion:   chars.girlfriend != null ? chars.girlfriend : 'gf',
			stage:       v2.stage != null        ? v2.stage       : 'stage',
			format:      'psych_v2'
		};

		if (v2.arrowSkin  != null) song.arrowSkin  = v2.arrowSkin;
		if (v2.splashSkin != null) song.splashSkin = v2.splashSkin;
		if (v2.disableNoteRGB == true) song.disableNoteRGB = true;
		if (v2.gameOverChar  != null) song.gameOverChar  = v2.gameOverChar;
		if (v2.gameOverSound != null) song.gameOverSound = v2.gameOverSound;
		if (v2.gameOverLoop  != null) song.gameOverLoop  = v2.gameOverLoop;
		if (v2.gameOverEnd   != null) song.gameOverEnd   = v2.gameOverEnd;
		if (v2.useModcharts  == true) song.useModcharts  = true;

		return song;
	}

		private static function buildRuntimeSectionsFromV2(v2:Dynamic):Array<SwagSection>
		{
			var rawChanges:Array<Dynamic> = v2.bpmChanges != null ? cast v2.bpmChanges : [];
			var baseBpm:Float = v2.bpm != null ? v2.bpm : 100.0;
			var bpmChanges:Array<Dynamic> = rawChanges.copy();
			bpmChanges.sort(function(a, b) return Std.int(a.time - b.time));
			if (bpmChanges.length == 0 || bpmChanges[0].time > 0)
				bpmChanges.unshift({ time: 0.0, bpm: baseBpm });

			var getBpmAt = function(t:Float):Float
			{
				var bpm:Float = baseBpm;
				for (change in bpmChanges)
				{
					if (change.time <= t + 1) bpm = change.bpm;
					else break;
				}
				return bpm;
			};

			var flatNotes:Array<Dynamic> = v2.notes != null ? cast v2.notes : [];
			var flatEvents:Array<Dynamic> = v2.events != null ? cast v2.events : [];

			var lastTime:Float = 0;
			for (note in flatNotes)
			{
				var end:Float = note.t + (note.l != null && note.l > 0 ? note.l : 0.0);
				if (end > lastTime) lastTime = end;
			}
			for (ev in flatEvents)
			{
				if (ev != null && ev.t != null && ev.t > lastTime)
					lastTime = ev.t;
			}
			for (change in bpmChanges)
			{
				if (change != null && change.time != null && change.time > lastTime)
					lastTime = change.time;
			}
			if (lastTime <= 0) lastTime = (60000.0 / baseBpm) * 4;

			var sectionTimes:Array<Float> = [];
			var t:Float = 0;
			while (t <= lastTime + 1)
			{
				sectionTimes.push(t);
				t += (60000.0 / getBpmAt(t)) * 4;
			}

			var cameraEvents:Array<Dynamic> = [];
			for (ev in flatEvents)
			{
				if (ev != null && ev.name == 'Camera Focus')
					cameraEvents.push(ev);
			}
			cameraEvents.sort(function(a, b) return Std.int(a.t - b.t));

			var sectionMustHits:Array<Bool> = [];
			var camIdx:Int = 0;
			var lastMustHit:Bool = false;
			for (i in 0...sectionTimes.length)
			{
				var secStart:Float = sectionTimes[i];
				var secEnd:Float = (i + 1 < sectionTimes.length) ? sectionTimes[i + 1] : Math.POSITIVE_INFINITY;
				while (camIdx < cameraEvents.length && cameraEvents[camIdx].t < secEnd)
				{
					var cam:Dynamic = cameraEvents[camIdx++];
					if (cam.t >= secStart)
					{
						var payload:Dynamic = Reflect.field(cam, 'v');
						if (payload != null && Reflect.hasField(payload, 'target'))
							lastMustHit = Std.string(Reflect.field(payload, 'target')) == 'player';
					}
				}
				sectionMustHits.push(lastMustHit);
			}

			var sections:Array<SwagSection> = [];
			var lastBpm:Float = baseBpm;
			for (i in 0...sectionTimes.length)
			{
				var bpm:Float = getBpmAt(sectionTimes[i]);
				var sec:SwagSection = {
					sectionNotes: [],
					sectionBeats: 4.0,
					mustHitSection: sectionMustHits[i]
				};
				if (bpm != lastBpm)
				{
					sec.changeBPM = true;
					sec.bpm = bpm;
					lastBpm = bpm;
				}
				sections.push(sec);
			}

			return sections;
		}

		private static function prepareRuntimeFromV2(songJson:SwagSong):SwagSong
		{
			var chars:Dynamic = Reflect.field(songJson, 'characters');
			if (chars != null)
			{
				songJson.player1 = Reflect.hasField(chars, 'player') ? Reflect.field(chars, 'player') : songJson.player1;
				songJson.player2 = Reflect.hasField(chars, 'opponent') ? Reflect.field(chars, 'opponent') : songJson.player2;
				songJson.gfVersion = Reflect.hasField(chars, 'girlfriend') ? Reflect.field(chars, 'girlfriend') : songJson.gfVersion;
			}

			songJson.notesV2 = cast (Reflect.hasField(songJson, 'notes') ? Reflect.field(songJson, 'notes') : []);
			songJson.eventsV2 = cast (Reflect.hasField(songJson, 'events') ? Reflect.field(songJson, 'events') : []);
			songJson.bpmChangesV2 = cast (Reflect.hasField(songJson, 'bpmChanges') ? Reflect.field(songJson, 'bpmChanges') : []);

			songJson.notes = buildRuntimeSectionsFromV2(songJson);
			songJson.events = [];
			return songJson;
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

		if (rawData == null) return null;
		var song:SwagSong = parseJSON(rawData, jsonInput);

		// Auto-migrate charts that are not yet in psych_v2 format.
		// Only runs for mod files (writable paths on disk), never for embedded assets.
		#if (MODS_ALLOWED && sys)
		if (song != null && _lastPath != null && sys.FileSystem.exists(_lastPath)
			&& (song.format == null || !song.format.startsWith('psych_v2')))
		{
			try
			{
				var v2:Dynamic = upgradeToV2(song);
				sys.io.File.saveContent(_lastPath, PsychJsonPrinter.print(v2, ['notes', 'events', 'bpmChanges', 'characters']));
				trace('Auto-migrated chart "$jsonInput" to psych_v2 at $_lastPath');
			}
			catch (e:Dynamic) { trace('Could not auto-migrate chart "$jsonInput": $e'); }
		}
		#end

		return song;
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
						if (fmt == 'psych_v2')
						{
							trace('loading v2 chart $nameForError, using native runtime v2 path...');
							songJson = prepareRuntimeFromV2(songJson);
						}
						else
						{
							trace('converting chart $nameForError with format $fmt to psych_v1 format...');
							songJson.format = 'psych_v1_convert';
							convert(songJson);
						}
					}
			}
		}
		return songJson;
	}
}
