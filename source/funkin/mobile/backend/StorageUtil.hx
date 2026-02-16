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

package funkin.mobile.backend;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;

using Lambda;

/**
 * A storage class for mobile.
 * @author Karim Akra and Homura Akemi (HomuHomu833)
 */
class StorageUtil
{
	#if sys
	public static function getStorageDirectory():String
	{
		#if android
		// Use the configured storage type from ClientPrefs
		if (ClientPrefs.data != null && ClientPrefs.data.storageType != null)
			return getStoragePathForType(ClientPrefs.data.storageType);
		else
			return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir()); // Fallback to default
		#elseif ios
		return lime.system.System.documentsDirectory;
		#else
		return Sys.getCwd();
		#end
	}

	public static function getSMDirectory():String
		return #if android '/sdcard/.PlusEngine/sm/' #else './sm/' #end;

	public static function saveContent(fileName:String, fileData:String, ?alert:Bool = true):Void
	{
		// modsList.txt always goes to public storage (/sdcard/.PlusEngine/)
		var folder:String;
		if (fileName == 'modsList.txt')
		{
			#if android
			folder = getExternalStorageDirectory();
			#else
			folder = Sys.getCwd();
			#end
		}
		else
		{
			// Other files go to the configured storage + saves/
			folder = #if android StorageUtil.getExternalStorageDirectory() + #else Sys.getCwd() + #end 'saves/';
		}
		
		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			File.saveContent(folder + fileName, fileData);
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_success', '{1} has been saved.', [fileName]), Language.getPhrase('mobile_success', "Success!"));
		}
		catch (e:Dynamic)
		{
			// Fallback: if the selected storage is not writable (common on newer Android versions),
			// try app-specific external files dir.
			#if android
			try
			{
				final fallbackFolder:String = haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir()) + 'saves/';
				if (!FileSystem.exists(fallbackFolder))
					FileSystem.createDirectory(fallbackFolder);
				File.saveContent('$fallbackFolder/$fileName', fileData);
				if (alert)
					CoolUtil.showPopUp(Language.getPhrase('file_save_success', '{1} has been saved.', [fileName]), Language.getPhrase('mobile_success', "Success!"));
				return;
			}
			catch (_:Dynamic) {}
			#end

			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_fail', '{1} couldn\'t be saved.\n({2})', [fileName, Std.string(e)]), Language.getPhrase('mobile_error', "Error!"));
			else
				trace('$fileName couldn\'t be saved. (${e.message})');
		}
	}

	#if android
	// always force path due to haxe
	public static function getExternalStorageDirectory():String
		return '/sdcard/.PlusEngine/';

	public static function requestPermissions():Void
	{
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO', 'READ_MEDIA_VISUAL_USER_SELECTED']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		if (AndroidVersion.SDK_INT == AndroidVersionCode.TIRAMISU && !AndroidEnvironment.isExternalStorageManager())
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

		if ((AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_MEDIA_IMAGES'))
			|| (AndroidVersion.SDK_INT < AndroidVersionCode.TIRAMISU
				&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')))
			CoolUtil.showPopUp(Language.getPhrase('permissions_message', 'If you accepted the permissions you are all good!\nIf you didn\'t then expect a crash\nPress OK to see what happens'),
				Language.getPhrase('mobile_notice', "Notice!"));

		// Create main storage directory
		try
		{
			var mainDir = StorageUtil.getStorageDirectory();
			if (!FileSystem.exists(mainDir))
				FileSystem.createDirectory(mainDir);
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game', [StorageUtil.getStorageDirectory()]), Language.getPhrase('mobile_error', "Error!"));
			LimeSystem.exit(1);
		}

		// Create mods directory in public external storage
		try
		{
			if (!FileSystem.exists(StorageUtil.getExternalStorageDirectory() + 'mods'))
				FileSystem.createDirectory(StorageUtil.getExternalStorageDirectory() + 'mods');
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game', [StorageUtil.getExternalStorageDirectory()]), Language.getPhrase('mobile_error', "Error!"));
			lime.system.System.exit(1);
		}

		// Create StepMania directory
		try
		{
			if (!FileSystem.exists(StorageUtil.getSMDirectory()))
				FileSystem.createDirectory(StorageUtil.getSMDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game', [StorageUtil.getSMDirectory()]), Language.getPhrase('mobile_error', "Error!"));
			LimeSystem.exit(1);
		}
	}

	public static function checkExternalPaths(?splitStorage = false):Array<String>
	{
		var process = new Process('grep -o "/storage/....-...." /proc/mounts | paste -sd \',\'');
		var paths:String = process.stdout.readAll().toString();
		if (splitStorage)
			paths = paths.replace('/storage/', '');
		return paths.split(',');
	}

	public static function getExternalDirectory(externalDir:String):String
	{
		var daPath:String = '';
		for (path in checkExternalPaths())
			if (path.contains(externalDir))
				daPath = path;

		daPath = Path.addTrailingSlash(daPath.endsWith("\n") ? daPath.substr(0, daPath.length - 1) : daPath);
		return daPath;
	}

	/**
	 * Best-effort migration when switching storage types.
	 * Copies game data (saves, logs, assets) from old storage to new storage.
	 * Mods and modsList.txt are NOT migrated as they remain in public storage.
	 */
	public static function migrateStorage(oldType:String, newType:String):Void
	{
		if (oldType == null || newType == null || oldType == newType) return;

		var oldRoot = haxe.io.Path.addTrailingSlash(getStoragePathForType(oldType));
		var newRoot = haxe.io.Path.addTrailingSlash(getStoragePathForType(newType));
		if (oldRoot == newRoot) return;

		// Ensure target directory exists and is writable
		try
		{
			if (!FileSystem.exists(newRoot))
				FileSystem.createDirectory(newRoot);
			
			// Test write permission
			var testFile = newRoot + '.write_test';
			File.saveContent(testFile, 'test');
			FileSystem.deleteFile(testFile);
		}
		catch (e:Dynamic)
		{
			return;
		}

		// Migrate game data only (saves, logs, assets)
		// Mods and modsList.txt stay in /sdcard/.PlusEngine/ and are not migrated
		copyDirectoryIfExists(oldRoot + 'saves', newRoot + 'saves');
		copyDirectoryIfExists(oldRoot + 'logs', newRoot + 'logs');
		copyDirectoryIfExists(oldRoot + 'assets', newRoot + 'assets');

		// Cleanup old data to avoid duplicated storage usage and prevent filling up device storage
		deleteDirectoryIfExists(oldRoot + 'saves');
		deleteDirectoryIfExists(oldRoot + 'logs');
		deleteDirectoryIfExists(oldRoot + 'assets');
		
		// Try to delete the entire old root directory if it's now empty
		try
		{
			if (FileSystem.exists(oldRoot) && FileSystem.isDirectory(oldRoot))
			{
				var contents = FileSystem.readDirectory(oldRoot);
				// Only delete if empty or only contains hidden files
				if (contents.length == 0 || !Lambda.exists(contents, f -> !f.startsWith('.')))
				{
					deleteDirectoryIfExists(oldRoot);
					trace('[StorageUtil] Deleted old storage directory: ' + oldRoot);
				}
			}
		}
		catch (e:Dynamic)
		{
			trace('[StorageUtil] Could not delete old root directory: ' + e);
		}
	}

	static function copyFileIfExists(src:String, dst:String):Void
	{
		try
		{
			if (!FileSystem.exists(src) || FileSystem.isDirectory(src)) return;

			var dstDir = haxe.io.Path.directory(dst);
			if (dstDir != null && dstDir.length > 0 && !FileSystem.exists(dstDir))
				FileSystem.createDirectory(dstDir);

			sys.io.File.copy(src, dst);
		}
		catch (_:Dynamic) {}
	}

	static function copyDirectoryIfExists(srcDir:String, dstDir:String):Void
	{
		try
		{
			if (!FileSystem.exists(srcDir) || !FileSystem.isDirectory(srcDir)) return;
			if (!FileSystem.exists(dstDir)) FileSystem.createDirectory(dstDir);

			for (name in FileSystem.readDirectory(srcDir))
			{
				var src = haxe.io.Path.join([srcDir, name]);
				var dst = haxe.io.Path.join([dstDir, name]);
				if (FileSystem.isDirectory(src))
					copyDirectoryIfExists(src, dst);
				else
					copyFileIfExists(src, dst);
			}
		}
		catch (_:Dynamic) {}
	}

	static function deleteDirectoryIfExists(dir:String):Void
	{
		try
		{
			if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) return;
			for (name in FileSystem.readDirectory(dir))
			{
				var path = haxe.io.Path.join([dir, name]);
				if (FileSystem.isDirectory(path))
					deleteDirectoryIfExists(path);
				else
					FileSystem.deleteFile(path);
			}
			FileSystem.deleteDirectory(dir);
		}
		catch (_:Dynamic) {}
	}
	
	/**
	 * Returns an array of available storage types with their descriptions
	 */
	public static function getAvailableStorageTypes():Array<StorageTypeInfo>
	{
		return [
			{
				id: "EXTERNAL_DATA",
				name: "App Data (Recommended)",
				description: "Android/data/<package>/files/\nScoped storage, no special permissions needed.\nData cleared when app is uninstalled."
			},
			{
				id: "EXTERNAL",
				name: "Public Storage",
				description: "Stores in /sdcard/.PlusEngine/\nOnly requires file manager permission on Android 11+.\nRemains after uninstall, easily accessible with file manager. (Only on Android 11+)"
			},
			{
				id: "EXTERNAL_MEDIA",
				name: "Media Storage",
				description: "Android/media/<package>/files/\nSuitable for media files.\nData cleared when app is uninstalled."
			},
			{
				id: "EXTERNAL_OBB",
				name: "OBB Storage",
				description: "Android/obb/<package>/files/\nFor large expansion files and DLCs.\nData cleared when app is uninstalled."
			},
			{
				id: "EXTERNAL_GLOBAL",
				name: "Global App Data",
				description: "Android/data/<package>/files/\nSame as App Data (kept for compatibility).\nData cleared when app is uninstalled."
			}
		];
	}
	
	/**
	 * Gets the storage path for a specific storage type (useful for migration)
	 */
	public static function getStoragePathForType(storageType:String):String
	{
		switch(storageType)
		{
			case "EXTERNAL":
				return AndroidEnvironment.getExternalStorageDirectory() + '/.PlusEngine/';
				
			case "EXTERNAL_DATA":
				return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
				
			case "EXTERNAL_MEDIA":
				// Android/media/<package>/files/
				var externalFilesPath = AndroidContext.getExternalFilesDir();
				if (externalFilesPath != null && externalFilesPath.length > 0)
				{
					// Replace '/Android/data/' with '/Android/media/'
					var mediaPath = externalFilesPath.replace('/Android/data/', '/Android/media/');
					return haxe.io.Path.addTrailingSlash(mediaPath);
				}
				return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
				
			case "EXTERNAL_OBB":
				// Android/obb/<package>/
				return haxe.io.Path.addTrailingSlash(AndroidContext.getObbDir());
				
			case "EXTERNAL_GLOBAL":
				return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
				
			default:
				// Fallback to EXTERNAL_DATA
				return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
		}
	}
	
	/**
	 * Checks if storage type requires special permissions
	 */
	public static function requiresSpecialPermissions(storageType:String):Bool
	{
		return (AndroidVersion.SDK_INT == AndroidVersionCode.TIRAMISU) && 
			(storageType == "EXTERNAL" || storageType == "EXTERNAL_GLOBAL");
	}
	#end
	#end
}

typedef StorageTypeInfo = 
{
	var id:String;
	var name:String;
	var description:String;
}