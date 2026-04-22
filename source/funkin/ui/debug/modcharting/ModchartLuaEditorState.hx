package funkin.ui.debug.modcharting;

import funkin.audio.Conductor;
import funkin.data.song.Song;
import funkin.data.stage.StageData;
import funkin.modding.modchart.Manager;
import funkin.modding.modchart.backend.standalone.adapters.psych.ModchartEditorPreviewContext;
import funkin.modding.modchart.engine.events.EventType;
import funkin.modding.modchart.engine.events.types.AddEvent;
import funkin.modding.modchart.engine.events.types.EaseEvent;
import funkin.modding.modchart.engine.modifiers.ModifierGroup;
#if LUA_ALLOWED
import funkin.modding.scripting.FunkinLua;
#end
import funkin.play.PlayState;
import funkin.play.notes.Note;
import funkin.play.notes.NoteSplash;
import funkin.play.notes.StrumNote;
import funkin.ui.LoadingState;
import funkin.ui.components.PsychUIButton;
import funkin.ui.components.PsychUIBox;
import funkin.ui.components.PsychUIDropDownMenu;
import funkin.ui.components.PsychUIInputText;
import funkin.ui.components.PsychUINumericStepper;
import funkin.ui.debug.MasterEditorMenu;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import haxe.io.Path;
import lime.system.Clipboard;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
#if sys
import sys.FileSystem;
import sys.io.File;
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
}

typedef LuaEditorParsedModchart = {
	var playfieldCount:Int;
	var modifiers:Array<LuaEditorModifierEntry>;
	var events:Array<LuaEditorEventEntry>;
	@:optional var projectName:String;
}

@:access(funkin.modding.modchart.engine.events.EventManager)
class ModchartLuaEditorState extends MusicBeatState
{
	static inline final TIMELINE_X:Int = 32;
	static inline final TIMELINE_Y:Int = 96;
	static inline final TIMELINE_HEIGHT:Int = 236;
	static inline final TIMELINE_ACTIVE_PADDING_TOP:Int = 40;
	static inline final TIMELINE_ACTIVE_PADDING_BOTTOM:Int = 12;
	static inline final GRID_SIZE:Int = 32;
	static inline final BEAT_WIDTH:Int = GRID_SIZE * 4;
	static inline final SNAP_STEP:Float = 0.25;
	static inline final VISIBLE_BEAT_LABELS:Int = 10;
	static inline final TIMELINE_GRID_HEIGHT:Int = 46;
	static inline final PREVIEW_VIEWPORT_GAP:Int = 10;
	static inline final PREVIEW_VIEWPORT_MARGIN:Int = 8;

	static var capturedPlayStateContext:LuaEditorPlayStateCapture = null;
	static var suppressPlayStateHotkeyUntilRelease:Bool = false;

