package lenin.slushithings.windows;

#if windows
import lenin.slushithings.windows.WindowsCPP;
#end

/**
 * API wrapper for screenshot functionality
 * Uses native Windows C++ code for reliable screen capture
 */
class ScreenshotAPI
{
	/**
	 * Captures a screenshot and saves it to the specified path
	 * @param path Absolute path where to save the screenshot
	 */
	public static function capture(path:String):Void
	{
		#if windows
		WindowsCPP.captureFullScreen(path);
		#else
		trace("[Screenshot]: Screenshot capture is only available on Windows");
		#end
	}
}
