package;

import funkin.util.VersionUtil;
import funkin.util.UpdateManager;

/**
 * Unit tests for Version comparison and Update system
 * Run this to verify semantic versioning works correctly
 */
class TestVersionSystem
{
	public static function runTests():Void
	{
		trace("=== VERSION UTIL TESTS ===\n");
		
		testBasicComparison();
		testEdgeCases();
		testPreReleaseTags();
		testValidation();
		testFlexibleFormats(); // NEW: Test flexible version formats
		testComparisonStrings();
		
		trace("\n=== UPDATE MANAGER TESTS ===\n");
		
		testUpdateDetection();
		testPlatformDetection();
		
		trace("\n✅ ALL TESTS PASSED!");
	}
	
	// Test basic version comparison
	static function testBasicComparison():Void
	{
		trace("Testing basic version comparison...");
		
		// Less than
		assert(VersionUtil.isLessThan("1.2.3", "1.2.4"), "1.2.3 < 1.2.4");
		assert(VersionUtil.isLessThan("1.2.3", "1.3.0"), "1.2.3 < 1.3.0");
		assert(VersionUtil.isLessThan("1.2.3", "2.0.0"), "1.2.3 < 2.0.0");
		
		// Greater than
		assert(VersionUtil.isGreaterThan("1.2.4", "1.2.3"), "1.2.4 > 1.2.3");
		assert(VersionUtil.isGreaterThan("1.3.0", "1.2.9"), "1.3.0 > 1.2.9");
		assert(VersionUtil.isGreaterThan("2.0.0", "1.99.99"), "2.0.0 > 1.99.99");
		
		// Equal
		assert(VersionUtil.isEqual("1.2.3", "1.2.3"), "1.2.3 == 1.2.3");
		assert(VersionUtil.isEqual("0.0.0", "0.0.0"), "0.0.0 == 0.0.0");
		
		trace("✓ Basic comparison tests passed\n");
	}
	
	// Test edge cases
	static function testEdgeCases():Void
	{
		trace("Testing edge cases...");
		
		// Double digit versions
		assert(VersionUtil.isGreaterThan("1.10.0", "1.9.0"), "1.10.0 > 1.9.0");
		assert(VersionUtil.isGreaterThan("1.0.10", "1.0.9"), "1.0.10 > 1.0.9");
		assert(VersionUtil.isGreaterThan("10.0.0", "9.0.0"), "10.0.0 > 9.0.0");
		
		// Major version takes priority
		assert(VersionUtil.isGreaterThan("2.0.0", "1.99.99"), "2.0.0 > 1.99.99");
		assert(VersionUtil.isLessThan("1.99.99", "2.0.0"), "1.99.99 < 2.0.0");
		
		// Minor version takes priority over patch
		assert(VersionUtil.isGreaterThan("1.1.0", "1.0.99"), "1.1.0 > 1.0.99");
		
		trace("✓ Edge case tests passed\n");
	}
	
	// Test pre-release tags (should be ignored)
	static function testPreReleaseTags():Void
	{
		trace("Testing pre-release tag handling...");
		
		// Pre-release tags should be stripped for comparison
		assert(VersionUtil.isEqual("1.2.3-beta", "1.2.3-alpha"), "1.2.3-beta == 1.2.3-alpha (tags ignored)");
		assert(VersionUtil.isEqual("1.2.3-beta", "1.2.3"), "1.2.3-beta == 1.2.3 (tag ignored)");
		assert(VersionUtil.isLessThan("1.2.3-beta", "1.2.4-alpha"), "1.2.3-beta < 1.2.4-alpha");
		
		// Build metadata should also be stripped
		assert(VersionUtil.isEqual("1.2.3+build123", "1.2.3+build456"), "1.2.3+build123 == 1.2.3+build456");
		
		trace("✓ Pre-release tag tests passed\n");
	}
	
	// Test version validation
	static function testValidation():Void
	{
		trace("Testing version validation...");
		
		// Valid versions - Full format
		assert(VersionUtil.isValid("1.2.3"), "1.2.3 is valid");
		assert(VersionUtil.isValid("0.0.0"), "0.0.0 is valid");
		assert(VersionUtil.isValid("10.20.30"), "10.20.30 is valid");
		assert(VersionUtil.isValid("1.2.3-beta"), "1.2.3-beta is valid");
		assert(VersionUtil.isValid("1.2.3+build123"), "1.2.3+build123 is valid");
		
		// Valid versions - Flexible format (NEW!)
		assert(VersionUtil.isValid("1.2"), "1.2 is valid (major.minor)");
		assert(VersionUtil.isValid("1"), "1 is valid (major only)");
		assert(VersionUtil.isValid("0.5"), "0.5 is valid");
		assert(VersionUtil.isValid("2"), "2 is valid");
		assert(VersionUtil.isValid("1.2-beta"), "1.2-beta is valid");
		
		// Invalid versions
		assert(!VersionUtil.isValid("invalid"), "invalid is invalid");
		assert(!VersionUtil.isValid(""), "empty string is invalid");
		assert(!VersionUtil.isValid("v1.2.3"), "v1.2.3 is invalid (no 'v' prefix)");
		assert(!VersionUtil.isValid("1.2.3.4"), "1.2.3.4 is invalid (too many parts)");
		assert(!VersionUtil.isValid("a.b.c"), "a.b.c is invalid (not numbers)");
		
		trace("✓ Validation tests passed\n");
	}
	
