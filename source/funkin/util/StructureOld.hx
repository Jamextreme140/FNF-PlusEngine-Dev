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
		'backend.ClientPrefs' => 'funkin.Preferences.ClientPrefs',
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
		
		// Options 
		'options.OptionsState' => 'funkin.ui.options.OptionsState',
		
		// ===== OLD Psych 0.6.3 (no namespace) =====
		'Conductor' => 'funkin.audio.Conductor',
		'ClientPrefs' => 'funkin.Preferences.ClientPrefs',
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
		'OptionsState' => 'funkin.ui.options.OptionsState'
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
		}
		
		return myClass;
	}
}