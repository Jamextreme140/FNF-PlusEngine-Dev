package funkin.ui.debug.charting.components;

// Credits: Codename Engine by CodenameCrew
// https://github.com/CodenameCrew/CodenameEngine

import funkin.data.song.Song;
import funkin.ui.debug.charting.components.VSlice.PsychPackage;
import funkin.ui.mainmenu.MainMenuState;
import flixel.util.FlxSort;

/** Root Codename Engine chart data structure. */
typedef CodenameChart =
{
	var strumLines:Array<CodenameStrumLine>;
	var events:Array<CodenameEvent>;
	var ?meta:CodenameMetaData;
	var codenameChart:Bool;
	var ?stage:String;
	var scrollSpeed:Float;
	var noteTypes:Array<String>;
	var ?chartVersion:String;
}

/** Song/difficulty metadata stored in meta.json or embedded in the chart. */
typedef CodenameMetaData =
{
	var name:String;
	var ?bpm:Float;
	var ?beatsPerMeasure:Float;
	var ?stepsPerBeat:Int;
	var ?needsVoices:Bool;
	var ?displayName:String;
}

/** A strum line (opponent / player / additional). */
typedef CodenameStrumLine =
{
	var characters:Array<String>;
	/** 0 = OPPONENT, 1 = PLAYER, 2 = ADDITIONAL (GF / spectator). */
	var type:Int;
	var notes:Array<CodenameNote>;
	var position:String;
	var ?scrollSpeed:Null<Float>;
	var ?keyCount:Null<Int>;
}

/** A single note inside a strum line. */
typedef CodenameNote =
{
	/** Hit time in ms. */
	var time:Float;
	/** Column index within the strum line (0-3 for a standard 4K lane). */
	var id:Int;
	/** 1-based index into noteTypes; 0 = default note. */
	var type:Int;
	/** Sustain / hold length in ms. */
	var sLen:Float;
}

/** A chart event. */
typedef CodenameEvent =
{
	var name:String;
	var time:Float;
	var params:Array<Dynamic>;
	var ?global:Bool;
}

class CodenameEngine
{
	static inline final DEFAULT_BPM:Float = 100.0;
	static inline final DEFAULT_BEATS_PER_MEASURE:Float = 4.0;