	static final COMMON_EVENT_TARGETS:Array<String> = buildCommonTargets();
	static final EASE_NAMES:Array<String> = [
		'linear', 'quadIn', 'quadOut', 'quadInOut', 'cubeIn', 'cubeOut', 'cubeInOut',
		'quartIn', 'quartOut', 'quartInOut', 'quintIn', 'quintOut', 'quintInOut',
		'sineIn', 'sineOut', 'sineInOut', 'backIn', 'backOut', 'backInOut',
		'bounceIn', 'bounceOut', 'bounceInOut', 'circIn', 'circOut', 'circInOut',
		'expoIn', 'expoOut', 'expoInOut'
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

	var availableModifiers:Array<String> = buildModifierNames();

	var timelinePanel:FlxSprite;
	var timelineGrid:FlxSprite;
	var timelineLine:FlxSprite;
	var timelineHighlight:FlxSprite;
	var selectedEventBox:FlxSprite;
	var previewViewportBg:FlxSprite;
	var previewViewportBorder:FlxSprite;
	var previewStrumLine:FlxSprite;
	var previewCamera:FlxCamera;
	var previewOverlayCamera:FlxCamera;
	var beatTexts:Array<FlxText> = [];
	var eventSprites:FlxTypedGroup<ModchartTimelineEventSprite>;
	var infoText:FlxText;
	var statusText:FlxText;
	var previewText:FlxText;

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

	var modifiers:Array<LuaEditorModifierEntry> = [];
	var events:Array<LuaEditorEventEntry> = [];
	var selectedEventIndex:Int = 0;
	var hasUnsavedChanges:Bool = false;
	var _file:FileReference;
	var timelineBeat:Float = 0;
	var isRefreshingInputs:Bool = false;
	var useCurrentPlayStateSong:Bool = false;
	var previewSongName:String = 'test';
	var previewSongData:Dynamic = null;
	var previewSongLoaded:Bool = false;
	var previewInst:FlxSound;
	var previewPlaybackActive:Bool = false;
	var previewManager:Manager;
	var previewNoteGroup:FlxTypedGroup<FlxBasic>;
	var previewStrumLineNotes:FlxTypedGroup<StrumNote>;
	var previewVisualStrums:FlxTypedGroup<StrumNote>;
	var previewOpponentStrums:FlxTypedGroup<StrumNote>;
	var previewPlayerStrums:FlxTypedGroup<StrumNote>;
	var previewNotes:FlxTypedGroup<Note>;
	var previewNoteSplashes:FlxTypedGroup<NoteSplash>;
	var previewAllNotes:Array<Note> = [];
	var previewUnspawnNotes:Array<Note> = [];
	var previewLastSongPosition:Float = 0;

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

	public static function capturePlayStateContext(playState:PlayState):Void
	{
		if (playState == null)
		{
			capturedPlayStateContext = null;
			return;
		}

		var modifiers:Array<LuaEditorModifierEntry> = [];
		var events:Array<LuaEditorEventEntry> = [];
		var playfieldCount = 1;
		var projectName:String = null;
		var manager = Manager.instance;
		var parsedModchart = parsePlayStateLuaModchart(playState);

		if (parsedModchart != null)
		{
			playfieldCount = Std.int(Math.max(playfieldCount, parsedModchart.playfieldCount));
			modifiers = parsedModchart.modifiers;
			events = parsedModchart.events;
			projectName = parsedModchart.projectName;
		}

		if ((modifiers.length <= 0 && events.length <= 0) && manager != null)
		{
			playfieldCount = Std.int(Math.max(1, manager.playfields.length));
			for (fieldIndex => playfield in manager.playfields)
			{
				if (playfield == null)
					continue;

				for (name in playfield.modifiers.modifiers.keys())
				{
					modifiers.push({
						name: name,
						field: fieldIndex
					});
				}

				for (i in 0...playfield.events.eventCount)
				{
					var serialized = serializeRuntimeEvent(playfield.events.eventList[i], fieldIndex);
					if (serialized != null)
						events.push(serialized);
				}
			}
		}

		if (projectName == null && PlayState.SONG != null && PlayState.SONG.song != null)
			projectName = Paths.formatToSongPath(PlayState.SONG.song);

		capturedPlayStateContext = {
			playfieldCount: playfieldCount,
			timelineBeat: FlxMath.roundDecimal(playState.curDecBeat, 3),
			modifiers: modifiers,
			events: events,
			projectName: projectName
		};
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
		{
			if (entry != null && entry.name == name && entry.field == field)
				return true;
		}
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

	static function parsePlayStateLuaModchart(playState:PlayState):LuaEditorParsedModchart
	{
		#if (LUA_ALLOWED && sys)
		if (playState == null || playState.luaArray == null || playState.luaArray.length <= 0)
			return null;

		var collectedModifiers:Array<LuaEditorModifierEntry> = [];
		var collectedEvents:Array<LuaEditorEventEntry> = [];
		var playfieldCount:Int = 1;
		var projectName:String = null;

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
			projectName: projectName
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

		var parsedModifiers:Array<LuaEditorModifierEntry> = [];
		var parsedEvents:Array<LuaEditorEventEntry> = [];
		var playfieldCount:Int = 1;
		var hasInitModchart:Bool = false;

		Lua_helper.add_callback(lua, 'addModifier', function(name:String, ?field:Int = -1) {
			var normalizedName = normalizeModchartName(name, 'transform');
			if (!hasModifierEntry(parsedModifiers, normalizedName, field))
				parsedModifiers.push({name: normalizedName, field: field});
		});
		Lua_helper.add_callback(lua, 'set', function(name:String, beat:Float, value:Float, ?player:Int = -1, ?field:Int = -1) {
			parsedEvents.push({type: 'set', target: normalizeModchartName(name, 'xmod'), beat: beat, value: value, length: 0, ease: 'linear', player: player, field: field});
		});
		Lua_helper.add_callback(lua, 'ease', function(name:String, beat:Float, length:Float, value:Float, ?easeName:String = 'linear', ?player:Int = -1, ?field:Int = -1) {
			parsedEvents.push({type: 'ease', target: normalizeModchartName(name, 'xmod'), beat: beat, value: value, length: length, ease: normalizeModchartName(easeName, 'linear', false), player: player, field: field});
		});
		Lua_helper.add_callback(lua, 'add', function(name:String, beat:Float, length:Float, value:Float, ?easeName:String = 'linear', ?player:Int = -1, ?field:Int = -1) {
			parsedEvents.push({type: 'add', target: normalizeModchartName(name, 'xmod'), beat: beat, value: value, length: length, ease: normalizeModchartName(easeName, 'linear', false), player: player, field: field});
		});
		Lua_helper.add_callback(lua, 'callback', function(beat:Float, callbackName:Dynamic, ?field:Int = -1) {
			parsedEvents.push({type: 'callback', target: normalizeModchartName(callbackName, 'callback', false), beat: beat, value: 0, length: 0, ease: 'linear', player: -1, field: field});
		});
		Lua_helper.add_callback(lua, 'addPlayfield', function() {
			playfieldCount++;
		});
		Lua_helper.add_callback(lua, 'setHoldSubdivisions', function(_:Dynamic) {});

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
			projectName: Path.withoutExtension(Path.withoutDirectory(script.scriptName))
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
		FlxG.camera.bgColor = FlxColor.BLACK;

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.color = 0xFF262626;
		bg.scrollFactor.set();
		add(bg);

		var titleText:FlxText = new FlxText(32, 18, FlxG.width - 64, 'Lua Modchart Editor', 32);
		titleText.setFormat(Paths.font('phantom.ttf'), 32, FlxColor.WHITE, LEFT);
		add(titleText);

		infoText = new FlxText(32, 56, FlxG.width - 64,
			'Timeline editor for direct Lua modcharts. The top strip is the event timeline; the viewport below runs a real playfield preview with live modifiers over notes and strums.', 16);
		infoText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT);
		infoText.alpha = 0.85;
		add(infoText);

		setupTimeline();

		uiBox = new PsychUIBox(20, TIMELINE_Y + TIMELINE_HEIGHT + 8, FlxG.width - 40, FlxG.height - (TIMELINE_Y + TIMELINE_HEIGHT + 82),
			['Project', 'Modifiers', 'Events', 'Preview']);
		uiBox.scrollFactor.set();
		add(uiBox);

		setupProjectTab();
		setupModifierTab();
		setupEventTab();
		setupPreviewTab();
		uiBox.selectedName = 'Events';

		statusText = new FlxText(20, FlxG.height - 58, FlxG.width - 40, '', 16);
		statusText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT);
		add(statusText);

		seedDefaults();
		applyCapturedPlayStateContext();
		loadPreviewSong();
		refreshAllViews();

		Cursor.show();
		addTouchPad('UP_DOWN', 'B');

		super.create();
	}

	function setupTimeline()
	{
		timelinePanel = new FlxSprite(TIMELINE_X, TIMELINE_Y).makeGraphic(FlxG.width - 64, TIMELINE_HEIGHT, 0xFF121212);
		timelinePanel.alpha = 0.9;
		add(timelinePanel);

		timelineGrid = new FlxSprite(TIMELINE_X, getTimelineActiveY()).loadGraphic(
			FlxGridOverlay.createGrid(GRID_SIZE, Std.int(getTimelineActiveHeight()), Std.int(timelinePanel.width + (BEAT_WIDTH * 3)), Std.int(getTimelineActiveHeight()), true, 0xFF303030, 0xFF1F1F1F)
		);
		timelineGrid.alpha = 0.95;
		add(timelineGrid);

		for (i in 0...VISIBLE_BEAT_LABELS)
		{
			var beatText = new FlxText(0, TIMELINE_Y + 10, 0, '', 16);
			beatText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT);
			add(beatText);
			beatTexts.push(beatText);
		}

		eventSprites = new FlxTypedGroup<ModchartTimelineEventSprite>();
		add(eventSprites);

