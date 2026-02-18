package funkin.util;

import haxe.Http;
import funkin.ui.mainmenu.MainMenuState;

/**
 * Advanced Update Manager with semantic versioning
 * Supports multiple platforms and smart update detection
 * 
 * Only shows update notification if remote version is GREATER than current
 */
class UpdateManager
{
	/**
	 * Has an update available?
	 */
	public static var hasUpdate:Bool = false;

	/**
	 * Latest version available
	 */
	public static var latestVersion:String = "";

	/**
	 * Current engine version
	 */
	public static var currentVersion:String = "";

	/**
	 * Is checking for updates?
	 */
	public static var isChecking:Bool = false;

	/**
	 * Update check URL (GitHub raw)
	 */
	private static var updateURL:String = "https://raw.githubusercontent.com/Psych-Plus-Team/FNF-PlusEngine/refs/heads/main/gitVersion.txt";

	/**
	 * Changelog URL (GitHub raw)
	 */
	public static var changelogURL:String = "https://raw.githubusercontent.com/Psych-Plus-Team/FNF-PlusEngine/refs/heads/main/gitChangelog.txt";

	/**
	 * Release page URL
	 */
	public static var releaseURL:String = "https://github.com/Psych-Plus-Team/FNF-PlusEngine/releases";

	/**
	 * Base download URL
	 */
	private static var baseDownloadURL:String = "https://github.com/Psych-Plus-Team/FNF-PlusEngine/releases/download";

	/**
	 * Platform-specific download filenames
	 */
	private static var downloadFilenames:Map<String, String> = [
		"windows" => "PlusEngine-Windows.zip",
		"linux" => "PlusEngine-Linux.zip",
		"mac" => "PlusEngine-macOS.zip",
		"android" => "PlusEngine-Android.apk"
	];

	/**
	 * Callback to execute on main thread after check
	 */
	private static var updateCheckCallback:Void->Void = null;

	/**
	 * Check for updates with semantic version comparison
	 * Only triggers hasUpdate if remote version is GREATER than current
	 * 
	 * @param customURL Custom URL to check (optional)
	 * @param onComplete Callback when check is done
	 * @return Current version string
	 */
	public static function checkForUpdates(?customURL:String, ?onComplete:Void->Void):String
	{
		if (customURL != null && customURL.length > 0)
			updateURL = customURL;

		currentVersion = MainMenuState.plusEngineVersion.trim();
		hasUpdate = false;
		latestVersion = currentVersion;
		isChecking = true;

		if (!ClientPrefs.data.checkForUpdates)
		{
			trace('Update checking is disabled in settings');
			isChecking = false;
			if (onComplete != null)
				onComplete();
			return currentVersion;
		}

		trace('Checking for updates...');
		trace('Current version: $currentVersion (${getVersionType(currentVersion)})');

		#if sys
		// Run in separate thread for desktop platforms
		sys.thread.Thread.create(function()
		{
			performUpdateCheck(onComplete);
		});
		#else
		// Run synchronously for web/non-sys platforms
		performUpdateCheck(onComplete);
		#end

		return currentVersion;
	}

	/**
	 * Performs the actual HTTP request and version comparison
	 */
	private static function performUpdateCheck(?onComplete:Void->Void):Void
	{
		var http = new Http(updateURL);

		http.onData = function(data:String)
		{
			var remoteVersion:String = data.split('\n')[0].trim();
			trace('Remote version: $remoteVersion (${getVersionType(remoteVersion)})');

			// Validate version formats
			if (!VersionUtil.isValid(currentVersion))
			{
				trace('WARNING: Current version "$currentVersion" is not valid semantic version');
			}

			if (!VersionUtil.isValid(remoteVersion))
			{
				trace('WARNING: Remote version "$remoteVersion" is not valid semantic version');
			}

			// Use semantic version comparison
			if (VersionUtil.isLessThan(currentVersion, remoteVersion))
			{
				// Current version is OLDER than remote - update available!
				trace('Update available! $currentVersion -> $remoteVersion');
				hasUpdate = true;
				latestVersion = remoteVersion;
			}
			else if (VersionUtil.isEqual(currentVersion, remoteVersion))
			{
				// Versions match - up to date
				trace('Already up to date! (v$currentVersion)');
				hasUpdate = false;
				latestVersion = currentVersion;
			}
			else
			{
				// Current version is NEWER than remote (dev build?)
				trace('Your version is newer than latest release ($currentVersion > $remoteVersion)');
				hasUpdate = false;
				latestVersion = remoteVersion;
			}

			isChecking = false;
			http.onData = null;
			http.onError = null;
			http = null;

			// Store callback for main thread
			if (onComplete != null)
			{
				updateCheckCallback = onComplete;
			}
		};

		http.onError = function(error:String)
		{
			trace('Error checking for updates: $error');
			hasUpdate = false;
			isChecking = false;

			http.onData = null;
			http.onError = null;
			http = null;

			// Store callback for main thread
			if (onComplete != null)
			{
				updateCheckCallback = onComplete;
			}
		};

		http.request();
	}

