package funkin.data.stepmania;

import funkin.data.song.Song;
#if !(mac || ios)
import moonchart.formats.StepMania;
import moonchart.formats.fnf.legacy.FNFPsych;
import moonchart.formats.BasicFormat;
import moonchart.backend.FormatData;
import moonchart.backend.Timing;
#end

/**
 * Wrapper used to load StepMania files through Moonchart.
 * Keeps compatibility with the previous interface while using Moonchart internally.
 */
class SMFile
{
	public var header:SMHeader;
	public var difficulties:Array<SMDifficulty> = [];
	public var isValid:Bool = true;

	// Moonchart objects
	#if !(mac || ios)
	private var moonchartSM:StepMania;
	#end
	private var smFilePath:String;

	public function new(data:String, ?filePath:String = null)
	{
		this.smFilePath = filePath;
		parseFile(data);
	}

	public static function loadFile(path:String):SMFile
	{
		#if sys
		if (!sys.FileSystem.exists(path))
		{
			return null;
		}

		var content = sys.io.File.getContent(path);
		return new SMFile(content, path);
		#else
		return null;
		#end
	}

	function parseFile(data:String):Void
	{
		#if !(mac || ios)
		try
		{
			// Initialize Moonchart if it has not been initialized yet.
			moonchart.Moonchart.init();

			// Parse the SM file through Moonchart.
			moonchartSM = new StepMania();
			moonchartSM.fromStepMania(data);

			// Extract header information.
			var basicChart = moonchartSM.toBasicFormat();
			var meta = basicChart.meta;

			// Create a header compatible with the previous implementation.
			header = new SMHeader("");
			header.TITLE = meta.title ?? "Unknown";
			header.ARTIST = cast(meta.extraData.get("SONG_ARTIST"), String) ?? "Unknown";
			header.MUSIC = cast(meta.extraData.get("AUDIO_FILE"), String) ?? "audio.ogg";
			header.OFFSET = Std.string(meta.offset ?? 0.0);

			// Build the BPMS string from BPM changes.
			var bpmsArray:Array<String> = [];
			var totalBeats:Float = 0;
			for (i in 0...meta.bpmChanges.length)
			{
				var bpmChange = meta.bpmChanges[i];

				if (i > 0)
				{
					var prevChange = meta.bpmChanges[i - 1];
					var timeDiff = bpmChange.time - prevChange.time;
					var beatsInPeriod = (timeDiff / 1000.0) * (prevChange.bpm / 60.0);
					totalBeats += beatsInPeriod;
				}

				bpmsArray.push('$totalBeats=${bpmChange.bpm}');
			}
			header.BPMS = bpmsArray.join(',');

			// Rebuild BPM changes for the compatibility header.
			header.parseBPMChanges();

			// Keep compatibility even if the file extension is not .ogg.
			if (!header.MUSIC.toLowerCase().endsWith('.ogg'))
			{
			}

			// Extract difficulties from Moonchart data.
			var smData:Dynamic = moonchartSM.data;
			if (smData != null && smData.NOTES != null)
			{
				var notesMap:Map<String, Dynamic> = smData.NOTES;

				for (diffName in notesMap.keys())
				{
					var diffData:Dynamic = notesMap.get(diffName);

					// Determine whether the chart is double based on the dance type.
					var isDouble = false;
					if (Reflect.hasField(diffData, 'dance'))
					{
						var danceType:String = Reflect.field(diffData, 'dance');
						isDouble = (danceType == 'dance-double');
					}

					difficulties.push({
						name: diffName,
						isDouble: isDouble,
						measures: [] // Measures are not needed when Moonchart handles parsing.
					});
				}
			}

			if (difficulties.length == 0)
			{
				isValid = false;
				return;
			}
		}
		catch (e:Dynamic)
		{
			isValid = false;
		}
		#else
		isValid = false;
		#end
	}

