package funkin.modding;

import openfl.utils.Assets;
import haxe.Json;

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
};

class Mods
{
	static public var currentModDirectory:String = '';
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	public static final ignorePublicRootFolders:Array<String> = ['mods', 'assets', 'saves', 'logs', 'sm', 'cache', 'backups'];

	private static var globalMods:Array<String> = [];
	#if android
	private static var lastStorageType:String = StorageUtil.getModsStorageType();
	#end

	public static function refreshStorageTypeContext():Bool
	{
		#if android
		var currentStorageType:String = StorageUtil.getModsStorageType();
		if (lastStorageType != currentStorageType)
		{
			lastStorageType = currentStorageType;
			updatedOnState = false;
			currentModDirectory = '';
			globalMods = [];
			return true;
		}
		#end
		return false;
	}

	static function safeExists(path:String):Bool
	{
		try
		{
			return FileSystem.exists(path);
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	static function safeIsDirectory(path:String):Bool
	{
		try
		{
			return FileSystem.isDirectory(path);
		}
		catch (_:Dynamic)
		{
			return false;
		}
	}

	static function safeReadDirectory(path:String):Array<String>
	{
		try
		{
			return Paths.readDirectory(path);
		}
		catch (e:Dynamic)
		{
			return [];
		}
	}

	static function isLegacyRootModFolder(path:String, folder:String):Bool
	{
		var folderLower:String = folder.toLowerCase();
		if (ignoreModFolders.contains(folderLower) || ignorePublicRootFolders.contains(folderLower))
			return false;

		var markers:Array<String> = [
			'pack.json',
			'pack.png',
			'pack-pixel.png',
			'data',
			'weeks',
			'songs',
			'images',
			'scripts',
			'stages',
			'music',
			'sounds'
		];
		for (marker in markers)
		{
			if (safeExists(path + '/' + marker))
				return true;
		}

		return false;
	}

	static function scanModsRoot(root:String, list:Array<String>, legacyRoot:Bool):Void
	{
		if (!safeExists(root) || !safeIsDirectory(root))
			return;

		for (folder in safeReadDirectory(root))
		{
			var path:String = root + folder;
			if (!safeIsDirectory(path) || list.contains(folder))
				continue;

			var folderLower:String = folder.toLowerCase();
			if (ignoreModFolders.contains(folderLower))
				continue;

			if (legacyRoot && !isLegacyRootModFolder(path, folder))
				continue;

			list.push(folder);
		}
	}

	inline public static function getGlobalMods()
		return globalMods;

	inline public static function pushGlobalMods() // prob a better way to do this but idc
	{
		globalMods = [];
		for (mod in parseList().enabled)
		{
			var pack:Dynamic = getPack(mod);
			if (pack != null && pack.runsGlobally)
				globalMods.push(mod);
		}
		return globalMods;
	}

	inline public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		refreshStorageTypeContext();
		for (modsRoot in Paths.getModsRootDirectories())
			scanModsRoot(modsRoot, list, false);
		for (legacyRoot in Paths.getLegacyModsRootDirectories())
			scanModsRoot(legacyRoot, list, true);
		#end
		return list;
	}

	inline public static function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null)
			defaultDirectory = Paths.getSharedPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/'))
			defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/'))
			defaultDirectory = 'assets/$defaultDirectory';

		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);

		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}

		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0)
					mergedList.push(value);
		}
		return mergedList;
	}

	inline public static function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		// Main folder - check filesystem first, then fall back to APK assets (needed on Android)
		var mainPath:String = path + fileToFind;
		if (FileSystem.exists(mainPath))
			foldersToCheck.push(mainPath);
		#if android
		else if (Lambda.exists(Assets.list(), f -> f.startsWith(mainPath)))
			foldersToCheck.push(mainPath);
		#end

		// Week folder
		if (Paths.currentLevel != null && Paths.currentLevel != path)
		{
			var pth:String = Paths.getFolderPath(fileToFind, Paths.currentLevel);
			if (!foldersToCheck.contains(pth) && FileSystem.exists(pth))
				foldersToCheck.push(pth);
		}

		#if MODS_ALLOWED
		if (mods)
		{
			// Global mods first
			for (mod in Mods.getGlobalMods())
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}

			// Then "PsychEngine/mods/" main folder
			var folder:String = Paths.mods(fileToFind);
			if (FileSystem.exists(folder) && !foldersToCheck.contains(folder))
				foldersToCheck.push(Paths.mods(fileToFind));

			// And lastly, the loaded mod's folder
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder))
					foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}

	public static function getPack(?folder:String = null):Dynamic
	{
		#if MODS_ALLOWED
		if (folder == null)
			folder = Mods.currentModDirectory;

		var path = Paths.mods(folder + '/pack.json');
		if (FileSystem.exists(path))
		{
			try
			{
				#if sys
				var rawJson:String = File.getContent(path);
				#else
				var rawJson:String = Assets.getText(path);
				#end
				if (rawJson != null && rawJson.length > 0)
					return tjson.TJSON.parse(rawJson);
			}
			catch (e:Dynamic)
			{
				trace(e);
			}
		}
		#end
		return null;
	}

	public static var updatedOnState:Bool = false;

	inline static function getModsListPath():String
		return #if android StorageUtil.getStoragePathForType(StorageUtil.getModsStorageType()) + #else Sys.getCwd() + #end

	'modsList.txt';
	inline static function getFallbackModsListPath():String
		return #if android StorageUtil.getStorageDirectory() + #else Sys.getCwd() + #end

	'modsList.txt';
	static function resolveModsListReadPath():String
	{
		#if android
		return getModsListPath();
		#else
		return getModsListPath();
		#end
	}

	inline public static function parseList():ModsList
	{
		refreshStorageTypeContext();
		if (!updatedOnState)
			updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};

		#if MODS_ALLOWED
		try
		{
			for (mod in CoolUtil.coolTextFile(resolveModsListReadPath()))
			{
				// trace('Mod: $mod');
				if (mod.trim().length < 1)
					continue;

				var dat = mod.split("|");
				list.all.push(dat[0]);
				if (dat[1] == "1")
					list.enabled.push(dat[0]);
				else
					list.disabled.push(dat[0]);
			}
		}
		catch (e)
		{
			trace(e);
		}
		#end
		return list;
	}

	private static function updateModList()
	{
		#if MODS_ALLOWED
		var discoveredMods:Array<String> = getModDirectories();

		// Find all that are already ordered
		var list:Array<Array<Dynamic>> = [];
		var added:Array<String> = [];
		try
		{
			for (mod in CoolUtil.coolTextFile(resolveModsListReadPath()))
			{
				var dat:Array<String> = mod.split("|");
				var folder:String = dat[0];
				if (folder.trim().length > 0
					&& FileSystem.exists(Paths.mods(folder))
					&& FileSystem.isDirectory(Paths.mods(folder))
					&& !added.contains(folder))
				{
					added.push(folder);
					list.push([folder, (dat[1] == "1")]);
				}
			}
		}
		catch (e)
		{
			trace(e);
		}

		// Scan for folders that aren't on modsList.txt yet
		for (folder in discoveredMods)
		{
			if (folder.trim().length > 0
				&& FileSystem.exists(Paths.mods(folder))
				&& FileSystem.isDirectory(Paths.mods(folder))
				&& !ignoreModFolders.contains(folder.toLowerCase())
				&& !added.contains(folder))
			{
				added.push(folder);
				list.push([folder, true]); // i like it false by default. -bb //Well, i like it True! -Shadow Mario (2022)
				// Shadow Mario (2023): What the fuck was bb thinking
			}
		}

		// Now save file
		var fileStr:String = '';
		for (values in list)
		{
			if (fileStr.length > 0)
				fileStr += '\n';
			fileStr += values[0] + '|' + (values[1] ? '1' : '0');
		}

		// Save modsList next to the public mods folder for compatibility.
		// If Android blocks the write, fall back to app-specific storage.
		try
		{
			File.saveContent(getModsListPath(), fileStr);
		}
		catch (_:Dynamic)
		{
			try
			{
				File.saveContent(getFallbackModsListPath(), fileStr);
			}
			catch (_:Dynamic)
			{
			}
		}
		updatedOnState = true;
		// trace('Saved modsList.txt');
		#end
	}

	public static function loadTopMod()
	{
		refreshStorageTypeContext();
		Mods.currentModDirectory = '';

		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if (list != null && list[0] != null)
			Mods.currentModDirectory = list[0];
		#end
	}
}