		previewViewportBg = new FlxSprite(TIMELINE_X + PREVIEW_VIEWPORT_MARGIN, getPreviewViewportY()).makeGraphic(
			Std.int(timelinePanel.width - (PREVIEW_VIEWPORT_MARGIN * 2)),
			Std.int(getPreviewViewportHeight()),
			0xFF101010
		);
		add(previewViewportBg);

		previewViewportBorder = new FlxSprite(previewViewportBg.x, previewViewportBg.y).makeGraphic(
			Std.int(previewViewportBg.width),
			Std.int(previewViewportBg.height),
			0xFF232323
		);
		previewViewportBorder.alpha = 0.2;
		add(previewViewportBorder);

		previewStrumLine = new FlxSprite(0, 0).makeGraphic(Std.int(previewViewportBg.width), 6, 0x66FFFFFF);
		previewStrumLine.visible = false;
		add(previewStrumLine);

		previewCamera = new FlxCamera(
			Std.int(previewViewportBg.x),
			Std.int(previewViewportBg.y),
			Std.int(previewViewportBg.width),
			Std.int(previewViewportBg.height)
		);
		previewCamera.bgColor = 0xFF101010;
		previewCamera.bgColor.alpha = 0;
		previewCamera.zoom = 0.8;
		FlxG.cameras.add(previewCamera, false);

		previewOverlayCamera = new FlxCamera(
			Std.int(previewViewportBg.x),
			Std.int(previewViewportBg.y),
			Std.int(previewViewportBg.width),
			Std.int(previewViewportBg.height)
		);
		previewOverlayCamera.bgColor = 0xFF101010;
		previewOverlayCamera.bgColor.alpha = 0;
		previewOverlayCamera.zoom = previewCamera.zoom;
		FlxG.cameras.add(previewOverlayCamera, false);
		previewStrumLine.cameras = [previewOverlayCamera];

		timelineHighlight = new FlxSprite().makeGraphic(GRID_SIZE, Std.int(getTimelineActiveHeight()), FlxColor.WHITE);
		timelineHighlight.y = getTimelineActiveY();
		timelineHighlight.alpha = 0.15;
		add(timelineHighlight);

		selectedEventBox = new FlxSprite().makeGraphic(40, 40, FlxColor.TRANSPARENT);
		selectedEventBox.color = FlxColor.LIME;
		selectedEventBox.alpha = 0.85;
		selectedEventBox.visible = false;
		add(selectedEventBox);

		timelineLine = new FlxSprite().makeGraphic(3, Std.int(getTimelineActiveHeight()), FlxColor.RED);
		timelineLine.y = getTimelineActiveY();
		add(timelineLine);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		updatePreviewPlaybackState();
		syncPreviewSpawnedNotes();
		syncPreviewContextMetrics();
		handleTimelineInput();
		updateTimelineVisuals();

