package funkin.util;

/**
 * Utilities for working with memory and garbage collector.
 * 
 * Based on FunkinCrew's MemoryUtil implementation.
 * @see https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/util/MemoryUtil.hx
 */
@:nullSafety
class MemoryUtil
{
	/**
	 * Check if the current platform supports Task Memory retrieval.
	 * @return True if Task Memory is available on this platform
	 */
	public static function supportsTaskMem():Bool
	{
		#if ((cpp && (windows || ios || macos)) || linux || android)
		return true;
		#else
		return false;
		#end
	}

	/**
	 * Get the current Task Memory usage (Working Set) in bytes.
	 * This is the actual RAM usage shown in Task Manager (Windows), Activity Monitor (macOS), etc.
	 * @return Memory usage in bytes as Float
	 */
	public static function getTaskMemory():Float
	{
		#if (windows && cpp)
		return lenin.slushithings.windows.WindowsCPP.getProcessMemoryUsage();
		#elseif ((ios || macos) && cpp)
		return funkin.external.apple.MemoryUtil.getCurrentProcessRss();
		#elseif (linux || android)
		try
		{
			#if cpp
			final input:sys.io.FileInput = sys.io.File.read('/proc/${cpp.NativeSys.sys_get_pid()}/status', false);
			#else
			final input:sys.io.FileInput = sys.io.File.read('/proc/self/status', false);
			#end

			final regex:EReg = ~/^VmRSS:\s+(\d+)\s+kB/m;
			var line:String;
			do
			{
				if (input.eof())
				{
					input.close();
					return 0.0;
				}
				line = input.readLine();
			}
			while (!regex.match(line));

			input.close();

			final kb:Float = Std.parseFloat(regex.matched(1));

			if (!Math.isNaN(kb))
			{
				// Convert kilobytes to bytes
				return kb * 1024.0;
			}
		}
		catch (e:Dynamic)
		{
			trace('Error reading memory from /proc/status: ${e}');
		}
		#end

		return 0.0;
	}

	/**
	 * Get the Garbage Collector memory usage in bytes.
	 * This is NOT the total program memory, only memory managed by the GC.
	 * @return GC memory usage in bytes
	 */
	public static function getGCMemory():Float
	{
		return openfl.system.System.totalMemoryNumber;
	}

	/**
	 * Enable garbage collection if it was previously disabled.
	 */
	public static function enable():Void
	{
		#if cpp
		cpp.vm.Gc.enable(true);
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Disable garbage collection entirely.
	 */
	public static function disable():Void
	{
		#if cpp
		cpp.vm.Gc.enable(false);
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Manually perform garbage collection once.
	 * Should only be called from the main thread.
	 * @param major `true` to perform major collection
	 */
	public static function collect(major:Bool = false):Void
	{
		#if cpp
		cpp.vm.Gc.run(major);
		#elseif hl
		hl.Gc.major();
		#else
		throw 'Not implemented!';
		#end
	}

	/**
	 * Perform garbage collection compaction (reduces fragmentation).
	 */
	public static function compact():Void
	{
		#if cpp
		cpp.vm.Gc.compact();
		#else
		throw 'Not implemented!';
		#end
	}
}
