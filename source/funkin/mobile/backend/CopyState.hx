package funkin.mobile.backend;

#if COPYSTATE_ALLOWED
import funkin.ui.title.TitleState;
import funkin.ui.Language;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets as OpenFLAssets;
import openfl.utils.ByteArray;
import haxe.io.Path;
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;
import lime.system.ThreadPool;

/**
 * ...
 * @author: Karim Akra
 */
class CopyState extends MusicBeatState
{
	private static final textFilesExtensions:Array<String> = ['ini', 'txt', 'xml', 'hxs', 'hx', 'lua', 'json', 'frag', 'vert'];
	public static final IGNORE_FOLDER_FILE_NAME:String = "CopyState-Ignore.txt";
	private static var directoriesToIgnore:Array<String> = [];
	public static var locatedFiles:Array<String> = [];
	public static var maxLoopTimes:Int = 0;

	public var loadingImage:FlxSprite;
	public var loadingBar:FlxBar;
	public var loadedText:FlxText;
	public var thread:ThreadPool;

	var failedFilesStack:Array<String> = [];
	var failedFiles:Array<String> = [];
	var shouldCopy:Bool = false;
	var canUpdate:Bool = true;
	var loopTimes:Int = 0;
	var currentFile:String = '';

	override function create()
	{
		// Load ClientPrefs and Language early for translations
		ClientPrefs.loadPrefs();
		
		// Auto-detect system language on first run
		#if (TRANSLATIONS_ALLOWED && mobile)
		if (FlxG.save.data.languageAutoDetected == null) {
			var detectedLang = Language.detectSystemLanguage();
			if (detectedLang != null && detectedLang != ClientPrefs.data.language) {
				ClientPrefs.data.language = detectedLang;
				FlxG.save.data.language = detectedLang;
			}
			FlxG.save.data.languageAutoDetected = true;
			FlxG.save.flush();
		}
		#end
		
		Language.reloadPhrases();
		funkin.graphics.shaders.ColorblindFilter.UpdateColors();
		
		#if android
		// Using scoped storage (EXTERNAL_DATA) - no special permissions needed
		// Scoped storage is always accessible by the app without additional permissions
		#end
		
		locatedFiles = [];
		maxLoopTimes = 0;
		checkExistingFiles();
		
		if (maxLoopTimes <= 0)
		{
			MusicBeatState.switchState(new TitleState());
			return;
		}

		var filesList:String = '';
		var maxFilesToShow:Int = 10;
		for (i in 0...Math.floor(Math.min(locatedFiles.length, maxFilesToShow)))
		{
			filesList += '\n- ' + locatedFiles[i];
		}
		if (locatedFiles.length > maxFilesToShow)
			filesList += '\n... and ${locatedFiles.length - maxFilesToShow} more files';
		
		CoolUtil.showPopUp(Language.getPhrase('files_missing', "Seems like you have some missing files that are necessary to run the game\nPress OK to begin the copy process") + '\n\nMissing files ($maxLoopTimes):' + filesList, Language.getPhrase('mobile_notice', 'Notice!'));

		shouldCopy = true;

		add(new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, 0xffcaff4d));

		loadingImage = new FlxSprite(0, 0, Paths.image('funkay'));
		loadingImage.setGraphicSize(0, FlxG.height);
		loadingImage.updateHitbox();
		loadingImage.screenCenter();
		add(loadingImage);

		loadingBar = new FlxBar(0, FlxG.height - 26, FlxBarFillDirection.LEFT_TO_RIGHT, FlxG.width, 26);
		loadingBar.setRange(0, maxLoopTimes);
		add(loadingBar);

		loadedText = new FlxText(loadingBar.x, loadingBar.y + 4, FlxG.width, '', 16);
		loadedText.setFormat(Paths.font("phantom.ttf"), 16, FlxColor.BLACK, CENTER);
		add(loadedText);

