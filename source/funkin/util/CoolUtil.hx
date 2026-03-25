package funkin.util;

import openfl.utils.Assets;
import lime.utils.Assets as LimeAssets;
#if android
import lime.system.JNI;
#end

#if cpp
@:cppFileCode('#include <thread>')
#end
class CoolUtil
{
	#if android
	private static var showMessageBox_jni:Dynamic = null;
	private static var showCrashScreen_jni:Dynamic = null;
	#end

	// Legacy update checker variables (forwarded to UpdateManager for compatibility)
	public static var hasUpdate(get, never):Bool;
	public static var latestVersion(get, never):String;
	
	static function get_hasUpdate():Bool return UpdateManager.hasUpdate;
	static function get_latestVersion():String return UpdateManager.latestVersion;
	
	public static final haxeExtensions:Array<String> = ["hx", "hscript", "hsc", "hxs"];

	/**
	 * Check for updates using semantic versioning
	 * Now uses UpdateManager for proper version comparison
	 */
	public static function checkForUpdates(url:String = null, ?onComplete:Void->Void):String 
	{
		return UpdateManager.checkForUpdates(url, onComplete);
	}
	
	// Call this in the update loop to execute callbacks on the main thread
	public static function executeUpdateCallback():Void 
	{
		UpdateManager.update();
	}
	inline public static function quantize(f:Float, snap:Float){
		// changed so this actually works lol
		var m:Float = Math.fround(f * snap);
		//trace(snap);
		return (m / snap);
	}

	inline public static function capitalize(text:String)
		return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	inline public static function coolTextFile(path:String):Array<String>
	{
		// Try loading from mods first (FileSystem), then from APK (OpenFlAssets)
		var daList:String = null;
		#if MODS_ALLOWED
		if(FileSystem.exists(path))
			daList = File.getContent(path);
		#end
		
		if(daList == null && Assets.exists(path))
			daList = Assets.getText(path);
		
		return daList != null ? listFromString(daList) : [];
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if(color.startsWith('0x')) color = color.substring(color.length - 6);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if(colorNum == null) colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	inline public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
			daList[i] = daList[i].trim();

		return daList;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		return Math.floor(value * Math.pow(10, decimals)) / Math.pow(10, decimals);
	}

	#if linux
	public static function sortAlphabetically(list:Array<String>):Array<String> {
		if (list == null) return [];

		list.sort((a, b) -> {
			var upperA = a.toUpperCase();
			var upperB = b.toUpperCase();
			
			return upperA < upperB ? -1 : upperA > upperB ? 1 : 0;
		});
		return list;
	}
	#end

	inline public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for(col in 0...sprite.frameWidth)
		{
			for(row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if(colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.exists(colorOfThisPixel) ? countByColor[colorOfThisPixel] : 0;
					countByColor[colorOfThisPixel] = count + 1;
				}
			}
		}

		var maxCount = 0;
		var maxKey:Int = 0; //after the loop this will store the max color
		countByColor[FlxColor.BLACK] = 0;
		for(key => count in countByColor)
		{
			if(count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		countByColor = [];
		return maxKey;
	}

	inline public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max) dumbArray.push(i);

		return dumbArray;
	}

	inline public static function browserLoad(site:String) {
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false) {
		#if sys
			if(!absolute) folder =  Sys.getCwd() + '$folder';

			folder = folder.replace('/', '\\');
			if(folder.endsWith('/')) folder.substr(0, folder.length - 1);

			#if linux
			var command:String = '/usr/bin/xdg-open';
			#else
			var command:String = 'explorer.exe';
			#end
			Sys.command(command, [folder]);
			trace('$command $folder');
		#else
			FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String {
		final company:String = FlxG.stage.application.meta.get('company');
		// #if (flixel < "5.0.0") return company; #else
		return '${company}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
		// #end
	}

	public static function setTextBorderFromString(text:FlxText, border:String)
	{
		switch(border.toLowerCase().trim())
		{
			case 'shadow':
				text.borderStyle = SHADOW;
			case 'outline':
				text.borderStyle = OUTLINE;
			case 'outline_fast', 'outlinefast':
				text.borderStyle = OUTLINE_FAST;
			default:
				text.borderStyle = NONE;
		}
	}

	public static function showPopUp(message:String, title:String):Void
	{
		#if android
		try
		{
			if (showMessageBox_jni == null)
			{
				showMessageBox_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'showMessageBox',
					'(Ljava/lang/String;Ljava/lang/String;)V'
				);
			}

			showMessageBox_jni(title, message);
		}
		catch (e:Dynamic)
		{
			trace('[CoolUtil] Native showPopUp failed: ' + e);
			FlxG.stage.window.alert(message, title);
		}
		#else
		FlxG.stage.window.alert(message, title);
		#end
	}

	/**
	 * Show crash screen with full error details (Android only).
	 * This displays a native activity with the crash information.
	 * @param errorTitle Short error title
	 * @param errorMessage Brief error message  
	 * @param stackTrace Full stack trace
	 */
	public static function showCrashScreen(errorTitle:String, errorMessage:String, stackTrace:String):Void
	{
		#if android
		try
		{
			if (showCrashScreen_jni == null)
			{
				showCrashScreen_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'showCrashScreen',
					'(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V'
				);
			}

			showCrashScreen_jni(errorTitle, errorMessage, stackTrace);
		}
		catch (e:Dynamic)
		{
			trace('[CoolUtil] Native showCrashScreen failed: ' + e);
			// Fallback to popup
			showPopUp('$errorTitle\n$errorMessage\n\n$stackTrace', "Critical Error");
		}
		#else
		// On non-Android platforms, use regular popup
		showPopUp('$errorTitle\n$errorMessage\n\n$stackTrace', errorTitle);
		#end
	}

	#if cpp
    @:functionCode('
        return std::thread::hardware_concurrency();
    ')
	#end
    public static function getCPUThreadsCount():Int
    {
        return 1;
    }
}
