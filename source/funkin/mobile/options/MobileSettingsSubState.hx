package funkin.mobile.options;

import funkin.ui.options.BaseOptionsMenu;
import funkin.ui.options.Option;


/**
 * ...
 * @author: Homura Akemi (HomuHomu833) and Karim Akra
 */
class MobileSettingsSubState extends BaseOptionsMenu
{
	#if android
	var storageTypes:Array<String> = ["EXTERNAL_DATA", "EXTERNAL_OBB", "EXTERNAL_MEDIA", "EXTERNAL", "EXTERNAL_GLOBAL"];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.data.storageType;
	#end
	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	#if android
	var initialStorageType:String;
	var pendingStorageType:String;
	var storageTypeChanged:Bool = false;
	#end
	var option:Option;

	public function new()
	{
		#if android if (!externalPaths.contains('\n'))
			storageTypes = storageTypes.concat(externalPaths); #end
		title = Language.getPhrase('mobile_menu', 'Mobile Settings');
		rpcTitle = 'Mobile Settings Menu'; // for Discord Rich Presence
		#if android
		initialStorageType = ClientPrefs.data.storageType;
		pendingStorageType = initialStorageType;
		
		// Show detected device tier (informational only)
		var tierName = funkin.mobile.AndroidOptimizer.getTierName();
		var gpuName = funkin.util.Native.detectGPU();
		var tierInfo = 'Detected: $tierName | GPU: $gpuName\n\nQuality settings were auto-configured.\nYou can manually override in Graphics Settings.';
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
		option.onChange = () -> FlxG.scaleMode = new funkin.mobile.backend.MobileScaleMode();
		addOption(option);
		#end
		
		#if android
		option = new Option('Storage Type',
			'Select where the game should store its data.\nEXTERNAL_DATA: Recommended, scoped storage.\nEXTERNAL: Public /sdcard/.PlusEngine/\nChanging this requires restarting the game!',
			'storageType', STRING, storageTypes);
		option.onChange = () -> 
		{
			var newType = curOption.getValue();
			pendingStorageType = newType;
			storageTypeChanged = (pendingStorageType != initialStorageType);
			// Don't save here, we'll save on close with the correct value
		};
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
	override public function close()
	{
		if (storageTypeChanged)
		{
			trace('[MobileSettings] Storage type changing from ' + initialStorageType + ' to ' + pendingStorageType);
			
			// Update ClientPrefs.data FIRST
			ClientPrefs.data.storageType = pendingStorageType;
			
			// Now save settings (this will copy data.storageType to FlxG.save.data.storageType)
			ClientPrefs.saveSettings();
			
			trace('[MobileSettings] Verifying save: ClientPrefs.data.storageType = ' + ClientPrefs.data.storageType);
			trace('[MobileSettings] Verifying save: FlxG.save.data.storageType = ' + FlxG.save.data.storageType);
			
			var oldPath = StorageUtil.getStoragePathForType(initialStorageType);
			var newPath = StorageUtil.getStoragePathForType(pendingStorageType);

			trace('[MobileSettings] Old path: ' + oldPath);
			trace('[MobileSettings] New path: ' + newPath);

			// Copy data and delete old directory to free up space
			StorageUtil.migrateStorage(initialStorageType, pendingStorageType);

			var message = 'Storage directory changed.\n\n';
			message += 'The game will now close. Please reopen it.\n\n';
			message += 'Old: ' + oldPath + '\n';
			message += 'New: ' + newPath + '\n\n';
			message += 'Your data has been copied to the new location.\n';
			message += 'The old directory will be cleaned up to free space.';
			
			FlxG.stage.window.alert(message, 'Restart Required');
			lime.system.System.exit(0);
			return;
		}

		super.close();
	}
	#end
}
