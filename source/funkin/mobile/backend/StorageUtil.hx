package funkin.mobile.backend;

import lime.system.System as LimeSystem;
import haxe.io.Path;
import haxe.Exception;
#if android
import funkin.external.android.JNIUtil;
#end

using Lambda;

/**
 * A storage class for mobile.
 * @author Karim Akra and Homura Akemi (HomuHomu833)
 */
class StorageUtil
{
	#if sys
	#if android
	public static inline var STORAGE_TYPE_SCOPED:String = 'EXTERNAL_DATA';
	public static inline var STORAGE_TYPE_EXTERNAL:String = 'EXTERNAL';
	private static inline var PUBLIC_PLUS_ENGINE_DIR:String = '/sdcard/.PlusEngine/';
	private static var getExternalStoragePathJNI:Null<Dynamic> = null;
	private static var cachedPublicStorageDirectory:Null<String> = null;
	#end

	public static function getStorageDirectory():String
	{
		#if android
		// Always use scoped storage (EXTERNAL_DATA): Android/data/<package>/files/
		// This is the recommended approach for modern Android versions
		return haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
		#elseif ios
		return Path.addTrailingSlash(LimeSystem.documentsDirectory);
		#else
		return Sys.getCwd();
		#end
	}

	#if android
	public static function getPublicStorageDirectory():String
	{
		if (cachedPublicStorageDirectory != null)
			return cachedPublicStorageDirectory;

		var storageRoot:String = null;
		if (getExternalStoragePathJNI == null)
			getExternalStoragePathJNI = JNIUtil.createStaticMethod('com/leninasto/plusengine/PlusEngineExtension', 'getExternalStoragePath',
				'()Ljava/lang/String;');

		if (getExternalStoragePathJNI != null)
		{
			try
			{
				storageRoot = cast getExternalStoragePathJNI();
			}
			catch (e:Dynamic)
			{
			}
		}

		if (storageRoot == null || storageRoot.length == 0)
			storageRoot = Path.directory(PUBLIC_PLUS_ENGINE_DIR.substr(0, PUBLIC_PLUS_ENGINE_DIR.length - 1));

		cachedPublicStorageDirectory = Path.addTrailingSlash(storageRoot);
		return cachedPublicStorageDirectory;
	}

	public static inline function getPublicPlusEngineDirectory():String
		return PUBLIC_PLUS_ENGINE_DIR;

	public static inline function getPublicModsDirectory():String
		return getPublicPlusEngineDirectory() + 'mods/';

	public static function getPublicStorageDirectoryCandidates():Array<String>
	{
		var candidates:Array<String> = [];

		function pushUnique(path:String):Void
		{
			if (path == null || path.length == 0)
				return;

			var normalized:String = Path.addTrailingSlash(path.replace('\\', '/'));
			if (!candidates.contains(normalized))
				candidates.push(normalized);
		}

		pushUnique(getPublicStorageDirectory());
		pushUnique('/storage/emulated/0');
		pushUnique('/sdcard');

		return candidates;
	}

	public static function getPublicModsDirectoryCandidates():Array<String>
	{
		var candidates:Array<String> = [];
		for (storageRoot in getPublicStorageDirectoryCandidates())
		{
			var modsRoot:String = storageRoot + '.PlusEngine/mods/';
			if (!candidates.contains(modsRoot))
				candidates.push(modsRoot);
		}
		return candidates;
	}
	#end

	public static function getSMDirectory():String // Use scoped storage for StepMania files: Android/data/<package>/files/sm/
		return #if android getStorageDirectory() + 'sm/' #else './sm/' #end;

	#if android
	public static function normalizeModsStorageType(storageType:String):String
	{
		return switch (storageType)
		{
			case STORAGE_TYPE_EXTERNAL: STORAGE_TYPE_EXTERNAL;
			default: STORAGE_TYPE_SCOPED;
		}
	}

	public static function getModsStorageType():String
		return normalizeModsStorageType(ClientPrefs.data.storageType);

	public static inline function useScopedModsStorage():Bool
		return getModsStorageType() == STORAGE_TYPE_SCOPED;

