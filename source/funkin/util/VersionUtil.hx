package funkin.util;

/**
 * Semantic Version comparison utility
 * Supports version formats like: "1.2.3", "0.5.0", "2.0.0-beta", etc.
 * 
 * Based on Semantic Versioning 2.0.0 (semver.org)
 */
class VersionUtil
{
	/**
	 * Compares two semantic version strings
	 * @param version1 First version (e.g., "1.2.3")
	 * @param version2 Second version (e.g., "1.2.4")
	 * @return -1 if version1 < version2, 0 if equal, 1 if version1 > version2
	 */
	public static function compare(version1:String, version2:String):Int
	{
		if (version1 == null || version2 == null)
			return 0;

		version1 = version1.trim();
		version2 = version2.trim();

		if (version1 == version2)
			return 0;

		var v1Parts = parseVersion(version1);
		var v2Parts = parseVersion(version2);

		// Compare major version
		if (v1Parts.major < v2Parts.major)
			return -1;
		if (v1Parts.major > v2Parts.major)
			return 1;

		// Compare minor version
		if (v1Parts.minor < v2Parts.minor)
			return -1;
		if (v1Parts.minor > v2Parts.minor)
			return 1;

		// Compare patch version
		if (v1Parts.patch < v2Parts.patch)
			return -1;
		if (v1Parts.patch > v2Parts.patch)
			return 1;

		// Versions are equal
		return 0;
	}

	/**
	 * Checks if version1 is less than version2
	 * @param version1 First version
	 * @param version2 Second version
	 * @return True if version1 < version2
	 */
	public static function isLessThan(version1:String, version2:String):Bool
	{
		return compare(version1, version2) == -1;
	}

	/**
	 * Checks if version1 is greater than version2
	 * @param version1 First version
	 * @param version2 Second version
	 * @return True if version1 > version2
	 */
	public static function isGreaterThan(version1:String, version2:String):Bool
	{
		return compare(version1, version2) == 1;
	}

	/**
	 * Checks if version1 is equal to version2
	 * @param version1 First version
	 * @param version2 Second version
	 * @return True if versions are equal
	 */
	public static function isEqual(version1:String, version2:String):Bool
	{
		return compare(version1, version2) == 0;
	}

	/**
	 * Checks if version1 is less than or equal to version2
	 * @param version1 First version
	 * @param version2 Second version
	 * @return True if version1 <= version2
	 */
	public static function isLessThanOrEqual(version1:String, version2:String):Bool
	{
		var result = compare(version1, version2);
		return result == -1 || result == 0;
	}

	/**
	 * Checks if version1 is greater than or equal to version2
	 * @param version1 First version
	 * @param version2 Second version
	 * @return True if version1 >= version2
	 */
	public static function isGreaterThanOrEqual(version1:String, version2:String):Bool
	{
		var result = compare(version1, version2);
		return result == 1 || result == 0;
	}

	/**
	 * Parses a version string into major, minor, and patch components
	 * Handles flexible formats:
	 * - "1" → {major:1, minor:0, patch:0}
	 * - "1.2" → {major:1, minor:2, patch:0}
	 * - "1.2.3" → {major:1, minor:2, patch:3}
	 * - "1.2.3-beta" → {major:1, minor:2, patch:3} (tags ignored)
	 * 
	 * @param version Version string (e.g., "1.2.3", "1.2", "1", or "1.2.3-beta")
	 * @return Version structure with major, minor, patch
	 */
	private static function parseVersion(version:String):Version
	{
		// Remove any pre-release tags (e.g., "-beta", "-alpha")
		var cleaned = version.split('-')[0];
		cleaned = cleaned.split('+')[0]; // Also remove build metadata
		cleaned = normalizeDisplaySuffix(cleaned); // Remove display-only suffixes like " (Build 500)"

		var parts:Array<String> = cleaned.split('.');

		var major:Int = 0;
		var minor:Int = 0;
		var patch:Int = 0;

		// Parse major (always present)
		if (parts.length > 0)
			major = Std.parseInt(parts[0]) ?? 0;

		// Parse minor (optional)
		if (parts.length > 1)
			minor = Std.parseInt(parts[1]) ?? 0;

		// Parse patch (optional)
		if (parts.length > 2)
			patch = Std.parseInt(parts[2]) ?? 0;

		return {
			major: major,
			minor: minor,
			patch: patch
		};
	}

	/**
	 * Validates if a string is a valid semantic version
	 * Accepts flexible formats:
	 * - "1" (major only)
	 * - "1.2" (major.minor)
	 * - "1.2.3" (major.minor.patch - full semver)
	 * - "1.2.3-beta" (with pre-release tag)
	 * - "1.2.3+build123" (with build metadata)
	 * 
	 * @param version Version string to validate
	 * @return True if valid version format
	 */
	public static function isValid(version:String):Bool
	{
		if (version == null || version.trim() == "")
			return false;

		var cleaned = normalizeDisplaySuffix(version.trim());

		// Flexible regex for versioning
		// Accepts: "1", "1.2", "1.2.3", "1.2.3-beta", "1.2.3+build"
		var regex:EReg = ~/^(\d+)(?:\.(\d+))?(?:\.(\d+))?(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/;
		return regex.match(cleaned);
	}

	/**
	 * Removes display-only suffixes from versions.
	 * Example: "1.2.5 (Build 500)" -> "1.2.5"
	 */
	private static function normalizeDisplaySuffix(version:String):String
	{
		if (version == null)
			return "";

		var trimmed = version.trim();
		var regex:EReg = ~/\s*\([^\)]*\)\s*$/;
		if (regex.match(trimmed))
			return regex.matchedLeft().trim();

		return trimmed;
	}

	/**
	 * Gets a human-readable comparison string
	 * @param currentVersion Current version
	 * @param remoteVersion Remote version
	 * @return String like "1.2.3 is older than 1.2.4" or "Up to date!"
	 */
	public static function getComparisonString(currentVersion:String, remoteVersion:String):String
	{
		var result = compare(currentVersion, remoteVersion);

		if (result == -1)
			return '$currentVersion is older than $remoteVersion';
		else if (result == 1)
			return '$currentVersion is newer than $remoteVersion';
		else
			return 'Up to date! (v$currentVersion)';
	}
}

/**
 * Version structure
 */
typedef Version =
{
	var major:Int;
	var minor:Int;
	var patch:Int;
}
