package funkin.modding.scripting.psychlua;

#if WINDOWS_FUNCTIONS_ALLOWED
import funkin.modding.scripting.psychlua.WindowTweens;
#end

class WindowsFunctions
{
	public static function implement(funk:FunkinLua) {
		#if WINDOWS_FUNCTIONS_ALLOWED
		var lua = funk.lua;
		
		// Window Tween Functions
		Lua_helper.add_callback(lua, "winTweenSize", function(width:Int, height:Int, duration:Float = 1, ease:String = "linear") {
			return WindowTweens.winTweenSize(width, height, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "winTweenX", function(tag:String, targetX:Int, duration:Float = 1, ease:String = "linear") {
			return WindowTweens.winTweenX(tag, targetX, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "winTweenY", function(tag:String, targetY:Int, duration:Float = 1, ease:String = "linear") {
			return WindowTweens.winTweenY(tag, targetY, duration, ease);
		});

		// Window Position Functions (Immediate)
		Lua_helper.add_callback(lua, "setWindowX", function(x:Int) {
			WindowTweens.setWindowX(x);
		});
		
		Lua_helper.add_callback(lua, "setWindowY", function(y:Int) {
			WindowTweens.setWindowY(y);
		});
		
		Lua_helper.add_callback(lua, "setWindowSize", function(width:Int, height:Int) {
			WindowTweens.setWindowSize(width, height);
		});
		
		// Window Information Functions
		Lua_helper.add_callback(lua, "getWindowX", function() {
			return WindowTweens.getWindowX();
		});
		
		Lua_helper.add_callback(lua, "getWindowY", function() {
			return WindowTweens.getWindowY();
		});
		
		Lua_helper.add_callback(lua, "getWindowWidth", function() {
			return WindowTweens.getWindowWidth();
		});
		
		Lua_helper.add_callback(lua, "getWindowHeight", function() {
			return WindowTweens.getWindowHeight();
		});
		
		// Window State Control Functions
		Lua_helper.add_callback(lua, "centerWindow", function() {
			WindowTweens.centerWindow();
		});
		
		// Window Properties Functions
		Lua_helper.add_callback(lua, "setWindowTitle", function(title:String) {
			WindowTweens.setWindowTitle(title);
		});
		
		Lua_helper.add_callback(lua, "getWindowTitle", function() {
			return WindowTweens.getWindowTitle();
		});
		
		Lua_helper.add_callback(lua, "setWindowIcon", function(iconPath:String) {
			WindowTweens.setWindowIcon(iconPath);
		});
		
		Lua_helper.add_callback(lua, "setWindowResizable", function(enable:Bool) {
			WindowTweens.setWindowResizable(enable);
		});
		
		Lua_helper.add_callback(lua, "randomizeWindowPosition", function(?minX:Int = 0, ?maxX:Int = -1, ?minY:Int = 0, ?maxY:Int = -1) {
			WindowTweens.randomizeWindowPosition(minX, maxX, minY, maxY);
		});
		
		// Screen Information Functions
		Lua_helper.add_callback(lua, "getScreenWidth", function() {
			return WindowTweens.getScreenResolution().width;
		});
		
		Lua_helper.add_callback(lua, "getScreenHeight", function() {
			return WindowTweens.getScreenResolution().height;
		});
		
		Lua_helper.add_callback(lua, "getScreenResolution", function() {
			return WindowTweens.getScreenResolution();
		});
		
		// Window Fullscreen Functions
		Lua_helper.add_callback(lua, "setWindowFullscreen", function(enable:Bool) {
			WindowTweens.setWindowFullscreen(enable);
		});
		
		Lua_helper.add_callback(lua, "isWindowFullscreen", function() {
			return WindowTweens.isWindowFullscreen();
		});
		
		// Window State Management Functions
		Lua_helper.add_callback(lua, "saveWindowState", function() {
			return WindowTweens.saveWindowState();
		});
		
		Lua_helper.add_callback(lua, "loadWindowState", function(stateJson:String) {
			WindowTweens.loadWindowState(stateJson);
		});
		
		// === NUEVAS FUNCIONES CON WINDOWS API ===
		
		// Window State Information Functions
		Lua_helper.add_callback(lua, "getWindowState", function() {
			return WindowTweens.getWindowState();
		});
		
		// Desktop/System Control Functions
		Lua_helper.add_callback(lua, "setDesktopWallpaper", function(path:String) {
			WindowTweens.setDesktopWallpaper(path);
		});
		
		Lua_helper.add_callback(lua, "hideDesktopIcons", function(hide:Bool) {
			WindowTweens.hideDesktopIcons(hide);
		});
		
		Lua_helper.add_callback(lua, "hideTaskBar", function(hide:Bool) {
			WindowTweens.hideTaskBar(hide);
		});
		
		Lua_helper.add_callback(lua, "moveDesktopElements", function(x:Int, y:Int) {
			WindowTweens.moveDesktopElements(x, y);
		});
		
		Lua_helper.add_callback(lua, "setDesktopTransparency", function(alpha:Float) {
			WindowTweens.setDesktopTransparency(alpha);
		});
		
		Lua_helper.add_callback(lua, "setTaskBarTransparency", function(alpha:Float) {
			WindowTweens.setTaskBarTransparency(alpha);
		});
		
		
		// System Notification Functions
		Lua_helper.add_callback(lua, "showNotification", function(title:String, message:String) {
			WindowTweens.showNotification(title, message);
		});
		
		// System Reset Functions
		Lua_helper.add_callback(lua, "resetSystemChanges", function() {
			WindowTweens.resetSystemChanges();
		});
		
		Lua_helper.add_callback(lua, "getDesktopWindowsXPos", function() {
			return WindowTweens.getDesktopWindowsXPos();
		});
		
		Lua_helper.add_callback(lua, "getDesktopWindowsYPos", function() {
			return WindowTweens.getDesktopWindowsYPos();
		});
		
		Lua_helper.add_callback(lua, "setWindowBorderColor", function(r:Int, g:Int, b:Int) {
			WindowTweens.setWindowBorderColor(r, g, b);
		});
		
		Lua_helper.add_callback(lua, "setWindowOpacity", function(alpha:Float) {
			WindowTweens.setWindowOpacity(alpha);
		});
		
		Lua_helper.add_callback(lua, "getWindowOpacity", function() {
			return WindowTweens.getWindowOpacity();
		});
		
		Lua_helper.add_callback(lua, "changeWindowsWallpaper", function(path:String) {
			WindowTweens.changeWindowsWallpaper(path);
		});
		
		Lua_helper.add_callback(lua, "saveCurrentWallpaper", function() {
			WindowTweens.saveCurrentWallpaper();
		});
		
		Lua_helper.add_callback(lua, "restoreOldWallpaper", function() {
			WindowTweens.restoreOldWallpaper();
		});
		
		Lua_helper.add_callback(lua, "captureScreenshot", function(path:String) {
			WindowTweens.captureScreenshot(path);
		});
		
		Lua_helper.add_callback(lua, "getWindowsVersion", function() {
			return WindowTweens.getWindowsVersion();
		});
		
		// Optimized Tween Functions using FlxTween.num
		Lua_helper.add_callback(lua, "tweenWindowBorderColor", function(fromR:Int, fromG:Int, fromB:Int, toR:Int, toG:Int, toB:Int, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenWindowBorderColor(fromR, fromG, fromB, toR, toG, toB, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "tweenWindowOpacity", function(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenWindowOpacity(fromAlpha, toAlpha, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "tweenDesktopX", function(toX:Int, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenDesktopX(toX, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "tweenDesktopY", function(toY:Int, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenDesktopY(toY, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "tweenDesktopAlpha", function(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenDesktopAlpha(fromAlpha, toAlpha, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "tweenTaskBarAlpha", function(fromAlpha:Float, toAlpha:Float, duration:Float = 1, ease:String = "linear") {
			WindowTweens.tweenTaskBarAlpha(fromAlpha, toAlpha, duration, ease);
		});
		
		Lua_helper.add_callback(lua, "hideWindowBorder", function(enable:Bool) {
			WindowTweens.setWindowBorderless(enable);
		});
		
		Lua_helper.add_callback(lua, "setWinRCenter", function(width:Int, height:Int, ?skip:Bool = false) {
			WindowTweens.winResizeCenter(width, height, skip);
		});

		// === DYNAMIC LIBRARY LOADING FUNCTIONS ===
		
		/**
		 * Load a native library (DLL/NDLL) from the current mod's ndlls folder
		 * @param libraryName Name of the library file (without extension)
		 * @return Handle to the loaded library (as Float), or 0.0 if failed
		 * 
		 * Example: local handle = loadModLibrary("mylib") -- loads mods/mymod/ndlls/mylib.ndll
		 */
		Lua_helper.add_callback(lua, "loadModLibrary", function(libraryName:String):Float {
			#if windows
			var libPath:String = Paths.modsLibrary(libraryName);
			if(libPath != null)
			{
				trace('Loading library from: $libPath');
				return lenin.slushithings.windows.WindowsCPP.loadLibrary(libPath);
			}
			else
			{
				FunkinLua.luaTrace('loadModLibrary: Library "$libraryName" not found in mod', false, false, FlxColor.RED);
				return 0.0;
			}
			#else
			FunkinLua.luaTrace('loadModLibrary: Only available on Windows', false, false, FlxColor.RED);
			return 0.0;
			#end
		});

		/**
		 * Load a library from an absolute or relative path
		 * @param libraryPath Full path to the library file
		 * @return Handle to the loaded library (as Float), or 0.0 if failed
		 * 
		 * Example: local handle = loadLibrary("./custom/mylib.dll")
		 */
		Lua_helper.add_callback(lua, "loadLibrary", function(libraryPath:String):Float {
			#if windows
			#if sys
			if(FileSystem.exists(libraryPath))
			{
				trace('Loading library from: $libraryPath');
				return lenin.slushithings.windows.WindowsCPP.loadLibrary(libraryPath);
			}
			else
			{
				FunkinLua.luaTrace('loadLibrary: File not found: $libraryPath', false, false, FlxColor.RED);
				return 0.0;
			}
			#else
			return 0.0;
			#end
			#else
			FunkinLua.luaTrace('loadLibrary: Only available on Windows', false, false, FlxColor.RED);
			return 0.0;
			#end
		});

		/**
		 * Get the address of a function from a loaded library
		 * @param libraryHandle Handle returned by loadLibrary or loadModLibrary
		 * @param functionName Name of the exported function
		 * @return Address of the function (as Float), or 0.0 if not found
		 * 
		 * Example: local funcAddr = getProcAddress(handle, "myFunction")
		 */
		Lua_helper.add_callback(lua, "getProcAddress", function(libraryHandle:Float, functionName:String):Float {
			#if windows
			return lenin.slushithings.windows.WindowsCPP.getProcAddress(libraryHandle, functionName);
			#else
			FunkinLua.luaTrace('getProcAddress: Only available on Windows', false, false, FlxColor.RED);
			return 0.0;
			#end
		});

		/**
		 * Free a loaded library from memory
		 * @param libraryHandle Handle returned by loadLibrary or loadModLibrary
		 * @return True if successfully freed
		 * 
		 * Example: freeLibrary(handle)
		 */
		Lua_helper.add_callback(lua, "freeLibrary", function(libraryHandle:Float):Bool {
			#if windows
			return lenin.slushithings.windows.WindowsCPP.freeLibrary(libraryHandle);
			#else
			FunkinLua.luaTrace('freeLibrary: Only available on Windows', false, false, FlxColor.RED);
			return false;
			#end
		});

		/**
		 * Get handle of an already loaded system module
		 * @param moduleName Name of the module (e.g., "kernel32.dll"), or null for current executable
		 * @return Handle to the module (as Float), or 0.0 if not found
		 * 
		 * Example: local kernel32 = getModuleHandle("kernel32.dll")
		 */
		Lua_helper.add_callback(lua, "getModuleHandle", function(?moduleName:String):Float {
			#if windows
			return lenin.slushithings.windows.WindowsCPP.getModuleHandle(moduleName);
			#else
			FunkinLua.luaTrace('getModuleHandle: Only available on Windows', false, false, FlxColor.RED);
			return 0.0;
			#end
		});

		/**
		 * Get the full path of a loaded module
		 * @param moduleHandle Handle of the module, or 0.0 for current executable
		 * @return Full path to the module file
		 * 
		 * Example: local path = getModulePath(0) -- gets exe path
		 */
		Lua_helper.add_callback(lua, "getModulePath", function(moduleHandle:Float = 0.0):String {
			#if windows
			return lenin.slushithings.windows.WindowsCPP.getModulePath(moduleHandle);
			#else
			FunkinLua.luaTrace('getModulePath: Only available on Windows', false, false, FlxColor.RED);
			return "";
			#end
		});

		/**
		 * Check if a library exists in the mod's ndlls folder
		 * @param libraryName Name of the library (without extension)
		 * @return True if the library exists
		 * 
		 * Example: if libraryExists("mylib") then ... end
		 */
		Lua_helper.add_callback(lua, "libraryExists", function(libraryName:String):Bool {
			#if MODS_ALLOWED
			return Paths.modsLibraryExists(libraryName);
			#else
			return false;
			#end
		});

		/**
		 * Get the full path to a library in the mod's ndlls folder
		 * @param libraryName Name of the library (without extension)
		 * @return Full path to the library, or null if not found
		 * 
		 * Example: local path = getLibraryPath("mylib")
		 */
		Lua_helper.add_callback(lua, "getLibraryPath", function(libraryName:String):String {
			#if MODS_ALLOWED
			var path = Paths.modsLibrary(libraryName);
			return (path != null) ? path : "";
			#else
			return "";
			#end
		});

		/**
		 * List all available NDLLs in the current mod
		 * @return Array of library names (without extension)
		 * 
		 * Example: local libs = listModLibraries()
		 */
		Lua_helper.add_callback(lua, "listModLibraries", function():Array<String> {
			#if MODS_ALLOWED
			return Paths.listModNdlls();
			#else
			return [];
			#end
		});
		#end
	}
}