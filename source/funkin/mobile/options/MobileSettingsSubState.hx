/*
 * Copyright (C) 2026 Mobile Porting Team
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */

package funkin.mobile.options;

import funkin.ui.options.BaseOptionsMenu;
import funkin.ui.options.Option;

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

	#if android
	// JNI method handles for native file manager integration (lazy initialization)
	private static var openFileManager_jni:Dynamic = null;
	private static var openModsFolder_jni:Dynamic = null;
	private static var openSavesFolder_jni:Dynamic = null;
	#end

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
		option = new Option('Open File Manager',
			'Browse and edit game files using a native Android file manager.\nPress ACCEPT to open.',
			'', BUTTON, []);
		option.onChange = openFileManager;
		addOption(option);

		option = new Option('Manage Mods',
			'Quick access to mods folder. Add, remove or edit mod files.',
			'', BUTTON, []);
		option.onChange = openModsFolder;
		addOption(option);

		option = new Option('Browse Saves',
			'View and manage your save files.',
			'', BUTTON, []);
		option.onChange = openSavesFolder;
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
	 * Open native Android File Manager to browse game files
	 */
	function openFileManager():Void
	{
		try
		{
			// Initialize JNI handle if needed (lazy initialization)
			if (openFileManager_jni == null) {
				openFileManager_jni = lime.system.JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'openFileManager',
					'(Ljava/lang/String;)V'
				);
			}
			
			// Call Kotlin extension via JNI
			var scopedPath = StorageUtil.getStorageDirectory();
			openFileManager_jni(scopedPath);
		}
		catch (e:Dynamic)
		{
			trace('[MobileSettings] Error opening file manager: ' + e);
			CoolUtil.showPopUp('Could not open file manager.\nError: ' + e, Language.getPhrase('mobile_error', 'Error!'));
		}
	}

	/**
	 * Open file manager directly to mods folder
	 */
	function openModsFolder():Void
	{
		try
		{
			// Initialize JNI handle if needed (lazy initialization)
			if (openModsFolder_jni == null) {
				openModsFolder_jni = lime.system.JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'openModsFolder',
					'()V'
				);
			}
			
			openModsFolder_jni();
		}
		catch (e:Dynamic)
		{
			trace('[MobileSettings] Error opening mods folder: ' + e);
			CoolUtil.showPopUp('Could not open mods folder.\nError: ' + e, Language.getPhrase('mobile_error', 'Error!'));
		}
	}

	/**
	 * Open file manager directly to saves folder
	 */
	function openSavesFolder():Void
	{
		try
		{
			// Initialize JNI handle if needed (lazy initialization)
			if (openSavesFolder_jni == null) {
				openSavesFolder_jni = lime.system.JNI.createStaticMethod(
					'com/leninasto/plusengine/PlusEngineExtension',
					'openSavesFolder',
					'()V'
				);
			}
			
			openSavesFolder_jni();
		}
		catch (e:Dynamic)
		{
			trace('[MobileSettings] Error opening saves folder: ' + e);
			CoolUtil.showPopUp('Could not open saves folder.\nError: ' + e, Language.getPhrase('mobile_error', 'Error!'));
		}
	}
	#end
}
