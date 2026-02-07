package;

import funkin.ui.debug.FPSCounter;
import funkin.ui.debug.TraceDisplay;
import funkin.ui.debug.TraceButton;
import funkin.ui.debug.DebugButton;
import funkin.Preferences as ClientPrefs;
import funkin.util.Screenshot;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Lib;
import openfl.display.Sprite;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.StageScaleMode;
import lime.app.Application;
import funkin.ui.title.TitleState;
import funkin.InitState;
#if HSCRIPT_ALLOWED
import crowplexus.iris.Iris;
import funkin.modding.scripting.HScript.HScriptInfos;
#end
import openfl.events.KeyboardEvent;

#if (linux || mac)
import lime.graphics.Image;
#end
#if COPYSTATE_ALLOWED
import funkin.mobile.backend.CopyState;
#end
import funkin.save.Highscore;
import lime.system.System as LimeSystem;

import lenin.slushithings.windows.WindowsAPI;

// NATIVE API STUFF, YOU CAN IGNORE THIS AND SCROLL //
#if (linux && !debug)
@:cppInclude('./funkin/external/linux/gamemode_client.h')
@:cppFileCode('#define GAMEMODE_AUTO')
#end

// // // // // // // // //
class Main extends Sprite
{
	public static final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var fpsVar:FPSCounter;
	public static var traceDisplay:TraceDisplay;
	public static var traceButton:TraceButton;
	public static var debugButton:DebugButton;

	public static final platform:String = #if mobile "Phones" #else "PCs" #end;
	public static var watermarkSprite:Sprite = null;
	public static var watermark:Bitmap = null;