	/**
	 * Converts a Codename Engine chart (and optional separate meta) into a PsychPackage
	 * compatible with Psych Engine 1.0 / FNF Plus Engine.
	 *
	 * Credits: Codename Engine by CodenameCrew
	 * https://github.com/CodenameCrew/CodenameEngine
	 *
	 * @param chart       Parsed Codename chart JSON.
	 * @param extraMeta   Optional meta loaded from a separate meta.json file.
	 *                    Used only when the chart does not contain embedded meta.
	 * @param diffName    Difficulty name used as the key in the returned package's difficulties map.
	 */
	public static function convertToPsych(chart:CodenameChart, ?extraMeta:CodenameMetaData, ?diffName:String = 'normal'):PsychPackage
	{
		var meta:CodenameMetaData = chart.meta != null ? chart.meta : extraMeta;

		var songName:String = 'converted';
		if (meta != null)
			songName = (meta.displayName != null && meta.displayName.length > 0) ? meta.displayName : meta.name;

		var baseBpm:Float = (meta != null && meta.bpm != null && meta.bpm > 0) ? meta.bpm : DEFAULT_BPM;
		var beatsPerMeasure:Float = (meta != null && meta.beatsPerMeasure != null && meta.beatsPerMeasure > 0) ? meta.beatsPerMeasure : DEFAULT_BEATS_PER_MEASURE;

		var noteTypes:Array<String> = chart.noteTypes != null ? chart.noteTypes : [];
		var strumLines:Array<CodenameStrumLine> = chart.strumLines != null ? chart.strumLines : [];

		// Sort and classify events
		var events:Array<CodenameEvent> = chart.events != null ? chart.events.copy() : [];
		events.sort(sortByTime);

		var bpmChanges:Array<CodenameEvent> = events.filter(function(e) return e.name == 'BPM Change');
		var camChanges:Array<CodenameEvent> = events.filter(function(e) return e.name == 'Camera Movement');
		// Exclude events handled implicitly (camera / BPM / alt anim) and global event files
		var otherEvents:Array<CodenameEvent> = events.filter(function(e)
			return e.name != 'Camera Movement'
				&& e.name != 'BPM Change'
				&& e.name != 'Alt Animation Toggle'
				&& e.global != true
		);

		// Returns the active BPM at time t using BPM Change events
		var getBpmAt = function(t:Float):Float
		{
			var bpm:Float = baseBpm;
			for (change in bpmChanges)
			{
				if (change.time <= t + 1)
					bpm = change.params[0];
				else
					break;
			}
			return bpm;
		};

		// Find the time of the last note (including sustain length)
		var lastNoteTime:Float = 0;
		for (sl in strumLines)
		{
			if (sl.notes == null) continue;
			for (note in sl.notes)
			{
				var endTime:Float = note.time + (note.sLen > 0 ? note.sLen : 0);
				if (endTime > lastNoteTime)
					lastNoteTime = endTime;
			}
		}
		// Always generate at least one section
		if (lastNoteTime <= 0)
			lastNoteTime = (60000.0 / baseBpm) * beatsPerMeasure;

		// Build section start times using correct BPM at each boundary
		var sectionTimes:Array<Float> = [];
		var time:Float = 0;
		while (time <= lastNoteTime + 1)
		{
			sectionTimes.push(time);
			var bpm:Float = getBpmAt(time);
			time += (60000.0 / bpm) * beatsPerMeasure;
		}

		// Compute mustHitSection per section from Camera Movement events.
		// Camera Movement params[0] = strumLine index; PLAYER type (1) → mustHitSection = true.
		// This mirrors how FNFLegacyParser.__convertToSwagSections assigns mustHitSection.
		var sectionMustHits:Array<Bool> = [];
		var lastMustHit:Bool = false;
		var camIdx:Int = 0;

		for (i in 0...sectionTimes.length)
		{
			var sectionStart:Float = sectionTimes[i];
			var sectionEnd:Float = (i + 1 < sectionTimes.length) ? sectionTimes[i + 1] : Math.POSITIVE_INFINITY;

			while (camIdx < camChanges.length && camChanges[camIdx].time < sectionEnd)
			{
				var cam:CodenameEvent = camChanges[camIdx++];
				if (cam.time >= sectionStart)
				{
					var idx:Int = Std.int(cam.params[0]);
					if (idx < strumLines.length)
						lastMustHit = (strumLines[idx].type == 1); // PLAYER = 1
				}
			}
			sectionMustHits.push(lastMustHit);
		}

		// Build SwagSection array
		var swagSections:Array<SwagSection> = [];
		var lastBpm:Float = baseBpm;

		for (i in 0...sectionTimes.length)
		{
			var sec:SwagSection = emptySection();
			sec.mustHitSection = (i < sectionMustHits.length) ? sectionMustHits[i] : false;

			var bpm:Float = getBpmAt(sectionTimes[i]);
			if (bpm != lastBpm)
			{
				sec.changeBPM = true;
				sec.bpm = bpm;
				lastBpm = bpm;
			}
			swagSections.push(sec);
		}

		// Distribute notes from each strum line into the correct section and column.
		// Note column mapping (inverse of FNFLegacyParser.parse logic):
		//   needsOffset = (isPlayer) XOR (mustHitSection)
		//   noteData    = note.id + (needsOffset ? 4 : 0)
		for (sl in strumLines)
		{
			if (sl.notes == null || sl.type > 1) continue; // Skip GF / spectator strum lines

			var isPlayer:Bool = (sl.type == 1);

			for (note in sl.notes)
			{
				// Locate the containing section
				var secIdx:Int = sectionTimes.length - 1;
				for (i in 0...sectionTimes.length - 1)
				{
					if (sectionTimes[i + 1] > note.time)
					{
						secIdx = i;
						break;
					}
				}
				if (secIdx < 0 || secIdx >= swagSections.length) continue;

				var mustHit:Bool = swagSections[secIdx].mustHitSection;
				var needsOffset:Bool = isPlayer != mustHit;
				var noteData:Int = note.id + (needsOffset ? 4 : 0);

				// Resolve note type string (noteTypes is 0-indexed; note.type is 1-based)
				var noteTypeStr:String = '';
				if (note.type > 0 && note.type <= noteTypes.length)
				{
					var t:String = noteTypes[note.type - 1];
					if (t != null && t != 'Default Note')
						noteTypeStr = t;
				}

				var psychNote:Array<Dynamic> = [note.time, noteData, note.sLen];
				if (noteTypeStr.length > 0)
					psychNote.push(noteTypeStr);

				swagSections[secIdx].sectionNotes.push(psychNote);
			}
		}

		// Extract character names from strum lines
		var player1:String = 'bf';
		var player2:String = 'dad';
		var gfVersion:String = 'gf';

		for (sl in strumLines)
		{
			var chars:Array<String> = sl.characters != null ? sl.characters : [];
			switch (sl.type)
			{
				case 0: if (chars.length > 0) player2   = chars[0]; // OPPONENT
				case 1: if (chars.length > 0) player1   = chars[0]; // PLAYER
				case 2: if (chars.length > 0) gfVersion = chars[0]; // ADDITIONAL
			}
		}

		var generatedBy:String = 'Psych Engine v${MainMenuState.psychEngineVersion} - Chart Editor Codename Engine Importer (https://github.com/CodenameCrew/CodenameEngine)';

		var swagSong:SwagSong = {
			song:        songName,
			notes:       swagSections,
			events:      [],
			bpm:         baseBpm,
			needsVoices: (meta != null && meta.needsVoices != null) ? meta.needsVoices : true,
			speed:       chart.scrollSpeed > 0 ? chart.scrollSpeed : 1.0,
			offset:      0,
			player1:     player1,
			player2:     player2,
			gfVersion:   gfVersion,
			stage:       (chart.stage != null && chart.stage.length > 0) ? chart.stage : 'stage',
			format:      'psych_v1_convert'
		};

		Reflect.setField(swagSong, 'generatedBy', generatedBy);

		// Convert remaining events to Psych format: [time, [[name, val1, val2], ...]]
		var fileEvents:Array<Dynamic> = null;
		if (otherEvents.length > 0)
		{
			// Group events at the same timestamp
			var groupedTimes:Array<Float> = [];
			var groupedMap:Map<String, Array<Array<Dynamic>>> = [];

			for (event in otherEvents)
			{
				var key:String = Std.string(event.time);
				var params:Array<Dynamic> = event.params != null ? event.params : [];
				var val1:String = params.length > 0 ? Std.string(params[0]) : '';
				var val2:String = params.length > 1 ? Std.string(params[1]) : '';
				var psychEvent:Array<Dynamic> = [event.name, val1, val2];

				if (!groupedMap.exists(key))
				{
					groupedMap.set(key, []);
					groupedTimes.push(event.time);
				}
				groupedMap.get(key).push(psychEvent);
			}

			groupedTimes.sort(function(a, b) return a < b ? -1 : (a > b ? 1 : 0));

			fileEvents = [];
			for (t in groupedTimes)
				fileEvents.push([t, groupedMap.get(Std.string(t))]);
		}

		var difficulties:Map<String, SwagSong> = [];
		difficulties.set(diffName, swagSong);

		return {
			difficulties: difficulties,
			events: fileEvents != null ? {events: fileEvents, format: 'psych_v1_convert'} : null
		};
	}

	static function emptySection():SwagSection
	{
		return {
			sectionNotes: [],
			sectionBeats: 4,
			mustHitSection: false
		};
	}

	static function sortByTime(a:CodenameEvent, b:CodenameEvent):Int
		return FlxSort.byValues(FlxSort.ASCENDING, a.time, b.time);
}
