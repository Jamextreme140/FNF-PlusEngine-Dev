package funkin.mobile;

#if android
import lime.system.JNI;
#end

/**
 * Haxe wrapper for Material3 WavyProgressIndicator timebar
 * Provides cross-platform interface to native Android Compose UI component
 * 
 * Usage in PlayState:
 * ```haxe
 * // On create
 * WavyTimebar.initialize();
 * 
 * // In update loop
 * var progress = Conductor.songPosition / FlxG.sound.music.length;
 * WavyTimebar.setProgress(progress);
 * 
 * // On destroy
 * WavyTimebar.destroy();
 * ```
 */
class WavyTimebar
{
	// JNI method handles (lazy initialization)
	#if android
	private static var initialize_jni:Dynamic = null;
	private static var destroy_jni:Dynamic = null;
	private static var setProgress_jni:Dynamic = null;
	private static var show_jni:Dynamic = null;
	private static var hide_jni:Dynamic = null;
	private static var setAlpha_jni:Dynamic = null;
	private static var setLayout_jni:Dynamic = null;
	private static var isReady_jni:Dynamic = null;
	#end
	
	private static var _initialized:Bool = false;
	
	/**
	 * Initialize the wavy timebar overlay
	 * Call once when PlayState starts
	 */
	public static function initialize():Void
	{
		#if android
		if (_initialized) return;
		
		try
		{
			if (initialize_jni == null)
			{
				initialize_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'initializeTimebar',
					'()V'
				);
			}
			
			initialize_jni();
			_initialized = true;
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to initialize: ' + e);
		}
		#end
	}
	
	/**
	 * Destroy timebar and clean up resources
	 * Call when leaving PlayState
	 */
	public static function destroy():Void
	{
		#if android
		if (!_initialized) return;
		
		try
		{
			if (destroy_jni == null)
			{
				destroy_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'destroyTimebar',
					'()V'
				);
			}
			
			destroy_jni();
			_initialized = false;
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to destroy: ' + e);
		}
		#end
	}
	
	/**
	 * Update timebar progress
	 * @param progress Value from 0.0 (song start) to 1.0 (song end)
	 */
	public static function setProgress(progress:Float):Void
	{
		#if android
		if (!_initialized) return;
		
		try
		{
			if (setProgress_jni == null)
			{
				setProgress_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'setTimebarProgress',
					'(F)V'
				);
			}
			
			setProgress_jni(progress);
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to set progress: ' + e);
		}
		#end
	}
	
	/**
	 * Show timebar (fade in to full visibility)
	 */
	public static function show():Void
	{
		#if android
		if (!_initialized) return;
		
		try
		{
			if (show_jni == null)
			{
				show_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'showTimebar',
					'()V'
				);
			}
			
			show_jni();
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to show: ' + e);
		}
		#end
	}
	
	/**
	 * Hide timebar (fade out to invisible)
	 */
	public static function hide():Void
	{
		#if android
		if (!_initialized) return;
		
		try
		{
			if (hide_jni == null)
			{
				hide_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'hideTimebar',
					'()V'
				);
			}
			
			hide_jni();
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to hide: ' + e);
		}
		#end
	}
	
	/**
	 * Set timebar alpha/visibility
	 * @param alpha 0.0 = invisible, 1.0 = fully visible
	 */
	public static function setAlpha(alpha:Float):Void
	{
		#if android
		if (!_initialized) return;
		
		try
		{
			if (setAlpha_jni == null)
			{
				setAlpha_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'setTimebarAlpha',
					'(F)V'
				);
			}
			
			setAlpha_jni(alpha);
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to set alpha: ' + e);
		}
		#end
	}

	/**
	 * Configure native timebar layout.
	 * @param widthPercent Relative width in [0.2, 1.0]
	 * @param yPx Top margin in physical pixels
	 */
	public static function setLayout(widthPercent:Float, yPx:Float):Void
	{
		#if android
		if (!_initialized) return;
		
		try
		{
			if (setLayout_jni == null)
			{
				setLayout_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'setTimebarLayout',
					'(FF)V'
				);
			}
			
			setLayout_jni(widthPercent, yPx);
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to set layout: ' + e);
		}
		#end
	}
	
	/**
	 * Check if timebar is ready to use
	 * @return true if initialized and ready
	 */
	public static function isReady():Bool
	{
		#if android
		if (!_initialized) return false;
		
		try
		{
			if (isReady_jni == null)
			{
				isReady_jni = JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'isTimebarReady',
					'()Z'
				);
			}
			
			return isReady_jni();
		}
		catch (e:Dynamic)
		{
			trace('[WavyTimebar] Failed to check ready state: ' + e);
			return false;
		}
		#else
		return false;
		#end
	}
}