	// Window focus management
	public static var focused:Bool = true;
	var oldVol:Float = 1.0;
	var newVol:Float = 0.2;
	public static var focusMusicTween:FlxTween;

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		#if cpp
		cpp.NativeGc.enable(true);
		#elseif hl
		hl.Gc.enable(true);
		#end
	}

	public function new()
	{
		super();
		#if mobile
		#if android
		ClientPrefs.loadStorageTypeEarly();
		StorageUtil.requestPermissions();
		trace('[Main] Current storage type: ' + ClientPrefs.data.storageType);
		trace('[Main] Storage directory: ' + StorageUtil.getStorageDirectory());
		#end
		Sys.setCwd(StorageUtil.getStorageDirectory());
		#end
		funkin.util.CrashHandler.init();
		
		// Initialize optimization systems EARLY
		trace('Initializing optimization systems...');
		
		#if !macro
		// Initialize ThreadUtil
		#if (target.threaded && sys)
		funkin.util.ThreadUtil.init();
		#end
		
		// Initialize Paths with temp cache
		funkin.Paths.init();
		
		// Initialize FunkinMemory - NEW CACHE SYSTEM
		funkin.FunkinMemory.init();
		
		// Initialize MemoryManager
		funkin.util.MemoryManager.init();
		#end

		#if (cpp && windows)
		funkin.util.Native.fixScaling();
		// Initialize window transparency support
		WindowsAPI.setWindowLayered();
		// Set window border color to purple (128, 41, 182)
		WindowsAPI.setWindowBorderColor(128, 41, 182);
		#end

		#if VIDEOS_ALLOWED
		hxvlc.util.Handle.init(#if (hxvlc >= "1.8.0")  ['--no-lua'] #end);
		#end

		#if LUA_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();
		
		// Initialize GlobalScript
		#if HSCRIPT_ALLOWED
		funkin.modding.ModState.initGlobalScript();
		#end

		#if HSCRIPT_ALLOWED
		Iris.warn = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(WARN, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('WARNING: $msgInfo', FlxColor.YELLOW);
		}
		Iris.error = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(ERROR, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('ERROR: $msgInfo', FlxColor.RED);
		}
		Iris.fatal = function(x, ?pos:haxe.PosInfos) {
			Iris.logLevel(FATAL, x, pos);
			var newPos:HScriptInfos = cast pos;
			if (newPos.showLine == null) newPos.showLine = true;
			var msgInfo:String = (newPos.funcName != null ? '(${newPos.funcName}) - ' : '')  + '${newPos.fileName}:';
			#if LUA_ALLOWED
			if (newPos.isLua == true) {
				msgInfo += 'HScript:';
				newPos.showLine = false;
			}
			#end
			if (newPos.showLine == true) {
				msgInfo += '${newPos.lineNumber}:';
			}
			msgInfo += ' $x';
			if (PlayState.instance != null)
				PlayState.instance.addTextToDebug('FATAL: $msgInfo', 0xFFBB0000);
		}
		#end

		#if LUA_ALLOWED Lua.set_callbacks_function(cpp.Callable.fromStaticFunction(funkin.modding.scripting.psychlua.CallbackHandler.call)); #end
		Controls.instance = new Controls();
		ClientPrefs.loadDefaultKeys();
		#if ACHIEVEMENTS_ALLOWED Achievements.load(); #end
		MobileData.init();
		
		// Initialize Android optimizer for automatic quality adjustments
		#if android
		funkin.mobile.AndroidOptimizer.init();
		#end

		#if mobile
		FlxG.signals.postGameStart.addOnce(() -> {
			FlxG.scaleMode = new funkin.mobile.backend.MobileScaleMode();
		});
		#end
		
		// Determine initial state. InitialState will load mods and redirect accordingly.
		var initialState:Class<FlxState> = InitialState;
		#if COPYSTATE_ALLOWED
		if (!CopyState.checkExistingFiles()) {
			initialState = CopyState;
		} else {
			trace('[Main] All files exist, skipping CopyState');
		}
		#else
		// Preloader removed: always start at InitialState
		#end
		
		addChild(new FlxGame(game.width, game.height, initialState, game.framerate, game.framerate, game.skipSplash, game.startFullscreen));
		FlxG.save.bind('funkin', CoolUtil.getSavePath());
		ClientPrefs.loadPrefs();
		fpsVar = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsVar);
		
		traceDisplay = new TraceDisplay(10, 100, 0xFFFFFF);
		addChild(traceDisplay);
	
		// Initialize touch pointer visualization for mobile
		#if mobile

		// Add TraceDisplay and Debug and buttons for mobile.
		traceButton = new TraceButton();
		addChild(traceButton);
		debugButton = new DebugButton();
		addChild(debugButton);
		#end
		
		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		   if(fpsVar != null) {
			   // Position relative to FlxGame (accounts for letterboxing on Android)
			   var marginX = 10;
			   var marginY = 3;
			   #if android
			   fpsVar.positionFPS(FlxG.game.x + marginX, FlxG.game.y + marginY, 1.0);
			   #else
			   fpsVar.positionFPS(marginX, marginY, 1.0);
			   #end
		   }

		#if (linux || mac) // fix the app icon not showing up on the Linux Panel / Mac Dock
		var icon = Image.fromFile("icon.png");
		Lib.current.stage.window.setIcon(icon);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		FlxG.fixedTimestep = false;
		FlxG.game.focusLostFramerate = #if mobile 30 #else 60 #end;
		#if web
		FlxG.keys.preventDefaultKeys.push(TAB);
		#else
		FlxG.keys.preventDefaultKeys = [TAB];
		#end

		#if DISCORD_ALLOWED
		DiscordClient.prepare();
		#end
		
		#if desktop 
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, toggleFullScreen);
		Screenshot.init(); // Initialize screenshot folder
		#end

		#if mobile
		#if android FlxG.android.preventDefaultKeys = [BACK]; #end
		LimeSystem.allowScreenTimeout = ClientPrefs.data.screensaver;
		#end

		#if (cpp && windows)
		// Add window close handler for fade out effect
		Application.current.window.onClose.add(onWindowClose);
		// Add window focus handlers
		Application.current.window.onFocusIn.add(onWindowFocusIn);
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		#end

		// shader coords fix
		var resizeDebounceTimer:FlxTimer = null;
		function handleGameResized():Void {
			// Reposition the FPS counter relative to FlxGame (accounts for letterboxing)
			if(fpsVar != null) {
				var marginX = 10;
				var marginY = 3;
				#if android
				fpsVar.positionFPS(FlxG.game.x + marginX, FlxG.game.y + marginY, 1.0);
				#else
				fpsVar.positionFPS(marginX, marginY, 1.0);
				#end
			}
			
			// Reposition TraceDisplay button.
			#if mobile
			if(traceButton != null) {
				traceButton.updatePosition();
			}
			if(debugButton != null) {
				debugButton.updatePosition();
			}
			#end
			
			// Only reposition the watermark, no scaling.
			positionWatermark();
			
		     if (FlxG.cameras != null) {
			   for (cam in FlxG.cameras.list) {
				if (cam != null && cam.filters != null)
					resetSpriteCache(cam.flashSprite);
			   }
			}

			if (FlxG.game != null)
			resetSpriteCache(FlxG.game);
		}

		FlxG.signals.gameResized.add(function (w, h) {
			if(resizeDebounceTimer == null) {
				resizeDebounceTimer = new FlxTimer();
			}
			// Debounce window scripts so we only run heavy work once the resize settles.
			resizeDebounceTimer.start(0.05, function(_) {
				handleGameResized();
			});
		});

		setupGame();
	}

	static function resetSpriteCache(sprite:Sprite):Void {
		@:privateAccess {
		        sprite.__cacheBitmap = null;
			sprite.__cacheBitmapData = null;
		}
	}

	function toggleFullScreen(event:KeyboardEvent) {
		if (Controls.instance.justReleased('fullscreen'))
			funkin.util.WindowMode.toggleFullscreen();
	}

	function positionWatermark():Void {
		if (watermarkSprite != null && watermark != null) {
			var marginX = 10;
			var marginY = 10;
			var stageW = openfl.Lib.current.stage.stageWidth;
			watermarkSprite.x = stageW - watermark.width * Math.abs(watermark.scaleX) - marginX;
			watermarkSprite.y = marginY;
		}
		if (watermark != null && watermark.parent == this) {
			var stageW = Lib.current.stage.stageWidth;
			var stageH = Lib.current.stage.stageHeight;
			watermark.x = stageW - watermark.width * Math.abs(watermark.scaleX) + 110;
			watermark.y = stageH - watermark.height * Math.abs(watermark.scaleY) - 30;
		}
	}

	#if (cpp && windows)
	function onWindowClose():Void
	{
		lenin.slushithings.windows.WindowsAPI.fadeOutAndExit();
	}

	function onWindowFocusOut():Void
	{
		focused = false;

		oldVol = FlxG.sound.volume;
		if (oldVol > 0.3)
		{
			newVol = 0.3;
		}
		else
		{
			if (oldVol > 0.1)
			{
				newVol = 0.1;
			}
			else
			{
				newVol = 0;
			}
		}

		if (focusMusicTween != null) focusMusicTween.cancel();
		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);
	}

	function onWindowFocusIn():Void
	{
		new FlxTimer().start(0.2, function(tmr:FlxTimer) {
			focused = true;
		});

		// Normal global volume when focused
		if (focusMusicTween != null) focusMusicTween.cancel();

		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);
	}
	#end

	private function setupGame():Void
	{
		funkin.graphics.shaders.ShaderCompatibility.init();
		
		trace('\n\n' + funkin.util.Native.buildSystemInfo());
		
		#if hxvlc
		try {
			hxvlc.util.Handle.init();
			trace('hxvlc initialized successfully');
		} catch(e:Dynamic) {
			trace('hxvlc initialization failed: $e');
		}
		#end
		
		var flxGraphic = funkin.Paths.image("marca");
		if (flxGraphic != null) {
			var bmpData:openfl.display.BitmapData = flxGraphic.bitmap;
			if (watermarkSprite != null && watermarkSprite.parent != null) {
				watermarkSprite.parent.removeChild(watermarkSprite);
			}
			watermark = new openfl.display.Bitmap(bmpData);
			watermark.smoothing = true;
			watermarkSprite = new openfl.display.Sprite();
			watermarkSprite.addChild(watermark);
			var scale:Float = 0.85;
			watermark.scaleX = scale;
			watermark.scaleY = scale;
			positionWatermark();
			watermarkSprite.alpha = 0.5;
			watermarkSprite.visible = ClientPrefs.data.showWatermark;
			openfl.Lib.current.stage.addChild(watermarkSprite);
		} else {
			trace('No se pudo cargar la marca de agua con funkin.Paths.image("marca").');
		}

		var imagePath = funkin.Paths.getPath('images/marca.png', IMAGE);
		if (sys.FileSystem.exists(imagePath)) {
		    if (watermark != null && watermark.parent != null)
		        removeChild(watermark);
			var bmpData = openfl.display.BitmapData.fromFile(imagePath);
			watermark = new openfl.display.Bitmap(bmpData);
			var scale = 0.85;
			watermark.scaleX = -scale;
			watermark.scaleY = scale;
			watermark.alpha = 0.5;
			addChild(watermark);
			positionWatermark();
			Lib.current.stage.addEventListener(openfl.events.Event.RESIZE, function(_) positionWatermark());
		}
		if (watermark != null) {
		    watermark.visible = ClientPrefs.data.showWatermark;
		}
	}
}
