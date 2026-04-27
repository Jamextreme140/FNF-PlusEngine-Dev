package funkin.ui.debug.modcharting;

import funkin.audio.Conductor;
import funkin.data.song.Song;
import funkin.data.song.Song.SwagSection;
import funkin.data.song.Song.SwagSong;
import funkin.data.stage.StageData;
import funkin.modding.modchart.Manager;
import funkin.modding.modchart.backend.standalone.adapters.psych.ModchartEditorPreviewContext;
import funkin.modding.modchart.engine.events.EventType;
import funkin.modding.modchart.engine.events.types.AddEvent;
import funkin.modding.modchart.engine.events.types.EaseEvent;
import funkin.modding.modchart.engine.modifiers.ModifierGroup;
import funkin.modding.modchart.engine.modifiers.list.PathModifier;
import funkin.modding.modchart.engine.modifiers.list.PathModifier.PathNode;
#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
import funkin.modding.scripting.psychlua.LuaUtils;
#end
import funkin.play.PlayState;
import funkin.play.notes.Note;
import funkin.play.notes.NoteSplash;
import funkin.play.notes.StrumNote;
import funkin.play.scoring.Rating;
import funkin.ui.components.PsychUIButton;
import funkin.ui.components.PsychUIBox;
import funkin.ui.components.PsychUIDropDownMenu;
import funkin.ui.components.PsychUIInputText;
import funkin.ui.components.PsychUINumericStepper;
import funkin.ui.components.PsychUISkin;
import funkin.ui.debug.charting.components.Prompt.BasePrompt;
import funkin.ui.debug.MasterEditorMenu;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.text.FlxText.FlxTextBorderStyle;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import haxe.io.Path;
import lime.system.Clipboard;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.events.KeyboardEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
#if sys
import sys.FileSystem;
#end

using StringTools;

typedef LuaEditorModifierEntry = {
	var name:String;
	var field:Int;
}

typedef LuaEditorEventEntry = {
	var type:String;
	var target:String;
	var beat:Float;
	var value:Float;
	var length:Float;
	var ease:String;
	var player:Int;
	var field:Int;
}

typedef LuaEditorPlayStateCapture = {
	var playfieldCount:Int;
	var timelineBeat:Float;
	var modifiers:Array<LuaEditorModifierEntry>;
	var events:Array<LuaEditorEventEntry>;
	@:optional var projectName:String;
	@:optional var scriptPaths:Array<String>;
}

typedef LuaEditorParsedModchart = {
	var playfieldCount:Int;
	var modifiers:Array<LuaEditorModifierEntry>;
	var events:Array<LuaEditorEventEntry>;
	@:optional var projectName:String;
	@:optional var scriptPaths:Array<String>;
}

class ModchartEditorState extends MusicBeatState
{
	static inline final DEFAULT_SONG:String = 'test';
	static var capturedSong:SwagSong = null;
	static var capturedPlayStateContext:LuaEditorPlayStateCapture = null;
	static var suppressPlayStateHotkeyUntilRelease:Bool = false;
	static inline final TIMELINE_X:Int = 20;
	static inline final TIMELINE_Y:Int = 84;
	static inline final TIMELINE_HEIGHT:Int = 180;
	static inline final TIMELINE_ACTIVE_PADDING_TOP:Int = 34;
	static inline final TIMELINE_ACTIVE_PADDING_BOTTOM:Int = 10;
	static inline final GRID_SIZE:Int = 32;
	static inline final BEAT_WIDTH:Int = GRID_SIZE * 4;
	static inline final SNAP_STEP:Float = 0.25;
	static inline final VISIBLE_BEAT_LABELS:Int = 12;
	static final COMMON_EVENT_TARGETS:Array<String> = buildCommonTargets();
	static final EASE_NAMES:Array<String> = buildEaseNames();
	public static var instance:ModchartEditorState;

	var finishTimer:FlxTimer = null;
	var noteKillOffset:Float = 350;
	var spawnTime:Float = 2000;
	var startingSong:Bool = true;

