package funkin.util;

import openfl.events.UncaughtErrorEvent;
import openfl.events.ErrorEvent;
import openfl.errors.Error;
import flixel.FlxG;
import funkin.ui.title.TitleState;
import funkin.ui.freeplay.FreeplayState;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if windows
import lenin.slushithings.windows.WindowsCPP;
#end

using StringTools;
using flixel.util.FlxArrayUtil;

/**
 * Crash Handler.
 * @author YoshiCrafter29, Ne_Eo, MAJigsaw77 and Homura Akemi (HomuHomu833)
 */
class CrashHandler
{
	// Help link / repository shown in crash messages
	public static final HELP_LINK:String = "https://github.com/LeninAsto/FNF-PlusEngine";
	
	// Fun error messages for null references
	static final NULL_ERROR_MESSAGES:Array<String> = [
		"Oops! The code gods are not pleased... null reference found!",
		"Houston, we have a null problem!",
		"Error 404: Object not found (it's just null)",
		"Congrats! You've discovered the void! (null)",
		"The object decided to take a vacation (null)",
		"*sad trombone* null happened",
		"Null? More like... not cool!",
		"The object went to buy cigarettes and never came back (null)",
		"Achievement Unlocked: Find a null reference!",
		"Null references are stored in the balls",
		"Bruh moment: null reference detected",
		"Skill issue: you tried to use a null object",
		"The object said 'aight imma head out' (null)",
		"Error: object.exe has stopped working (null)",
		"Congratulations, you broke it! (null reference)",
		"The object is on a date with undefined (null)",
		"Null reference? In MY engine? It's more likely than you think",
		"Object not found. Did you check under the couch? (null)"
	];
	
	/**
	 * Analyzes error message and stack to provide detailed null reference information
	 */
	static function analyzeNullError(originalMessage:String, stack:Array<haxe.CallStack.StackItem>):String
	{
		if (originalMessage == null) return "Null error message (ironic, isn't it?)";
		
		var lowerMsg = originalMessage.toLowerCase();
		var isNullError = lowerMsg.contains("null") || 
		                  lowerMsg.contains("object reference") || 
		                  lowerMsg.contains("null pointer") ||
		                  lowerMsg.contains("null object");
		
		if (!isNullError) return originalMessage;
		
		// Fun message
		var funnyMsg = NULL_ERROR_MESSAGES[Std.random(NULL_ERROR_MESSAGES.length)];
		var detailedInfo = new Array<String>();
		detailedInfo.push(funnyMsg);
		detailedInfo.push("");
		
		// Extract specific location from stack
		if (stack != null && stack.length > 0)
		{
			var firstItem = stack[0];
			var locationInfo = "";
			var fileName = "";
			var lineNum = -1;
			var functionName = "";
			
			switch (firstItem)
			{
				case FilePos(parent, file, line, col):
					fileName = file.replace('.hx', '');
					lineNum = line;
					locationInfo = 'File: $file at line $line';
					
					switch (parent)
					{
						case Method(cla, func):
							functionName = '$cla.$func()';
						case _:
					}
					
				case Method(cl, m):
					functionName = '$cl.$m()';
					
				case _:
			}
			
			if (functionName != "")
			{
				detailedInfo.push('>>> Location: $functionName');
				if (lineNum > 0) detailedInfo.push('    Line: $lineNum');
			}
			else if (locationInfo != "")
			{
				detailedInfo.push('>>> $locationInfo');
			}
		}
		
		// Try to extract variable/object name from error message
		var objectName = extractNullObjectName(originalMessage);
		if (objectName != "")
		{
			detailedInfo.push('XXX Null Object: $objectName');
		}
		
		// Memory info if on Windows
		#if windows
		try {
			var memUsage = Math.round(WindowsCPP.getProcessMemoryUsage() / 1024 / 1024);
			var availRAM = WindowsCPP.getAvailableSystemRAM();
			detailedInfo.push('');
			detailedInfo.push('[!] Memory: ${memUsage}MB used, ${availRAM}MB available');
		} catch(e:Dynamic) {}
		#end
		
		return detailedInfo.join('\n');
	}
	
	/**
	 * Attempts to extract the null object/variable name from error message
	 */
	static function extractNullObjectName(message:String):String
	{
		if (message == null) return "";
		
		// Common patterns for null reference errors
		var patterns = [
			~/Null Object Reference/i,
			~/object reference not set/i,
			~/Cannot access field or identifier ([a-zA-Z_][a-zA-Z0-9_]*)/,
			~/null\.([a-zA-Z_][a-zA-Z0-9_]*)/,
			~/([a-zA-Z_][a-zA-Z0-9_]*) is null/,
		];
		
		for (pattern in patterns)
		{
			if (pattern.match(message))
			{
				try {
					var matched = pattern.matched(1);
					if (matched != null && matched != "") return matched;
				} catch(e:Dynamic) {}
			}
		}
		
		return "";
	}
	
