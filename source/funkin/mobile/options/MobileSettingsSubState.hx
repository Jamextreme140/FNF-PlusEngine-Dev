package funkin.mobile.options;

import funkin.ui.options.BaseOptionsMenu;
import funkin.ui.options.Option;


/**
 * ...
 * @author: Homura Akemi (HomuHomu833) and Karim Akra
 */
class MobileSettingsSubState extends BaseOptionsMenu
{
	// Storage selection removed - now using only scoped storage (EXTERNAL_DATA)
	/*
	#if android
	var storageTypes:Array<String> = [];
	var storageTypeNames:Array<String> = [];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.data.storageType;
	var storageInfos:Array<StorageTypeInfo> = [];
	var initialStorageType:String;
	var pendingStorageType:String;
	var storageTypeChanged:Bool = false;
	var currentStorageOptionIndex:Int = -1;
	#end
	*/
	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	var option:Option;

	public function new()
	{
		title = Language.getPhrase('mobile_menu', 'Mobile Settings');
		rpcTitle = 'Mobile Settings Menu'; // for Discord Rich Presence
		
		#if android
		// Show detected device tier (informational only)
		var tierName = funkin.mobile.AndroidOptimizer.getTierName();
		var gpuName = funkin.util.Native.detectGPU();
		var tierInfo = 'Detected: $tierName | GPU: $gpuName\n\nQuality settings were auto-configured.\nYou can manually override in Graphics Settings.\n\nStorage: Scoped (Android/data)';
		option = new Option('Device Performance Info', tierInfo, '', STRING, []);
		addOption(option);
		#end

		option = new Option('Extra Controls', 'Select how many extra buttons you prefer to have?\nThey can be used for mechanics with LUA or HScript.',
			'extraButtons', STRING, exControlTypes);
		addOption(option);

		option = new Option('Mobile Controls Opacity',
			'Selects the opacity for the mobile buttons (careful not to put it at 0 and lose track of your buttons).', 'controlsAlpha', PERCENT);
		option.scrollSpeed = 1;
		option.minValue = 0.001;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = () ->
		{
			touchPad.alpha = curOption.getValue();
			ClientPrefs.toggleVolumeKeys();
		};
		addOption(option);

		#if mobile
		option = new Option('Allow Phone Screensaver',
			'If checked, the phone will sleep after going inactive for few seconds.\n(The time depends on your phone\'s options)', 'screensaver', BOOL);
		option.onChange = () -> lime.system.System.allowScreenTimeout = curOption.getValue();
		addOption(option);

		option = new Option('Infinity Display',
			'Extends the viewport vertically for modern screens\nwhile keeping the game in 16:9 for mod compatibility.\nTouchpad controls will adjust automatically.',
			'infinityDisplay', BOOL);
		option.onChange = () -> FlxG.scaleMode = new flixel.system.scaleModes.MobileScaleMode();
		addOption(option);
		#end

		if (MobileData.mode == 3)
		{
			option = new Option('Hitbox Design', 'Choose how your hitbox should look like.', 'hitboxType', STRING, hintOptions);
			addOption(option);

			option = new Option('Hitbox Position', 'If checked, the hitbox will be put at the bottom of the screen, otherwise will stay at the top.',
				'hitboxPos', BOOL);
			addOption(option);
		}

		option = new Option('Dynamic Controls Color',
			'If checked, the mobile controls color will be set to the notes color in your settings.\n(have effect during gameplay only)', 'dynamicColors',
			BOOL);
		addOption(option);

		option = new Option('Show Debug Buttons',
			'If checked, shows the T (Trace) and D (Debug) buttons in the top-right corner.\nT toggles trace display, D cycles FPS debug levels.',
			'showMobileDebugButtons',
			BOOL);
		option.onChange = onChangeMobileDebugButtons;
		addOption(option);

		#if android
		// File Manager options (BUTTON type shows checkboxes but only triggers onChange, doesn't save values)
		option = new Option('Open Data Folder',
			'Opens the Android system file explorer to browse game data folder.\nLocation: Android/data/com.leninasto.plusengine/files/',
			'', BUTTON, []);
		option.onChange = openDataFolder;
		addOption(option);
		#end

		super();
	}

	function onChangeMobileDebugButtons()
	{
		#if mobile
		if(Main.traceButton != null)
			Main.traceButton.visible = ClientPrefs.data.showMobileDebugButtons;
		if(Main.debugButton != null)
			Main.debugButton.visible = ClientPrefs.data.showMobileDebugButtons;
		#end
	}

	#if android
	/**
	 * Open system file explorer to browse game data folder
	 * Opens Android/data/com.leninasto.plusengine/files/
	 * Uses native Kotlin implementation via JNI for optimal performance
	 */
	function openDataFolder():Void
	{
		try
		{
			funkin.external.android.DataFolderUtil.openDataFolder();
		}
		catch (e:Dynamic)
		{
			trace('[MobileSettings] Error opening data folder: ' + e);
			CoolUtil.showPopUp('Could not open data folder.\nError: ' + e, Language.getPhrase('mobile_error', 'Error!'));
		}
	}

	/**
	 * Open system file explorer directly to mods folder
	 * Opens Android/data/com.leninasto.plusengine/files/mods/
	 */
	function openModsFolder():Void
	{
		try
		{
			funkin.external.android.DataFolderUtil.openModsFolder();
		}
		catch (e:Dynamic)
		{
			trace('[MobileSettings] Error opening mods folder: ' + e);
			CoolUtil.showPopUp('Could not open mods folder.\nError: ' + e, Language.getPhrase('mobile_error', 'Error!'));
		}
	}

	/**
	 * Open system file explorer directly to saves folder
	 * Opens Android/data/com.leninasto.plusengine/files/saves/
	 */
	function openSavesFolder():Void
	{
		try
		{
			funkin.external.android.DataFolderUtil.openSavesFolder();
		}
		catch (e:Dynamic)
		{
			trace('[MobileSettings] Error opening saves folder: ' + e);
			CoolUtil.showPopUp('Could not open saves folder.\nError: ' + e, Language.getPhrase('mobile_error', 'Error!'));
		}
	}
	#end
}