	var playbackRate:Float = 1;
	var inst:FlxSound = new FlxSound();
	var vocals:FlxSound = new FlxSound();
	var opponentVocals:FlxSound = new FlxSound();

	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];
	var ratingsData:Array<Rating> = Rating.loadDefault();
	var comboGroup:FlxSpriteGroup;
	var strumLineNotes:FlxTypedGroup<StrumNote>;
	var opponentStrums:FlxTypedGroup<StrumNote>;
	var playerStrums:FlxTypedGroup<StrumNote>;
	var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	var combo:Int = 0;
	var songHits:Int = 0;
	var songMisses:Int = 0;
	var songLength:Float = 0;
	var songSpeed:Float = 1;

	var showCombo:Bool = true;
	var showComboNum:Bool = true;
	var showRating:Bool = true;

	var startOffset:Float = 0;
	var startPos:Float = 0;
	var timerToStart:Float = 0;

	var scoreTxt:FlxText;
	var dataTxt:FlxText;
	var statusTxt:FlxText;
	var guitarHeroSustains:Bool = false;
	var useCurrentPlayStateSong:Bool = false;
	var noteList:Array<Note> = [];
	var modchartManager:Manager;
	var autoplayPlayer:Bool = true;
	var previewPlaying:Bool = false;
	var playbackReady:Bool = false;
	var availableModifiers:Array<String> = buildModifierNames();
	var timelinePanel:FlxSprite;
	var timelineGrid:FlxSprite;
	var timelineLine:FlxSprite;
	var timelineHighlight:FlxSprite;
	var selectedEventBox:FlxSprite;
	var beatTexts:Array<FlxText> = [];
	var eventSprites:FlxTypedGroup<ModchartTimelineEventSprite>;
	var editorStatusText:FlxText;
	var infoText:FlxText;
	var uiBox:PsychUIBox;
	var projectNameInput:PsychUIInputText;
	var playfieldCountStepper:PsychUINumericStepper;
	var modifierIndexStepper:PsychUINumericStepper;
	var modifierNameInput:PsychUIInputText;
	var modifierFieldStepper:PsychUINumericStepper;
	var modifierPresetDropDown:PsychUIDropDownMenu;
	var modifierSummaryText:FlxText;
	var eventIndexStepper:PsychUINumericStepper;
	var eventTypeDropDown:PsychUIDropDownMenu;
	var eventTargetInput:PsychUIInputText;
	var eventTargetDropDown:PsychUIDropDownMenu;
	var eventBeatStepper:PsychUINumericStepper;
	var eventValueStepper:PsychUINumericStepper;
	var eventLengthStepper:PsychUINumericStepper;
	var eventEaseInput:PsychUIInputText;
	var eventEaseDropDown:PsychUIDropDownMenu;
	var eventPlayerStepper:PsychUINumericStepper;
	var eventFieldStepper:PsychUINumericStepper;
	var eventSummaryText:FlxText;
	var functionNameInput:PsychUIInputText;
	var functionTemplateDropDown:PsychUIDropDownMenu;
	var functionsPreviewBg:FlxSprite;
	var functionsPreviewText:FlxText;
	var functionCachedLines:Array<String> = [];
	var functionScrollOffset:Int = 0;
	var customFunctionLua:String = '';
	var customInitLua:String = '';
	var previewBg:FlxSprite;
	var previewText:FlxText;
	var previewCachedLines:Array<String> = [];
	var previewScrollOffset:Int = 0;
	var previewInitFailed:Bool = false;
	var transportScrubActive:Bool = false;
	var transportScrubPendingRebuild:Bool = false;
	var transportScrubResumeAfter:Bool = false;
	var transportScrubRebuildCooldown:Float = 0;
	var modchartScriptPaths:Array<String> = [];
	var editorLuaCallbackStates:Array<ModchartEditorLuaCallbackState> = [];
	var modifiers:Array<LuaEditorModifierEntry> = [];
	var events:Array<LuaEditorEventEntry> = [];
	var selectedEventIndex:Int = 0;
	var hoveredEventIndex:Int = -1;
	var hasUnsavedChanges:Bool = false;
	var editorFileRef:FileReference;
	var timelineBeat:Float = 0;
	var isRefreshingInputs:Bool = false;
	var activeModifiersDebugText:FlxText;
	var timelineEventInfoText:FlxText;

	var keysArray:Array<String> = [
		'note_left',
		'note_down',
		'note_up',
		'note_right'
	];

	static function buildModifierNames():Array<String>
	{
		var names:Array<String> = [];
		for (cls in ModifierGroup.COMPILED_MODIFIERS)
		{
			var className = Type.getClassName(cls);
			if (className == null)
				continue;

			className = className.substring(className.lastIndexOf('.') + 1).toLowerCase();
			if (!names.contains(className))
				names.push(className);
		}
		names.sort(Reflect.compare);
		return names;
	}

	static function buildCommonTargets():Array<String>
	{
		var targets:Array<String> = [
			'xmod', 'x', 'y', 'z', 'alpha', 'flip', 'invert', 'reverse', 'zoom', 'centered',
			'dark', 'sudden', 'suddenglow', 'suddenend', 'stealth', 'drunk', 'tipsy',
			'beat', 'beatmult', 'beatspeed', 'beatoffset', 'beatx', 'beatxmult', 'beatxspeed',
			'beaty', 'beatymult', 'beatyspeed', 'beatz', 'beatzmult', 'beatzspeed',
			'bounce', 'bumpyx', 'bumpyy', 'bumpyz', 'bumpyymult', 'bumpyzmult',
			'opponentswap', 'radionic', 'scrollanglex', 'scrollangley', 'scrollanglez',
			'anglex', 'angley', 'anglez', 'curvedscrollx', 'curvedscrolly', 'curvedscrollz',
			'curvedscrollperiod', 'receptorscroll', 'randomspeed'
		];

		for (lane in 0...8)
		{
			for (base in ['x', 'y', 'z', 'alpha', 'reverse', 'xmod', 'scrollanglex', 'scrollangley', 'scrollanglez', 'curvedscrollx', 'curvedscrolly', 'curvedscrollz'])
			{
				var laneTarget = base + lane;
				if (!targets.contains(laneTarget))
					targets.push(laneTarget);
			}
		}

		targets.sort(Reflect.compare);
		return targets;
	}

	static function buildEaseNames():Array<String>
	{
		return [
			'linear',
			'accelerate', 'backIn', 'backInOut', 'backOut', 'backOutIn', 'bell',
			'bounce', 'bounceIn', 'bounceInOut', 'bounceOut', 'bounceOutIn',
			'circIn', 'circInOut', 'circOut', 'circOutIn',
			'cubeIn', 'cubeInOut', 'cubeOut', 'cubicOutIn',
			'decelerate', 'elasticIn', 'elasticInOut', 'elasticOut', 'elasticOutIn',
			'emphasizedAccelerate', 'emphasizedDecelerate',
			'expoIn', 'expoInOut', 'expoOut', 'expoOutIn',
			'instant', 'inverse', 'outInBack', 'outInBounce', 'outInCirc', 'outInCubic',
			'outInElastic', 'outInExpo', 'outInQuad', 'outInQuart', 'outInQuint', 'outInSine',
			'pop', 'pulse',
			'quadIn', 'quadInOut', 'quadOut', 'quadOutIn',
			'quartIn', 'quartInOut', 'quartOut', 'quartOutIn',
			'quintIn', 'quintInOut', 'quintOut', 'quintOutIn',
			'sineIn', 'sineInOut', 'sineOut', 'sineOutIn',
			'smoothStepIn', 'smoothStepInOut', 'smoothStepOut',
			'smootherStepIn', 'smootherStepInOut', 'smootherStepOut',
			'spike', 'standard', 'tap', 'tri'
		];
	}

	static function normalizeModchartName(value:Dynamic, fallback:String, ?toLowerCase:Bool = true):String
	{
		var result = value != null ? Std.string(value).trim() : '';
		if (result.length <= 0)
			result = fallback;
		return toLowerCase ? result.toLowerCase() : result;
	}

	static function hasModifierEntry(entries:Array<LuaEditorModifierEntry>, name:String, field:Int):Bool
	{
		for (entry in entries)
			if (entry != null && entry.name == name && entry.field == field)
				return true;
		return false;
	}

	static function sortCapturedEvents(left:LuaEditorEventEntry, right:LuaEditorEventEntry):Int
	{
		if (left == null && right == null)
			return 0;
		if (left == null)
			return 1;
		if (right == null)
			return -1;
		if (left.beat < right.beat)
			return -1;
		if (left.beat > right.beat)
			return 1;
		return 0;
	}

	static function parseIntValue(value:Dynamic, fallback:Int):Int
	{
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Int))
			return cast value;
		var parsed = Std.parseInt(Std.string(value));
		return parsed == null ? fallback : parsed;
	}

	static function parseFloatValue(value:Dynamic, fallback:Float):Float
	{
		if (value == null)
			return fallback;
		if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
			return cast value;
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function stringifyEaseName(value:Dynamic, fallback:String = 'linear'):String
	{
		var result = value != null ? Std.string(value).trim() : '';
		return result.length > 0 ? result : fallback;
	}

	static function captureLuaTimedEvent(events:Array<LuaEditorEventEntry>, eventType:String, nameOrMods:Dynamic, beat:Float, length:Float,
		?value:Dynamic, ?easeName:Dynamic = null, ?player:Dynamic = -1, ?field:Dynamic = -1):Void
	{
		if (events == null || nameOrMods == null)
			return;

		if (Std.isOfType(nameOrMods, String))
		{
			events.push({
				type: eventType,
				target: normalizeModchartName(nameOrMods, 'xmod'),
				beat: beat,
				value: parseFloatValue(value, 0),
				length: length,
				ease: normalizeModchartName(stringifyEaseName(easeName), 'linear', false),
				player: parseIntValue(player, -1),
				field: parseIntValue(field, -1)
			});
			return;
		}

		var mods:Dynamic = nameOrMods;
		switch (eventType)
		{
			case 'set':
				var actualPlayer = parseIntValue(value, -1);
				var actualField = parseIntValue(player, -1);
				for (modName in Reflect.fields(mods))
				{
					events.push({
						type: eventType,
						target: normalizeModchartName(modName, 'xmod'),
						beat: beat,
						value: parseFloatValue(Reflect.field(mods, modName), 0),
						length: 0,
						ease: 'linear',
						player: actualPlayer,
						field: actualField
					});
				}
			case 'ease', 'add':
				var actualEase = normalizeModchartName(stringifyEaseName(value), 'linear', false);
				var actualPlayer = parseIntValue(easeName, -1);
				var actualField = parseIntValue(player, -1);
				for (modName in Reflect.fields(mods))
				{
					events.push({
						type: eventType,
						target: normalizeModchartName(modName, 'xmod'),
						beat: beat,
						value: parseFloatValue(Reflect.field(mods, modName), 0),
						length: length,
						ease: actualEase,
						player: actualPlayer,
						field: actualField
					});
				}
			default:
		}
	}

	function applyLuaTimedEvent(eventType:String, nameOrMods:Dynamic, beat:Float, length:Float,
		?value:Dynamic, ?easeName:Dynamic = null, ?player:Dynamic = -1, ?field:Dynamic = -1):Void
	{
		if (modchartManager == null || nameOrMods == null)
			return;

		if (Std.isOfType(nameOrMods, String))
		{
			var target:String = cast nameOrMods;
			switch (eventType)
			{
				case 'set':
					modchartManager.set(target, beat, parseFloatValue(value, 0), parseIntValue(player, -1), parseIntValue(field, -1));
				case 'ease':
					modchartManager.ease(target, beat, length, parseFloatValue(value, 0), easeFromName(stringifyEaseName(easeName)), parseIntValue(player, -1), parseIntValue(field, -1));
				case 'add':
					modchartManager.add(target, beat, length, parseFloatValue(value, 0), easeFromName(stringifyEaseName(easeName)), parseIntValue(player, -1), parseIntValue(field, -1));
				default:
			}
			return;
		}

		var mods:Dynamic = nameOrMods;
		switch (eventType)
		{
			case 'set':
				var actualPlayer = parseIntValue(value, -1);
				var actualField = parseIntValue(player, -1);
				for (modName in Reflect.fields(mods))
					modchartManager.set(modName, beat, parseFloatValue(Reflect.field(mods, modName), 0), actualPlayer, actualField);
			case 'ease', 'add':
				var actualEase = easeFromName(stringifyEaseName(value));
				var actualPlayer = parseIntValue(easeName, -1);
				var actualField = parseIntValue(player, -1);
				for (modName in Reflect.fields(mods))
				{
					var modValue = parseFloatValue(Reflect.field(mods, modName), 0);
					if (eventType == 'ease')
						modchartManager.ease(modName, beat, length, modValue, actualEase, actualPlayer, actualField);
					else
						modchartManager.add(modName, beat, length, modValue, actualEase, actualPlayer, actualField);
				}
			default:
		}
	}

	public static function capturePlayStateContext(playState:PlayState):Void
	{
		capturedSong = playState != null ? PlayState.SONG : null;
		capturedPlayStateContext = null;
		if (playState == null)
			return;

		var capturedModifiers:Array<LuaEditorModifierEntry> = [];
		var capturedEvents:Array<LuaEditorEventEntry> = [];
		var playfieldCount:Int = 1;
		var projectName:String = null;
		var scriptPaths:Array<String> = [];
		var manager = Manager.instance;
		var parsedModchart = parsePlayStateLuaModchart(playState);

		if (parsedModchart != null)
		{
			playfieldCount = Std.int(Math.max(playfieldCount, parsedModchart.playfieldCount));
			capturedModifiers = parsedModchart.modifiers;
			capturedEvents = parsedModchart.events;
			projectName = parsedModchart.projectName;
			if (parsedModchart.scriptPaths != null)
				scriptPaths = parsedModchart.scriptPaths.copy();
		}

		if ((capturedModifiers.length <= 0 && capturedEvents.length <= 0) && manager != null)
		{
			playfieldCount = Std.int(Math.max(1, manager.playfields.length));
			for (fieldIndex => playfield in manager.playfields)
			{
				if (playfield == null)
					continue;

				for (name in playfield.modifiers.modifiers.keys())
				{
					capturedModifiers.push({
						name: name,
						field: fieldIndex
					});
				}

				@:privateAccess
				for (i in 0...playfield.events.eventCount)
				{
					@:privateAccess
					var serialized = serializeRuntimeEvent(playfield.events.eventList[i], fieldIndex);
					if (serialized != null)
						capturedEvents.push(serialized);
				}
			}
		}

		if (projectName == null && PlayState.SONG != null && PlayState.SONG.song != null)
			projectName = Paths.formatToSongPath(PlayState.SONG.song);

		capturedPlayStateContext = {
			playfieldCount: playfieldCount,
			timelineBeat: FlxMath.roundDecimal(playState.curDecBeat, 3),
			modifiers: capturedModifiers,
			events: capturedEvents,
			projectName: projectName,
			scriptPaths: scriptPaths
		};
	}

	public static function suppressPlayStateHotkey():Void
	{
		suppressPlayStateHotkeyUntilRelease = true;
	}

	public static function shouldIgnorePlayStateHotkey(isHeld:Bool):Bool
	{
		if (!suppressPlayStateHotkeyUntilRelease)
			return false;

		if (!isHeld)
			suppressPlayStateHotkeyUntilRelease = false;

		return true;
	}

	static function parsePlayStateLuaModchart(playState:PlayState):LuaEditorParsedModchart
	{
		#if (LUA_ALLOWED && sys)
		if (playState == null || playState.luaArray == null || playState.luaArray.length <= 0)
			return null;

		var collectedModifiers:Array<LuaEditorModifierEntry> = [];
		var collectedEvents:Array<LuaEditorEventEntry> = [];
		var playfieldCount:Int = 1;
		var projectName:String = null;
		var scriptPaths:Array<String> = [];

		for (script in playState.luaArray)
		{
			if (script == null || script.closed)
				continue;

			var parsed = parseLuaModchartScript(script);
			if (parsed == null)
				continue;

			playfieldCount = Std.int(Math.max(playfieldCount, parsed.playfieldCount));
			if (projectName == null && parsed.projectName != null)
				projectName = parsed.projectName;
			if (script.scriptName != null && !scriptPaths.contains(script.scriptName))
				scriptPaths.push(script.scriptName);

			for (entry in parsed.modifiers)
			{
				if (entry == null || hasModifierEntry(collectedModifiers, entry.name, entry.field))
					continue;
				collectedModifiers.push({name: entry.name, field: entry.field});
			}

			for (entry in parsed.events)
			{
				if (entry == null)
					continue;
				collectedEvents.push({
					type: entry.type,
					target: entry.target,
					beat: entry.beat,
					value: entry.value,
					length: entry.length,
					ease: entry.ease,
					player: entry.player,
					field: entry.field
				});
			}
		}

		if (collectedModifiers.length <= 0 && collectedEvents.length <= 0 && playfieldCount <= 1)
			return null;

		collectedEvents.sort(sortCapturedEvents);
		return {
			playfieldCount: playfieldCount,
			modifiers: collectedModifiers,
			events: collectedEvents,
			projectName: projectName,
			scriptPaths: scriptPaths
		};
		#else
		return null;
		#end
	}

	static function parseLuaModchartScript(script:FunkinLua):LuaEditorParsedModchart
	{
		#if (LUA_ALLOWED && sys)
		if (script == null || script.scriptName == null || !FileSystem.exists(script.scriptName))
			return null;

		var lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.pushnumber(lua, FlxG.width);
		Lua.setglobal(lua, 'screenWidth');
		Lua.pushnumber(lua, FlxG.height);
		Lua.setglobal(lua, 'screenHeight');

		var parsedModifiers:Array<LuaEditorModifierEntry> = [];
		var parsedEvents:Array<LuaEditorEventEntry> = [];
		var playfieldCount:Int = 1;
		var hasInitModchart:Bool = false;

		Lua_helper.add_callback(lua, 'addModifier', function(name:String, ?field:Int = -1) {
			var normalizedName = normalizeModchartName(name, 'transform');
			if (!hasModifierEntry(parsedModifiers, normalizedName, field))
				parsedModifiers.push({name: normalizedName, field: field});
		});
		Lua_helper.add_callback(lua, 'set', function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
			captureLuaTimedEvent(parsedEvents, 'set', nameOrMods, beat, 0, value, null, player, field);
		});
		Lua_helper.add_callback(lua, 'ease', function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:Dynamic = 'linear', ?player:Int = -1, ?field:Int = -1) {
			captureLuaTimedEvent(parsedEvents, 'ease', nameOrMods, beat, length, value, easeName, player, field);
		});
		Lua_helper.add_callback(lua, 'add', function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:Dynamic = 'linear', ?player:Int = -1, ?field:Int = -1) {
			captureLuaTimedEvent(parsedEvents, 'add', nameOrMods, beat, length, value, easeName, player, field);
		});
		Lua_helper.add_callback(lua, 'callback', function(beat:Float, callbackName:Dynamic, ?field:Int = -1) {
			parsedEvents.push({type: 'callback', target: normalizeModchartName(callbackName, 'callback', false), beat: beat, value: 0, length: 0, ease: 'linear', player: -1, field: field});
		});
		Lua_helper.add_callback(lua, 'addPlayfield', function() {
			playfieldCount++;
		});
		Lua_helper.add_callback(lua, 'setHoldSubdivisions', function(_:Dynamic) {});
		Lua_helper.add_callback(lua, 'setModifierPath', function(_:String, _:Array<Dynamic>, ?__:Int = 0, ?___:Int = -1) {});
		Lua_helper.add_callback(lua, 'setModifierPathOffset', function(_:String, _:Float, _:Float, ?__:Float = 0, ?___:Int = 0) {});
		Lua_helper.add_callback(lua, 'setModifierPathBound', function(_:String, _:Float, ?__:Int = 0) {});

		try
		{
			if (LuaL.dofile(lua, script.scriptName) != 0)
			{
				hxluajit.Lua.close(lua);
				return null;
			}

			Lua.getglobal(lua, 'onInitModchart');
			hasInitModchart = Lua.type(lua, -1) == Lua.LUA_TFUNCTION;
			if (!hasInitModchart)
			{
				Lua.pop(lua, 1);
				hxluajit.Lua.close(lua);
				return null;
			}

			if (Lua.pcall(lua, 0, 0, 0) != Lua.LUA_OK)
			{
				hxluajit.Lua.close(lua);
				return null;
			}
		}
		catch (_:Dynamic)
		{
			hxluajit.Lua.close(lua);
			return null;
		}

		hxluajit.Lua.close(lua);
		if (!hasInitModchart && parsedModifiers.length <= 0 && parsedEvents.length <= 0)
			return null;

		parsedEvents.sort(sortCapturedEvents);
		return {
			playfieldCount: playfieldCount,
			modifiers: parsedModifiers,
			events: parsedEvents,
			projectName: Path.withoutExtension(Path.withoutDirectory(script.scriptName)),
			scriptPaths: [script.scriptName]
		};
		#else
		return null;
		#end
	}

	static function serializeRuntimeEvent(event:Dynamic, field:Int):LuaEditorEventEntry
	{
		if (event == null)
			return null;

		var eventType:String = switch (event.getType())
		{
			case EventType.SET: 'set';
			case EventType.EASE: 'ease';
			case EventType.ADD: 'add';
			default: null;
		};

		if (eventType == null)
			return null;

		var eventLength:Float = 0;
		var eventEase = 'linear';
		var eventValue:Float = event.target;

		if (Std.isOfType(event, EaseEvent))
		{
			var easeEvent:EaseEvent = cast event;
			eventLength = easeEvent.beatLength;
			eventEase = getEaseName(easeEvent.ease);
		}

		if (Std.isOfType(event, AddEvent))
		{
			var addEvent:AddEvent = cast event;
			eventValue = addEvent.addAmount;
		}

		return {
			type: eventType,
			target: event.name != null ? event.name.toLowerCase() : 'xmod',
			beat: event.beat,
			value: eventValue,
			length: eventLength,
			ease: eventEase,
			player: event.player,
			field: field
		};
	}

	public function new(?useCurrentPlayStateSong:Bool = false)
	{
		this.useCurrentPlayStateSong = useCurrentPlayStateSong;
		super();
	}

	override function create()
	{
		instance = this;
		if (useCurrentPlayStateSong && PlayState.instance != null && (capturedPlayStateContext == null || capturedSong == null))
			capturePlayStateContext(PlayState.instance);

        Cursor.show();

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set();
		bg.color = FlxColor.WHITE;
		bg.alpha = 1;
		add(bg);

		var bgOverlay:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bgOverlay.scrollFactor.set();
		bgOverlay.alpha = 0.28;
		add(bgOverlay);

		statusTxt = new FlxText(0, 20, FlxG.width, 'Loading modchart state preview...', 20);
		statusTxt.setFormat(Paths.font('phantom.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		statusTxt.borderSize = 1.25;
		statusTxt.scrollFactor.set();
		add(statusTxt);

		if (!preparePreview())
		{
			previewInitFailed = true;
			var failTip:FlxText = new FlxText(0, FlxG.height - 40, FlxG.width,
				'ESC vuelve al menu. Si esta pantalla falla, Haxe ya eligio violencia otra vez.', 16);
			failTip.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			failTip.borderSize = 1.25;
			failTip.scrollFactor.set();
			add(failTip);
			super.create();
			return;
		}

		startPos = Conductor.songPosition;
		Conductor.safeZoneOffset = (ClientPrefs.data.safeFrames / 60) * 1000 * playbackRate;
		showCombo = false;
		showComboNum = false;
		showRating = false;

		cachePopUpScore();
		guitarHeroSustains = ClientPrefs.data.guitarHeroSustains;
		if(ClientPrefs.data.hitsoundVolume > 0) Paths.sound('hitsound');

		comboGroup = new FlxSpriteGroup();
		add(comboGroup);
		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash();
		grpNoteSplashes.add(splash);
		splash.alpha = 0.000001;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		generateStaticArrows(0);
		generateStaticArrows(1);

		scoreTxt = new FlxText(10, FlxG.height - 50, FlxG.width - 20, '', 20);
		scoreTxt.setFormat(Paths.font('phantom.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = false;
		add(scoreTxt);

		dataTxt = new FlxText(10, FlxG.height - 118, FlxG.width - 20, '', 20);
		dataTxt.setFormat(Paths.font('phantom.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		dataTxt.scrollFactor.set();
		dataTxt.borderSize = 1.25;
		add(dataTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0,
			'SPACE play/pause | LEFT/RIGHT seek | ${(controls.mobileC) ? #if android 'BACK' #else 'X' #end : 'ESC'} return', 16);
		tipText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);

		addMobileControls();
		mobileControls.instance.visible = true;
		mobileControls.onButtonDown.add(onButtonPress);
		mobileControls.onButtonUp.add(onButtonRelease);

		setupModchartUi();
		seedDefaults();
		applyCapturedPlayStateContext();

		generateSong();
		initializePlayback();
		initializeModchartManager();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);

		#if DISCORD_ALLOWED
		DiscordClient.changePresence('Playtesting on Modchart Editor', PlayState.SONG.song, null, true, songLength);
		#end

		updateScore();
		cachePopUpScore();

		#if !android
		addTouchPad('NONE', 'P');
		addTouchPadCamera();
		#end

		refreshAllViews();
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (previewInitFailed)
		{
			var failBackRequested:Bool = controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.F12;
			#if android
			failBackRequested = failBackRequested || FlxG.android.justReleased.BACK;
			#else
			failBackRequested = failBackRequested || (touchPad != null && touchPad.buttonP != null && touchPad.buttonP.justPressed);
			#end

			if (failBackRequested)
				MusicBeatState.switchState(new MasterEditorMenu());
			super.update(elapsed);
			return;
		}

		if (PlayState.SONG == null)
		{
			if (controls.BACK || FlxG.keys.justPressed.ESCAPE)
				MusicBeatState.switchState(new MasterEditorMenu());
			super.update(elapsed);
			return;
		}

		if (PsychUIInputText.focusOn == null)
			handleTransportInput(elapsed);

		var backRequested:Bool = controls.BACK || FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.F12;
		#if android
		backRequested = backRequested || FlxG.android.justReleased.BACK;
		#else
		backRequested = backRequested || (touchPad != null && touchPad.buttonP != null && touchPad.buttonP.justPressed);
		#end

		if(backRequested)
		{
			endSong();
			super.update(elapsed);
			return;
		}

		if (playbackReady)
		{
			if (previewPlaying)
			{
				Conductor.songPosition += elapsed * 1000 * playbackRate;
				var timeDiff:Float = Math.abs((inst.time + Conductor.offset) - Conductor.songPosition);
				Conductor.songPosition = FlxMath.lerp(inst.time + Conductor.offset, Conductor.songPosition, Math.exp(-elapsed * 2.5));
				if (timeDiff > 1000 * playbackRate)
					Conductor.songPosition = Conductor.songPosition + 1000 * FlxMath.signOf(timeDiff);
			}
			else
				Conductor.songPosition = inst.time + Conductor.offset;
		}

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime * playbackRate;
			if(songSpeed < 1) time /= songSpeed;
			if(unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;
				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		keysCheck();
		if(notes.length > 0)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strum:StrumNote = strumGroup.members[daNote.noteData];
				daNote.followStrumNote(strum, fakeCrochet, songSpeed / playbackRate);

				if (autoplayPlayer && shouldAutoHitPlayerNote(daNote))
				{
					goodNoteHit(daNote);
					if (!daNote.exists)
						return;
				}

				if(!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
					opponentNoteHit(daNote);

				if(daNote.isSustainNote && strum.sustainReduce) daNote.clipToStrumNote(strum);

				if (Conductor.songPosition - daNote.strumTime > noteKillOffset)
				{
					if (daNote.mustPress && !autoplayPlayer && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit))
						noteMiss(daNote);

					daNote.active = daNote.visible = false;
					invalidateNote(daNote);
				}
			});
		}

		var time:Float = CoolUtil.floorDecimal((Conductor.songPosition - ClientPrefs.data.noteOffset) / 1000, 1);
		var songLen:Float = CoolUtil.floorDecimal(songLength / 1000, 1);
		timelineBeat = FlxMath.roundDecimal(Conductor.getBeat(Conductor.songPosition), 3);
		dataTxt.text = PlayState.SONG.song + ' | ' + (previewPlaying ? 'Playing' : 'Paused') +
			'\n' + Language.getPhrase('editorplaystate_time', 'Time: {1} / {2}', [time, songLen]) +
			'\n' + Language.getPhrase('editorplaystate_section_current', 'Section: {1}', [curSection]) +
			'\n' + Language.getPhrase('editorplaystate_beat', 'Beat: {1}', [curBeat]) +
			'\n' + Language.getPhrase('editorplaystate_step', 'Step: {1}', [curStep]);
		syncModchartPreviewContext();
		refreshActiveModifierDebug();
		handleTimelineInput();
		handlePreviewInput();
		updateTimelineVisuals();
		super.update(elapsed);
	}

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		if(lastBeatHit >= curBeat)
			return;

		notes.sort(FlxSort.byY, ClientPrefs.data.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		super.beatHit();
		lastBeatHit = curBeat;
	}

	override function sectionHit()
	{
		if (PlayState.SONG.notes[curSection] != null)
		{
			if (PlayState.SONG.notes[curSection].changeBPM)
				Conductor.bpm = PlayState.SONG.notes[curSection].bpm;
		}
		super.sectionHit();
	}

	override function destroy()
	{
		if (instance == this)
			instance = null;

		if (FlxG.stage != null)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		Cursor.show();
		NoteSplash.configs.clear();
			cleanupFileReference();
		destroyModchartManager();
		cleanupSound(inst);
		cleanupSound(vocals);
		cleanupSound(opponentVocals);
		super.destroy();
	}

	function preparePreview():Bool
	{
		var songData:SwagSong = resolveSong();
		if (songData == null)
		{
			statusTxt.text = 'Could not load a chart for the modchart preview.';
			return false;
		}

		PlayState.SONG = songData;
		Song.loadedSongName = songData.song;
		StageData.loadDirectory(songData);
		Conductor.bpm = songData.bpm;
		Conductor.mapBPMChanges(songData);
		Conductor.songPosition = 0;

		noteList = buildNoteList(songData);
		if (noteList.length <= 0)
		{
			statusTxt.text = 'The loaded chart has no notes to preview.';
			return false;
		}

		if (!prepareInstrumental())
			return false;

		prepareVocals(songData);
		return true;
	}

	function resolveSong():SwagSong
	{
		if (useCurrentPlayStateSong && capturedSong != null)
			return capturedSong;

		if (PlayState.SONG != null && PlayState.SONG.song != null && PlayState.SONG.song.length > 0)
			return PlayState.SONG;

		try
		{
			return Song.getChart(DEFAULT_SONG, DEFAULT_SONG);
		}
		catch (e:Dynamic)
		{
			FlxG.log.error('Failed to load default modchart preview song: $e');
		}

		return null;
	}

	function buildNoteList(songData:SwagSong):Array<Note>
	{
		var generatedNotes:Array<Note> = [];
		var oldNote:Note = null;

		if (usesFlatNoteFormat(songData))
		{
			var flatNotes:Array<Dynamic> = cast songData.notes;
			for (rawNote in flatNotes)
			{
				if (rawNote == null)
					continue;

				var rawData:Int = Std.int(Reflect.field(rawNote, 'd'));
				var strumTime:Float = Reflect.field(rawNote, 't');
				var noteData:Int = rawData % 4;
				var mustPress:Bool = rawData < 4;
				var note:Note = new Note(strumTime, noteData, oldNote, false, false, this);
				note.mustPress = mustPress;
				note.sustainLength = Reflect.hasField(rawNote, 'l') && Reflect.field(rawNote, 'l') != null ? Reflect.field(rawNote, 'l') : 0;
				note.gfNote = false;
				note.noteType = Reflect.hasField(rawNote, 'type') && Reflect.field(rawNote, 'type') != null ? Std.string(Reflect.field(rawNote, 'type')) : '';
				generatedNotes.push(note);
				oldNote = note;
			}

			generatedNotes.sort(PlayState.sortByTime);
			return generatedNotes;
		}

		var sections:Array<SwagSection> = songData.notes;

		for (section in sections)
		{
			if (section == null || section.sectionNotes == null)
				continue;

			var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
			for (rawNote in sectionNotes)
			{
				if (rawNote == null)
					continue;

				var strumTime:Float = rawNote[0];
				var noteData:Int = Std.int(rawNote[1] % 4);
				var mustPress:Bool = rawNote[1] < 4;
				var note:Note = new Note(strumTime, noteData, oldNote, false, false, this);
				note.mustPress = mustPress;
				note.sustainLength = rawNote[2] != null ? rawNote[2] : 0;
				note.gfNote = section.gfSection == true && mustPress == section.mustHitSection;
				note.noteType = rawNote[3];
				generatedNotes.push(note);
				oldNote = note;
			}
		}

		generatedNotes.sort(PlayState.sortByTime);
		return generatedNotes;
	}

	function usesFlatNoteFormat(songData:SwagSong):Bool
	{
		if (songData == null || songData.notes == null || songData.notes.length <= 0)
			return false;

		var firstEntry:Dynamic = songData.notes[0];
		return firstEntry != null && Reflect.hasField(firstEntry, 't') && Reflect.hasField(firstEntry, 'd') && !Reflect.hasField(firstEntry, 'sectionNotes');
	}

	public function getModchartSongPosition():Float
	{
		return Conductor.songPosition;
	}

	public function getModchartCurrentBeat():Float
	{
		return curDecBeat;
	}

	public function getModchartArrowCamera():Array<FlxCamera>
	{
		return [FlxG.camera];
	}

	public function getModchartScrollSpeed():Float
	{
		return songSpeed * 0.45;
	}

	public function getModchartStrumFromInfo(lane:Int, player:Int):StrumNote
	{
		var group = player == 0 ? opponentStrums : playerStrums;
		if (group == null)
			return null;

		var strum:StrumNote = null;
		group.forEachAlive(note -> {
			@:privateAccess
			if (note.noteData == lane)
				strum = note;
		});
		return strum;
	}

	public function getModchartArrowItems():Array<Array<Array<FlxSprite>>>
	{
		var preview:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []]];

		if (strumLineNotes != null)
		{
			strumLineNotes.forEachAlive(strumNote -> {
				@:privateAccess
				preview[strumNote.player][0].push(strumNote);
			});
		}

		if (notes != null)
		{
			notes.forEachAlive(note -> {
				final player = note.mustPress ? 1 : 0;
				preview[player][note.isSustainNote ? 2 : 1].push(note);
			});
		}

		if (grpNoteSplashes != null)
		{
			grpNoteSplashes.forEachAlive(splash -> {
				@:privateAccess
				if (splash.babyArrow != null && splash.active)
					preview[splash.babyArrow.player][3].push(splash);
			});
		}

		return preview;
	}

	function prepareInstrumental():Bool
	{
		try
		{
			FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0);
			FlxG.sound.music.pause();
			FlxG.sound.music.time = 0;
			return true;
		}
		catch (e:Dynamic)
		{
			statusTxt.text = 'Could not load the instrumental for ' + PlayState.SONG.song + '.';
			FlxG.log.error('Failed to load modchart preview instrumental: $e');
		}

		return false;
	}

	function prepareVocals(songData:SwagSong):Void
	{
		cleanupSound(vocals);
		cleanupSound(opponentVocals);
		vocals = new FlxSound();
		opponentVocals = new FlxSound();

		if (!songData.needsVoices)
			return;

		try
		{
			var playerVocals:Sound = Paths.voices(songData.song, 'Player');
			if (playerVocals == null)
				playerVocals = Paths.voices(songData.song);
			if (playerVocals != null)
			{
				vocals.loadEmbedded(playerVocals);
				vocals.volume = 0;
				vocals.play();
				vocals.pause();
			}

			var enemyVocals:Sound = Paths.voices(songData.song, 'Opponent');
			if (enemyVocals != null)
			{
				opponentVocals.loadEmbedded(enemyVocals);
				opponentVocals.volume = 0;
				opponentVocals.play();
				opponentVocals.pause();
			}

			FlxG.sound.list.add(vocals);
			FlxG.sound.list.add(opponentVocals);
		}
		catch (e:Dynamic)
		{
			FlxG.log.warn('Failed to load modchart preview vocals: $e');
		}
	}

	function initializePlayback():Void
	{
		startingSong = false;
		@:privateAccess inst.loadEmbedded(FlxG.sound.music._sound);
		inst.looped = false;
		inst.onComplete = finishSong;
		inst.volume = vocals.volume = opponentVocals.volume = 1;
		FlxG.sound.list.add(inst);
		playbackReady = true;
		songLength = inst.length;
		setPreviewTime(startPos, false);
	}

	function generateSong()
	{
		songSpeed = PlayState.SONG.speed;
		var songSpeedType:String = ClientPrefs.getGameplaySetting('scrolltype');
		switch(songSpeedType)
		{
			case 'multiplicative':
				songSpeed = PlayState.SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed');
			case 'constant':
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed');
		}
		noteKillOffset = Math.max(Conductor.stepCrochet, 350 / songSpeed * playbackRate);

		Conductor.bpm = PlayState.SONG.bpm;
		inst.volume = vocals.volume = opponentVocals.volume = 0;
		if (notes == null)
		{
			notes = new FlxTypedGroup<Note>();
			add(notes);
		}
		rebuildSongNotes(Conductor.songPosition);
	}

	function rebuildSongNotes(targetTime:Float):Void
	{
		clearRuntimeNotes();

		var useFlatNotes:Bool = usesFlatNoteFormat(PlayState.SONG);
		var daBpm:Float = PlayState.SONG.bpm;
		if (!useFlatNotes && PlayState.SONG.notes != null && PlayState.SONG.notes.length > 0 && PlayState.SONG.notes[0].changeBPM == true)
			daBpm = PlayState.SONG.notes[0].bpm;
		var oldNote:Note = null;
		var noteSec:Int = 0;
		var secTime:Float = 0;
		var cachedSectionTimes:Array<Float> = [];

		if(PlayState.SONG != null && !useFlatNotes)
		{
			var tempBpm:Float = daBpm;
			for (section in PlayState.SONG.notes)
			{
				if(PlayState.SONG.notes[noteSec].changeBPM == true)
					tempBpm = PlayState.SONG.notes[noteSec].bpm;

				secTime += Conductor.calculateCrochet(tempBpm) * (Math.round(4 * section.sectionBeats) / 4);
				cachedSectionTimes.push(secTime);
				noteSec++;
			}
			noteSec = 0;
		}

		for (note in noteList)
		{
			if(note == null || note.strumTime < startPos) continue;

			while(cachedSectionTimes.length > noteSec + 1 && cachedSectionTimes[noteSec + 1] <= note.strumTime)
			{
				noteSec++;
				if(PlayState.SONG.notes[noteSec].changeBPM == true)
					daBpm = PlayState.SONG.notes[noteSec].bpm;
			}

			var idx:Int = noteList.indexOf(note);
			if (idx != 0)
			{
				for (evilNote in unspawnNotes)
				{
					var matches:Bool = note.noteData == evilNote.noteData && note.mustPress == evilNote.mustPress && note.noteType == evilNote.noteType;
					if (matches && Math.abs(note.strumTime - evilNote.strumTime) < flixel.math.FlxMath.EPSILON)
					{
						if (evilNote.tail.length > 0)
						{
							for (tail in evilNote.tail)
							{
								tail.destroy();
								unspawnNotes.remove(tail);
							}
						}
						evilNote.destroy();
						unspawnNotes.remove(evilNote);
					}
				}
			}

			var swagNote:Note = new Note(note.strumTime, note.noteData, oldNote, false, this);
			swagNote.mustPress = note.mustPress;
			swagNote.sustainLength = note.sustainLength;
			swagNote.gfNote = note.gfNote;
			swagNote.noteType = note.noteType;
			swagNote.scrollFactor.set();
			unspawnNotes.push(swagNote);

			var curStepCrochet:Float = 60 / daBpm * 1000 / 4.0;
			final roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
			if(roundSus > 0)
			{
				for (susNote in 0...roundSus)
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note = new Note(swagNote.strumTime + (curStepCrochet * susNote), note.noteData, oldNote, true, this);
					sustainNote.mustPress = swagNote.mustPress;
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.noteType = swagNote.noteType;
					sustainNote.scrollFactor.set();
					sustainNote.parent = swagNote;
					unspawnNotes.push(sustainNote);
					swagNote.tail.push(sustainNote);

					sustainNote.correctionOffset = swagNote.height / 2;
					if(!PlayState.isPixelStage)
					{
						if(oldNote.isSustainNote)
						{
							oldNote.scale.y *= Note.SUSTAIN_SIZE / oldNote.frameHeight;
							oldNote.scale.y /= playbackRate;
							oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
						}

						if(ClientPrefs.data.downScroll)
							sustainNote.correctionOffset = 0;
					}
					else if(oldNote.isSustainNote)
					{
						oldNote.scale.y /= playbackRate;
						oldNote.resizeByRatio(curStepCrochet / Conductor.stepCrochet);
					}

					if (sustainNote.mustPress) sustainNote.x += FlxG.width / 2;
					else if(ClientPrefs.data.middleScroll)
					{
						sustainNote.x += 310;
						if(sustainNote.noteData > 1)
							sustainNote.x += FlxG.width / 2 + 25;
					}
				}
			}

			if (swagNote.mustPress)
				swagNote.x += FlxG.width / 2;
			else if(ClientPrefs.data.middleScroll)
			{
				swagNote.x += 310;
				if(swagNote.noteData > 1)
					swagNote.x += FlxG.width / 2 + 25;
			}
			oldNote = swagNote;
		}
		unspawnNotes.sort(PlayState.sortByTime);
		syncSpawnedNotesToTime(targetTime);
	}

	function clearRuntimeNotes():Void
	{
		if (notes != null)
		{
			for (note in notes.members)
				if (note != null)
					note.destroy();
			notes.clear();
		}

		for (note in unspawnNotes)
			if (note != null)
				note.destroy();
		unspawnNotes = [];
	}

	function syncSpawnedNotesToTime(targetTime:Float):Void
	{
		var spawnWindow:Float = spawnTime * playbackRate;
		if(songSpeed < 1) spawnWindow /= songSpeed;

		var remaining:Array<Note> = [];
		for (note in unspawnNotes)
		{
			if (note == null)
				continue;

			if (note.strumTime < targetTime - noteKillOffset)
			{
				note.destroy();
				continue;
			}

			if (note.strumTime - targetTime < spawnWindow)
			{
				note.spawned = true;
				notes.insert(0, note);
				continue;
			}

			remaining.push(note);
		}
		unspawnNotes = remaining;
	}

	private function generateStaticArrows(player:Int):Void
	{
		var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? (FlxG.height - 150) : 50;
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;
			if (player < 1)
			{
				if(!ClientPrefs.data.opponentStrums) targetAlpha = 0;
				else if(ClientPrefs.data.middleScroll) targetAlpha = 0.35;
			}

			var babyArrow:StrumNote = new StrumNote(strumLineX, strumLineY, i, player);
			babyArrow.downScroll = ClientPrefs.data.downScroll;
			babyArrow.alpha = targetAlpha;

			if (player == 1)
				playerStrums.add(babyArrow);
			else
			{
				if(ClientPrefs.data.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) babyArrow.x += FlxG.width / 2 + 25;
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.playerPosition();
		}
	}

	public function finishSong():Void
	{
		previewPlaying = false;
		if(ClientPrefs.data.noteOffset <= 0)
			endSong();
		else
		{
			finishTimer = new FlxTimer().start(ClientPrefs.data.noteOffset / 1000, function(tmr:FlxTimer)
			{
				endSong();
			});
		}
	}

	public function endSong()
	{
		if (notes != null)
			notes.forEachAlive(function(note:Note) invalidateNote(note));

		for (note in unspawnNotes)
			if(note != null) invalidateNote(note);

		if (inst != null) inst.pause();
		if (vocals != null) vocals.pause();
		if (opponentVocals != null) opponentVocals.pause();

		if(finishTimer != null)
			finishTimer.destroy();

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (mobileControls != null && mobileControls.instance != null)
			mobileControls.instance.visible = false;

		MusicBeatState.switchState(new MasterEditorMenu());
	}

	private function cachePopUpScore()
	{
		var uiFolder:String = '';
		if (PlayState.stageUI != 'normal')
			uiFolder = PlayState.uiPrefix + 'UI/';

		for (rating in ratingsData)
			Paths.image(uiFolder + rating.image + PlayState.uiPostfix);
		for (i in 0...10)
			Paths.image(uiFolder + 'num' + i + PlayState.uiPostfix);
	}

	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.data.ratingOffset);
		vocals.volume = 1;

		if (!ClientPrefs.data.comboStacking && comboGroup.members.length > 0)
		{
			for (spr in comboGroup)
			{
				if(spr == null) continue;
				comboGroup.remove(spr);
				spr.destroy();
			}
		}

		var placement:Float = FlxG.width * 0.35;
		var rating:FlxSprite = new FlxSprite();
		var daRating:Rating = Conductor.judgeNote(ratingsData, noteDiff / playbackRate);

		note.ratingMod = daRating.ratingMod;
		if(!note.ratingDisabled) daRating.hits++;
		note.rating = daRating.name;

		if(daRating.noteSplash && !note.noteSplashData.disabled)
			spawnNoteSplashOnNote(note);

		if(!note.ratingDisabled)
			songHits++;

		var uiFolder:String = '';
		var antialias:Bool = ClientPrefs.data.antialiasing;
		if (PlayState.stageUI != 'normal')
		{
			uiFolder = PlayState.uiPrefix + 'UI/';
			antialias = !PlayState.isPixelStage;
		}

		if(ClientPrefs.data.popUpRating)
		{
			rating.loadGraphic(Paths.image(uiFolder + daRating.image + PlayState.uiPostfix));
			rating.screenCenter();
			rating.x = placement - 40;
			rating.y -= 60;
			rating.acceleration.y = 550 * playbackRate * playbackRate;
			rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
			rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
			rating.visible = (!ClientPrefs.data.hideHud && showRating);
			rating.x += ClientPrefs.data.comboOffset[0];
			rating.y -= ClientPrefs.data.comboOffset[1];
			rating.antialiasing = antialias;

			var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'combo' + PlayState.uiPostfix));
			comboSpr.screenCenter();
			comboSpr.x = placement;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.visible = (!ClientPrefs.data.hideHud && ClientPrefs.data.showCombo && showCombo);
			comboSpr.x += ClientPrefs.data.comboOffset[0];
			comboSpr.y -= ClientPrefs.data.comboOffset[1];
			comboSpr.antialiasing = antialias;
			comboSpr.y += 60;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;
			comboGroup.add(rating);

			if (!PlayState.isPixelStage)
			{
				rating.setGraphicSize(Std.int(rating.width * 0.7));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			}
			else
			{
				rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.85));
				comboSpr.setGraphicSize(Std.int(comboSpr.width * PlayState.daPixelZoom * 0.85));
			}

			comboSpr.updateHitbox();
			rating.updateHitbox();

			var daLoop:Int = 0;
			var xThing:Float = 0;
			if (ClientPrefs.data.showCombo && showCombo)
				comboGroup.add(comboSpr);

			var separatedScore:String = Std.string(combo).lpad('0', 3);
			for (i in 0...separatedScore.length)
			{
				var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(uiFolder + 'num' + Std.parseInt(separatedScore.charAt(i)) + PlayState.uiPostfix));
				numScore.screenCenter();
				numScore.x = placement + (43 * daLoop) - 90 + ClientPrefs.data.comboOffset[2];
				numScore.y += 80 - ClientPrefs.data.comboOffset[3];

				if (!PlayState.isPixelStage) numScore.setGraphicSize(Std.int(numScore.width * 0.5));
				else numScore.setGraphicSize(Std.int(numScore.width * PlayState.daPixelZoom));
				numScore.updateHitbox();

				numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
				numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
				numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
				numScore.visible = !ClientPrefs.data.hideHud;
				numScore.antialiasing = antialias;

				if(showComboNum)
					comboGroup.add(numScore);

				FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002 / playbackRate
				});

				daLoop++;
				if(numScore.x > xThing) xThing = numScore.x;
			}
			comboSpr.x = xThing + 50;
			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
				startDelay: Conductor.crochet * 0.001 / playbackRate
			});

			FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					comboSpr.destroy();
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});
		}
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		if (autoplayPlayer)
			return;

		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);

		if (!controls.controllerMode)
		{
			#if debug
			@:privateAccess if (!FlxG.keys._keyListMap.exists(eventKey)) return;
			#end

			if(FlxG.keys.checkStatus(eventKey, JUST_PRESSED)) keyPressed(key);
		}
	}

	private function keyPressed(key:Int)
	{
		if(key < 0) return;

		var lastTime:Float = Conductor.songPosition;
		if(Conductor.songPosition >= 0) Conductor.songPosition = inst.time + Conductor.offset;

		var plrInputNotes:Array<Note> = notes.members.filter(function(n:Note)
			return n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit && !n.isSustainNote && n.noteData == key);

		plrInputNotes.sort(PlayState.sortHitNotes);
		if (plrInputNotes.length != 0)
		{
			var funnyNote:Note = plrInputNotes[0];

			if (plrInputNotes.length > 1)
			{
				var doubleNote:Note = plrInputNotes[1];
				if (doubleNote.noteData == funnyNote.noteData)
				{
					if (Math.abs(doubleNote.strumTime - funnyNote.strumTime) < 1.0)
						invalidateNote(doubleNote);
					else if (doubleNote.strumTime < funnyNote.strumTime)
						funnyNote = doubleNote;
				}
			}

			goodNoteHit(funnyNote);
		}

		Conductor.songPosition = lastTime;
		var spr:StrumNote = playerStrums.members[key];
		if(spr != null && spr.animation.curAnim.name != 'confirm')
		{
			spr.playAnim('pressed');
			spr.resetAnim = 0;
		}
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		if (autoplayPlayer)
			return;

		var eventKey:FlxKey = event.keyCode;
		var key:Int = PlayState.getKeyFromEvent(keysArray, eventKey);
		if(!controls.controllerMode && key > -1) keyReleased(key);
	}

	private function keyReleased(key:Int)
	{
		var spr:StrumNote = playerStrums.members[key];
		if(spr != null)
		{
			spr.playAnim('static');
			spr.resetAnim = 0;
		}
	}

	private function onButtonPress(button:TouchButton):Void
	{
		if (autoplayPlayer)
			return;

		if (button.IDs.filter(id -> id.toString().startsWith('EXTRA')).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		if (button.justPressed) keyPressed(buttonCode);
	}

	private function onButtonRelease(button:TouchButton):Void
	{
		if (autoplayPlayer)
			return;

		if (button.IDs.filter(id -> id.toString().startsWith('EXTRA')).length > 0)
			return;

		var buttonCode:Int = (button.IDs[0].toString().startsWith('NOTE')) ? button.IDs[0] : button.IDs[1];
		if(buttonCode > -1) keyReleased(buttonCode);
	}

	private function keysCheck():Void
	{
		if (autoplayPlayer)
			return;

		var holdArray:Array<Bool> = [];
		var pressArray:Array<Bool> = [];
		var releaseArray:Array<Bool> = [];
		for (key in keysArray)
		{
			holdArray.push(controls.pressed(key));
			pressArray.push(controls.justPressed(key));
			releaseArray.push(controls.justReleased(key));
		}

		if(controls.controllerMode && pressArray.contains(true))
			for (i in 0...pressArray.length)
				if(pressArray[i]) keyPressed(i);

		if (notes.length > 0)
		{
			for (n in notes)
			{
				var canHit:Bool = (n != null && n.canBeHit && n.mustPress && !n.tooLate && !n.wasGoodHit && !n.blockHit);
				if (guitarHeroSustains)
					canHit = canHit && n.parent != null && n.parent.wasGoodHit;

				if (canHit && n.isSustainNote)
				{
					var released:Bool = !holdArray[n.noteData];
					if (!released)
						goodNoteHit(n);
				}
			}
		}

		if(controls.controllerMode && releaseArray.contains(true))
			for (i in 0...releaseArray.length)
				if(releaseArray[i]) keyReleased(i);
	}

	function opponentNoteHit(note:Note):Void
	{
		if (PlayState.SONG.needsVoices && opponentVocals.length <= 0)
			vocals.volume = 1;

		var strum:StrumNote = opponentStrums.members[Std.int(Math.abs(note.noteData))];
		if(strum != null)
		{
			strum.playAnim('confirm', true);
			strum.resetAnim = Conductor.stepCrochet * 1.25 / 1000 / playbackRate;
		}
		note.hitByOpponent = true;

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	function goodNoteHit(note:Note):Void
	{
		if(note.wasGoodHit) return;

		note.wasGoodHit = true;
		if (note.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound(note.hitsound), note.hitsoundVolume);

		if(note.hitCausesMiss)
		{
			noteMiss(note);
			if(!note.noteSplashData.disabled && !note.isSustainNote)
				spawnNoteSplashOnNote(note);
			if (!note.isSustainNote)
				invalidateNote(note);
			return;
		}

		if (!note.isSustainNote)
		{
			combo++;
			if(combo > 9999) combo = 9999;
			popUpScore(note);
		}

		var spr:StrumNote = playerStrums.members[note.noteData];
		if(spr != null) spr.playAnim('confirm', true);
		vocals.volume = 1;

		if (!note.isSustainNote)
			invalidateNote(note);
	}

	function noteMiss(daNote:Note):Void
	{
		notes.forEachAlive(function(note:Note)
		{
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1)
				invalidateNote(daNote);
		});

		if (daNote != null && guitarHeroSustains && daNote.parent == null)
		{
			if(daNote.tail.length > 0)
			{
				daNote.alpha = 0.35;
				for(childNote in daNote.tail)
				{
					childNote.alpha = daNote.alpha;
					childNote.missed = true;
					childNote.canBeHit = false;
					childNote.ignoreNote = true;
					childNote.tooLate = true;
				}
				daNote.missed = true;
				daNote.canBeHit = false;
			}

			if (daNote.missed)
				return;
		}

		if (daNote != null && guitarHeroSustains && daNote.parent != null && daNote.isSustainNote)
		{
			if (daNote.missed)
				return;

			var parentNote:Note = daNote.parent;
			if (parentNote.wasGoodHit && parentNote.tail.length > 0)
			{
				for (child in parentNote.tail)
				{
					if (child != daNote)
					{
						child.missed = true;
						child.canBeHit = false;
						child.ignoreNote = true;
						child.tooLate = true;
					}
				}
			}
		}

		songMisses++;
		updateScore();
		vocals.volume = 0;
		combo = 0;
	}

	public function invalidateNote(note:Note):Void
	{
		if (notes != null)
			notes.remove(note, true);
		note.destroy();
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if(note != null)
		{
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null)
				spawnNoteSplash(strum.x, strum.y, note.noteData, note, strum);
		}
	}

	function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null, strum:StrumNote)
	{
		var splash:NoteSplash = new NoteSplash();
		splash.babyArrow = strum;
		splash.spawnSplashNote(note);
		grpNoteSplashes.add(splash);
	}

	function updateScore()
	{
		if (scoreTxt != null)
			scoreTxt.visible = false;
	}

	function shouldAutoHitPlayerNote(note:Note):Bool
	{
		if (note == null || !note.mustPress || note.wasGoodHit || note.tooLate || note.blockHit || note.ignoreNote)
			return false;

		if (!note.canBeHit)
			return false;

		if (!note.isSustainNote && note.strumTime > Conductor.songPosition)
			return false;

		if (note.isSustainNote && guitarHeroSustains)
			return note.parent != null && note.parent.wasGoodHit;

		return true;
	}

	function handleTransportInput(elapsed:Float):Void
	{
		if (!playbackReady)
			return;

		if (FlxG.keys.justPressed.SPACE)
		{
			finishTransportScrub();
			togglePlayback();
		}

		var seekDirection:Int = 0;
		if (FlxG.keys.pressed.RIGHT)
			seekDirection++;
		if (FlxG.keys.pressed.LEFT)
			seekDirection--;

		if (seekDirection != 0)
			scrubPreview(seekDirection, elapsed);
		else if (transportScrubActive)
			finishTransportScrub();
	}

	function scrubPreview(direction:Int, elapsed:Float):Void
	{
		if (!transportScrubActive)
		{
			transportScrubActive = true;
			transportScrubPendingRebuild = false;
			transportScrubResumeAfter = previewPlaying;
			transportScrubRebuildCooldown = 0;
			if (previewPlaying)
				pausePlayback();
		}

		var seekSpeed:Float = Conductor.crochet * 1.5 * (FlxG.keys.pressed.SHIFT ? 4 : 1) * elapsed;
		if (seekSpeed <= 0)
			return;

		setPreviewTime(Conductor.songPosition + (seekSpeed * direction), false, true);
		transportScrubRebuildCooldown -= elapsed;
		if (direction < 0 || transportScrubRebuildCooldown <= 0)
		{
			rebuildPreviewRuntime(false);
			transportScrubRebuildCooldown = direction < 0 ? 0.06 : 0.12;
		}
	}

	function finishTransportScrub():Void
	{
		if (!transportScrubActive)
			return;

		transportScrubActive = false;
		if (transportScrubPendingRebuild)
		{
			rebuildPreviewRuntime(false);
			transportScrubPendingRebuild = false;
		}

		if (transportScrubResumeAfter)
			resumePlayback();
		transportScrubResumeAfter = false;
	}

	function togglePlayback():Void
	{
		if (previewPlaying)
			pausePlayback();
		else
			resumePlayback();
	}

	function pausePlayback():Void
	{
		previewPlaying = false;
		inst.pause();
		if (vocals != null) vocals.pause();
		if (opponentVocals != null) opponentVocals.pause();
		syncModchartPreviewContext();
	}

	function resumePlayback():Void
	{
		previewPlaying = true;
		var playbackTime:Float = Math.max(0, Conductor.songPosition - Conductor.offset);
		inst.play(false, playbackTime);
		if (vocals != null && vocals.length > 0) vocals.play(false, playbackTime);
		if (opponentVocals != null && opponentVocals.length > 0) opponentVocals.play(false, playbackTime);
		syncModchartPreviewContext();
	}

	function seekPreview(direction:Int):Void
	{
		var seekAmount:Float = Conductor.crochet;
		var targetTime:Float = FlxMath.bound(Conductor.songPosition + (seekAmount * direction), 0, Math.max(songLength - 1, 0));
		setPreviewTime(targetTime, previewPlaying);
	}

	function setPreviewTime(targetTime:Float, resumeAfter:Bool, ?deferNoteRebuild:Bool = false):Void
	{
		var boundedTime:Float = FlxMath.bound(targetTime, 0, Math.max(songLength - 1, 0));
		previewPlaying = false;
		inst.pause();
		inst.time = boundedTime;
		if (FlxG.sound.music != null)
			FlxG.sound.music.time = boundedTime;
		if (vocals != null)
		{
			vocals.pause();
			vocals.time = boundedTime;
		}
		if (opponentVocals != null)
		{
			opponentVocals.pause();
			opponentVocals.time = boundedTime;
		}

		Conductor.songPosition = boundedTime + Conductor.offset;
		if (deferNoteRebuild)
		{
			transportScrubPendingRebuild = true;
			syncModchartPreviewContext();
			return;
		}

		rebuildPreviewRuntime(false);

		if (resumeAfter)
			resumePlayback();
	}

	function rebuildPreviewRuntime(resumeAfter:Bool):Void
	{
		rebuildSongNotes(Conductor.songPosition);
		initializeModchartManager();
		syncModchartPreviewContext();
		if (resumeAfter)
			resumePlayback();
	}

	function initializeModchartManager():Void
	{
		destroyModchartManager();
		ModchartEditorPreviewContext.active = {
			currentBeat: Conductor.getBeat(Conductor.songPosition),
			songPosition: Conductor.songPosition,
			scrollSpeed: songSpeed * 0.45,
			camera: FlxG.camera,
			strumLineNotes: strumLineNotes,
			opponentStrums: opponentStrums,
			playerStrums: playerStrums,
			notes: notes,
			noteSplashes: grpNoteSplashes
		};

		modchartManager = new Manager();
		var targetPlayfields:Int = playfieldCountStepper != null ? Std.int(Math.max(1, playfieldCountStepper.value)) : 1;
		while (modchartManager.playfields.length < targetPlayfields)
			modchartManager.addPlayfield();

		for (entry in modifiers)
			modchartManager.addModifier(entry.name, entry.field);

		initializeEditorLuaCallbacks();
		executeEditorCustomInitScript();

		for (entry in events)
		{
			switch (entry.type)
			{
				case 'set':
					modchartManager.set(entry.target, entry.beat, entry.value, entry.player, entry.field);
				case 'ease':
					modchartManager.ease(entry.target, entry.beat, entry.length, entry.value, easeFromName(entry.ease), entry.player, entry.field);
				case 'add':
					modchartManager.add(entry.target, entry.beat, entry.length, entry.value, easeFromName(entry.ease), entry.player, entry.field);
				case 'callback':
					modchartManager.callback(entry.beat, _ -> executeEditorLuaCallback(entry.target), entry.field);
				default:
			}
		}
		add(modchartManager);
	}

	function syncModchartPreviewContext():Void
	{
		if (ModchartEditorPreviewContext.active == null)
			return;

		ModchartEditorPreviewContext.active.currentBeat = Conductor.getBeat(Conductor.songPosition);
		ModchartEditorPreviewContext.active.songPosition = Conductor.songPosition;
		ModchartEditorPreviewContext.active.scrollSpeed = songSpeed * 0.45;
	}

	function destroyModchartManager():Void
	{
		ModchartEditorPreviewContext.active = null;
		destroyEditorLuaCallbacks();
		if (modchartManager != null)
		{
			remove(modchartManager, true);
			modchartManager.destroy();
			modchartManager = null;
		}
		Manager.instance = null;
	}

	function initializeEditorLuaCallbacks():Void
	{
		destroyEditorLuaCallbacks();
		var generatedFunctionScript = buildEditorFunctionLuaScript(false);
		var hasGeneratedScript = generatedFunctionScript.trim().length > 0;
		if ((modchartScriptPaths == null || modchartScriptPaths.length <= 0) && !hasGeneratedScript)
			return;

		if (hasGeneratedScript)
			registerGeneratedEditorLuaState(generatedFunctionScript);

		for (scriptPath in modchartScriptPaths)
		{
			if (scriptPath == null || scriptPath.length <= 0 || !FileSystem.exists(scriptPath))
				continue;

			var lua:State = LuaL.newstate();
			LuaL.openlibs(lua);
			registerEditorLuaState(lua);

			try
			{
				if (LuaL.dofile(lua, scriptPath) == 0)
				{
					var callbackState = new ModchartEditorLuaCallbackState();
					callbackState.lua = lua;
					editorLuaCallbackStates.push(callbackState);
				}
				else
					hxluajit.Lua.close(lua);
			}
			catch (_:Dynamic)
			{
				hxluajit.Lua.close(lua);
			}
		}
	}

	function registerGeneratedEditorLuaState(scriptSource:String):Void
	{
		if (scriptSource == null || scriptSource.trim().length <= 0)
			return;

		var lua:State = LuaL.newstate();
		LuaL.openlibs(lua);
		registerEditorLuaState(lua);

		try
		{
			if (LuaL.dostring(lua, scriptSource) == 0)
			{
				var callbackState = new ModchartEditorLuaCallbackState();
				callbackState.lua = lua;
				editorLuaCallbackStates.push(callbackState);
			}
			else
				hxluajit.Lua.close(lua);
		}
		catch (_:Dynamic)
		{
			hxluajit.Lua.close(lua);
		}
	}

	function executeEditorCustomInitScript():Void
	{
		var scriptSource = buildEditorFunctionLuaScript(true);
		if (scriptSource == null || scriptSource.trim().length <= 0)
			return;

		var lua:State = LuaL.newstate();
		LuaL.openlibs(lua);
		registerEditorLuaState(lua);

		try
		{
			if (LuaL.dostring(lua, scriptSource) == 0)
			{
				Lua.getglobal(lua, 'onInitModchart');
				if (Lua.type(lua, -1) == Lua.LUA_TFUNCTION)
					Lua.pcall(lua, 0, 0, 0);
				else
					Lua.pop(lua, 1);
			}
		}
		catch (_:Dynamic) {}

		hxluajit.Lua.close(lua);
	}

	function destroyEditorLuaCallbacks():Void
	{
		for (luaState in editorLuaCallbackStates)
			if (luaState != null && luaState.lua != null)
				hxluajit.Lua.close(luaState.lua);
		editorLuaCallbackStates = [];
	}

	function registerEditorLuaState(lua:State):Void
	{
		Lua.pushnumber(lua, FlxG.width);
		Lua.setglobal(lua, 'screenWidth');
		Lua.pushnumber(lua, FlxG.height);
		Lua.setglobal(lua, 'screenHeight');

		Lua_helper.add_callback(lua, 'addModifier', function(name:String, ?field:Int = -1) {
			if (modchartManager != null)
				modchartManager.addModifier(name, field);
		});
		Lua_helper.add_callback(lua, 'set', function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
			applyLuaTimedEvent('set', nameOrMods, beat, 0, value, null, player, field);
		});
		Lua_helper.add_callback(lua, 'setNow', function(nameOrMods:Dynamic, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
			applyLuaTimedEvent('set', nameOrMods, Conductor.getBeat(Conductor.songPosition), 0, value, null, player, field);
		});
		Lua_helper.add_callback(lua, 'ease', function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:Dynamic = 'linear', ?player:Int = -1, ?field:Int = -1) {
			applyLuaTimedEvent('ease', nameOrMods, beat, length, value, easeName, player, field);
		});
		Lua_helper.add_callback(lua, 'easeNow', function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:Dynamic = 'linear', ?player:Int = -1, ?field:Int = -1) {
			applyLuaTimedEvent('ease', nameOrMods, Conductor.getBeat(Conductor.songPosition), length, value, easeName, player, field);
		});
		Lua_helper.add_callback(lua, 'add', function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:Dynamic = 'linear', ?player:Int = -1, ?field:Int = -1) {
			applyLuaTimedEvent('add', nameOrMods, beat, length, value, easeName, player, field);
		});
		Lua_helper.add_callback(lua, 'addNow', function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:Dynamic = 'linear', ?player:Int = -1, ?field:Int = -1) {
			applyLuaTimedEvent('add', nameOrMods, Conductor.getBeat(Conductor.songPosition), length, value, easeName, player, field);
		});
		Lua_helper.add_callback(lua, 'getCurrentBeat', function():Float {
			return Conductor.getBeat(Conductor.songPosition);
		});
		Lua_helper.add_callback(lua, 'getSongPosition', function():Float {
			return Conductor.songPosition;
		});
		Lua_helper.add_callback(lua, 'setModifierPath', function(modName:String, nodes:Array<Dynamic>, ?field:Int = 0, ?lane:Int = -1) {
			if (modchartManager == null || field < 0 || field >= modchartManager.playfields.length)
				return;

			var pf = modchartManager.playfields[field];
			if (pf == null)
				return;

			var mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier))
				return;

			var parsed = parsePathNodes(nodes);
			if (lane >= 0)
				cast(mod, PathModifier).loadPathForLane(parsed, lane);
			else
				cast(mod, PathModifier).loadPath(parsed);
		});
		Lua_helper.add_callback(lua, 'setModifierPathOffset', function(modName:String, x:Float, y:Float, ?z:Float = 0, ?field:Int = 0) {
			if (modchartManager == null || field < 0 || field >= modchartManager.playfields.length)
				return;

			var pf = modchartManager.playfields[field];
			if (pf == null)
				return;

			var mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier))
				return;

			cast(mod, PathModifier).pathOffset.setTo(x, y, z);
		});
		Lua_helper.add_callback(lua, 'setModifierPathBound', function(modName:String, bound:Float, ?field:Int = 0) {
			if (modchartManager == null || field < 0 || field >= modchartManager.playfields.length)
				return;

			var pf = modchartManager.playfields[field];
			if (pf == null)
				return;

			var mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier))
				return;

			cast(mod, PathModifier).setPathBound(bound);
		});
	}

	function executeEditorLuaCallback(functionName:String):Void
	{
		if (functionName == null || functionName.length <= 0)
			return;

		for (luaState in editorLuaCallbackStates)
		{
			if (luaState == null || luaState.lua == null)
				continue;

			var state:State = luaState.lua;

			Lua.getglobal(state, functionName);
			if (Lua.type(state, -1) != Lua.LUA_TFUNCTION)
			{
				Lua.pop(state, 1);
				continue;
			}

			if (Lua.pcall(state, 0, 0, 0) != Lua.LUA_OK)
				Lua.pop(state, 1);
		}
	}

	function setupModchartUi():Void
	{
		statusTxt.visible = false;

		var titleText:FlxText = new FlxText(20, 14, FlxG.width - 40, 'Modchart Editor', 28);
		titleText.setFormat(Paths.font('phantom.ttf'), 28, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleText.scrollFactor.set();
		titleText.borderSize = 1.25;
		add(titleText);

		infoText = new FlxText(20, 44, FlxG.width - 40,
			'Live modchart preview with manual modifier/event editing, export to Lua, and capture from the current PlayState scripts.', 16);
		infoText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		infoText.scrollFactor.set();
		infoText.borderSize = 1;
		infoText.alpha = 0.85;
		add(infoText);

		setupTimelineUi();

		uiBox = new PsychUIBox(20, FlxG.height - 348, FlxG.width - 40, 272, ['Project', 'Modifiers', 'Events', 'Functions', 'Preview']);
		uiBox.scrollFactor.set();
		add(uiBox);

		setupProjectTab();
		setupModifierTab();
		setupEventTab();
		setupFunctionsTab();
		setupPreviewTab();

		activeModifiersDebugText = new FlxText(24, uiBox.y - 58, uiBox.width - 48, '', 14);
		activeModifiersDebugText.setFormat(Paths.font('phantom.ttf'), 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		activeModifiersDebugText.scrollFactor.set();
		activeModifiersDebugText.borderSize = 1;
		activeModifiersDebugText.alpha = 0.9;
		add(activeModifiersDebugText);

		editorStatusText = new FlxText(20, uiBox.y + uiBox.height + 8, FlxG.width - 40, '', 16);
		editorStatusText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		editorStatusText.scrollFactor.set();
		editorStatusText.borderSize = 1;
		add(editorStatusText);

		dataTxt.width = 360;
		dataTxt.x = FlxG.width - dataTxt.width - 16;
		dataTxt.y = TIMELINE_Y + 4;
		dataTxt.size = 18;
	}

	function setupTimelineUi():Void
	{
		timelinePanel = new FlxSprite(TIMELINE_X, TIMELINE_Y).makeGraphic(FlxG.width - 40, TIMELINE_HEIGHT, 0xBB101010);
		timelinePanel.scrollFactor.set();
		add(timelinePanel);

		timelineGrid = new FlxSprite(TIMELINE_X, getTimelineGridY()).loadGraphic(
			FlxGridOverlay.createGrid(GRID_SIZE, GRID_SIZE, Std.int(timelinePanel.width + (BEAT_WIDTH * 3)), Std.int(getTimelineGridHeight()), true, 0xFF303030, 0xFF1C1C1C)
		);
		timelineGrid.scrollFactor.set();
		add(timelineGrid);

		for (i in 0...VISIBLE_BEAT_LABELS)
		{
			var beatText = new FlxText(0, TIMELINE_Y + 8, 0, '', 16);
			beatText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			beatText.scrollFactor.set();
			beatText.borderSize = 1;
			add(beatText);
			beatTexts.push(beatText);
		}

		eventSprites = new FlxTypedGroup<ModchartTimelineEventSprite>();
		add(eventSprites);

		timelineHighlight = new FlxSprite().makeGraphic(GRID_SIZE, Std.int(getTimelineGridHeight()), FlxColor.WHITE);
		timelineHighlight.scrollFactor.set();
		timelineHighlight.y = getTimelineGridY();
		timelineHighlight.alpha = 0.15;
		timelineHighlight.visible = false;
		add(timelineHighlight);

		selectedEventBox = new FlxSprite().makeGraphic(40, 40, FlxColor.TRANSPARENT);
		selectedEventBox.scrollFactor.set();
		selectedEventBox.color = FlxColor.LIME;
		selectedEventBox.alpha = 0.85;
		selectedEventBox.visible = false;
		add(selectedEventBox);

		timelineEventInfoText = new FlxText(TIMELINE_X + 8, TIMELINE_Y + TIMELINE_HEIGHT - 26, timelinePanel.width - 16, '', 14);
		timelineEventInfoText.setFormat(Paths.font('phantom.ttf'), 14, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timelineEventInfoText.scrollFactor.set();
		timelineEventInfoText.borderSize = 1;
		timelineEventInfoText.visible = false;
		add(timelineEventInfoText);

		timelineLine = new FlxSprite().makeGraphic(3, Std.int(getTimelineGridHeight()), FlxColor.RED);
		timelineLine.scrollFactor.set();
		timelineLine.y = getTimelineGridY();
		add(timelineLine);
	}

	function setupProjectTab():Void
	{
		var tab = uiBox.getTab('Project').menu;

		projectNameInput = new PsychUIInputText(24, 34, 220, 'modchart', 8);
		projectNameInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			markUnsaved();
			refreshPreview();
		};

		playfieldCountStepper = new PsychUINumericStepper(24, 96, 1, 1, 1, 16, 0, 80);
		playfieldCountStepper.onValueChange = function()
		{
			if (isRefreshingInputs)
				return;
			markUnsaved();
			refreshDerivedViews();
		};

		var exportButton = new PsychUIButton(24, 146, 'Export Lua', function()
		{
			exportLua();
		});

		var copyButton = new PsychUIButton(132, 146, 'Copy Preview', function()
		{
			Clipboard.text = generateLua();
			editorStatusText.text = 'Lua preview copied to clipboard.';
		});

		tab.add(makeLabel(projectNameInput, 'Suggested File Name'));
		tab.add(projectNameInput);
		tab.add(makeLabel(playfieldCountStepper, 'Playfield Count'));
		tab.add(playfieldCountStepper);
		tab.add(exportButton);
		tab.add(copyButton);
	}

	function setupFunctionsTab():Void
	{
		var tab = uiBox.getTab('Functions').menu;

		functionNameInput = new PsychUIInputText(24, 34, 160, 'newFunction', 8);
		functionNameInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			refreshFunctionsPreview();
		};

		functionTemplateDropDown = new PsychUIDropDownMenu(200, 34,
			['helper_blank', 'helper_wave', 'helper_spin', 'advanced_helper', 'callback_blank', 'callback_zoom', 'advanced_callback'],
			function(_, _)
			{
				refreshFunctionsPreview();
			}, 190);

		var addTemplateButton = new PsychUIButton(24, 70, 'Add Template', function()
		{
			appendFunctionTemplate();
		}, 110);

		var addCallButton = new PsychUIButton(144, 70, 'Add Call', function()
		{
			appendFunctionInvocation();
		}, 100);

		var pasteFunctionsButton = new PsychUIButton(254, 70, 'Paste Funcs', function()
		{
			importCustomLuaFromClipboard(true);
		}, 110);

		var pasteInitButton = new PsychUIButton(374, 70, 'Paste Init', function()
		{
			importCustomLuaFromClipboard(false);
		}, 100);

		var copyFunctionsButton = new PsychUIButton(24, 102, 'Copy Funcs', function()
		{
			Clipboard.text = customFunctionLua;
			editorStatusText.text = 'Custom function block copied to clipboard.';
		}, 110);

		var copyInitButton = new PsychUIButton(144, 102, 'Copy Init', function()
		{
			Clipboard.text = customInitLua;
			editorStatusText.text = 'Custom onInitModchart block copied to clipboard.';
		}, 100);

		var clearFunctionsButton = new PsychUIButton(254, 102, 'Clear Funcs', function()
		{
			customFunctionLua = '';
			markUnsaved();
			refreshDerivedViews();
		}, 110);

		var clearInitButton = new PsychUIButton(374, 102, 'Clear Init', function()
		{
			customInitLua = '';
			markUnsaved();
			refreshDerivedViews();
		}, 100);

		functionsPreviewBg = new FlxSprite(24, 138);
		drawCodeBoxBackground(functionsPreviewBg, Std.int(uiBox.width - 72), Std.int(uiBox.height - 166));
		tab.add(functionsPreviewBg);

		functionsPreviewText = new FlxText(28, 142, uiBox.width - 80, '', 14);
		functionsPreviewText.setFormat(Paths.font('phantom.ttf'), 14, FlxColor.WHITE, LEFT);
		tab.add(functionsPreviewText);

		tab.add(makeLabel(functionNameInput, 'Function Name'));
		tab.add(functionNameInput);
		tab.add(makeLabel(functionTemplateDropDown, 'Template'));
		tab.add(functionTemplateDropDown);
		tab.add(addTemplateButton);
		tab.add(addCallButton);
		tab.add(pasteFunctionsButton);
		tab.add(pasteInitButton);
		tab.add(copyFunctionsButton);
		tab.add(copyInitButton);
		tab.add(clearFunctionsButton);
		tab.add(clearInitButton);
	}

	function setupModifierTab():Void
	{
		var tab = uiBox.getTab('Modifiers').menu;

		modifierIndexStepper = new PsychUINumericStepper(24, 34, 1, 0, 0, 0, 0, 80);
		modifierIndexStepper.onValueChange = function()
		{
			if (!isRefreshingInputs)
				loadSelectedModifier();
		};

		modifierNameInput = new PsychUIInputText(124, 34, 170, '', 8);
		modifierNameInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			syncCurrentModifierFromInputs();
		};

		modifierFieldStepper = new PsychUINumericStepper(314, 34, 1, -1, -1, 16, 0, 80);
		modifierFieldStepper.onValueChange = function()
		{
			if (isRefreshingInputs)
				return;
			syncCurrentModifierFromInputs();
		};

		modifierPresetDropDown = new PsychUIDropDownMenu(24, 100, availableModifiers, function(_, label)
		{
			modifierNameInput.text = label;
			syncCurrentModifierFromInputs();
		}, 170);

		var addButton = new PsychUIButton(24, 142, 'Add New', function()
		{
			addModifierEntry();
		});

		var removeButton = new PsychUIButton(120, 142, 'Remove', function()
		{
			removeModifierEntry();
		});

		modifierSummaryText = new FlxText(24, 176, uiBox.width - 96, '', 14);
		modifierSummaryText.setFormat(Paths.font('phantom.ttf'), 14, FlxColor.WHITE, LEFT);

		tab.add(makeLabel(modifierIndexStepper, 'Selected Index'));
		tab.add(modifierIndexStepper);
		tab.add(makeLabel(modifierNameInput, 'Modifier Name'));
		tab.add(modifierNameInput);
		tab.add(makeLabel(modifierFieldStepper, 'Field (-1 = all)'));
		tab.add(modifierFieldStepper);
		tab.add(makeLabel(modifierPresetDropDown, 'Compiled Modifiers'));
		tab.add(modifierPresetDropDown);
		tab.add(addButton);
		tab.add(removeButton);
		tab.add(modifierSummaryText);
	}

	function setupEventTab():Void
	{
		var tab = uiBox.getTab('Events').menu;

		eventIndexStepper = new PsychUINumericStepper(24, 34, 1, 0, 0, 0, 0, 80);
		eventIndexStepper.onValueChange = function()
		{
			if (!isRefreshingInputs)
				loadSelectedEvent();
		};

		eventTypeDropDown = new PsychUIDropDownMenu(124, 34, ['set', 'ease', 'add', 'callback'], function(_, label)
		{
			if (isRefreshingInputs)
				return;
			refreshEventFieldState(label);
			syncCurrentEventFromInputs();
		}, 96);

		eventTargetInput = new PsychUIInputText(236, 34, 180, '', 8);
		eventTargetInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			syncCurrentEventFromInputs();
		};

		eventTargetDropDown = new PsychUIDropDownMenu(24, 96, COMMON_EVENT_TARGETS, function(_, label)
		{
			eventTargetInput.text = label;
			syncCurrentEventFromInputs();
		}, 160);

		eventBeatStepper = new PsychUINumericStepper(24, 152, SNAP_STEP, 0, -9999, 9999, 3, 90);
		eventValueStepper = new PsychUINumericStepper(128, 152, 0.1, 1, -99999, 99999, 3, 90);
		eventLengthStepper = new PsychUINumericStepper(232, 152, SNAP_STEP, 1, 0, 9999, 3, 90);
		eventPlayerStepper = new PsychUINumericStepper(336, 152, 1, -1, -1, 8, 0, 90);
		eventFieldStepper = new PsychUINumericStepper(440, 152, 1, -1, -1, 16, 0, 90);

		for (stepper in [eventBeatStepper, eventValueStepper, eventLengthStepper, eventPlayerStepper, eventFieldStepper])
		{
			stepper.onValueChange = function()
			{
				if (isRefreshingInputs)
					return;
				syncCurrentEventFromInputs();
			};
		}

		eventEaseInput = new PsychUIInputText(24, 208, 160, 'linear', 8);
		eventEaseInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			syncCurrentEventFromInputs();
		};

		eventEaseDropDown = new PsychUIDropDownMenu(200, 208, EASE_NAMES, function(_, label)
		{
			eventEaseInput.text = label;
			syncCurrentEventFromInputs();
		}, 160);

		var addButton = new PsychUIButton(24, 238, 'Add New', function()
		{
			addEventEntry();
		});

		var removeButton = new PsychUIButton(120, 238, 'Remove', function()
		{
			removeEventEntry();
		});

		eventSummaryText = new FlxText(24, 268, uiBox.width - 96, '', 14);
		eventSummaryText.setFormat(Paths.font('phantom.ttf'), 14, FlxColor.WHITE, LEFT);

		tab.add(makeLabel(eventIndexStepper, 'Selected Index'));
		tab.add(eventIndexStepper);
		tab.add(makeLabel(eventTypeDropDown, 'Type'));
		tab.add(eventTypeDropDown);
		tab.add(makeLabel(eventTargetInput, 'Target / Callback'));
		tab.add(eventTargetInput);
		tab.add(makeLabel(eventTargetDropDown, 'Common Targets'));
		tab.add(eventTargetDropDown);
		tab.add(makeLabel(eventBeatStepper, 'Beat'));
		tab.add(eventBeatStepper);
		tab.add(makeLabel(eventValueStepper, 'Value'));
		tab.add(eventValueStepper);
		tab.add(makeLabel(eventLengthStepper, 'Ease Length'));
		tab.add(eventLengthStepper);
		tab.add(makeLabel(eventPlayerStepper, 'Player'));
		tab.add(eventPlayerStepper);
		tab.add(makeLabel(eventFieldStepper, 'Field'));
		tab.add(eventFieldStepper);
		tab.add(makeLabel(eventEaseInput, 'Ease'));
		tab.add(eventEaseInput);
		tab.add(makeLabel(eventEaseDropDown, 'Common Eases'));
		tab.add(eventEaseDropDown);
		tab.add(addButton);
		tab.add(removeButton);
		tab.add(eventSummaryText);
	}

	function setupPreviewTab():Void
	{
		var tab = uiBox.getTab('Preview').menu;

		previewBg = new FlxSprite(24, 26);
		drawCodeBoxBackground(previewBg, Std.int(uiBox.width - 72), Std.int(uiBox.height - 58));
		tab.add(previewBg);

		previewText = new FlxText(24, 30, uiBox.width - 96, '', 14);
		previewText.setFormat(Paths.font('phantom.ttf'), 14, FlxColor.WHITE, LEFT);
		tab.add(previewText);
	}

	function handleTimelineInput():Void
	{
		if (PsychUIInputText.focusOn != null || timelinePanel == null)
			return;

		hoveredEventIndex = getHoveredEventIndex();
		var hoveredIndex = hoveredEventIndex;
		if (hoveredIndex >= 0)
		{
			timelineHighlight.visible = false;
			if (FlxG.mouse.justPressed)
				selectEvent(hoveredIndex);
			if (FlxG.keys.justPressed.BACKSPACE && selectedEventIndex >= 0 && selectedEventIndex < events.length)
				removeEventEntry();
			return;
		}

		if (!isMouseInsideTimeline())
		{
			timelineHighlight.visible = false;
			return;
		}

		var snappedBeat = snapBeat(mouseToBeat(FlxG.mouse.x));
		timelineHighlight.visible = true;
		timelineHighlight.x = beatToScreen(snappedBeat) - (GRID_SIZE * 0.5);

		if (FlxG.mouse.justPressed)
			createEventAt(snappedBeat);

		if (FlxG.keys.justPressed.BACKSPACE && selectedEventIndex >= 0 && selectedEventIndex < events.length)
			removeEventEntry();
	}

	function handlePreviewInput():Void
	{
		if (PsychUIInputText.focusOn != null || uiBox == null)
			return;

		var isPreviewTab = uiBox.selectedName == 'Preview' && previewText != null;
		var isFunctionsTab = uiBox.selectedName == 'Functions' && functionsPreviewText != null;
		if (!isPreviewTab && !isFunctionsTab)
			return;

		var visibleLines = getCodeVisibleLineCount();
		var nextOffset = isFunctionsTab ? functionScrollOffset : previewScrollOffset;

		if (FlxG.mouse.wheel != 0 && isMouseInsideUiBox())
			nextOffset -= FlxG.mouse.wheel;

		if (FlxG.keys.justPressed.DOWN)
			nextOffset += 1;
		else if (FlxG.keys.justPressed.UP)
			nextOffset -= 1;
		else if (FlxG.keys.justPressed.PAGEDOWN)
			nextOffset += Std.int(Math.max(1, visibleLines - 1));
		else if (FlxG.keys.justPressed.PAGEUP)
			nextOffset -= Std.int(Math.max(1, visibleLines - 1));

		nextOffset = Std.int(FlxMath.bound(nextOffset, 0, isFunctionsTab ? getFunctionMaxScroll() : getPreviewMaxScroll()));
		if (isFunctionsTab)
		{
			if (nextOffset != functionScrollOffset)
			{
				functionScrollOffset = nextOffset;
				refreshFunctionsPreview();
			}
		}
		else if (nextOffset != previewScrollOffset)
		{
			previewScrollOffset = nextOffset;
			refreshPreview();
		}
	}

	function updateTimelineVisuals():Void
	{
		if (timelinePanel == null)
			return;

		timelineLine.x = getCursorX();
		var beatOffset = timelineBeat - Math.floor(timelineBeat);
		timelineGrid.x = getCursorX() - BEAT_WIDTH - (beatOffset * BEAT_WIDTH);

		for (i in 0...beatTexts.length)
		{
			var beatValue = Math.floor(timelineBeat) + i;
			beatTexts[i].text = Std.string(beatValue);
			beatTexts[i].x = beatToScreen(beatValue) - 10;
			beatTexts[i].visible = beatTexts[i].x >= TIMELINE_X && beatTexts[i].x <= TIMELINE_X + timelinePanel.width - 20;
		}

		var stacks:Map<String, Int> = new Map<String, Int>();
		selectedEventBox.visible = false;
		timelineEventInfoText.visible = false;
		var focusedEventIndex:Int = hoveredEventIndex >= 0 ? hoveredEventIndex : selectedEventIndex;

		for (sprite in eventSprites.members)
		{
			if (sprite == null)
				continue;

			var entry = events[sprite.eventIndex];
			if (entry == null)
				continue;

			var x = beatToScreen(entry.beat) - (sprite.width * 0.5);
			var stackKey = Std.string(snapBeat(entry.beat));
			var stackIndex = stacks.exists(stackKey) ? stacks.get(stackKey) : 0;
			stacks.set(stackKey, stackIndex + 1);

			sprite.visible = x > TIMELINE_X - sprite.width && x < TIMELINE_X + timelinePanel.width;
			sprite.x = x;
			sprite.y = getTimelineGridY() + (stackIndex * 18);
			sprite.alpha = sprite.eventIndex == focusedEventIndex ? 1 : 0.85;

			if (sprite.eventIndex == focusedEventIndex && sprite.visible)
			{
				selectedEventBox.visible = true;
				selectedEventBox.x = sprite.x - 4;
				selectedEventBox.y = sprite.y - 4;
				timelineEventInfoText.text = describeEvent(entry, sprite.eventIndex);
				timelineEventInfoText.visible = true;
			}
		}
	}

	function isMouseInsideTimeline():Bool
	{
		return FlxG.mouse.x >= TIMELINE_X && FlxG.mouse.x <= TIMELINE_X + timelinePanel.width
			&& FlxG.mouse.y >= getTimelineActiveY() && FlxG.mouse.y <= TIMELINE_Y + TIMELINE_HEIGHT - TIMELINE_ACTIVE_PADDING_BOTTOM;
	}

	function mouseToBeat(mouseX:Float):Float
	{
		return timelineBeat + ((mouseX - getCursorX()) / BEAT_WIDTH);
	}

	function beatToScreen(beat:Float):Float
	{
		return getCursorX() + ((beat - timelineBeat) * BEAT_WIDTH);
	}

	inline function getCursorX():Float
	{
		return TIMELINE_X + BEAT_WIDTH;
	}

	inline function getTimelineActiveY():Float
	{
		return TIMELINE_Y + TIMELINE_ACTIVE_PADDING_TOP;
	}

	inline function getTimelineActiveHeight():Float
	{
		return TIMELINE_HEIGHT - TIMELINE_ACTIVE_PADDING_TOP - TIMELINE_ACTIVE_PADDING_BOTTOM;
	}

	inline function getTimelineGridY():Float
	{
		return getTimelineActiveY();
	}

	inline function getTimelineGridHeight():Float
	{
		return GRID_SIZE;
	}

	inline function snapBeat(beat:Float):Float
	{
		return FlxMath.roundDecimal(Math.round(beat / SNAP_STEP) * SNAP_STEP, 3);
	}

	function seedDefaults():Void
	{
		var projectName = useCurrentPlayStateSong && PlayState.SONG != null ? Paths.formatToSongPath(PlayState.SONG.song) : DEFAULT_SONG;
		modifiers = [
			{name: 'transform', field: -1},
			{name: 'reverse', field: -1},
			{name: 'zoom', field: -1}
		];
		events = [
			{type: 'set', target: 'xmod', beat: 0, value: 1, length: 1, ease: 'linear', player: -1, field: -1}
		];
		selectedEventIndex = 0;
		timelineBeat = 0;
		customFunctionLua = '';
		customInitLua = '';
		if (projectNameInput != null)
			projectNameInput.text = projectName;
		if (playfieldCountStepper != null)
			playfieldCountStepper.value = 1;
	}

	function applyCapturedPlayStateContext():Void
	{
		if (!useCurrentPlayStateSong || capturedPlayStateContext == null)
			return;

		playfieldCountStepper.value = Math.max(1, capturedPlayStateContext.playfieldCount);
		modifiers = capturedPlayStateContext.modifiers.copy();
		events = capturedPlayStateContext.events.copy();
		modchartScriptPaths = capturedPlayStateContext.scriptPaths != null ? capturedPlayStateContext.scriptPaths.copy() : [];
		customFunctionLua = '';
		customInitLua = '';
		timelineBeat = capturedPlayStateContext.timelineBeat;
		if (capturedPlayStateContext.projectName != null)
			projectNameInput.text = capturedPlayStateContext.projectName;
		selectedEventIndex = events.length > 0 ? 0 : 0;
		hasUnsavedChanges = false;
		capturedPlayStateContext = null;
	}

	function refreshAllViews():Void
	{
		refreshModifierControls();
		refreshEventControls();
		refreshDerivedViews();
	}

	function refreshDerivedViews():Void
	{
		refreshEventSprites();
		if (strumLineNotes != null && notes != null)
			initializeModchartManager();
		refreshModifierSummary();
		refreshEventSummary();
		refreshFunctionsPreview();
		refreshPreview();
		refreshActiveModifierDebug();
		refreshStatusText();
		updateTimelineVisuals();
	}

	function refreshModifierControls():Void
	{
		isRefreshingInputs = true;
		modifierIndexStepper.max = Math.max(0, modifiers.length - 1);
		if (modifierIndexStepper.value > modifierIndexStepper.max)
			modifierIndexStepper.value = modifierIndexStepper.max;
		loadSelectedModifier();
		isRefreshingInputs = false;
	}

	function refreshEventControls():Void
	{
		isRefreshingInputs = true;
		eventIndexStepper.max = Math.max(0, events.length - 1);
		if (selectedEventIndex > events.length - 1)
			selectedEventIndex = events.length - 1;
		eventIndexStepper.value = Math.max(0, selectedEventIndex);
		loadSelectedEvent();
		isRefreshingInputs = false;
	}

	function refreshEventSprites():Void
	{
		eventSprites.clear();
		for (index => entry in events)
			eventSprites.add(new ModchartTimelineEventSprite(index, entry));
	}

	function addModifierEntry():Void
	{
		modifiers.push({name: defaultString(modifierNameInput.text, 'transform').toLowerCase(), field: Std.int(modifierFieldStepper.value)});
		modifierIndexStepper.value = modifiers.length - 1;
		markUnsaved();
		refreshAllViews();
	}

	function removeModifierEntry():Void
	{
		if (modifiers.length <= 0)
			return;

		var index = Std.int(modifierIndexStepper.value);
		if (index < 0 || index >= modifiers.length)
			return;

		modifiers.splice(index, 1);
		if (modifiers.length == 0)
			modifiers.push({name: 'transform', field: -1});

		modifierIndexStepper.value = Math.min(index, modifiers.length - 1);
		markUnsaved();
		refreshAllViews();
	}

	function loadSelectedModifier():Void
	{
		if (modifiers.length <= 0)
			return;

		var index = Std.int(modifierIndexStepper.value);
		if (index < 0 || index >= modifiers.length)
			return;

		var entry = modifiers[index];
		modifierNameInput.text = entry.name;
		modifierFieldStepper.value = entry.field;
		modifierPresetDropDown.selectedLabel = entry.name;
	}

	function syncCurrentModifierFromInputs():Void
	{
		if (modifiers.length <= 0)
			return;

		var index = Std.int(modifierIndexStepper.value);
		if (index < 0 || index >= modifiers.length)
			return;

		modifiers[index] = {
			name: defaultString(modifierNameInput.text, 'transform').toLowerCase(),
			field: Std.int(modifierFieldStepper.value)
		};
		markUnsaved();
		refreshDerivedViews();
	}

	function createEventAt(beat:Float):Void
	{
		var base = getCurrentEventTemplate();
		base.beat = beat;
		events.push(base);
		selectedEventIndex = events.length - 1;
		eventIndexStepper.value = selectedEventIndex;
		markUnsaved();
		refreshAllViews();
		uiBox.selectedName = 'Events';
	}

	function getCurrentEventTemplate():LuaEditorEventEntry
	{
		if (selectedEventIndex >= 0 && selectedEventIndex < events.length)
		{
			var current = events[selectedEventIndex];
			return {
				type: current.type,
				target: current.target,
				beat: current.beat,
				value: current.value,
				length: current.length,
				ease: current.ease,
				player: current.player,
				field: current.field
			};
		}

		return {
			type: eventTypeDropDown != null && eventTypeDropDown.selectedLabel != null ? eventTypeDropDown.selectedLabel : 'set',
			target: defaultString(eventTargetInput != null ? eventTargetInput.text : '', 'xmod').toLowerCase(),
			beat: timelineBeat,
			value: eventValueStepper != null ? eventValueStepper.value : 1,
			length: eventLengthStepper != null ? eventLengthStepper.value : 1,
			ease: defaultString(eventEaseInput != null ? eventEaseInput.text : '', 'linear'),
			player: eventPlayerStepper != null ? Std.int(eventPlayerStepper.value) : -1,
			field: eventFieldStepper != null ? Std.int(eventFieldStepper.value) : -1
		};
	}

	function addEventEntry():Void
	{
		createEventAt(snapBeat(timelineBeat));
	}

	function removeEventEntry():Void
	{
		if (events.length <= 0)
			return;

		var index = selectedEventIndex;
		if (index < 0 || index >= events.length)
			return;

		events.splice(index, 1);
		if (events.length == 0)
			events.push({type: 'set', target: 'xmod', beat: 0, value: 1, length: 1, ease: 'linear', player: -1, field: -1});

		selectEvent(index < events.length ? index : events.length - 1);
		markUnsaved();
		refreshAllViews();
	}

	function selectEvent(index:Int):Void
	{
		selectedEventIndex = (events.length > 0) ? Std.int(FlxMath.bound(index, 0, events.length - 1)) : 0;
		eventIndexStepper.value = selectedEventIndex;
		loadSelectedEvent();
		refreshDerivedViews();
	}

	function loadSelectedEvent():Void
	{
		if (events.length <= 0)
			return;

		var index = Std.int(eventIndexStepper.value);
		if (index < 0 || index >= events.length)
			return;

		selectedEventIndex = index;
		var entry = events[index];

		isRefreshingInputs = true;
		eventTypeDropDown.selectedLabel = entry.type;
		eventTargetInput.text = entry.target;
		eventTargetDropDown.selectedLabel = entry.target;
		eventBeatStepper.value = entry.beat;
		eventValueStepper.value = entry.value;
		eventLengthStepper.value = entry.length;
		eventEaseInput.text = entry.ease;
		eventEaseDropDown.selectedLabel = entry.ease;
		eventPlayerStepper.value = entry.player;
		eventFieldStepper.value = entry.field;
		refreshEventFieldState(entry.type);
		isRefreshingInputs = false;
	}

	function syncCurrentEventFromInputs():Void
	{
		if (events.length <= 0 || selectedEventIndex < 0 || selectedEventIndex >= events.length)
			return;

		events[selectedEventIndex] = {
			type: eventTypeDropDown.selectedLabel != null ? eventTypeDropDown.selectedLabel : 'set',
			target: defaultString(eventTargetInput.text, 'xmod').toLowerCase(),
			beat: snapBeat(eventBeatStepper.value),
			value: eventValueStepper.value,
			length: Math.max(0, eventLengthStepper.value),
			ease: defaultString(eventEaseInput.text, 'linear'),
			player: Std.int(eventPlayerStepper.value),
			field: Std.int(eventFieldStepper.value)
		};
		markUnsaved();
		refreshDerivedViews();
	}

	function refreshEventFieldState(type:String):Void
	{
		var isEase = type == 'ease' || type == 'add';
		var isCallback = type == 'callback';

		eventValueStepper.alpha = isCallback ? 0.45 : 1;
		eventPlayerStepper.alpha = isCallback ? 0.45 : 1;
		eventLengthStepper.alpha = isEase ? 1 : 0.45;
		eventEaseInput.alpha = isEase ? 1 : 0.45;
		eventEaseDropDown.alpha = isEase ? 1 : 0.45;
	}

	function refreshModifierSummary():Void
	{
		var lines:Array<String> = ['Registered addModifier calls:'];
		for (i => entry in modifiers)
			lines.push('${i}. addModifier("${entry.name}", ${entry.field})');

		modifierSummaryText.text = lines.join('\n');
	}

	function refreshEventSummary():Void
	{
		var lines:Array<String> = ['Timeline events:'];
		for (i => entry in events)
		{
			var line = '${i}. ${entry.type} ${entry.target} @ ${fmt(entry.beat)}';
			switch (entry.type)
			{
				case 'ease', 'add':
					line += ' => ${fmt(entry.value)} in ${fmt(entry.length)} (${entry.ease}) [player=${entry.player}, field=${entry.field}]';
				case 'callback':
					line += ' [field=${entry.field}]';
				default:
					line += ' => ${fmt(entry.value)} [player=${entry.player}, field=${entry.field}]';
			}
			lines.push(line);
		}

		eventSummaryText.text = lines.join('\n');
	}

	function drawCodeBoxBackground(sprite:FlxSprite, width:Int, height:Int):Void
	{
		if (sprite == null)
			return;
		PsychUISkin.drawStyledRect(sprite, width, height, PsychUISkin.panelStyle());
	}

	function hasLuaBlock(value:String):Bool
	{
		return value != null && value.trim().length > 0;
	}

	function appendLuaSnippet(existing:String, snippet:String):String
	{
		var cleanSnippet = snippet != null ? snippet.replace('\r\n', '\n').replace('\r', '\n').trim() : '';
		if (cleanSnippet.length <= 0)
			return existing;

		var cleanExisting = existing != null ? existing.replace('\r\n', '\n').replace('\r', '\n').trim() : '';
		if (cleanExisting.length <= 0)
			return cleanSnippet;

		return cleanExisting + '\n\n' + cleanSnippet;
	}

	function appendLuaBlock(lines:Array<String>, block:String, indentLevel:Int = 0):Void
	{
		if (!hasLuaBlock(block))
			return;

		var indent = '';
		for (_ in 0...indentLevel)
			indent += '\t';

		for (line in block.replace('\r\n', '\n').replace('\r', '\n').split('\n'))
			lines.push(line.length > 0 ? indent + line : '');
	}

	function sanitizeLuaIdentifier(value:String):String
	{
		var base = defaultString(value, 'newFunction').trim();
		if (base.length <= 0)
			base = 'newFunction';

		var out = new StringBuf();
		for (i in 0...base.length)
		{
			var char = base.charAt(i);
			var code = base.charCodeAt(i);
			var isAlpha = (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
			var isDigit = code >= 48 && code <= 57;
			if (isAlpha || char == '_' || (i > 0 && isDigit))
				out.add(char);
			else if (char == ' ' || char == '-' || char == '.')
				out.add('_');
		}

		var result = out.toString();
		if (result.length <= 0)
			result = 'newFunction';
		if (result.charCodeAt(0) >= 48 && result.charCodeAt(0) <= 57)
			result = '_' + result;
		return result;
	}

	function buildFunctionTemplate(functionName:String, templateName:String):String
	{
		return switch (templateName)
		{
			case 'helper_wave':
				'function ' + functionName + '(beat)\n'
				+ '\tease("x", beat, 1, 60, "quadOut")\n'
				+ '\tease("x", beat + 1, 1, -60, "quadInOut")\n'
				+ '\tease("x", beat + 2, 1, 0, "quadIn")\n'
				+ 'end';
			case 'helper_spin':
				'function ' + functionName + '(beat)\n'
				+ '\tset("rotatey", beat, 0)\n'
				+ '\tease("rotatey", beat, 0.5, 180, "expoOut")\n'
				+ '\tease("rotatey", beat + 0.5, 0.5, 360, "expoOut")\n'
				+ 'end';
			case 'advanced_helper':
				'function ' + functionName + '(beat, length, amount, easeName, player, field)\n'
				+ '\tlocal span = length or 1\n'
				+ '\tlocal value = amount or 1\n'
				+ '\tlocal easeMode = easeName or "linear"\n'
				+ '\tlocal targetPlayer = player or -1\n'
				+ '\tlocal targetField = field or -1\n'
				+ '\tease("xmod", beat, span, value, easeMode, targetPlayer, targetField)\n'
				+ 'end';
			case 'callback_blank':
				'function ' + functionName + '()\n'
				+ '\tsetNow("xmod", 1)\n'
				+ 'end';
			case 'callback_zoom':
				'function ' + functionName + '()\n'
				+ '\tsetNow("zoom", 1.12)\n'
				+ '\teaseNow("zoom", 0.5, 0, "quadOut")\n'
				+ 'end';
			case 'advanced_callback':
				'function ' + functionName + '()\n'
				+ '\tlocal field = 0\n'
				+ '\teaseNow({rotatex = -45, anglex = -30}, 1, "bounce", -1, field)\n'
				+ '\teaseNow({rotatex = 45, anglex = 30}, 1, "bounce", -1, field)\n'
				+ 'end';
			default:
				'function ' + functionName + '(beat)\n'
				+ '\t-- Add your modchart logic here.\n'
				+ '\tease("xmod", beat, 1, 1, "linear")\n'
				+ 'end';
		};
	}

	function templateIsCallback(templateName:String):Bool
	{
		return templateName != null && templateName.startsWith('callback');
	}

	function appendFunctionTemplate():Void
	{
		var functionName = sanitizeLuaIdentifier(functionNameInput != null ? functionNameInput.text : 'newFunction');
		var templateName = functionTemplateDropDown != null ? defaultString(functionTemplateDropDown.selectedLabel, 'helper_blank') : 'helper_blank';
		customFunctionLua = appendLuaSnippet(customFunctionLua, buildFunctionTemplate(functionName, templateName));
		if (functionNameInput != null)
			functionNameInput.text = functionName;
		markUnsaved();
		refreshDerivedViews();
		editorStatusText.text = 'Template "$templateName" added for function "$functionName".';
	}

	function appendFunctionInvocation():Void
	{
		var functionName = sanitizeLuaIdentifier(functionNameInput != null ? functionNameInput.text : 'newFunction');
		var templateName = functionTemplateDropDown != null ? defaultString(functionTemplateDropDown.selectedLabel, 'helper_blank') : 'helper_blank';
		if (templateIsCallback(templateName))
		{
			events.push({type: 'callback', target: functionName, beat: snapBeat(timelineBeat), value: 0, length: 0, ease: 'linear', player: -1, field: -1});
			selectedEventIndex = events.length - 1;
			refreshEventControls();
			editorStatusText.text = 'Callback event for "$functionName" added at beat ${fmt(snapBeat(timelineBeat))}.';
		}
		else
		{
			customInitLua = appendLuaSnippet(customInitLua, functionName + '(' + fmt(snapBeat(timelineBeat)) + ')');
			editorStatusText.text = 'Init call for "$functionName" added at beat ${fmt(snapBeat(timelineBeat))}.';
		}
		markUnsaved();
		refreshDerivedViews();
	}

	function importCustomLuaFromClipboard(isFunctionBlock:Bool):Void
	{
		var clip = Clipboard.text;
		if (clip == null || clip.trim().length <= 0)
		{
			editorStatusText.text = 'Clipboard is empty.';
			return;
		}

		if (isFunctionBlock)
		{
			customFunctionLua = appendLuaSnippet(customFunctionLua, clip);
			editorStatusText.text = 'Clipboard appended to custom functions block.';
		}
		else
		{
			customInitLua = appendLuaSnippet(customInitLua, clip);
			editorStatusText.text = 'Clipboard appended to custom onInitModchart block.';
		}

		markUnsaved();
		refreshDerivedViews();
	}

	function refreshFunctionsPreview():Void
	{
		if (functionsPreviewText == null)
			return;

		drawCodeBoxBackground(functionsPreviewBg, Std.int(uiBox.width - 72), Std.int(uiBox.height - 166));

		var lines:Array<String> = [];
		var functionName = sanitizeLuaIdentifier(functionNameInput != null ? functionNameInput.text : 'newFunction');
		var templateName = functionTemplateDropDown != null ? defaultString(functionTemplateDropDown.selectedLabel, 'helper_blank') : 'helper_blank';

		lines.push('-- template: ' + templateName + ' | function: ' + functionName + ' --');
		lines.push('');
		lines.push('-- functions / callbacks --');
		if (hasLuaBlock(customFunctionLua))
			lines = lines.concat(customFunctionLua.replace('\r\n', '\n').replace('\r', '\n').split('\n'));
		else
			lines.push('-- no custom functions yet --');

		lines.push('');
		lines.push('-- extra onInitModchart code --');
		if (hasLuaBlock(customInitLua))
			lines = lines.concat(customInitLua.replace('\r\n', '\n').replace('\r', '\n').split('\n'));
		else
			lines.push('-- no extra init code yet --');

		functionCachedLines = lines;
		functionScrollOffset = Std.int(FlxMath.bound(functionScrollOffset, 0, getFunctionMaxScroll()));

		var shown:Array<String> = [];
		var visibleLines = getCodeVisibleLineCount();
		var startLine = functionScrollOffset;
		var endLine = Std.int(Math.min(lines.length, startLine + visibleLines));

		if (lines.length > visibleLines)
			shown.push('-- functions ${startLine + 1}-${endLine} / ${lines.length} (wheel or PgUp/PgDn) --');

		for (i in startLine...endLine)
			shown.push(lines[i]);

		functionsPreviewText.text = shown.join('\n');
	}

	function buildEditorFunctionLuaScript(includeInitCode:Bool):String
	{
		var lines:Array<String> = [];
		appendLuaBlock(lines, customFunctionLua);

		if (includeInitCode && hasLuaBlock(customInitLua))
		{
			if (lines.length > 0)
				lines.push('');
			lines.push('function onInitModchart()');
			appendLuaBlock(lines, customInitLua, 1);
			lines.push('end');
		}

		return lines.join('\n');
	}

	function refreshPreview():Void
	{
		drawCodeBoxBackground(previewBg, Std.int(uiBox.width - 72), Std.int(uiBox.height - 58));
		var lines = generateLua().split('\n');
		previewCachedLines = lines;
		previewScrollOffset = Std.int(FlxMath.bound(previewScrollOffset, 0, getPreviewMaxScroll()));
		var shown:Array<String> = [];
		var visibleLines:Int = getPreviewVisibleLineCount();
		var startLine:Int = previewScrollOffset;
		var endLine:Int = Std.int(Math.min(lines.length, startLine + visibleLines));

		if (lines.length > visibleLines)
			shown.push('-- preview ${startLine + 1}-${endLine} / ${lines.length} (wheel or PgUp/PgDn) --');

		for (i in startLine...endLine)
			shown.push(lines[i]);

		previewText.text = shown.join('\n');
	}

	function refreshActiveModifierDebug():Void
	{
		if (activeModifiersDebugText == null)
			return;

		if (uiBox == null || uiBox.selectedName != 'Preview' || modchartManager == null || modchartManager.playfields == null)
		{
			activeModifiersDebugText.visible = false;
			return;
		}

		var shown:Array<String> = [];
		var seen:Map<String, Bool> = new Map<String, Bool>();
		for (fieldIndex => playfield in modchartManager.playfields)
		{
			if (playfield == null)
				continue;

			for (name in playfield.modifiers.modifiers.keys())
			{
				for (player in 0...2)
				{
					var value = playfield.getPercent(name, player);
					if (Math.isNaN(value) || Math.abs(value) < 0.0001)
						continue;

					var key = '${fieldIndex}:${player}:${name}';
					if (seen.exists(key))
						continue;
					seen.set(key, true);
					shown.push('F${fieldIndex} P${player} ${name}=${fmt(value)}');
				}
			}
		}

		shown.sort(Reflect.compare);
		if (shown.length <= 0)
			shown = ['Active modifiers: none'];
		else
		{
			shown.unshift('Active modifiers');
			if (shown.length > 8)
			{
				var hiddenCount = shown.length - 8;
				shown = shown.slice(0, 8);
				shown.push('+${hiddenCount} more');
			}
		}

		activeModifiersDebugText.text = shown.join(' | ');
		activeModifiersDebugText.visible = true;
	}

	function getCodeVisibleLineCount():Int
	{
		if (uiBox == null)
			return 12;
		return Std.int(Math.max(6, Math.floor((uiBox.height - 86) / 18)));
	}

	function getPreviewVisibleLineCount():Int
	{
		return getCodeVisibleLineCount();
	}

	function getPreviewMaxScroll():Int
	{
		return Std.int(Math.max(0, previewCachedLines.length - getPreviewVisibleLineCount()));
	}

	function getFunctionMaxScroll():Int
	{
		return Std.int(Math.max(0, functionCachedLines.length - getCodeVisibleLineCount()));
	}

	function refreshStatusText():Void
	{
		if (editorStatusText == null)
			return;

		var stateLabel = hasUnsavedChanges ? 'Unsaved changes' : 'Ready';
		editorStatusText.text = '${stateLabel} | playfields=${playfieldCountStepper != null ? Std.int(playfieldCountStepper.value) : 1} | modifiers=${modifiers.length} | events=${events.length} | beat=${fmt(timelineBeat)}';
	}

	function generateLua():String
	{
		var lines:Array<String> = [
			'-- Generated by Plus Engine Modchart Editor.'
		];

		if (hasLuaBlock(customFunctionLua))
		{
			lines.push('');
			appendLuaBlock(lines, customFunctionLua);
		}

		lines.push('');
		lines.push('function onInitModchart()');

		for (i in 1...Std.int(playfieldCountStepper.value))
			lines.push('\taddPlayfield()');

		if (Std.int(playfieldCountStepper.value) > 1)
			lines.push('');

		var seen:Map<String, Bool> = new Map<String, Bool>();
		for (entry in modifiers)
		{
			var key = entry.name + ':' + entry.field;
			if (seen.exists(key))
				continue;
			seen.set(key, true);
			lines.push('\taddModifier("${escapeLua(entry.name)}", ${entry.field})');
		}

		if (modifiers.length > 0)
			lines.push('');

		if (hasLuaBlock(customInitLua))
		{
			appendLuaBlock(lines, customInitLua, 1);
			lines.push('');
		}

		var sortedEvents = events.copy();
		sortedEvents.sort(sortCapturedEvents);
		for (entry in sortedEvents)
		{
			switch (entry.type)
			{
				case 'ease':
					lines.push('\tease("${escapeLua(entry.target)}", ${fmt(entry.beat)}, ${fmt(entry.length)}, ${fmt(entry.value)}, "${escapeLua(defaultString(entry.ease, "linear"))}", ${entry.player}, ${entry.field})');
				case 'add':
					lines.push('\tadd("${escapeLua(entry.target)}", ${fmt(entry.beat)}, ${fmt(entry.length)}, ${fmt(entry.value)}, "${escapeLua(defaultString(entry.ease, "linear"))}", ${entry.player}, ${entry.field})');
				case 'callback':
					lines.push('\tcallback(${fmt(entry.beat)}, "${escapeLua(entry.target)}", ${entry.field})');
				default:
					lines.push('\tset("${escapeLua(entry.target)}", ${fmt(entry.beat)}, ${fmt(entry.value)}, ${entry.player}, ${entry.field})');
			}
		}

		lines.push('end');
		return lines.join('\n');
	}

	function exportLua():Void
	{
		var data = generateLua();
		var fileName = sanitizeFileName(defaultString(projectNameInput.text, 'modchart-generated')) + '.lua';
		if (data.length <= 0)
			return;

		editorFileRef = new FileReference();
		editorFileRef.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		editorFileRef.addEventListener(Event.CANCEL, onSaveCancel);
		editorFileRef.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		editorFileRef.save(data, fileName);
	}

	function onSaveComplete(_):Void
	{
		hasUnsavedChanges = false;
		refreshStatusText();
		cleanupFileReference();
	}

	function onSaveCancel(_):Void
	{
		cleanupFileReference();
	}

	function onSaveError(_):Void
	{
		if (editorStatusText != null)
			editorStatusText.text = 'Failed to save Lua modchart.';
		cleanupFileReference();
	}

	function cleanupFileReference():Void
	{
		if (editorFileRef == null)
			return;

		editorFileRef.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		editorFileRef.removeEventListener(Event.CANCEL, onSaveCancel);
		editorFileRef.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		editorFileRef = null;
	}

	function getHoveredEventIndex():Int
	{
		for (sprite in eventSprites.members)
			if (sprite != null && sprite.visible && FlxG.mouse.overlaps(sprite))
				return sprite.eventIndex;
		return -1;
	}

	function markUnsaved():Void
	{
		hasUnsavedChanges = true;
		refreshStatusText();
	}

	function makeLabel(target:FlxSprite, text:String):FlxText
	{
		var label = new FlxText(target.x, target.y - 16, 0, text, 12);
		label.setFormat(Paths.font('phantom.ttf'), 12, FlxColor.WHITE, LEFT);
		return label;
	}

	function isMouseInsideUiBox():Bool
	{
		return FlxG.mouse.x >= uiBox.x && FlxG.mouse.x <= uiBox.x + uiBox.width
			&& FlxG.mouse.y >= uiBox.y && FlxG.mouse.y <= uiBox.y + uiBox.height;
	}

	function sanitizeFileName(value:String):String
	{
		var output = value.trim();
		for (token in ['<', '>', ':', '"', '/', '\\', '|', '?', '*'])
			output = output.replace(token, '-');
		return defaultString(output, 'modchart-generated');
	}

	function escapeLua(value:String):String
	{
		return value.replace('\\', '\\\\').replace('"', '\\"');
	}

	function defaultString(value:String, fallback:String):String
	{
		var trimmed = value != null ? value.trim() : '';
		return trimmed.length > 0 ? trimmed : fallback;
	}

	function fmt(value:Float):String
	{
		return Std.string(FlxMath.roundDecimal(value, 3));
	}

	function describeEvent(entry:LuaEditorEventEntry, index:Int):String
	{
		if (entry == null)
			return '';

		var base = '#${index} ${entry.type} ${entry.target} @ ${fmt(entry.beat)}';
		switch (entry.type)
		{
			case 'ease', 'add':
				return '${base} -> ${fmt(entry.value)} len ${fmt(entry.length)} ${entry.ease} p${entry.player} f${entry.field}';
			case 'callback':
				return '${base} callback f${entry.field}';
			default:
				return '${base} -> ${fmt(entry.value)} p${entry.player} f${entry.field}';
		}
	}

	function parsePathNodes(nodes:Array<Dynamic>):Array<PathNode>
	{
		var out:Array<PathNode> = [];
		if (nodes == null)
			return out;

		for (node in nodes)
		{
			if (node == null)
				continue;

			var x:Float = 0;
			var y:Float = 0;
			var z:Float = 0;

			if (Std.isOfType(node, Array))
			{
				var arr:Array<Dynamic> = cast node;
				x = toFloat(arr.length > 0 ? arr[0] : null, 0);
				y = toFloat(arr.length > 1 ? arr[1] : null, 0);
				z = toFloat(arr.length > 2 ? arr[2] : null, 0);
				if (x == 0 && y == 0 && z == 0 && arr.length >= 4)
				{
					x = toFloat(arr[1], 0);
					y = toFloat(arr[2], 0);
					z = toFloat(arr[3], 0);
				}
			}
			else
			{
				x = toFloat(Reflect.field(node, 'x'), 0);
				y = toFloat(Reflect.field(node, 'y'), 0);
				z = toFloat(Reflect.field(node, 'z'), 0);
			}

			out.push({x: x, y: y, z: z});
		}

		return out;
	}

	function toFloat(value:Dynamic, fallback:Float):Float
	{
		if (value == null)
			return fallback;
		var parsed = Std.parseFloat(Std.string(value));
		return Math.isNaN(parsed) ? fallback : parsed;
	}

	static function easeFromName(name:String):Dynamic
	{
		#if LUA_ALLOWED
		return LuaUtils.getTweenEaseByString(name != null ? name : '');
		#else
		return FlxEase.linear;
		#end
	}

	static function getEaseName(ease:Dynamic):String
	{
		if (ease == FlxEase.accelerate) return 'accelerate';
		if (ease == FlxEase.quadIn) return 'quadIn';
		if (ease == FlxEase.quadOut) return 'quadOut';
		if (ease == FlxEase.quadInOut) return 'quadInOut';
		if (ease == FlxEase.quadOutIn) return 'quadOutIn';
		if (ease == FlxEase.outInQuad) return 'outInQuad';
		if (ease == FlxEase.cubeIn) return 'cubeIn';
		if (ease == FlxEase.cubeOut) return 'cubeOut';
		if (ease == FlxEase.cubeInOut) return 'cubeInOut';
		if (ease == FlxEase.cubicOutIn) return 'cubicOutIn';
		if (ease == FlxEase.outInCubic) return 'outInCubic';
		if (ease == FlxEase.quartIn) return 'quartIn';
		if (ease == FlxEase.quartOut) return 'quartOut';
		if (ease == FlxEase.quartInOut) return 'quartInOut';
		if (ease == FlxEase.quartOutIn) return 'quartOutIn';
		if (ease == FlxEase.outInQuart) return 'outInQuart';
		if (ease == FlxEase.quintIn) return 'quintIn';
		if (ease == FlxEase.quintOut) return 'quintOut';
		if (ease == FlxEase.quintInOut) return 'quintInOut';
		if (ease == FlxEase.quintOutIn) return 'quintOutIn';
		if (ease == FlxEase.outInQuint) return 'outInQuint';
		if (ease == FlxEase.sineIn) return 'sineIn';
		if (ease == FlxEase.sineOut) return 'sineOut';
		if (ease == FlxEase.sineInOut) return 'sineInOut';
		if (ease == FlxEase.sineOutIn) return 'sineOutIn';
		if (ease == FlxEase.outInSine) return 'outInSine';
		if (ease == FlxEase.backIn) return 'backIn';
		if (ease == FlxEase.backOut) return 'backOut';
		if (ease == FlxEase.backInOut) return 'backInOut';
		if (ease == FlxEase.backOutIn) return 'backOutIn';
		if (ease == FlxEase.outInBack) return 'outInBack';
		if (ease == FlxEase.bell) return 'bell';
		if (ease == FlxEase.bounce) return 'bounce';
		if (ease == FlxEase.bounceIn) return 'bounceIn';
		if (ease == FlxEase.bounceOut) return 'bounceOut';
		if (ease == FlxEase.bounceInOut) return 'bounceInOut';
		if (ease == FlxEase.bounceOutIn) return 'bounceOutIn';
		if (ease == FlxEase.outInBounce) return 'outInBounce';
		if (ease == FlxEase.circIn) return 'circIn';
		if (ease == FlxEase.circOut) return 'circOut';
		if (ease == FlxEase.circInOut) return 'circInOut';
		if (ease == FlxEase.circOutIn) return 'circOutIn';
		if (ease == FlxEase.outInCirc) return 'outInCirc';
		if (ease == FlxEase.expoIn) return 'expoIn';
		if (ease == FlxEase.expoOut) return 'expoOut';
		if (ease == FlxEase.expoInOut) return 'expoInOut';
		if (ease == FlxEase.expoOutIn) return 'expoOutIn';
		if (ease == FlxEase.outInExpo) return 'outInExpo';
		if (ease == FlxEase.decelerate) return 'decelerate';
		if (ease == FlxEase.elasticIn) return 'elasticIn';
		if (ease == FlxEase.elasticOut) return 'elasticOut';
		if (ease == FlxEase.elasticInOut) return 'elasticInOut';
		if (ease == FlxEase.elasticOutIn) return 'elasticOutIn';
		if (ease == FlxEase.outInElastic) return 'outInElastic';
		if (ease == FlxEase.emphasizedAccelerate) return 'emphasizedAccelerate';
		if (ease == FlxEase.emphasizedDecelerate) return 'emphasizedDecelerate';
		if (ease == FlxEase.instant) return 'instant';
		if (ease == FlxEase.inverse) return 'inverse';
		if (ease == FlxEase.pop) return 'pop';
		if (ease == FlxEase.tap) return 'tap';
		if (ease == FlxEase.pulse) return 'pulse';
		if (ease == FlxEase.spike) return 'spike';
		if (ease == FlxEase.standard) return 'standard';
		if (ease == FlxEase.tri) return 'tri';
		if (ease == FlxEase.smoothStepIn) return 'smoothStepIn';
		if (ease == FlxEase.smoothStepOut) return 'smoothStepOut';
		if (ease == FlxEase.smoothStepInOut) return 'smoothStepInOut';
		if (ease == FlxEase.smootherStepIn) return 'smootherStepIn';
		if (ease == FlxEase.smootherStepOut) return 'smootherStepOut';
		if (ease == FlxEase.smootherStepInOut) return 'smootherStepInOut';
		return 'linear';
	}

	function cleanupSound(sound:FlxSound):Void
	{
		if (sound == null)
			return;

		sound.stop();
		FlxG.sound.list.remove(sound);
		sound.destroy();
	}
}

class ModchartTimelineEventSprite extends FlxSprite
{
	public var eventIndex:Int;

	public function new(eventIndex:Int, eventData:LuaEditorEventEntry)
	{
		this.eventIndex = eventIndex;
		super();

		try
		{
			loadGraphic(Paths.image('eventArrowModchart'));
		}
		catch (_:Dynamic)
		{
			makeGraphic(32, 32, FlxColor.WHITE);
		}

		setGraphicSize(32, 32);
		updateHitbox();
		antialiasing = true;
		scrollFactor.set();

		switch (eventData.type)
		{
			case 'ease':
				color = FlxColor.CYAN;
			case 'callback':
				color = FlxColor.LIME;
			default:
				color = FlxColor.ORANGE;
		}
	}
}

class ModchartEditorLuaCallbackState
{
	public var lua:State = null;

	public function new()
	{
	}
}
