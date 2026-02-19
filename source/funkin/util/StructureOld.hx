package funkin.util;

/**
 * Compatibility mapping for old Psych Engine class paths.
 * This allows old mods to work without modification by redirecting old class paths to new ones.
 * Supports Psych Engine 0.6.3 -> 0.7.3 -> 1.0.4 -> FNF PlusEngine
 */
class StructureOld
{
	/**
	 * Compatibility map for Psych Engine 0.6.3 and 0.7.3 - 1.0.4 -> FNF PlusEngine
	 * This allows old mods to work without modification by redirecting old class paths to new ones
	 */
	public static final classAliasMap:Map<String, String> = [
        // ===== OLD Psych 0.7.3 - 1.0.4  =====
		// backend
		'backend.Conductor' => 'funkin.audio.Conductor',
		'backend.ClientPrefs' => 'funkin.Preferences',
		'backend.Paths' => 'funkin.Paths',
		'backend.CoolUtil' => 'funkin.util.CoolUtil',
		'backend.Difficulty' => 'funkin.data.story.level.Difficulty',
		'backend.Mods' => 'funkin.data.Mods',
		'backend.Highscore' => 'funkin.save.Highscore',
		'backend.Achievements' => 'funkin.data.Achievements',
		'backend.MusicBeatState' => 'funkin.ui.MusicBeatState',
		'backend.MusicBeatSubstate' => 'funkin.ui.MusicBeatSubstate',
		'backend.BaseStage' => 'funkin.play.stage.Stage',
		'backend.StageData' => 'funkin.data.stage.StageData',
		'backend.WeekData' => 'funkin.data.story.level.WeekData',
		'backend.Song' => 'funkin.data.song.Song',
		'backend.Rating' => 'funkin.play.scoring.Rating',
		'backend.Controls' => 'funkin.input.Controls',
		'backend.Discord' => 'funkin.api.discord.Discord',
		'backend.DiscordClient' => 'funkin.api.discord.Discord',

		// psychlua
		'psychlua.LuaUtils' => 'funkin.modding.scripting.psychlua.LuaUtils',
		
		// States
		'states.PlayState' => 'funkin.play.PlayState',
		'states.MainMenuState' => 'funkin.ui.mainmenu.MainMenuState',
		'states.FreeplayState' => 'funkin.ui.freeplay.FreeplayState',
		'states.StoryMenuState' => 'funkin.ui.story.StoryMenuState',
		'states.TitleState' => 'funkin.ui.title.TitleState',
		'states.LoadingState' => 'funkin.ui.LoadingState',
		'states.CreditsState' => 'funkin.ui.credits.CreditsState',
		'states.ModsMenuState' => 'funkin.ui.mods.ModsMenuState',
		'states.editors.CharacterEditorState' => 'funkin.ui.debug.character.CharacterEditorState',
		'states.editors.ChartingState' => 'funkin.ui.debug.charting.ChartingState',
		'states.editors.MasterEditorMenu' => 'funkin.ui.debug.MasterEditorMenu',
		'states.editors.NoteSplashEditorState' => 'funkin.ui.debug.NoteSplashEditorState',
		'states.editors.StageEditorState' => 'funkin.ui.debug.stage.StageEditorState',
		'states.editors.WeekEditorState' => 'funkin.ui.debug.WeekEditorState',
		'states.editors.MenuCharacterEditorState' => 'funkin.ui.debug.MenuCharacterEditorState',
		
		// Objects
		'objects.Alphabet' => 'funkin.graphics.Alphabet',
		'objects.Character' => 'funkin.play.character.Character',
		'objects.Note' => 'funkin.play.notes.Note',
		'objects.NoteSplash' => 'funkin.play.notes.NoteSplash',
		'objects.StrumNote' => 'funkin.play.notes.StrumNote',
		'objects.HealthIcon' => 'funkin.play.components.HealthIcon',
		'objects.BGSprite' => 'funkin.play.stage.BGSprite',
		'objects.AttachedSprite' => 'funkin.graphics.AttachedSprite',
		'objects.AttachedText' => 'funkin.graphics.AttachedText',
		'objects.MenuCharacter' => 'funkin.ui.freeplay.charselect.MenuCharacter',
		
		// Substates
		'substates.GameOverSubstate' => 'funkin.play.substates.GameOverSubstate',
		'substates.PauseSubState' => 'funkin.play.substates.PauseSubState',
		'substates.CustomSubstate' => 'funkin.modding.scripting.psychlua.CustomSubstate',
		'substates.GameplayChangersSubstate' => 'funkin.ui.options.GameplayChangersSubstate',
		'substates.ResultsScreen' => 'funkin.play.ResultsState',
		
		// Options 
		'options.OptionsState' => 'funkin.ui.options.OptionsState',
		'options.GameplayChangersSubstate' => 'funkin.ui.options.GameplayChangersSubstate',
		'options.NotesColorSubState' => 'funkin.ui.options.NotesColorSubState',
		'options.NoteOffsetState' => 'funkin.ui.options.NoteOffsetState',
		'options.VisualsSettingsSubState' => 'funkin.ui.options.VisualsSettingsSubState',
		'options.GraphicsSettingsSubState' => 'funkin.ui.options.GraphicsSettingsSubState',
		'options.GameplaySettingsSubState' => 'funkin.ui.options.GameplaySettingsSubState',
		
		// ===== OLD Psych 0.6.3 (no namespace) =====
		'Conductor' => 'funkin.audio.Conductor',
		'ClientPrefs' => 'funkin.Preferences',
		'Paths' => 'funkin.Paths',
		'CoolUtil' => 'funkin.util.CoolUtil',
		'Difficulty' => 'funkin.data.story.level.Difficulty',
		'Mods' => 'funkin.data.Mods',
		'Highscore' => 'funkin.save.Highscore',
		'Achievements' => 'funkin.data.Achievements',
		'MusicBeatState' => 'funkin.ui.MusicBeatState',
		'MusicBeatSubstate' => 'funkin.ui.MusicBeatSubstate',
		'BaseStage' => 'funkin.play.stage.Stage',
		'StageData' => 'funkin.data.stage.StageData',
		'WeekData' => 'funkin.data.story.level.WeekData',
		'Song' => 'funkin.data.song.Song',
		'Rating' => 'funkin.play.scoring.Rating',
		'Controls' => 'funkin.input.Controls',
		'Discord' => 'funkin.api.discord.Discord',
		'DiscordClient' => 'funkin.api.discord.Discord',
		'PlayState' => 'funkin.play.PlayState',
		'MainMenuState' => 'funkin.ui.mainmenu.MainMenuState',
		'FreeplayState' => 'funkin.ui.freeplay.FreeplayState',
		'StoryMenuState' => 'funkin.ui.story.StoryMenuState',
		'TitleState' => 'funkin.ui.title.TitleState',
		'LoadingState' => 'funkin.ui.LoadingState',
		'CreditsState' => 'funkin.ui.credits.CreditsState',
		'ModsMenuState' => 'funkin.ui.mods.ModsMenuState',
		'CharacterEditorState' => 'funkin.ui.debug.character.CharacterEditorState',
		'ChartingState' => 'funkin.ui.debug.charting.ChartingState',
		'MasterEditorMenu' => 'funkin.ui.debug.MasterEditorMenu',
		'NoteSplashEditorState' => 'funkin.ui.debug.NoteSplashEditorState',
		'StageEditorState' => 'funkin.ui.debug.stage.StageEditorState',
		'WeekEditorState' => 'funkin.ui.debug.WeekEditorState',
		'MenuCharacterEditorState' => 'funkin.ui.debug.MenuCharacterEditorState',
		'Alphabet' => 'funkin.graphics.Alphabet',
		'Character' => 'funkin.play.character.Character',
		'Note' => 'funkin.play.notes.Note',
		'NoteSplash' => 'funkin.play.notes.NoteSplash',
		'StrumNote' => 'funkin.play.notes.StrumNote',
		'HealthIcon' => 'funkin.play.components.HealthIcon',
		'BGSprite' => 'funkin.play.stage.BGSprite',
		'AttachedSprite' => 'funkin.graphics.AttachedSprite',
		'AttachedText' => 'funkin.graphics.AttachedText',
		'MenuCharacter' => 'funkin.ui.freeplay.charselect.MenuCharacter',
		'GameOverSubstate' => 'funkin.play.substates.GameOverSubstate',
		'PauseSubState' => 'funkin.play.substates.PauseSubState',
		'CustomSubstate' => 'funkin.modding.scripting.psychlua.CustomSubstate',
		'GameplayChangersSubstate' => 'funkin.ui.options.GameplayChangersSubstate',
		'ResultsScreen' => 'funkin.play.ResultsState',
		'OptionsState' => 'funkin.ui.options.OptionsState',
		'NotesColorSubState' => 'funkin.ui.options.NotesColorSubState',
		'NoteOffsetState' => 'funkin.ui.options.NoteOffsetState',
		'VisualsSettingsSubState' => 'funkin.ui.options.VisualsSettingsSubState',
		'GraphicsSettingsSubState' => 'funkin.ui.options.GraphicsSettingsSubState',
		'GameplaySettingsSubState' => 'funkin.ui.options.GameplaySettingsSubState'
	];
	
