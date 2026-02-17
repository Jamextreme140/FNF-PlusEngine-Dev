package funkin.util;

#if debug
/**
 * Test suite for backwards compatibility with old Psych Engine mods.
 * Run this to verify that old class paths are properly redirected.
 * 
 * Usage:
 * - Call `CompatibilityTest.runTests()` from InitState or Main during development
 * - Check console for results
 * - Any failed tests indicate missing aliases that should be added to StructureOld.hx
 */
class CompatibilityTest
{
	/**
	 * Test common Psych Engine class paths for compatibility
	 * @return Array of failed class names
	 */
	public static function runTests():Array<String>
	{
		var failed:Array<String> = [];
		
		// Test classes from different Psych Engine versions
		var testClasses:Array<String> = [
			// ===== Backend (0.7.3+) =====
			'backend.ClientPrefs',
			'backend.Conductor',
			'backend.Paths',
			'backend.Highscore',
			'backend.MusicBeatState',
			'backend.MusicBeatSubstate',
			'backend.Song',
			'backend.WeekData',
			'backend.Difficulty',
			'backend.Rating',
			'backend.Controls',
			'backend.Achievements',
			'backend.CoolUtil',
			'backend.Mods',
			'backend.BaseStage',
			'backend.StageData',
			'backend.Discord',
			'backend.DiscordClient',
			
			// ===== States (0.7.3+) =====
			'states.PlayState',
			'states.MainMenuState',
			'states.FreeplayState',
			'states.StoryMenuState',
			'states.TitleState',
			'states.LoadingState',
			'states.CreditsState',
			'states.ModsMenuState',
			
			// ===== Editor States (0.7.3+) =====
			'states.editors.CharacterEditorState',
			'states.editors.ChartingState',
			'states.editors.MasterEditorMenu',
			'states.editors.NoteSplashEditorState',
			'states.editors.StageEditorState',
			'states.editors.WeekEditorState',
			'states.editors.MenuCharacterEditorState',
			
			// ===== Objects (0.7.3+) =====
			'objects.Alphabet',
			'objects.Character',
			'objects.Note',
			'objects.NoteSplash',
			'objects.StrumNote',
			'objects.HealthIcon',
			'objects.BGSprite',
			'objects.AttachedSprite',
			'objects.AttachedText',
			'objects.MenuCharacter',
			
			// ===== Substates (0.7.3+) =====
			'substates.GameOverSubstate',
			'substates.PauseSubState',
			'substates.CustomSubstate',
			'substates.GameplayChangersSubstate',
			'substates.ResultsScreen',
			
			// ===== Options (0.7.3+) =====
			'options.OptionsState',
			'options.NotesColorSubState',
			'options.NoteOffsetState',
			'options.VisualsSettingsSubState',
			'options.GraphicsSettingsSubState',
			'options.GameplaySettingsSubState',
			
			// ===== PsychLua (0.7.3+) =====
			'psychlua.LuaUtils',
			
			// ===== No namespace (0.6.3) =====
			'ClientPrefs',
			'Conductor',
			'Paths',
			'PlayState',
			'Character',
			'Note',
			'Alphabet',
			'MusicBeatState',
			'Highscore',
			'Song',
			'WeekData',
			'Difficulty',
			'Controls',
			'Achievements',
			'MainMenuState',
			'FreeplayState',
			'StoryMenuState',
			'TitleState',
			'LoadingState',
			'CreditsState',
			'CharacterEditorState',
			'ChartingState',
			'MasterEditorMenu',
			'NoteSplashEditorState',
			'StageEditorState',
			'WeekEditorState',
			'MenuCharacterEditorState',
			'NoteSplash',
			'StrumNote',
			'HealthIcon',
			'BGSprite',
			'AttachedSprite',
			'AttachedText',
			'MenuCharacter',
			'GameOverSubstate',
			'PauseSubState',
			'CustomSubstate',
			'GameplayChangersSubstate',
			'ResultsScreen',
			'OptionsState',
			'NotesColorSubState',
			'NoteOffsetState',
			'VisualsSettingsSubState',
			'GraphicsSettingsSubState',
			'GameplaySettingsSubState'
		];
		
		trace('\n===== COMPATIBILITY TEST START =====\n');
		
		var passed = 0;
		var totalTests = testClasses.length;
		
		for (className in testClasses)
		{
			var resolved = StructureOld.resolveClass(className);
			if (resolved == null)
			{
				failed.push(className);
				trace('[❌ FAIL] $className');
			}
			else
			{
				passed++;
				// Only show passed in verbose mode to reduce spam
				// trace('[✅ PASS] $className');
			}
		}
		
		trace('\n===== COMPATIBILITY TEST END =====');
		trace('Results: $passed/$totalTests passed (${failed.length} failed)');
		
		if (failed.length > 0)
		{
			trace('\n❌ FAILED CLASSES:');
			for (cls in failed)
				trace('  - $cls');
			trace('\nThese classes should be added to StructureOld.classAliasMap\n');
		}
		else
		{
			trace('\n✅ All compatibility tests passed!\n');
		}
		
		return failed;
	}
	
	/**
	 * Auto-run test on game startup (only in debug builds)
	 * Call this from InitState.hx or Main.hx
	 */
	public static function autoRun():Void
	{
		#if debug
		runTests();
		#end
	}
	
	/**
	 * Test a specific class path
	 * @param className The class path to test
	 * @return True if class resolves successfully
	 */
	public static function testSingleClass(className:String):Bool
	{
		var resolved = StructureOld.resolveClass(className);
		var result = (resolved != null);
		
		if (result)
			trace('[✅ PASS] $className → ${Type.getClassName(resolved)}');
		else
			trace('[❌ FAIL] $className (not found)');
			
		return result;
	}
	
	/**
	 * Get statistics about compatibility usage
	 * Useful for analytics to see which old paths are still being used
	 */
	public static function getUsageStats():String
	{
		var stats = 'Compatibility Statistics:\n';
		stats += '  Total Aliases: ${StructureOld.classAliasMap.keys().length}\n';
		
		#if debug
		var warnings = StructureOld.getWarningLog();
		stats += '  Failed Lookups: ${warnings.length}\n';
		if (warnings.length > 0) {
			stats += '\nFailed Classes:\n';
			for (cls in warnings) {
				stats += '  - $cls\n';
			}
		}
		#end
		
		return stats;
	}
}
#else
/**
 * Empty implementation for release builds
 */
class CompatibilityTest
{
	public static function runTests():Array<String> { return []; }
	public static function autoRun():Void {}
	public static function testSingleClass(className:String):Bool { return true; }
	public static function getUsageStats():String { return ''; }
}
#end
