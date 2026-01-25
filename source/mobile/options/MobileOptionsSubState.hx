/*
 * Copyright (C) 2025 Mobile Porting Team
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

package mobile.options;

import options.BaseOptionsMenu;
import options.Option;

class MobileOptionsSubState extends BaseOptionsMenu
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
		title = Language.getPhrase('mobile_options_menu', 'Mobile Options');
		rpcTitle = 'Mobile Options Menu'; // for Discord Rich Presence, fuck it
		#if android
		initialStorageType = ClientPrefs.data.storageType;
		pendingStorageType = initialStorageType;
		
		// Show detected device tier (informational only)
		var tierName = backend.AndroidOptimizer.getTierName();
		var gpuName = backend.Native.detectGPU();
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

		option = new Option('Wide Screen Mode',
			'If checked, The game will stetch to fill your whole screen. (WARNING: Can result in bad visuals & break some mods that resizes the game/cameras)',
			'wideScreen', BOOL);
		option.onChange = () -> FlxG.scaleMode = new mobile.backend.MobileScaleMode();
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

		super();
	}

	#if android
	override public function close()
	{
		if (storageTypeChanged)
		{
			trace('[MobileOptions] Storage type changing from ' + initialStorageType + ' to ' + pendingStorageType);
			
			// Update ClientPrefs.data FIRST
			ClientPrefs.data.storageType = pendingStorageType;
			
			// Now save settings (this will copy data.storageType to FlxG.save.data.storageType)
			ClientPrefs.saveSettings();
			
			trace('[MobileOptions] Verifying save: ClientPrefs.data.storageType = ' + ClientPrefs.data.storageType);
			trace('[MobileOptions] Verifying save: FlxG.save.data.storageType = ' + FlxG.save.data.storageType);
			
			var oldPath = StorageUtil.getStoragePathForType(initialStorageType);
			var newPath = StorageUtil.getStoragePathForType(pendingStorageType);

			trace('[MobileOptions] Old path: ' + oldPath);
			trace('[MobileOptions] New path: ' + newPath);

			// Copy what we can before exiting (best-effort)
			StorageUtil.migrateStorage(initialStorageType, pendingStorageType);

			var message = 'Storage directory changed.\n\n';
			message += 'The game will now close. Please reopen it.\n\n';
			message += 'Old: ' + oldPath + '\n';
			message += 'New: ' + newPath + '\n\n';
			message += 'Missing files will be copied on next launch.';
			
			FlxG.stage.window.alert(message, 'Restart Required');
			lime.system.System.exit(0);
			return;
		}

		super.close();
	}
	#end
}