		thread = new ThreadPool(0, CoolUtil.getCPUThreadsCount());
		thread.doWork.add(function(poop)
		{
			for (file in locatedFiles)
			{
				currentFile = file;
				loopTimes++;
				copyAsset(file);
			}
		});
		new FlxTimer().start(0.5, (tmr) ->
		{
			thread.queue({});
		});

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (shouldCopy)
		{
			if (loopTimes >= maxLoopTimes && canUpdate)
			{
				if (failedFiles.length > 0)
				{
					CoolUtil.showPopUp(failedFiles.join('\n'), 'Failed To Copy ${failedFiles.length} File.');
					// Save error log to configured storage directory
					final folder:String = #if android StorageUtil.getStorageDirectory() + 'logs/' #else Sys.getCwd() + 'logs/' #end;
					try {
						if (!FileSystem.exists(folder))
							FileSystem.createDirectory(folder);
						File.saveContent(folder + Date.now().toString().replace(' ', '-').replace(':', "'") + '-CopyState' + '.txt', failedFilesStack.join('\n'));
					} catch (e:Dynamic) {
						trace('[CopyState] Could not save error log: ' + e);
					}
				}
				
				FlxG.sound.play(Paths.sound('confirmMenu')).onComplete = () ->
				{
					MusicBeatState.switchState(new TitleState());
				};
		
				canUpdate = false;
			}

			if (loopTimes >= maxLoopTimes)
				loadedText.text = "Completed!";
			else
			{
				var fileName:String = currentFile;
				if (fileName.length > 50)
					fileName = '...' + fileName.substr(fileName.length - 47);
				loadedText.text = '$loopTimes/$maxLoopTimes - $fileName';
			}

			loadingBar.percent = Math.min((loopTimes / maxLoopTimes) * 100, 100);
		}
		super.update(elapsed);
	}

	public function copyAsset(file:String)
	{
		if (!FileSystem.exists(file))
		{
			var directory = Path.directory(file);
			if (!FileSystem.exists(directory))
				FileSystem.createDirectory(directory);
			try
			{
				if (OpenFLAssets.exists(getFile(file)))
				{
					if (textFilesExtensions.contains(Path.extension(file)))
						createContentFromInternal(file);
					else
					{
						var path:String = '';
						#if android
						// All files go to scoped storage (EXTERNAL_DATA)
						path = StorageUtil.getStorageDirectory() + file;
						#else
						path = file;
						#end
						File.saveBytes(path, getFileBytes(getFile(file)));
					}		
				}
				else
				{
					failedFiles.push(getFile(file) + " (File Dosen't Exist)");
					failedFilesStack.push('Asset ${getFile(file)} does not exist.');
				}
			}
			catch (e:haxe.Exception)
			{
				failedFiles.push('${getFile(file)} (${e.message})');
				failedFilesStack.push('${getFile(file)} (${e.stack})');
			}
		}
	}

	public function createContentFromInternal(file:String)
	{
		var fileName = Path.withoutDirectory(file);
		var directory = Path.directory(file);
		#if android
		// All files go to scoped storage (EXTERNAL_DATA)
		directory = StorageUtil.getStorageDirectory() + directory;
		#end
		
		var fullPath = Path.join([directory, fileName]);
		
		try
		{
			// Use ByteArray for Android 14/15 compatibility instead of direct File.getContent
			var fileBytes:openfl.utils.ByteArray = null;
			try {
				fileBytes = OpenFLAssets.getBytes(getFile(file));
			} catch (e:Dynamic) {
				// Fallback to getText for text files
				var fileData:String = OpenFLAssets.getText(getFile(file));
				if (fileData == null)
					fileData = '';
				fileBytes = openfl.utils.ByteArray.fromBytes(haxe.io.Bytes.ofString(fileData));
			}
			
			if (fileBytes == null)
				throw 'Could not read asset data';
				
			if (!FileSystem.exists(directory))
			{
				FileSystem.createDirectory(directory);
			}
			
			// Use saveBytes instead of saveContent for better Android 14/15 compatibility
			File.saveBytes(fullPath, fileBytes);
		}
		catch (e:haxe.Exception)
		{
			failedFiles.push('${getFile(file)} (${e.message})');
			failedFilesStack.push('${getFile(file)} (${e.stack})');
		}
	}

	public function getFileBytes(file:String):ByteArray
	{
		switch (Path.extension(file).toLowerCase())
		{
			case 'otf' | 'ttf':
				return ByteArray.fromFile(file);
			default:
				return OpenFLAssets.getBytes(file);
		}
	}

	public static function getFile(file:String):String
	{
		if (OpenFLAssets.exists(file))
			return file;

		@:privateAccess
		for (library in LimeAssets.libraries.keys())
		{
			if (OpenFLAssets.exists('$library:$file') && library != 'default')
				return '$library:$file';
		}

		return file;
	}

	public static function checkExistingFiles():Bool
	{
		locatedFiles = OpenFLAssets.list();

		// removes unwanted assets
		var assets = locatedFiles.filter(folder -> folder.startsWith('assets/'));
		var mods = locatedFiles.filter(folder -> folder.startsWith('mods/'));
		locatedFiles = assets.concat(mods);
		
		#if android
		// Check if files exist in scoped storage (EXTERNAL_DATA)
		locatedFiles = locatedFiles.filter(file -> {
			try {
				// All files are checked in scoped storage
				return !FileSystem.exists(StorageUtil.getStorageDirectory() + file);
			} catch (e:Dynamic) {
				// If we can't access the file, assume it's missing
				trace('[CopyState] Could not check file: $file - ${e}');
				return true;
			}
		});
		#else
		locatedFiles = locatedFiles.filter(file -> !FileSystem.exists(file));
		#end
		


		var filesToRemove:Array<String> = [];

		for (file in locatedFiles)
		{
			if (filesToRemove.contains(file))
				continue;

			if(file.endsWith(IGNORE_FOLDER_FILE_NAME) && !directoriesToIgnore.contains(Path.directory(file)))
				directoriesToIgnore.push(Path.directory(file));

			if (directoriesToIgnore.length > 0)
			{
				for (directory in directoriesToIgnore)
				{
					if (file.startsWith(directory))
						filesToRemove.push(file);
				}
			}
		}

		locatedFiles = locatedFiles.filter(file -> !filesToRemove.contains(file));

		maxLoopTimes = locatedFiles.length;

		return (maxLoopTimes <= 0);
	}
}
#end