	/**
	 * Resolves a class by name with backwards compatibility support.
	 * @param className The full class path to resolve
	 * @return The resolved class or null if not found
	 */
	public static function resolveClass(className:String):Class<Dynamic>
	{
		var myClass:Dynamic = Type.resolveClass(className);
		
		// If class not found, try aliases for backwards compatibility
		if (myClass == null && classAliasMap.exists(className))
		{
			var newClassName = classAliasMap.get(className);
			myClass = Type.resolveClass(newClassName);
			if (myClass != null)
			{
				#if debug
				trace('[Compatibility] Redirected "$className" to "$newClassName"');
				#end
			}
			else
			{
				// Alias exists but new class also not found - possible broken alias
				#if debug
				trace('[Compatibility] WARNING: Alias "$className" → "$newClassName" exists, but target class not found!');
				#end
			}
		}
		else if (myClass == null)
		{
			// Class not found and no alias exists
			#if debug
			if (!_warnedClasses.exists(className)) {
				trace('[Compatibility] WARNING: Class "$className" not found and no alias exists. This may break old mods.');
				trace('[Compatibility] If this is a common class, consider adding it to StructureOld.classAliasMap');
				_warnedClasses.set(className, true);
			}
			#end
		}
		
		return myClass;
	}
	
	#if debug
	// Track warned classes to avoid spam
	private static var _warnedClasses:Map<String, Bool> = new Map();
	
	/**
	 * Get list of all classes that failed to resolve (for debugging)
	 */
	public static function getWarningLog():Array<String>
	{
		var log:Array<String> = [];
		for (className in _warnedClasses.keys()) {
			log.push(className);
		}
		return log;
	}
	
	/**
	 * Clear warning log
	 */
	public static function clearWarningLog():Void
	{
		_warnedClasses.clear();
	}
	#end
}