		if ((controls.BACK || FlxG.keys.justPressed.ESCAPE) && PsychUIInputText.focusOn == null)
		{
			MusicBeatState.switchState(new MasterEditorMenu());
		}
	}

	function handleTimelineInput()
	{
		if (PsychUIInputText.focusOn != null)
			return;

		if (FlxG.keys.justPressed.SPACE)
			togglePreviewPlayback();
		if (FlxG.keys.justPressed.ENTER)
			goToPlayState();

		var step = FlxG.keys.pressed.SHIFT ? 1.0 : SNAP_STEP;
		if (previewPlaybackActive)
			return;

		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.D)
			timelineBeat += step;
		if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A)
			timelineBeat -= step;

		if (isMouseInsideTimeline() && FlxG.mouse.wheel != 0)
			timelineBeat -= FlxG.mouse.wheel * step;

		timelineBeat = FlxMath.roundDecimal(timelineBeat, 3);

		if (isMouseInsideTimeline())
		{
			var snappedBeat = snapBeat(mouseToBeat(FlxG.mouse.x));
			timelineHighlight.visible = true;
			timelineHighlight.x = beatToScreen(snappedBeat) - (GRID_SIZE * 0.5);

			if (FlxG.mouse.justPressed)
			{
				var hoveredIndex = getHoveredEventIndex();
				if (hoveredIndex >= 0)
					selectEvent(hoveredIndex);
				else
					createEventAt(snappedBeat);
			}

			if (FlxG.keys.justPressed.BACKSPACE && selectedEventIndex >= 0 && selectedEventIndex < events.length)
				removeEventEntry();
		}
		else
		{
			timelineHighlight.visible = false;
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

	inline function snapBeat(beat:Float):Float
	{
		return FlxMath.roundDecimal(Math.round(beat / SNAP_STEP) * SNAP_STEP, 3);
	}

	function updateTimelineVisuals()
	{
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
			sprite.y = TIMELINE_Y + 10 + (stackIndex % 2) * 18;
			sprite.alpha = sprite.eventIndex == selectedEventIndex ? 1 : 0.85;

			if (sprite.eventIndex == selectedEventIndex && sprite.visible)
			{
				selectedEventBox.visible = true;
				selectedEventBox.x = sprite.x - 4;
				selectedEventBox.y = sprite.y - 4;
			}
		}
	}

	function setupProjectTab()
	{
		var tab = uiBox.getTab('Project').menu;

		projectNameInput = new PsychUIInputText(24, 34, 240, 'modchart', 8);
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
			refreshPreview();
			refreshStatusText();
		};

		var exportButton = new PsychUIButton(24, 148, 'Export Lua', function()
		{
			exportLua();
		});

		var copyButton = new PsychUIButton(144, 148, 'Copy Preview', function()
		{
			Clipboard.text = generateLua();
			statusText.text = 'Lua preview copied to clipboard.';
		});

		var resetButton = new PsychUIButton(286, 148, 'Reset Data', function()
		{
			resetData();
		});

		var notes = new FlxText(24, 206, uiBox.width - 96,
			'The save dialog lets the user rename the exported Lua file freely. This editor only owns onInitModchart(); put helper functions, videos and custom path callbacks in another Lua file.', 16);
		notes.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT);

		tab.add(makeLabel(projectNameInput, 'Suggested File Name'));
		tab.add(projectNameInput);
		tab.add(makeLabel(playfieldCountStepper, 'Playfield Count'));
		tab.add(playfieldCountStepper);
		tab.add(exportButton);
		tab.add(copyButton);
		tab.add(resetButton);
		tab.add(notes);
	}

	function setupModifierTab()
	{
		var tab = uiBox.getTab('Modifiers').menu;

		modifierIndexStepper = new PsychUINumericStepper(24, 34, 1, 0, 0, 0, 0, 80);
		modifierIndexStepper.onValueChange = function()
		{
			if (!isRefreshingInputs)
				loadSelectedModifier();
		};

		modifierNameInput = new PsychUIInputText(124, 34, 180, '', 8);
		modifierNameInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			syncCurrentModifierFromInputs();
		};

		modifierFieldStepper = new PsychUINumericStepper(324, 34, 1, -1, -1, 16, 0, 80);
		modifierFieldStepper.onValueChange = function()
		{
			if (isRefreshingInputs)
				return;
			syncCurrentModifierFromInputs();
		};

		modifierPresetDropDown = new PsychUIDropDownMenu(24, 104, availableModifiers, function(_, label)
		{
			modifierNameInput.text = label;
			syncCurrentModifierFromInputs();
		}, 180);

		var addButton = new PsychUIButton(24, 146, 'Add New', function()
		{
			addModifierEntry();
		});

		var removeButton = new PsychUIButton(126, 146, 'Remove Modifier', function()
		{
			removeModifierEntry();
		});

		modifierSummaryText = new FlxText(24, 206, uiBox.width - 96, '', 16);
		modifierSummaryText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT);

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

	function setupEventTab()
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
		}, 100);

		eventTargetInput = new PsychUIInputText(244, 34, 190, '', 8);
		eventTargetInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			syncCurrentEventFromInputs();
		};

		eventTargetDropDown = new PsychUIDropDownMenu(24, 98, COMMON_EVENT_TARGETS, function(_, label)
		{
			eventTargetInput.text = label;
			syncCurrentEventFromInputs();
		}, 180);

		eventBeatStepper = new PsychUINumericStepper(24, 158, SNAP_STEP, 0, -9999, 9999, 3, 90);
		eventValueStepper = new PsychUINumericStepper(132, 158, 0.1, 1, -99999, 99999, 3, 90);
		eventLengthStepper = new PsychUINumericStepper(240, 158, SNAP_STEP, 1, 0, 9999, 3, 90);
		eventPlayerStepper = new PsychUINumericStepper(348, 158, 1, -1, -1, 8, 0, 90);
		eventFieldStepper = new PsychUINumericStepper(456, 158, 1, -1, -1, 16, 0, 90);

		for (stepper in [eventBeatStepper, eventValueStepper, eventLengthStepper, eventPlayerStepper, eventFieldStepper])
		{
			stepper.onValueChange = function()
			{
				if (isRefreshingInputs)
					return;
				syncCurrentEventFromInputs();
			};
		}

		eventEaseInput = new PsychUIInputText(24, 224, 180, 'linear', 8);
		eventEaseInput.onChange = function(_, _)
		{
			if (isRefreshingInputs)
				return;
			syncCurrentEventFromInputs();
		};

		eventEaseDropDown = new PsychUIDropDownMenu(224, 224, EASE_NAMES, function(_, label)
		{
			eventEaseInput.text = label;
			syncCurrentEventFromInputs();
		}, 180);

		var addButton = new PsychUIButton(24, 280, 'Add New', function()
		{
			addEventEntry();
		});

		var removeButton = new PsychUIButton(126, 280, 'Remove Event', function()
		{
			removeEventEntry();
		});

		eventSummaryText = new FlxText(24, 334, uiBox.width - 96, '', 16);
		eventSummaryText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT);

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

	function setupPreviewTab()
	{
		var tab = uiBox.getTab('Preview').menu;

		previewText = new FlxText(24, 34, uiBox.width - 96, '', 16);
		previewText.setFormat(Paths.font('phantom.ttf'), 16, FlxColor.WHITE, LEFT);
		tab.add(previewText);

		var playtestButton = new PsychUIButton(24, 390, 'Playtest In Game', function()
		{
			goToPlayState();
		});
		tab.add(playtestButton);
	}

	function seedDefaults()
	{
		previewSongName = 'test';
		if (useCurrentPlayStateSong && PlayState.SONG != null && PlayState.SONG.song != null)
		{
			var currentSong = Paths.formatToSongPath(PlayState.SONG.song);
			if (currentSong.length > 0)
				previewSongName = currentSong;
		}

		var projectName = 'test';
		projectName = previewSongName;

		projectNameInput.text = projectName;
		playfieldCountStepper.value = 1;
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
	}

	function resetData()
	{
		stopPreviewPlayback();
		seedDefaults();
		loadPreviewSong();
		hasUnsavedChanges = true;
		refreshAllViews();
		statusText.text = 'Editor data reset.';
	}

	function addModifierEntry()
	{
		modifiers.push({name: defaultString(modifierNameInput.text, 'transform').toLowerCase(), field: Std.int(modifierFieldStepper.value)});
		modifierIndexStepper.value = modifiers.length - 1;
		markUnsaved();
		refreshAllViews();
	}

	function removeModifierEntry()
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

	function loadSelectedModifier()
	{
		if (modifiers.length <= 0)
			return;

		var index = Std.int(modifierIndexStepper.value);
		if (index < 0 || index >= modifiers.length)
			return;

		isRefreshingInputs = true;
		var entry = modifiers[index];
		modifierNameInput.text = entry.name;
		modifierFieldStepper.value = entry.field;
		modifierPresetDropDown.selectedLabel = entry.name;
		isRefreshingInputs = false;
	}

	function syncCurrentModifierFromInputs()
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

	function createEventAt(beat:Float)
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
			beat: 0,
			value: eventValueStepper != null ? eventValueStepper.value : 1,
			length: eventLengthStepper != null ? eventLengthStepper.value : 1,
			ease: defaultString(eventEaseInput != null ? eventEaseInput.text : '', 'linear'),
			player: eventPlayerStepper != null ? Std.int(eventPlayerStepper.value) : -1,
			field: eventFieldStepper != null ? Std.int(eventFieldStepper.value) : -1
		};
	}

	function addEventEntry()
	{
		createEventAt(snapBeat(timelineBeat));
	}

	function removeEventEntry()
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

	function selectEvent(index:Int)
	{
		selectedEventIndex = (events.length > 0) ? Std.int(FlxMath.bound(index, 0, events.length - 1)) : 0;
		eventIndexStepper.value = selectedEventIndex;
		loadSelectedEvent();
		refreshDerivedViews();
	}

	function loadSelectedEvent()
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

	function syncCurrentEventFromInputs()
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

	function refreshEventFieldState(type:String)
	{
		var isEase = type == 'ease' || type == 'add';
		var isCallback = type == 'callback';

		eventValueStepper.alpha = isCallback ? 0.45 : 1;
		eventPlayerStepper.alpha = isCallback ? 0.45 : 1;
		eventLengthStepper.alpha = isEase ? 1 : 0.45;
		eventEaseInput.alpha = isEase ? 1 : 0.45;
		eventEaseDropDown.alpha = isEase ? 1 : 0.45;
	}

	function refreshAllViews()
	{
		refreshModifierControls();
		refreshEventControls();
		refreshDerivedViews();
	}

	function refreshDerivedViews()
	{
		refreshEventSprites();
		rebuildPreviewModchart();
		refreshModifierSummary();
		refreshEventSummary();
		refreshPreview();
		refreshStatusText();
		updateTimelineVisuals();
	}

	function refreshModifierControls()
	{
		isRefreshingInputs = true;
		modifierIndexStepper.max = Math.max(0, modifiers.length - 1);
		if (modifierIndexStepper.value > modifierIndexStepper.max)
			modifierIndexStepper.value = modifierIndexStepper.max;
		loadSelectedModifier();
		isRefreshingInputs = false;
	}

	function refreshEventControls()
	{
		isRefreshingInputs = true;
		eventIndexStepper.max = Math.max(0, events.length - 1);
		if (selectedEventIndex > events.length - 1)
			selectedEventIndex = events.length - 1;
		eventIndexStepper.value = Math.max(0, selectedEventIndex);
		loadSelectedEvent();
		isRefreshingInputs = false;
	}

	function refreshEventSprites()
	{
		eventSprites.clear();
		for (index => entry in events)
			eventSprites.add(new ModchartTimelineEventSprite(index, entry));
	}

	function loadPreviewSong()
	{
		stopPreviewPlayback();
		previewSongLoaded = false;
		previewSongData = null;

		if (useCurrentPlayStateSong && PlayState.SONG != null)
			previewSongData = PlayState.SONG;
		else
			previewSongData = Song.getChart(previewSongName, previewSongName);

		if (previewSongData == null)
		{
			statusText.text = 'Could not load preview song: ' + previewSongName;
			destroyPreviewModchart();
			return;
		}

		Conductor.bpm = previewSongData.bpm;
		Conductor.songPosition = Conductor.beatToSeconds(timelineBeat);
		previewLastSongPosition = Conductor.songPosition;
		Conductor.mapBPMChanges(previewSongData);
		buildPreviewStrums();
		buildPreviewNotes();
		rebuildPreviewModchart();
		loadPreviewAudio();
		previewSongLoaded = previewManager != null;
	}

	function loadPreviewAudio()
	{
		if (previewInst != null)
		{
			previewInst.stop();
			previewInst.destroy();
			previewInst = null;
		}

		try
		{
			previewInst = new FlxSound();
			previewInst.loadEmbedded(Paths.inst(previewSongData.song));
			previewInst.onComplete = function()
			{
				previewPlaybackActive = false;
				if (previewInst != null)
					previewInst.time = 0;
				Conductor.songPosition = 0;
				timelineBeat = 0;
				syncPreviewContextMetrics();
				refreshStatusText();
			};
			FlxG.sound.list.add(previewInst);
		}
		catch (_:Dynamic)
		{
			previewInst = null;
			statusText.text = 'Could not load preview audio for ' + previewSongName + '.';
		}
	}

	function togglePreviewPlayback()
	{
		if (!previewSongLoaded || previewInst == null)
		{
			loadPreviewSong();
			if (!previewSongLoaded || previewInst == null)
				return;
		}

		if (previewPlaybackActive)
		{
			stopPreviewPlayback();
			return;
		}

		var startTime = Conductor.beatToSeconds(timelineBeat);
		startTime = FlxMath.bound(startTime, 0, Math.max(0, previewInst.length - 1));
		previewInst.play(true, startTime);
		previewPlaybackActive = true;
		Conductor.songPosition = previewInst.time;
		syncPreviewContextMetrics();
		refreshStatusText();
	}

	function stopPreviewPlayback()
	{
		if (previewInst != null)
			previewInst.pause();
		previewPlaybackActive = false;
		syncPreviewContextMetrics();
		refreshStatusText();
	}

	function updatePreviewPlaybackState()
	{
		if (!previewPlaybackActive || previewInst == null)
		{
			Conductor.songPosition = Conductor.beatToSeconds(timelineBeat);
			if (Conductor.songPosition < previewLastSongPosition)
				syncPreviewSpawnedNotes(true);
			return;
		}

		Conductor.songPosition = previewInst.time;
		if (Conductor.songPosition < previewLastSongPosition)
			syncPreviewSpawnedNotes(true);
		timelineBeat = FlxMath.roundDecimal(Conductor.getBeat(Conductor.songPosition), 3);
	}

	function buildPreviewStrums()
	{
		ensurePreviewGroups();
		previewStrumLineNotes.clear();
		previewVisualStrums.clear();
		previewOpponentStrums.clear();
		previewPlayerStrums.clear();
		previewNoteSplashes.clear();

		var oldSong = PlayState.SONG;
		PlayState.SONG = previewSongData;
		var strumLineX:Float = ClientPrefs.data.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X;
		var strumLineY:Float = ClientPrefs.data.downScroll ? Math.max(50, previewCamera.height - 150) : 50;
		trace('[ModchartLuaEditorState] buildPreviewStrums start viewport=' + previewViewportBg.width + 'x' + previewViewportBg.height
			+ ' camera=' + (previewCamera != null ? (previewCamera.width + 'x' + previewCamera.height) : 'null')
			+ ' cameraPos=' + (previewCamera != null ? ('(' + previewCamera.x + ', ' + previewCamera.y + ') zoom=' + previewCamera.zoom) : 'null')
			+ ' strumLineBase=(' + strumLineX + ', ' + strumLineY + ') middleScroll=' + ClientPrefs.data.middleScroll + ' downScroll=' + ClientPrefs.data.downScroll);
		if (previewStrumLine != null)
		{
			previewStrumLine.visible = true;
			previewStrumLine.x = 0;
			previewStrumLine.y = strumLineY + 36;
		}

		for (player in 0...2)
		{
			for (lane in 0...4)
			{
				var targetAlpha:Float = 1;
				if (player < 1)
				{
					if (!ClientPrefs.data.opponentStrums)
						targetAlpha = 0;
					else if (ClientPrefs.data.middleScroll)
						targetAlpha = 0.35;
				}

				var strum = new StrumNote(strumLineX, strumLineY, lane, player);
				strum.downScroll = ClientPrefs.data.downScroll;
				strum.alpha = targetAlpha;
				strum.active = true;
				strum.visible = true;
				strum.cameras = [previewCamera];
				if (player == 0 && ClientPrefs.data.middleScroll)
				{
					strum.x += 310;
					if (lane > 1)
						strum.x += FlxG.width / 2 + 25;
				}

				if (player == 1)
					previewPlayerStrums.add(strum);
				else
					previewOpponentStrums.add(strum);

				strum.playerPosition(player);
				previewStrumLineNotes.add(strum);

				var visualStrum = new StrumNote(strumLineX, strumLineY, lane, player);
				visualStrum.downScroll = strum.downScroll;
				visualStrum.alpha = targetAlpha;
				visualStrum.active = false;
				visualStrum.visible = true;
				visualStrum.cameras = [previewOverlayCamera];
				visualStrum.x = strum.x;
				visualStrum.y = strum.y;
				visualStrum.scale.set(strum.scale.x, strum.scale.y);
				visualStrum.updateHitbox();
				visualStrum.playAnim('static', true);
				previewVisualStrums.add(visualStrum);
			}
		}
		PlayState.SONG = oldSong;
	}

	function buildPreviewNotes()
	{
		ensurePreviewGroups();
		previewNotes.clear();
		previewAllNotes = [];
		previewUnspawnNotes = [];
		if (previewSongData == null || previewSongData.notes == null)
			return;

		var totalColumns:Int = 4;
		var oldSong = PlayState.SONG;
		PlayState.SONG = previewSongData;
		var previewSections:Array<Dynamic> = cast previewSongData.notes;
		var oldNote:Note = null;
		for (section in previewSections)
		{
			if (section == null || section.sectionNotes == null)
				continue;

			var sectionNotes:Array<Dynamic> = cast section.sectionNotes;
			for (songNote in sectionNotes)
			{
				if (songNote == null)
					continue;

				var spawnTime:Float = songNote[0];
				var noteColumn:Int = Std.int(songNote[1] % totalColumns);
				var holdLength:Float = songNote[2] != null ? songNote[2] : 0;
				if (Math.isNaN(holdLength))
					holdLength = 0;

				var gottaHitNote:Bool = (songNote[1] < totalColumns);
				var swagNote:Note = new Note(spawnTime, noteColumn, oldNote, false, false, {songSpeed: getPreviewScrollSpeed()});
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = holdLength;
				swagNote.active = true;
				swagNote.visible = true;
				swagNote.scrollFactor.set();
				swagNote.cameras = [previewCamera];
				previewAllNotes.push(swagNote);

				var curStepCrochet:Float = 60 / getPreviewSongBpmForTime(spawnTime) * 1000 / 4.0;
				var roundSus:Int = Math.round(swagNote.sustainLength / Conductor.stepCrochet);
				if (roundSus > 0)
				{
					for (susNote in 0...roundSus)
					{
						oldNote = previewAllNotes[Std.int(previewAllNotes.length - 1)];

						var sustainNote:Note = new Note(swagNote.strumTime + (curStepCrochet * susNote), noteColumn, oldNote, true, false, {songSpeed: getPreviewScrollSpeed()});
						sustainNote.mustPress = swagNote.mustPress;
						sustainNote.parent = swagNote;
						sustainNote.active = true;
						sustainNote.visible = true;
						sustainNote.scrollFactor.set();
						sustainNote.cameras = [previewCamera];
						previewAllNotes.push(sustainNote);
						swagNote.tail.push(sustainNote);
					}
				}

				oldNote = swagNote;
			}
		}
		PlayState.SONG = oldSong;
		previewAllNotes.sort(sortPreviewNotesByTime);
		previewUnspawnNotes = previewAllNotes.copy();
		syncPreviewSpawnedNotes(true);
	}

	function syncPreviewSpawnedNotes(?forceReset:Bool = false)
	{
		if (previewNotes == null)
			return;

		if (forceReset || Conductor.songPosition < previewLastSongPosition)
		{
			previewNotes.clear();
			previewUnspawnNotes = previewAllNotes.copy();
			for (note in previewUnspawnNotes)
			{
				if (note == null)
					continue;
				note.spawned = false;
				note.active = true;
				note.visible = true;
			}
		}

		var time:Float = 2000;
		var previewSpeed = getPreviewScrollSpeed();
		if (previewSpeed < 1)
			time /= previewSpeed;

		while (previewUnspawnNotes.length > 0 && previewUnspawnNotes[0] != null && previewUnspawnNotes[0].strumTime - Conductor.songPosition < time)
		{
			var dunceNote:Note = previewUnspawnNotes.shift();
			previewNotes.insert(0, dunceNote);
			dunceNote.spawned = true;
		}

		previewLastSongPosition = Conductor.songPosition;
	}

	static function sortPreviewNotesByTime(first:Note, second:Note):Int
	{
		if (first == null && second == null)
			return 0;
		if (first == null)
			return 1;
		if (second == null)
			return -1;
		return Std.int(first.strumTime - second.strumTime);
	}

	function ensurePreviewGroups()
	{
		if (previewNoteGroup == null)
		{
			previewNoteGroup = new FlxTypedGroup<FlxBasic>();
			add(previewNoteGroup);
		}
		previewNoteGroup.cameras = [previewCamera];
		if (previewStrumLineNotes == null)
		{
			previewStrumLineNotes = new FlxTypedGroup<StrumNote>();
			previewNoteGroup.add(previewStrumLineNotes);
		}
		if (previewOpponentStrums == null)
		{
			previewOpponentStrums = new FlxTypedGroup<StrumNote>();
		}
		if (previewPlayerStrums == null)
		{
			previewPlayerStrums = new FlxTypedGroup<StrumNote>();
		}
		if (previewVisualStrums == null)
		{
			previewVisualStrums = new FlxTypedGroup<StrumNote>();
			add(previewVisualStrums);
		}
		previewVisualStrums.cameras = [previewOverlayCamera];
		if (previewNotes == null)
		{
			previewNotes = new FlxTypedGroup<Note>();
			previewNoteGroup.add(previewNotes);
		}
		if (previewNoteSplashes == null)
		{
			previewNoteSplashes = new FlxTypedGroup<NoteSplash>();
			previewNoteGroup.add(previewNoteSplashes);
		}
	}

	function rebuildPreviewModchart()
	{
		destroyPreviewModchart();
		if (previewSongData == null || previewCamera == null)
			return;

		ensurePreviewGroups();
		ModchartEditorPreviewContext.active = {
			currentBeat: timelineBeat,
			songPosition: Conductor.songPosition,
			scrollSpeed: getPreviewScrollSpeed(),
			camera: previewCamera,
			strumLineNotes: previewStrumLineNotes,
			opponentStrums: previewOpponentStrums,
			playerStrums: previewPlayerStrums,
			notes: previewNotes,
			noteSplashes: previewNoteSplashes
		};

		var oldSong = PlayState.SONG;
		PlayState.SONG = previewSongData;
		previewManager = new Manager();
		while (previewManager.playfields.length < Std.int(playfieldCountStepper.value))
			previewManager.addPlayfield();

		for (entry in modifiers)
			previewManager.addModifier(entry.name, entry.field);

		for (entry in events)
		{
			switch (entry.type)
			{
				case 'set':
					previewManager.set(entry.target, entry.beat, entry.value, entry.player, entry.field);
				case 'ease':
					previewManager.ease(entry.target, entry.beat, entry.length, entry.value, easeFromName(entry.ease), entry.player, entry.field);
				case 'add':
					previewManager.add(entry.target, entry.beat, entry.length, entry.value, easeFromName(entry.ease), entry.player, entry.field);
				default:
			}
		}
		add(previewManager);
		if (previewStrumLine != null)
		{
			remove(previewStrumLine, false);
			add(previewStrumLine);
		}
		if (previewVisualStrums != null)
		{
			remove(previewVisualStrums, false);
			add(previewVisualStrums);
		}
		PlayState.SONG = oldSong;
		syncPreviewContextMetrics();
	}

	function destroyPreviewModchart()
	{
		if (previewManager != null)
		{
			remove(previewManager, true);
			previewManager.destroy();
			previewManager = null;
		}
		if (previewStrumLine != null)
			previewStrumLine.visible = false;
	}

	function syncPreviewContextMetrics()
	{
		if (ModchartEditorPreviewContext.active == null)
			return;

		ModchartEditorPreviewContext.active.currentBeat = timelineBeat;
		ModchartEditorPreviewContext.active.songPosition = Conductor.songPosition;
		ModchartEditorPreviewContext.active.scrollSpeed = getPreviewScrollSpeed();
	}

	function applyCapturedPlayStateContext()
	{
		if (!useCurrentPlayStateSong || capturedPlayStateContext == null)
			return;

		playfieldCountStepper.value = Math.max(1, capturedPlayStateContext.playfieldCount);
		modifiers = capturedPlayStateContext.modifiers.copy();
		events = capturedPlayStateContext.events.copy();
		timelineBeat = capturedPlayStateContext.timelineBeat;
		if (capturedPlayStateContext.projectName != null)
			projectNameInput.text = capturedPlayStateContext.projectName;
		selectedEventIndex = events.length > 0 ? 0 : 0;
		hasUnsavedChanges = false;
		capturedPlayStateContext = null;
	}

	function goToPlayState()
	{
		if (previewSongData == null)
			loadPreviewSong();
		if (previewSongData == null)
			return;

		stopPreviewPlayback();
		persistentUpdate = false;
		Cursor.hide();
		suppressPlayStateHotkey();
		PlayState.SONG = cast previewSongData;
		StageData.loadDirectory(PlayState.SONG);
		LoadingState.loadAndSwitchState(new PlayState(), false);
		ClientPrefs.toggleVolumeKeys(true);
	}

	function refreshModifierSummary()
	{
		var lines:Array<String> = ['Registered addModifier calls:'];
		for (i => entry in modifiers)
			lines.push('${i}. addModifier("${entry.name}", ${entry.field})');

		modifierSummaryText.text = lines.join('\n');
	}

	function refreshEventSummary()
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

	function refreshPreview()
	{
		var lines = generateLua().split('\n');
		var shown:Array<String> = [];
		var previewLineCount:Int = Std.int(Math.min(lines.length, 22));
		for (i in 0...previewLineCount)
			shown.push(lines[i]);

		if (lines.length > 22)
			shown.push('... (${lines.length - 22} more lines)');

		previewText.text = shown.join('\n');
	}

	function refreshStatusText()
	{
		var stateLabel = hasUnsavedChanges ? 'Unsaved changes' : 'Ready';
		var previewState = previewSongLoaded ? (previewPlaybackActive ? 'playing ' : 'loaded ') + previewSongName : 'missing ' + previewSongName;
		statusText.text = '${stateLabel} | song=${previewState} | playfields=${Std.int(playfieldCountStepper.value)} | modifiers=${modifiers.length} | events=${events.length} | timelineBeat=${fmt(timelineBeat)}';
	}

	function generateLua():String
	{
		var lines:Array<String> = [
			'-- Generated by Plus Engine Lua Modchart Editor.',
			'-- Keep callbacks, helper functions and manual gameplay logic in a separate Lua script.',
			'',
			'function onInitModchart()'
		];

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

		var sortedEvents = events.copy();
		sortedEvents.sort(function(a, b)
		{
			if (a.beat < b.beat) return -1;
			if (a.beat > b.beat) return 1;
			return 0;
		});

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

	function exportLua()
	{
		var data = generateLua();
		var fileName = sanitizeFileName(defaultString(projectNameInput.text, 'modchart-generated')) + '.lua';
		if (data.length <= 0)
			return;

		_file = new FileReference();
		_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file.save(data, fileName);
	}

	function onSaveComplete(_):Void
	{
		hasUnsavedChanges = false;
		statusText.text = 'Lua modchart exported.';
		cleanupFileReference();
	}

	function onSaveCancel(_):Void
	{
		cleanupFileReference();
	}

	function onSaveError(_):Void
	{
		statusText.text = 'Failed to save Lua modchart.';
		cleanupFileReference();
	}

	function cleanupFileReference()
	{
		if (_file == null)
			return;

		_file.removeEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function getHoveredEventIndex():Int
	{
		for (sprite in eventSprites.members)
		{
			if (sprite != null && sprite.visible && FlxG.mouse.overlaps(sprite))
				return sprite.eventIndex;
		}
		return -1;
	}

	function markUnsaved()
	{
		hasUnsavedChanges = true;
		refreshStatusText();
	}

	function makeLabel(target:FlxSprite, text:String):FlxText
	{
		var label = new FlxText(target.x, target.y - 18, 0, text, 14);
		label.setFormat(Paths.font('phantom.ttf'), 14, FlxColor.WHITE, LEFT);
		return label;
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

	inline function getTimelineActiveY():Float
	{
		return TIMELINE_Y + TIMELINE_ACTIVE_PADDING_TOP;
	}

	inline function getTimelineActiveHeight():Float
	{
		return TIMELINE_GRID_HEIGHT;
	}

	inline function getPreviewViewportY():Float
	{
		return getTimelineActiveY() + getTimelineActiveHeight() + PREVIEW_VIEWPORT_GAP;
	}

	inline function getPreviewViewportHeight():Float
	{
		return (TIMELINE_Y + TIMELINE_HEIGHT) - PREVIEW_VIEWPORT_MARGIN - getPreviewViewportY();
	}

	inline function getPreviewScrollSpeed():Float
	{
		return previewSongData != null && previewSongData.speed != null ? previewSongData.speed * 0.45 : 0.45;
	}

	function getPreviewSongBpmForTime(time:Float):Float
	{
		var bpmInfo = Conductor.getBPMFromSeconds(time);
		return bpmInfo != null ? bpmInfo.bpm : Conductor.bpm;
	}

	static function easeFromName(name:String):Dynamic
	{
		var normalized = name != null ? name.trim() : '';
		return switch (normalized)
		{
			case 'quadIn': FlxEase.quadIn;
			case 'quadOut': FlxEase.quadOut;
			case 'quadInOut': FlxEase.quadInOut;
			case 'cubeIn': FlxEase.cubeIn;
			case 'cubeOut': FlxEase.cubeOut;
			case 'cubeInOut': FlxEase.cubeInOut;
			case 'quartIn': FlxEase.quartIn;
			case 'quartOut': FlxEase.quartOut;
			case 'quartInOut': FlxEase.quartInOut;
			case 'quintIn': FlxEase.quintIn;
			case 'quintOut': FlxEase.quintOut;
			case 'quintInOut': FlxEase.quintInOut;
			case 'sineIn': FlxEase.sineIn;
			case 'sineOut': FlxEase.sineOut;
			case 'sineInOut': FlxEase.sineInOut;
			case 'backIn': FlxEase.backIn;
			case 'backOut': FlxEase.backOut;
			case 'backInOut': FlxEase.backInOut;
			case 'bounceIn': FlxEase.bounceIn;
			case 'bounceOut': FlxEase.bounceOut;
			case 'bounceInOut': FlxEase.bounceInOut;
			case 'circIn': FlxEase.circIn;
			case 'circOut': FlxEase.circOut;
			case 'circInOut': FlxEase.circInOut;
			case 'expoIn': FlxEase.expoIn;
			case 'expoOut': FlxEase.expoOut;
			case 'expoInOut': FlxEase.expoInOut;
			default: FlxEase.linear;
		};
	}

	static function getEaseName(ease:Dynamic):String
	{
		if (ease == FlxEase.quadIn) return 'quadIn';
		if (ease == FlxEase.quadOut) return 'quadOut';
		if (ease == FlxEase.quadInOut) return 'quadInOut';
		if (ease == FlxEase.cubeIn) return 'cubeIn';
		if (ease == FlxEase.cubeOut) return 'cubeOut';
		if (ease == FlxEase.cubeInOut) return 'cubeInOut';
		if (ease == FlxEase.quartIn) return 'quartIn';
		if (ease == FlxEase.quartOut) return 'quartOut';
		if (ease == FlxEase.quartInOut) return 'quartInOut';
		if (ease == FlxEase.quintIn) return 'quintIn';
		if (ease == FlxEase.quintOut) return 'quintOut';
		if (ease == FlxEase.quintInOut) return 'quintInOut';
		if (ease == FlxEase.sineIn) return 'sineIn';
		if (ease == FlxEase.sineOut) return 'sineOut';
		if (ease == FlxEase.sineInOut) return 'sineInOut';
		if (ease == FlxEase.backIn) return 'backIn';
		if (ease == FlxEase.backOut) return 'backOut';
		if (ease == FlxEase.backInOut) return 'backInOut';
		if (ease == FlxEase.bounceIn) return 'bounceIn';
		if (ease == FlxEase.bounceOut) return 'bounceOut';
		if (ease == FlxEase.bounceInOut) return 'bounceInOut';
		if (ease == FlxEase.circIn) return 'circIn';
		if (ease == FlxEase.circOut) return 'circOut';
		if (ease == FlxEase.circInOut) return 'circInOut';
		if (ease == FlxEase.expoIn) return 'expoIn';
		if (ease == FlxEase.expoOut) return 'expoOut';
		if (ease == FlxEase.expoInOut) return 'expoInOut';
		return 'linear';
	}

	override function destroy()
	{
		destroyPreviewModchart();
		ModchartEditorPreviewContext.active = null;
		if (previewOverlayCamera != null)
		{
			FlxG.cameras.remove(previewOverlayCamera, true);
			previewOverlayCamera = null;
		}
		if (previewCamera != null)
		{
			FlxG.cameras.remove(previewCamera, true);
			previewCamera = null;
		}
		if (previewStrumLine != null)
		{
			remove(previewStrumLine, true);
			previewStrumLine.destroy();
			previewStrumLine = null;
		}
		if (previewNoteGroup != null)
		{
			remove(previewNoteGroup, true);
			previewNoteGroup.destroy();
			previewNoteGroup = null;
		}
		if (previewVisualStrums != null)
		{
			remove(previewVisualStrums, true);
			previewVisualStrums.destroy();
			previewVisualStrums = null;
		}
		if (previewInst != null)
		{
			previewInst.stop();
			previewInst.destroy();
			previewInst = null;
		}
		cleanupFileReference();
		super.destroy();
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