	/**
	 * Detects the human-readable version type from a version string
	 * @param version Version string
	 * @return Version type label for logs
	 */
	private static function getVersionType(version:String):String
	{
		if (version == null)
			return "unknown";

		var normalized = version.trim().toLowerCase();
		if (normalized.length == 0)
			return "unknown";

		if (normalized.indexOf("beta") != -1)
			return "beta version";

		if (normalized.indexOf("build") != -1 || normalized.indexOf("developer") != -1 || normalized.indexOf("dev") != -1)
			return "developer build";

		return "stable release";
	}

	/**
	 * Call this in the update loop to execute callbacks on main thread
	 * Required for thread safety when using sys.thread
	 */
	public static function update():Void
	{
		if (updateCheckCallback != null)
		{
			var callback = updateCheckCallback;
			updateCheckCallback = null;
			callback();
		}
	}

	/**
	 * Gets the appropriate download URL for the current platform
	 * Builds URL dynamically: https://github.com/.../download/v1.2.5/PlusEngine-Windows.zip
	 * @return Download URL or release page if platform not found
	 */
	public static function getDownloadURL():String
	{
		var platform:String = getPlatformKey();
		var version:String = latestVersion.length > 0 ? latestVersion : currentVersion;

		if (downloadFilenames.exists(platform))
		{
			var filename:String = downloadFilenames.get(platform);
			// Build dynamic URL: .../download/1.2.5/PlusEngine-Windows.zip
			return '$baseDownloadURL/$version/$filename';
		}

		// Fallback to release page
		return releaseURL;
	}

	/**
	 * Opens the download page in browser
	 */
	public static function openDownloadPage():Void
	{
		var url = getDownloadURL();
		trace('Opening download page: $url');
		CoolUtil.browserLoad(url);
	}

	/**
	 * Gets the platform key for download URL mapping
	 * @return Platform key ("windows", "linux", "mac", "android", "ios")
	 */
	private static function getPlatformKey():String
	{
		#if windows
		return "windows";
		#elseif linux
		return "linux";
		#elseif mac
		return "mac";
		#elseif android
		return "android";
		#elseif ios
		return "ios";
		#else
		return "unknown";
		#end
	}

	/**
	 * Gets platform display name
	 * @return Human-readable platform name
	 */
	public static function getPlatformName():String
	{
		#if windows
		return "Windows";
		#elseif linux
		return "Linux";
		#elseif mac
		return "macOS";
		#elseif android
		return "Android";
		#elseif ios
		return "iOS";
		#else
		return "Unknown Platform";
		#end
	}

	/**
	 * Checks if auto-update is supported on this platform
	 * @return True if platform supports automatic updates
	 */
	public static function supportsAutoUpdate():Bool
	{
		#if (windows || linux || mac)
		// Desktop platforms can support auto-update with proper implementation
		return true;
		#elseif android
		// Android requires APK installation (manual for now)
		return false;
		#elseif ios
		// iOS requires App Store (not supported)
		return false;
		#else
		return false;
		#end
	}

	/**
	 * Gets update information as a formatted string
	 * @return Multi-line string with update info
	 */
	public static function getUpdateInfo():String
	{
		var info:String = "";

		info += 'Current Version: $currentVersion\n';
		info += 'Latest Version: $latestVersion\n';
		info += 'Platform: ${getPlatformName()}\n';

		if (hasUpdate)
		{
			info += 'Status: Update Available!\n';
			info += VersionUtil.getComparisonString(currentVersion, latestVersion);
		}
		else
		{
			info += 'Status: Up to date!';
		}

		return info;
	}

	/**
	 * Resets update check state
	 */
	public static function reset():Void
	{
		hasUpdate = false;
		latestVersion = "";
		currentVersion = "";
		isChecking = false;
		updateCheckCallback = null;
	}
}
