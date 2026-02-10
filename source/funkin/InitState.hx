package funkin;

#if (HSCRIPT_ALLOWED && MODS_ALLOWED)
import funkin.modding.ModState;
#end
import funkin.modding.Mods;
import funkin.save.Highscore;
import funkin.ui.Language;
import lime.app.Application;
import flixel.FlxG;
import funkin.util.CoolUtil;
import funkin.ui.title.TitleState;

/**
 * InitialState - Decides which state to start with.
 * Loads mods first, then checks if the top mod has custom state scripts
 * and loads them; otherwise goes to the default TitleState.
 */
class InitialState extends MusicBeatState
{
	override function create()
	{
		// Initialize GlobalScript before anything else
		// This is the first state created, so FlxG.state now exists
		#if HSCRIPT_ALLOWED
		funkin.ui.MusicBeatState.initGlobalScript();
		#end
		
		super.create();
		
		Highscore.load();
		Language.reloadPhrases();

		// Apply preferences-dependent runtime settings.
		#if !html5
		FlxG.autoPause = ClientPrefs.data.autoPause;
		#end
		
		// Check if top mod has custom state scripts
		#if (HSCRIPT_ALLOWED && MODS_ALLOWED)
		if (ModState.hasScript('FlashingState')) {
			MusicBeatState.switchState(new ModState('FlashingState'));
			return;
		} else if (ModState.hasScript('TitleState')) {
			MusicBeatState.switchState(new ModState('TitleState'));
			return;
		}
		#end
		
		// No mod states found, use default TitleState
		MusicBeatState.switchState(new TitleState());
	}
}