	/**
	 * Generates a detailed system report for crash logs
	 */
	static function generateSystemReport():String
	{
		var report = new Array<String>();
		
		report.push("=== SYSTEM INFORMATION ===");
		
		#if windows
		try {
			var totalRAM = WindowsCPP.getTotalSystemRAM();
			var availRAM = WindowsCPP.getAvailableSystemRAM();
			var memLoad = WindowsCPP.getMemoryLoadPercentage();
			var cpuCores = WindowsCPP.getCPUCoreCount();
			var processMemory = Math.round(WindowsCPP.getProcessMemoryUsage() / 1024 / 1024);
			
			report.push('OS: Windows');
			report.push('CPU Cores: $cpuCores');
			report.push('Total RAM: ${totalRAM}MB');
			report.push('Available RAM: ${availRAM}MB');
			report.push('Memory Load: ${memLoad}%');
			report.push('Process Memory: ${processMemory}MB');
		} catch(e:Dynamic) {
			report.push('OS: Windows (detailed info unavailable)');
		}
		#else
		report.push('OS: ${Sys.systemName()}');
		#end
		
		report.push('FlxG.width: ${FlxG.width}');
		report.push('FlxG.height: ${FlxG.height}');
		
		try {
			var state = Type.getClassName(Type.getClass(FlxG.state));
			report.push('Current State: $state');
		} catch(e:Dynamic) {
			report.push('Current State: Unknown');
		}
		
		report.push("==========================");
		
		return report.join('\n');
	}
	
	public static function init():Void
	{
		openfl.Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onError);
		#elseif hl
		hl.Api.setErrorHandler(onError);
		#end
	}

	private static function onUncaughtError(e:UncaughtErrorEvent):Void
	{
		e.preventDefault();
		e.stopPropagation();
		e.stopImmediatePropagation();

		var m:String = e.error;
		if (Std.isOfType(e.error, Error))
		{
			var err = cast(e.error, Error);
			m = '${err.message}';
		}
		else if (Std.isOfType(e.error, ErrorEvent))
		{
			var err = cast(e.error, ErrorEvent);
			m = '${err.text}';
		}
		
		var stack = haxe.CallStack.exceptionStack();
		
		// Analyze and enhance null error messages
		m = analyzeNullError(m, stack);
		
		var stackLabelArr:Array<String> = [];
		var stackLabel:String = "";
		for (e in stack)
		{
			switch (e)
			{
				case CFunction:
					stackLabelArr.push("Non-Haxe (C) Function");
				case Module(c):
					stackLabelArr.push('Module ${c}');
				case FilePos(parent, file, line, col):
					switch (parent)
					{
						case Method(cla, func):
							stackLabelArr.push('${file.replace('.hx', '')}.$func() [line $line]');
						case _:
							stackLabelArr.push('${file.replace('.hx', '')} [line $line]');
					}
				case LocalFunction(v):
					stackLabelArr.push('Local Function ${v}');
				case Method(cl, m):
					stackLabelArr.push('${cl} - ${m}');
			}
		}
		stackLabel = stackLabelArr.join('\r\n');

		// Generate system report
		var systemReport = generateSystemReport();

		// Print error to the console/terminal
		trace('\n\n$m\n\n$stackLabel\n\n$systemReport\n======================\nFor help, visit: $HELP_LINK');
		
		#if sys
		saveErrorMessage('$m\n\n$stackLabel\n\n$systemReport');
		#end

		// Show crash screen on Android, popup on other platforms
		#if android
		var fullStackTrace = '$stackLabel\n\n$systemReport\n\n========================\nFor help, visit: $HELP_LINK';
		CoolUtil.showCrashScreen("Error!", m, fullStackTrace);
		#else
		var errorMsg = '$m\n\n$stackLabel\n\n$systemReport\n\n========================\nNeed help? Visit:\n$HELP_LINK';
		CoolUtil.showPopUp(errorMsg, "Error!");
		#end
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end

		lime.system.System.exit(1);
	}

	#if (cpp || hl)
	private static function onError(message:Dynamic):Void
	{
		final log:Array<String> = [];

		var stack = haxe.CallStack.exceptionStack(true);
		
		if (message != null && message.length > 0)
		{
			// Analyze error for detailed null info
			var analyzedMessage = analyzeNullError(Std.string(message), stack);
			log.push(analyzedMessage);
		}

		log.push(haxe.CallStack.toString(stack));
		
		// Add system report
		log.push("");
		log.push(generateSystemReport());
		
		var errorLog = log.join('\n');
		
		// Print error to the console/terminal
		trace('=== CRITICAL ERROR ===');
		trace(errorLog);
		trace('======================');
		trace('For help, visit: $HELP_LINK');

		#if sys
		saveErrorMessage(errorLog);
		#end

		// Show crash screen on Android, popup on other platforms
		#if android
		var crashTitle = "Critical Error!";
		var crashMessage = message != null ? Std.string(message) : "Unknown error";
		var fullStackTrace = '$errorLog\n\n========================\nFor help, visit: $HELP_LINK';
		CoolUtil.showCrashScreen(crashTitle, crashMessage, fullStackTrace);
		#else
		var errorMsg = '$errorLog\n\n========================\nNeed help? Visit:\n$HELP_LINK';
		CoolUtil.showPopUp(errorMsg, "Critical Error!");
		#end
		#if DISCORD_ALLOWED DiscordClient.shutdown(); #end
        
		lime.system.System.exit(1);
	}
	#end

	#if sys
	private static function saveErrorMessage(message:String):Void
	{
		final folder:String = #if mobile StorageUtil.getStorageDirectory() + #else Sys.getCwd() + #end 'logs/';

		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			var fullLog = message + '\n\n========================\nFor help, visit: $HELP_LINK\n========================';
			File.saveContent(folder + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', fullLog);
		}
		catch (e:haxe.Exception)
			trace('Couldn\'t save error message. (${e.message})');
	}
	#end
}
