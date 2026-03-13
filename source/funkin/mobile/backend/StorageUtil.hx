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
		// Always use scoped storage (EXTERNAL_DATA): Android/data/<package>/files/
		// This is the recommended approach for modern Android versions
		return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
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
		// All files go to scoped storage (EXTERNAL_DATA)
		var folder:String;
		if (fileName == 'modsList.txt')
		{
			// modsList.txt goes to root of scoped storage
			#if android
			folder = getStorageDirectory();
			#else
			folder = Sys.getCwd();
			#end
		}
		else
		{
			// Other files go to scoped storage + saves/
			folder = #if android getStorageDirectory() + #else Sys.getCwd() + #end 'saves/';
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
			// Using scoped storage (EXTERNAL_DATA), no fallback needed
			// as this storage is always writable by the app
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
		// Request read permissions for accessing media files (images, audio, video)
		// Scoped storage doesn't require WRITE_EXTERNAL_STORAGE for app-specific directory
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions(['READ_MEDIA_IMAGES', 'READ_MEDIA_VIDEO', 'READ_MEDIA_AUDIO']);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE']);

		// No need for MANAGE_EXTERNAL_STORAGE with scoped storage
		// if (AndroidVersion.SDK_INT == AndroidVersionCode.TIRAMISU && !AndroidEnvironment.isExternalStorageManager())
		// 	AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

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

		// Create mods directory in scoped storage
		try
		{
			if (!FileSystem.exists(StorageUtil.getStorageDirectory() + 'mods'))
				FileSystem.createDirectory(StorageUtil.getStorageDirectory() + 'mods');
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game', [StorageUtil.getStorageDirectory()]), Language.getPhrase('mobile_error', "Error!"));
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
	 * Migration function kept for compatibility but disabled.
	 * Now using only scoped storage (EXTERNAL_DATA), so no migration needed.
	 */
	/*
	public static function migrateStorage(oldType:String, newType:String):Void
	{
		// Migration disabled - using only scoped storage
		return;
	}
	*/

	// Migration helper functions commented out - no longer needed with single storage type
	/*
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
	*/
	
	/**
	 * Storage type info - kept for compatibility but only EXTERNAL_DATA is used
	 */
	/*
	public static function getAvailableStorageTypes():Array<StorageTypeInfo>
	{
		return [
			{
				id: "EXTERNAL_DATA",
				name: "App Data (Scoped Storage)",
				description: "Android/data/<package>/files/\nScoped storage, no special permissions needed.\nData cleared when app is uninstalled."
			}
		];
	}
	*/
	
	/**
	 * Gets the storage path - now always returns EXTERNAL_DATA (scoped storage)
	 * Function kept for compatibility with existing code
	 */
	/*
	public static function getStoragePathForType(storageType:String):String
	{
		// Always return scoped storage path
		return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
	}
	*/
	
	/**
	 * Scoped storage (EXTERNAL_DATA) does not require special permissions
	 */
	/*
	public static function requiresSpecialPermissions(storageType:String):Bool
	{
		// Scoped storage doesn't need special permissions
		return false;
	}
	*/
	#end
	#end
}

typedef StorageTypeInfo = 
{
	var id:String;
	var name:String;
	var description:String;
}