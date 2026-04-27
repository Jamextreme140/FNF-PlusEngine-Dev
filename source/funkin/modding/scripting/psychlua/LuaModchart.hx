package funkin.modding.scripting.psychlua;

import funkin.modding.modchart.Manager;
import funkin.modding.modchart.backend.core.ArrowData;
import funkin.modding.modchart.backend.standalone.Adapter;
import funkin.modding.modchart.engine.modifiers.list.PathModifier;
import funkin.modding.modchart.engine.modifiers.list.PathModifier.PathNode;
import funkin.modding.scripting.FunkinLua;
import funkin.data.song.Song;
import funkin.input.Controls;
import flixel.tweens.FlxEase;
import flixel.input.keyboard.FlxKey;

using StringTools;

class LuaModchart
{
    static final __luaArrowPoint:FlxPoint = FlxPoint.get();
    static final __luaArrowData:ArrowData = {
        hitTime: 0,
        distance: 0,
        sourceTime: 0,
        lane: 0,
        player: 0,
        isTapArrow: false,
        straightHolds: false
    };

    public static function getRenderedStrumPosition(strum:FlxSprite, ?field:Int = -1):Null<FlxPoint> {
        if (strum == null || Manager.instance == null || Adapter.instance == null)
            return null;

        final playfields = Manager.instance.playfields;
        if (playfields == null || playfields.length == 0)
            return null;

        final player = Adapter.instance.getPlayerFromArrow(strum);
        var targetField = field;
        if (targetField < 0)
            targetField = playfields.length > 1 ? Std.int(Math.min(player, playfields.length - 1)) : 0;

        if (targetField < 0 || targetField >= playfields.length)
            return null;

        final playfield = playfields[targetField];
        if (playfield == null)
            return null;

        final lane = Adapter.instance.getLaneFromArrow(strum);
        final songPos = Adapter.instance.getSongPosition();
        var arrowTime = Adapter.instance.getTimeFromArrow(strum);
        var arrowDiff = arrowTime - songPos;
        final centered2 = playfield.getPercent('centered2', player);
        final isTapArrow = Adapter.instance.isTapNote(strum);

        if (isTapArrow) {
            arrowDiff += FlxG.height * 0.25 * centered2;
        } else {
            arrowTime = songPos + (FlxG.height * 0.25 * centered2);
            arrowDiff = arrowTime - songPos;
        }

        __luaArrowData.hitTime = arrowTime;
        __luaArrowData.distance = arrowDiff;
        __luaArrowData.sourceTime = Adapter.instance.getTimeFromArrow(strum);
        __luaArrowData.lane = lane;
        __luaArrowData.player = player;
        __luaArrowData.hitten = Adapter.instance.arrowHit(strum);
        __luaArrowData.isTapArrow = isTapArrow;

        final arrowPosition = new openfl.geom.Vector3D(
            Adapter.instance.getDefaultReceptorX(lane, player) + Manager.ARROW_SIZEDIV2,
            Adapter.instance.getDefaultReceptorY(lane, player) + Manager.ARROW_SIZEDIV2,
            0
        );
        final output = playfield.modifiers.getPath(arrowPosition, __luaArrowData);

        __luaArrowPoint.set(output.pos.x - Manager.ARROW_SIZEDIV2, output.pos.y - Manager.ARROW_SIZEDIV2);
        return __luaArrowPoint;
    }

    public static function implement(funk:FunkinLua) {
        var lua:State = funk.lua;
        
        // Add modifier
        Lua_helper.add_callback(lua, "addModifier", function(name:String, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.addModifier(name, field);
        });
        
        // Set modifier percent
        Lua_helper.add_callback(lua, "setPercent", function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.setPercent(name, value, player, field);
        });
        
