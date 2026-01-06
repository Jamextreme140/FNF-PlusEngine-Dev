package states;

#if (HSCRIPT_ALLOWED && MODS_ALLOWED)
import backend.scripting.ModState;
#end

/**
 * InitialState - State that determines which state to actually start with
 * Checks if the top mod has custom state scripts and loads them, otherwise goes to default TitleState
 */
class InitialState extends MusicBeatState
{
	override function create()
	{
		super.create();
		
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
