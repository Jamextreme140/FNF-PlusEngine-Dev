package funkin.external.apple;

#if (ios || macos)
/**
 * Apple (iOS/macOS) memory utilities using mach task_info APIs.
 * Based on FunkinCrew's implementation.
 */
@:buildXml('
<files id="haxe">
	<compilerflag value="-Isource/funkin/external/apple" />
</files>
')
@:headerCode('
#include <mach/mach.h>
#include <mach/task_info.h>
')
class MemoryUtil
{
	/**
	 * Gets the current process RSS (Resident Set Size) in bytes.
	 * This is the actual physical RAM being used by the process.
	 * @return Memory usage in bytes
	 */
	@:functionCode('
		// Get the current task (process)
		mach_task_basic_info_data_t taskInfo;
		mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
		kern_return_t kr = task_info(
			mach_task_self(),
			MACH_TASK_BASIC_INFO,
			(task_info_t)&taskInfo,
			&infoCount
		);
		
		if (kr == KERN_SUCCESS)
		{
			// Return resident_size (RSS) in bytes
			return (double)taskInfo.resident_size;
		}
		
		return 0.0;
	')
	public static function getCurrentProcessRss():Float
	{
		return 0.0;
	}
}
#end