	public static inline function useExternalModsStorage():Bool
		return getModsStorageType() == STORAGE_TYPE_EXTERNAL;
	#end

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
			folder = #if android getStorageDirectory() + #else Sys.getCwd() + #end
			'saves/';
		}

		try
		{
			if (!FileSystem.exists(folder))
				FileSystem.createDirectory(folder);

			File.saveContent(folder + fileName, fileData);
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_success', '{1} has been saved.', [fileName]),
					Language.getPhrase('mobile_success', "Success!"));
		}
		catch (e:Dynamic)
		{
			// Using scoped storage (EXTERNAL_DATA), no fallback needed
			// as this storage is always writable by the app
			if (alert)
				CoolUtil.showPopUp(Language.getPhrase('file_save_fail', '{1} couldn\'t be saved.\n({2})', [fileName, Std.string(e)]),
					Language.getPhrase('mobile_error', "Error!"));
		}
	}

	#if android
	/**
	 * @deprecated Kept for compatibility with older mobile codepaths.
	 * Returns the public Plus Engine root: /sdcard/.PlusEngine/
	 */
	public static function getExternalStorageDirectory():String
		return getPublicPlusEngineDirectory();

	public static function requestPermissions():Void
	{
		// Request read permissions for accessing media files (images, audio, video)
		if (AndroidVersion.SDK_INT >= AndroidVersionCode.TIRAMISU)
			AndroidPermissions.requestPermissions([
				'READ_MEDIA_IMAGES',
				'READ_MEDIA_VIDEO',
				'READ_MEDIA_AUDIO',
				'READ_MEDIA_VISUAL_USER_SELECTED'
			]);
		else
			AndroidPermissions.requestPermissions(['READ_EXTERNAL_STORAGE', 'WRITE_EXTERNAL_STORAGE']);

		// Public mod folders require broad file access on Android 11+.
		if (requiresSpecialPermissions(getModsStorageType()) && !AndroidEnvironment.isExternalStorageManager())
			AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');

		// Create main storage directory
		try
		{
			var mainDir = StorageUtil.getStorageDirectory();
			if (!FileSystem.exists(mainDir))
				FileSystem.createDirectory(mainDir);
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game',
				[StorageUtil.getStorageDirectory()]),
				Language.getPhrase('mobile_error', "Error!"));
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
			CoolUtil.showPopUp(Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game',
				[StorageUtil.getStorageDirectory()]),
				Language.getPhrase('mobile_error', "Error!"));
			lime.system.System.exit(1);
		}

		// Create public Plus Engine directories for shared mods when permissions allow it.
		try
		{
			if (!FileSystem.exists(StorageUtil.getPublicPlusEngineDirectory()))
				FileSystem.createDirectory(StorageUtil.getPublicPlusEngineDirectory());
			if (!FileSystem.exists(StorageUtil.getPublicModsDirectory()))
				FileSystem.createDirectory(StorageUtil.getPublicModsDirectory());
		}
		catch (e:Dynamic)
		{
		}

		// Create StepMania directory
		try
		{
			if (!FileSystem.exists(StorageUtil.getSMDirectory()))
				FileSystem.createDirectory(StorageUtil.getSMDirectory());
		}
		catch (e:Dynamic)
		{
			CoolUtil.showPopUp(Language.getPhrase('create_directory_error', 'Please create directory to\n{1}\nPress OK to close the game',
				[StorageUtil.getSMDirectory()]),
				Language.getPhrase('mobile_error', "Error!"));
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
	public static function getAvailableStorageTypes():Array<StorageTypeInfo>
	{
		return [
			{
				id: STORAGE_TYPE_SCOPED,
				name: 'Scoped Storage',
				description: 'Android/data/<package>/files/mods/\nRecommended default. No all-files access required.'
			},
			{
				id: STORAGE_TYPE_EXTERNAL,
				name: 'External Shared Storage',
				description: '/sdcard/.PlusEngine/mods/\nEasier to access from file managers, but may require full file access on Android 11+.'
			}
		];
	}

	public static function getStoragePathForType(storageType:String):String
	{
		return switch (normalizeModsStorageType(storageType))
		{
			case STORAGE_TYPE_EXTERNAL: getPublicPlusEngineDirectory();
			default: haxe.io.Path.addTrailingSlash(AndroidContext.getExternalFilesDir());
		}
	}

	public static function requiresSpecialPermissions(storageType:String):Bool
	{
		return normalizeModsStorageType(storageType) == STORAGE_TYPE_EXTERNAL && AndroidVersion.SDK_INT >= AndroidVersionCode.R;
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