	/**
	 * Convert the SMFile to a FNF SwagSong format using Moonchart
	 * @param songName 
	 * @param difficultyIndex 
	 */
	public function convertToFNF(songName:String, difficultyIndex:Int = 0):SwagSong
	{
		#if !(mac || ios)
		if (!isValid)
		{
			return null;
		}

		if (songName == null || songName.trim() == "")
		{
			return null;
		}

		if (header == null)
		{
			return null;
		}

		if (difficultyIndex < 0 || difficultyIndex >= difficulties.length)
		{
			return null;
		}

		try
		{
			// Read the chosen difficulty name.
			var diffName = difficulties[difficultyIndex].name;

			// Convert through Moonchart: SM -> BasicFormat -> Psych.
			var basicChart = moonchartSM.toBasicFormat();

			// Create the Psych converter.
			var psychConverter = new FNFPsych();

			// Convert from BasicFormat to Psych.
			psychConverter.fromBasicFormat(basicChart, diffName);

			// Read the generated Psych data.
			var psychData = psychConverter.data;

			if (psychData == null || psychData.song == null)
			{
				return null;
			}

			// Convert from PsychJsonFormat to SwagSong.
			var psychSong = psychData.song;

			var song:SwagSong = {
				song: songName,
				notes: [],
				events: [],
				bpm: psychSong.bpm,
				needsVoices: false,
				player1: 'bf',
				player2: 'dad',
				gfVersion: psychSong.gfVersion ?? 'gf',
				speed: psychSong.speed,
				stage: psychSong.stage ?? 'notitg',
				format: 'psych_v1',
				offset: 0,
				disableNoteRGB: false
			};

			// Convert sections.
			if (psychSong.notes != null)
			{
				for (section in psychSong.notes)
				{
					var swagSection:SwagSection = {
						sectionNotes: [],
						sectionBeats: 4, // Psych stores lengthInSteps, so keep the standard 4-beat section here.
						mustHitSection: section.mustHitSection,
						gfSection: false, // FNFLegacySection does not expose this field through Moonchart.
						bpm: section.bpm ?? 0,
						changeBPM: section.changeBPM ?? false,
						altAnim: section.altAnim ?? false
					};

					// Copy notes.
					if (section.sectionNotes != null)
					{
						for (note in section.sectionNotes)
						{
							swagSection.sectionNotes.push(note);
						}
					}

					song.notes.push(swagSection);
				}
			}

			// Copy events.
			if (psychSong.events != null)
			{
				for (event in psychSong.events)
				{
					song.events.push(event);
				}
			}
			return song;
		}
		catch (e:Dynamic)
		{
			return null;
		}
		#else
		return null;
		#end
	}

	function createNewSection(isDouble:Bool = false):SwagSection
	{
		return {
			sectionNotes: [],
			sectionBeats: 4,
			mustHitSection: !isDouble,
			gfSection: false,
			bpm: 0,
			changeBPM: false,
			altAnim: false
		};
	}
}

typedef SMDifficulty =
{
	var name:String;
	var isDouble:Bool;
	var measures:Array<SMMeasure>;
}

/**
 * TimingStruct keeps compatibility with the previous code.
 * Moonchart now handles the timing internally.
 */
class TimingStruct
{
	public static var allTimings:Array<TimingData> = [];

	public static function clearTimings():Void
	{
		allTimings = [];
	}

	public static function addTiming(startBeat:Float, bpm:Float, endBeat:Float, offset:Float):Void
	{
		allTimings.push({
			startBeat: startBeat,
			bpm: bpm,
			endBeat: endBeat,
			startTime: offset,
			length: 0
		});
	}

	public static function getTimingAtBeat(beat:Float):TimingData
	{
		for (timing in allTimings)
		{
			if (beat >= timing.startBeat && beat < timing.endBeat)
			{
				return timing;
			}
		}
		return allTimings.length > 0 ? allTimings[0] : {
			startBeat: 0,
			bpm: 100,
			endBeat: 999999,
			startTime: 0,
			length: 0
		};
	}
}

typedef TimingData =
{
	var startBeat:Float;
	var bpm:Float;
	var endBeat:Float;
	var startTime:Float;
	var length:Float;
}