        // Get modifier percent
        Lua_helper.add_callback(lua, "getPercent", function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
            if (Manager.instance != null)
                return Manager.instance.getPercent(name, player, field);
            return 0.0;
        });
        
        // Set modifier raw value
        Lua_helper.add_callback(lua, "setRawValue", function(name:String, value:Float, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance != null)
                Manager.instance.setRawValue(name, value, player, field);
        });
        
        // Get modifier raw value
        Lua_helper.add_callback(lua, "getRawValue", function(name:String, ?player:Int = 0, ?field:Int = 0):Float {
            if (Manager.instance != null)
                return Manager.instance.getRawValue(name, player, field);
            return 0.0;
        });
        
        // Set a value at a specific beat
        Lua_helper.add_callback(lua, "set", function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: set('modname', beat, value, player, field)
                Manager.instance.set(cast nameOrMods, beat, cast value, player, field);
            } else {
                // Multiple mods: set({mod1=100, mod2=50}, beat, player, field)
                // In this case: value becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Int = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.set(modName, beat, modValue, actualPlayer, actualField);
                }
            }
        });
        
        // Ease a modifier
        Lua_helper.add_callback(lua, "ease", function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: ease('modname', beat, length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.ease(cast nameOrMods, beat, length, cast value, easeFunc, player, field);
            } else {
                // Multiple mods: ease({mod1=100, mod2=50}, beat, length, ease, player, field)
                // In this case: value becomes easeName, easeName becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Int = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.ease(modName, beat, length, modValue, easeFunc, actualPlayer, actualField);
                }
            }
        });
        
        // Add with easing
        Lua_helper.add_callback(lua, "add", function(nameOrMods:Dynamic, beat:Float, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: add('modname', beat, length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.add(cast nameOrMods, beat, length, cast value, easeFunc, player, field);
            } else {
                // Multiple mods: add({mod1=100, mod2=50}, beat, length, ease, player, field)
                // In this case: value becomes easeName, easeName becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Int = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.add(modName, beat, length, modValue, easeFunc, actualPlayer, actualField);
                }
            }
        });
        
        // SetAdd helper
        Lua_helper.add_callback(lua, "setAdd", function(nameOrMods:Dynamic, beat:Float, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: setAdd('modname', beat, value, player, field)
                Manager.instance.setAdd(cast nameOrMods, beat, cast value, player, field);
            } else {
                // Multiple mods: setAdd({mod1=100, mod2=50}, beat, player, field)
                // In this case: value becomes player, player becomes field
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Int = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.setAdd(modName, beat, modValue, actualPlayer, actualField);
                }
            }
        });
        
        // Add new playfield
        Lua_helper.add_callback(lua, "addPlayfield", function() {
            if (Manager.instance != null)
                Manager.instance.addPlayfield();
        });
        
        // Create alias for a modifier
        Lua_helper.add_callback(lua, "alias", function(name:String, aliasName:String, field:Int) {
            if (Manager.instance != null)
                Manager.instance.alias(name, aliasName, field);
        });
        
        // Useful constants
        Lua_helper.add_callback(lua, "getHoldSize", function():Float {
            return Manager.HOLD_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getHoldSizeDiv2", function():Float {
            return Manager.HOLD_SIZEDIV2;
        });
        
        Lua_helper.add_callback(lua, "getArrowSize", function():Float {
            return Manager.ARROW_SIZE;
        });
        
        Lua_helper.add_callback(lua, "getArrowSizeDiv2", function():Float {
            return Manager.ARROW_SIZEDIV2;
        });
        
        // Callback event: execute a function on a specific beat
        Lua_helper.add_callback(lua, "callback", function(beat:Float, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.callback(beat, function(event) {
                    funk.call(funcName, []); // Do not pass the event object to Lua
                }, field);
            }
        });
        
        // Schedule a callback to run once on a specific beat (alias for callback)
        Lua_helper.add_callback(lua, "scheduleCallback", function(beat:Float, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.scheduleCallback(beat, function(event) {
                    funk.call(funcName, []); // Do not pass the event object to Lua
                }, field);
            }
        });
        
        // Repeater event: execute a function repeatedly for a duration
        Lua_helper.add_callback(lua, "repeater", function(beat:Float, length:Float, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.repeater(beat, length, function(event) {
                    funk.call(funcName, []); // Do not pass the event object to Lua
                }, field);
            }
        });
        
        // Add scripted (custom) modifier
        Lua_helper.add_callback(lua, "addScriptedModifier", function(name:String, modifierInstance:Dynamic, ?field:Int = -1) {
            if (Manager.instance != null && modifierInstance != null) {
                // `modifierInstance` must be an instance of `Modifier` created via Lua/HScript
                Manager.instance.addScriptedModifier(name, modifierInstance, field);
            }
        });
        
        // Create a node: bind inputs and outputs through a function
        Lua_helper.add_callback(lua, "node", function(inputs:Array<String>, outputs:Array<String>, funcName:String, ?field:Int = -1) {
            if (Manager.instance != null) {
                Manager.instance.node(inputs, outputs, function(curInput:Array<Float>, curOutput:Int):Array<Float> {
                    // Call the Lua function with the input values
                    var result:Dynamic = funk.call(funcName, [curInput]);
                    // Return result as an array of floats, or an array with `curOutput` if missing
                    if (result != null && Std.isOfType(result, Array)) {
                        return cast result;
                    }
                    return [curOutput]; // Default to an array containing `curOutput`
                }, field);
            }
        });

		// PathModifier helpers (works for any modifier that extends PathModifier, e.g. arrowshape, luapath)
		Lua_helper.add_callback(lua, "setModifierPath", function(modName:String, nodes:Array<Dynamic>, ?field:Int = 0, ?lane:Int = -1) {
			if (Manager.instance == null)
				return;
			final pf = Manager.instance.playfields[field];
			if (pf == null) {
				PlayState.instance.addTextToDebug('setModifierPath: invalid playfield index: ' + field, 0xFFFF0000);
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null) {
				PlayState.instance.addTextToDebug('setModifierPath: modifier not found: ' + modName, 0xFFFF0000);
				return;
			}
			if (!Std.isOfType(mod, PathModifier)) {
				PlayState.instance.addTextToDebug('setModifierPath: modifier is not a PathModifier: ' + modName, 0xFFFF0000);
				return;
			}

			final parsed = parsePathNodes(nodes);
			if (lane >= 0) {
				// Set path for specific lane
				cast(mod, PathModifier).loadPathForLane(parsed, lane);
			} else {
				// Set global path (affects all lanes without specific paths)
				cast(mod, PathModifier).loadPath(parsed);
			}
		});

		Lua_helper.add_callback(lua, "setModifierPathOffset", function(modName:String, x:Float, y:Float, ?z:Float = 0, ?field:Int = 0) {
			if (Manager.instance == null)
				return;
			final pf = Manager.instance.playfields[field];
	 		if (pf == null) {
				PlayState.instance.addTextToDebug('setModifierPathOffset: invalid playfield index: ' + field, 0xFFFF0000);
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier)) {
				PlayState.instance.addTextToDebug('setModifierPathOffset: PathModifier not found: ' + modName, 0xFFFF0000);
				return;
			}

			cast(mod, PathModifier).pathOffset.setTo(x, y, z);
		});

		Lua_helper.add_callback(lua, "setModifierPathBound", function(modName:String, bound:Float, ?field:Int = 0) {
			if (Manager.instance == null)
				return;
			final pf = Manager.instance.playfields[field];
			if (pf == null) {
				PlayState.instance.addTextToDebug('setModifierPathBound: invalid playfield index: ' + field, 0xFFFF0000);
				return;
			}

			final mod = pf.modifiers.modifiers.get(modName.toLowerCase());
			if (mod == null || !Std.isOfType(mod, PathModifier)) {
				PlayState.instance.addTextToDebug('setModifierPathBound: PathModifier not found: ' + modName, 0xFFFF0000);
				return;
			}

			cast(mod, PathModifier).setPathBound(bound);
		});

        Lua_helper.add_callback(lua, "changeControls", function(bindings:Dynamic) {
            if (PlayState.instance == null || Controls.instance == null || bindings == null)
                return;

            for (fieldName in Reflect.fields(bindings)) {
                final controlName = normalizeGameplayControlName(fieldName);
                if (controlName == null) {
                    PlayState.instance.addTextToDebug('changeControls: invalid control "' + fieldName + '"', 0xFFFF0000);
                    continue;
                }

                final parsedKeys = parseLuaKeyList(Reflect.field(bindings, fieldName), fieldName);
                if (parsedKeys == null)
                    continue;

                if (parsedKeys.length <= 0)
                    Controls.instance.clearTemporaryKeyboardBind(controlName);
                else
                    Controls.instance.setTemporaryKeyboardBind(controlName, parsedKeys);
            }
        });

        Lua_helper.add_callback(lua, "restoreControls", function() {
            if (Controls.instance != null)
                Controls.instance.clearTemporaryGameplayBinds();
        });

        Lua_helper.add_callback(lua, "getGameplayControls", function():Dynamic {
            final result:Dynamic = {};
            if (Controls.instance == null)
                return result;

            for (controlName in Controls.GAMEPLAY_KEY_NAMES) {
                final keys = Controls.instance.getKeyboardBind(controlName);
                final keyNames:Array<String> = [];
                if (keys != null)
                    for (key in keys)
                        keyNames.push(Std.string(key));
                Reflect.setField(result, controlName, keyNames);
            }

            return result;
        });
        
        // ===== "NOW" VARIANTS FOR USE IN CALLBACKS =====
        // These functions automatically calculate the current beat,
        // allowing you to use modcharts from onBeatHit/onStepHit/onUpdatePost
        
        // Set modifier percent immediately (current beat)
        Lua_helper.add_callback(lua, "setNow", function(nameOrMods:Dynamic, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: setNow('modname', value, player, field)
                Manager.instance.set(cast nameOrMods, currentBeat, cast value, player, field);
            } else {
                // Multiple mods: setNow({mod1=100, mod2=50}, player, field)
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Int = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.set(modName, currentBeat, modValue, actualPlayer, actualField);
                }
            }
        });
        
        // Ease modifier from current beat
        Lua_helper.add_callback(lua, "easeNow", function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: easeNow('modname', length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.ease(cast nameOrMods, currentBeat, length, cast value, easeFunc, player, field);
            } else {
                // Multiple mods: easeNow({mod1=100, mod2=50}, length, ease, player, field)
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Int = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.ease(modName, currentBeat, length, modValue, easeFunc, actualPlayer, actualField);
                }
            }
        });
        
        // Add modifier with easing from current beat
        Lua_helper.add_callback(lua, "addNow", function(nameOrMods:Dynamic, length:Float, ?value:Dynamic, ?easeName:String, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: addNow('modname', length, value, ease, player, field)
                var easeFunc = getEaseFunction(easeName);
                Manager.instance.add(cast nameOrMods, currentBeat, length, cast value, easeFunc, player, field);
            } else {
                // Multiple mods: addNow({mod1=100, mod2=50}, length, ease, player, field)
                final mods:Dynamic = nameOrMods;
                final actualEaseName:String = cast value;
                final actualPlayer:Int = easeName != null ? Std.parseInt(easeName) : -1;
                final actualField:Int = player != null ? player : -1;
                
                var easeFunc = getEaseFunction(actualEaseName);
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.add(modName, currentBeat, length, modValue, easeFunc, actualPlayer, actualField);
                }
            }
        });
        
        // SetAdd helper from current beat
        Lua_helper.add_callback(lua, "setAddNow", function(nameOrMods:Dynamic, ?value:Dynamic, ?player:Int = -1, ?field:Int = -1) {
            if (Manager.instance == null)
                return;
            
            var currentBeat:Float = Conductor.songPosition / Conductor.crochet;
            
            // Check if first parameter is a table of mods
            if (Std.isOfType(nameOrMods, String)) {
                // Single mod: setAddNow('modname', value, player, field)
                Manager.instance.setAdd(cast nameOrMods, currentBeat, cast value, player, field);
            } else {
                // Multiple mods: setAddNow({mod1=100, mod2=50}, player, field)
                final mods:Dynamic = nameOrMods;
                final actualPlayer:Int = value != null ? cast value : -1;
                final actualField:Int = player != null ? player : -1;
                
                for (modName in Reflect.fields(mods)) {
                    final modValue:Float = Reflect.field(mods, modName);
                    Manager.instance.setAdd(modName, currentBeat, modValue, actualPlayer, actualField);
                }
            }
        });
        
        // Inspired by Troll Engine's forNoteInChart =P
        Lua_helper.add_callback(lua, "getChartNotes", function(chartName:String, ?songName:String):Dynamic {
            if (songName == null || songName.length == 0)
                songName = Song.loadedSongName;

            trace('Looking for chart="$chartName" song="$songName"');

            var swagSong = Song.getChart(chartName, songName);
            if (swagSong == null) {
                PlayState.instance.addTextToDebug('ERROR: chart "$chartName" not found in song "$songName"', 0xFFFF0000);
                return null;
            }

            trace('Chart found, sections=${swagSong.notes != null ? swagSong.notes.length : 0}');

            // Build a 1-indexed Lua-compatible array of note tables
            var result:Array<Dynamic> = [];
            if (swagSong.notes != null) {
                for (section in swagSong.notes) {
                    if (section == null || section.sectionNotes == null) continue;
                    for (noteData in section.sectionNotes) {
                        // noteData[0]=time(ms), noteData[1]=column/direction, noteData[2]=hold length
                        var time:Float = noteData[0];
                        var rawCol:Int = Std.int(noteData[1]);
                        var type:Int   = rawCol % 4;
                        var step:Float = Conductor.getStep(time);
                        result.push({
                            step: step,
                            type: type,
                            time: time
                        });
                    }
                }
            }

            // Sort ascending by step so the caller can just iterate in order
            result.sort(function(a, b) return a.step < b.step ? -1 : (a.step > b.step ? 1 : 0));

            trace('"$chartName" total notes=${result.length}'
                + (result.length > 0 ? ' | first: step=${result[0].step} type=${result[0].type} time=${result[0].time}ms' : ''));

            return result;
        });

        // Get current beat from Conductor
        Lua_helper.add_callback(lua, "getCurrentBeat", function():Float {
            return Conductor.songPosition / Conductor.crochet;
        });
        
        // Get current step from Conductor
        Lua_helper.add_callback(lua, "getCurrentStep", function():Float {
            return Conductor.songPosition / Conductor.stepCrochet;
        });
        
        // Get song position in milliseconds
        Lua_helper.add_callback(lua, "getSongPosition", function():Float {
            return Conductor.songPosition;
        });
        
        // Get current BPM
        Lua_helper.add_callback(lua, "getBPM", function():Float {
            return Conductor.bpm;
        });
        
        // Get player/playfield count
        Lua_helper.add_callback(lua, "getPlayerCount", function():Int {
            return Adapter.instance.getPlayerCount();
        });
        
        // Set hold subdivisions
        Lua_helper.add_callback(lua, "setHoldSubdivisions", function(value:Int) {
            if (Adapter.instance != null && Std.isOfType(Adapter.instance, funkin.modding.modchart.backend.standalone.adapters.psych.Psych)) {
                cast(Adapter.instance, funkin.modding.modchart.backend.standalone.adapters.psych.Psych).setHoldSubdivisions(value);
            }
        });
        
        // Get hold subdivisions
        Lua_helper.add_callback(lua, "getHoldSubdivisions", function():Int {
            if (Adapter.instance != null) {
                return Adapter.instance.getHoldSubdivisions(null);
            }
            return 0;
        });
    }
    
    // Helper: convert easing name to function
    private static function getEaseFunction(easeName:String) {
        return LuaUtils.getTweenEaseByString(easeName);
    }

    private static inline function toFloat(value:Dynamic, defaultValue:Float = 0):Float {
        if (value == null)
            return defaultValue;
        if (Std.isOfType(value, Float) || Std.isOfType(value, Int))
            return value;
        final f = Std.parseFloat(Std.string(value));
        return Math.isNaN(f) ? defaultValue : f;
    }

    private static function normalizeGameplayControlName(value:String):Null<String> {
        if (value == null)
            return null;

        switch (value.toLowerCase()) {
            case 'left', 'noteleft', 'note_left':
                return 'note_left';
            case 'down', 'notedown', 'note_down':
                return 'note_down';
            case 'up', 'noteup', 'note_up':
                return 'note_up';
            case 'right', 'noteright', 'note_right':
                return 'note_right';
            default:
                return null;
        }
    }

    private static function parseLuaKeyList(rawValue:Dynamic, fieldName:String):Null<Array<FlxKey>> {
        if (rawValue == null)
            return [];

        final values:Array<Dynamic> = Std.isOfType(rawValue, Array) ? cast rawValue : [rawValue];
        final parsed:Array<FlxKey> = [];

        for (value in values) {
            if (value == null)
                continue;

            final text = Std.string(value).trim();
            if (text.length <= 0)
                continue;

            final key = FlxKey.fromString(text.toUpperCase());
            if (key == NONE) {
                if (PlayState.instance != null)
                    PlayState.instance.addTextToDebug('changeControls: invalid key "' + text + '" for ' + fieldName, 0xFFFF0000);
                return null;
            }

            if (!parsed.contains(key))
                parsed.push(key);
        }

        return parsed;
    }

    private static function parsePathNodes(nodes:Array<Dynamic>):Array<PathNode> {
        final out:Array<PathNode> = [];
        if (nodes == null)
            return out;

        for (node in nodes) {
            if (node == null)
                continue;

            var x = 0.0;
            var y = 0.0;
            var z = 0.0;

            if (Std.isOfType(node, Array)) {
                final arr:Array<Dynamic> = cast node;
                // Try both 0-based and 1-based indexing (Lua tables can vary depending on bridge)
                x = toFloat(arr.length > 0 ? arr[0] : null, 0);
                y = toFloat(arr.length > 1 ? arr[1] : null, 0);
                z = toFloat(arr.length > 2 ? arr[2] : null, 0);
                if (x == 0 && y == 0 && z == 0 && arr.length >= 4) {
                    x = toFloat(arr[1], 0);
                    y = toFloat(arr[2], 0);
                    z = toFloat(arr[3], 0);
                }
            } else {
                x = toFloat(Reflect.field(node, 'x'), 0);
                y = toFloat(Reflect.field(node, 'y'), 0);
                z = toFloat(Reflect.field(node, 'z'), 0);
            }

            out.push({x: x, y: y, z: z});
        }
        return out;
    }
}