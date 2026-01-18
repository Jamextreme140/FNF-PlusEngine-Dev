package states;

#if (HSCRIPT_ALLOWED && MODS_ALLOWED)
import states.ModState;
#end
import backend.Mods;
import backend.ClientPrefs;
import backend.Highscore;
import backend.Language;
import lime.app.Application;
import flixel.FlxG;
import backend.CoolUtil;

/**
 * InitialState - Decides which state to start with.
 * Loads mods first, then checks if the top mod has custom state scripts
 * and loads them; otherwise goes to the default TitleState.
 */
class InitialState extends MusicBeatState
{
	override function create()
	{
		super.create();
		
		ClientPrefs.loadPrefs();
		Highscore.load();
		Language.reloadPhrases();
		MobileData.init();

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
