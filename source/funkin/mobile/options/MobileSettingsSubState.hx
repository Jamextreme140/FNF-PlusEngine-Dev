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
	#if android
	var storageTypes:Array<String> = [];
	var storageTypeNames:Array<String> = [];
	var externalPaths:Array<String> = StorageUtil.checkExternalPaths(true);
	final lastStorageType:String = ClientPrefs.data.storageType;
	var storageInfos:Array<StorageTypeInfo> = [];
	#end
	final exControlTypes:Array<String> = ["NONE", "SINGLE", "DOUBLE"];
	final hintOptions:Array<String> = ["No Gradient", "No Gradient (Old)", "Gradient", "Hidden"];
	#if android
	var initialStorageType:String;
	var pendingStorageType:String;
	var storageTypeChanged:Bool = false;
	var currentStorageOptionIndex:Int = -1;
	#end
	var option:Option;

	public function new()
	{
		#if android
		// Get available storage types
		storageInfos = StorageUtil.getAvailableStorageTypes();
		
		// Build ID and name arrays
		for (info in storageInfos)
		{
			storageTypes.push(info.id);
			storageTypeNames.push(info.name);
		}
		
		// Add external paths if available
		if (!externalPaths.contains('\n'))
		{
			for (path in externalPaths)
			{
				if (path != null && path.trim().length > 0)
				{
					storageTypes.push(path);
					storageTypeNames.push('SD Card: ' + path);
				}
			}
		}
		#end
		
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
		// Storage Type option with dynamic descriptions
		option = new Option('Storage Type',
			getStorageDescription(ClientPrefs.data.storageType),
			'storageType', STRING, storageTypeNames);
		
		// Override getValue/setValue to map between IDs and names
		option.getValue = function():Dynamic {
			var currentID = ClientPrefs.data.storageType;
			var index = Lambda.indexOf(storageTypes, currentID);
			if (index >= 0 && index < storageTypeNames.length)
				return storageTypeNames[index];
			return storageTypeNames[0]; // Fallback to first option
		};
		
		option.setValue = function(value:Dynamic):Dynamic {
			var selectedName:String = cast value;
			var index = Lambda.indexOf(storageTypeNames, selectedName);
			if (index >= 0 && index < storageTypes.length)
			{
				ClientPrefs.data.storageType = storageTypes[index];
				return storageTypes[index];
			}
			return ClientPrefs.data.storageType;
		};
		
		option.onChange = onChangeStorageType;
		addOption(option);
		currentStorageOptionIndex = optionsArray.length - 1;
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
	function onChangeStorageType()
	{
		// Get the actual storage ID (not the display name)
		var newTypeID = ClientPrefs.data.storageType;
		pendingStorageType = newTypeID;
		storageTypeChanged = (pendingStorageType != initialStorageType);
		
		// Update description
		if (currentStorageOptionIndex >= 0 && currentStorageOptionIndex < optionsArray.length)
		{
			optionsArray[currentStorageOptionIndex].description = getStorageDescription(newTypeID);
			if (descText != null)
				descText.text = optionsArray[currentStorageOptionIndex].description;
		}
	}
	
	function getStorageDescription(typeID:String):String
	{
		// Find the storage info for this type
		for (info in storageInfos)
		{
			if (info.id == typeID)
			{
				var desc = info.description;
				desc += '\n\nCurrent: ' + StorageUtil.getStoragePathForType(typeID);
				desc += '\n\nChanging this requires restarting the game!';
				return desc;
			}
		}
		
		// Fallback for external paths
		if (typeID.startsWith('/storage/'))
		{
			return 'External SD Card storage\nPath: ' + typeID + '\n\nChanging this requires restarting the game!';
		}
		
		return 'Select where the game should store its data.\nChanging this requires restarting the game!';
	}
	#end

	#if android
	override public function close()
	{
		if (storageTypeChanged)
		{
			trace('[MobileSettings] Storage type changing from ' + initialStorageType + ' to ' + pendingStorageType);
			
			// Check permissions if needed
			if (StorageUtil.requiresSpecialPermissions(pendingStorageType))
			{
				var permMessage = 'The selected storage type requires special permissions.\n\n';
				permMessage += 'Please grant "All Files Access" permission when prompted.\n';
				permMessage += 'The game will restart after changing permissions.';
				FlxG.stage.window.alert(permMessage, 'Permissions Required');
			}
			
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

			// Build detailed message
			var storageInfo = getStorageInfoByID(pendingStorageType);
			var message = 'Storage Type Changed!\n\n';
			message += 'New Type: ' + (storageInfo != null ? storageInfo.name : pendingStorageType) + '\n';
			message += 'Location: ' + newPath + '\n\n';
			message += 'Your game data has been migrated automatically.\n';
			message += 'The old directory has been cleaned up to save space.\n\n';
			message += 'The game will now restart to apply changes.';
			
			FlxG.stage.window.alert(message, 'Restart Required');
			lime.system.System.exit(0);
			return;
		}

		super.close();
	}
	
	function getStorageInfoByID(id:String):StorageTypeInfo
	{
		for (info in storageInfos)
		{
			if (info.id == id)
				return info;
		}
		return null;
	}
	#end
}