	// Test flexible version formats
	static function testFlexibleFormats():Void
	{
		trace("Testing flexible version formats...");
		
		// Compare "1" with "1.0.0" - should be equal
		assert(VersionUtil.isEqual("1", "1.0.0"), "1 == 1.0.0");
		assert(VersionUtil.isEqual("1.2", "1.2.0"), "1.2 == 1.2.0");
		
		// Compare different flexible formats
		assert(VersionUtil.isLessThan("1", "2"), "1 < 2");
		assert(VersionUtil.isLessThan("1.2", "1.3"), "1.2 < 1.3");
		assert(VersionUtil.isLessThan("1", "1.0.1"), "1 < 1.0.1");
		
		// Mixed formats
		assert(VersionUtil.isGreaterThan("1.3", "1.2.5"), "1.3 > 1.2.5 (1.3.0 > 1.2.5)");
		assert(VersionUtil.isLessThan("1.2", "1.2.1"), "1.2 < 1.2.1 (1.2.0 < 1.2.1)");
		
		trace("✓ Flexible format tests passed\n");
	}
	
	// Test comparison strings
	static function testComparisonStrings():Void
	{
		trace("Testing comparison strings...");
		
		var result1 = VersionUtil.getComparisonString("1.2.3", "1.2.4");
		assert(result1.indexOf("older") > -1, "Should say 'older' when current < remote");
		
		var result2 = VersionUtil.getComparisonString("1.2.5", "1.2.4");
		assert(result2.indexOf("newer") > -1, "Should say 'newer' when current > remote");
		
		var result3 = VersionUtil.getComparisonString("1.2.3", "1.2.3");
		assert(result3.indexOf("Up to date") > -1, "Should say 'Up to date' when versions match");
		
		trace("✓ Comparison string tests passed\n");
	}
	
	// Test update detection logic
	static function testUpdateDetection():Void
	{
		trace("Testing update detection logic...");
		
		// Simulate different scenarios
		var testCases = [
			{current: "1.2.3", remote: "1.2.4", shouldUpdate: true, desc: "Patch update"},
			{current: "1.2.3", remote: "1.3.0", shouldUpdate: true, desc: "Minor update"},
			{current: "1.2.3", remote: "2.0.0", shouldUpdate: true, desc: "Major update"},
			{current: "1.2.3", remote: "1.2.3", shouldUpdate: false, desc: "Same version"},
			{current: "1.2.4", remote: "1.2.3", shouldUpdate: false, desc: "Newer local (dev build)"},
			{current: "1.10.0", remote: "1.9.0", shouldUpdate: false, desc: "Double digit comparison"},
		];
		
		for (test in testCases) {
			var shouldUpdate = VersionUtil.isLessThan(test.current, test.remote);
			assert(shouldUpdate == test.shouldUpdate, 
				'${test.desc}: current=${test.current} remote=${test.remote} shouldUpdate=${test.shouldUpdate}');
		}
		
		trace("✓ Update detection tests passed\n");
	}
	
	// Test platform detection
	static function testPlatformDetection():Void
	{
		trace("Testing platform detection...");
		
		var platform = UpdateManager.getPlatformName();
		assert(platform != null && platform != "Unknown Platform", "Should detect platform: " + platform);
		
		var downloadURL = UpdateManager.getDownloadURL();
		assert(downloadURL != null && downloadURL.length > 0, "Should have download URL: " + downloadURL);
		
		#if (windows || linux || mac)
		assert(UpdateManager.supportsAutoUpdate(), "Desktop platforms should support auto-update");
		#elseif android
		assert(!UpdateManager.supportsAutoUpdate(), "Android should not support auto-update (APK manual install)");
		#end
		
		trace("✓ Platform detection tests passed\n");
	}
	
	// Assert helper
	static function assert(condition:Bool, ?message:String):Void
	{
		if (!condition) {
			var error = "ASSERTION FAILED" + (message != null ? ": " + message : "");
			trace(error);
			throw error;
		}
	}
}
