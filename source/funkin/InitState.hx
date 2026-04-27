package funkin;

#if (HSCRIPT_ALLOWED && MODS_ALLOWED && !mobile)
import funkin.modding.ScriptableState;
import funkin.modding.CustomState;
#end
import funkin.modding.Mods;
import funkin.save.Highscore;
import funkin.ui.Language;
import lime.app.Application;
import flixel.FlxG;
import funkin.util.CoolUtil;
import funkin.ui.FlashingState;
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
		funkin.ui.MusicBeatState.initMusicBeatStateScript();
		funkin.ui.MusicBeatSubstate.initMusicBeatSubstateScript();
		funkin.ui.transition.CustomFadeTransition.initCustomTransitionScript();
		#end
		
		super.create();
		
		Highscore.load();
		Language.reloadPhrases();

		// Apply preferences-dependent runtime settings.
		#if !html5
		FlxG.autoPause = ClientPrefs.data.autoPause;
		#end

		// ScriptableState.tryCreate checks mods then engine assets automatically.
		// CustomState is kept as a fallback for old flat-callback scripts.
		#if (HSCRIPT_ALLOWED && MODS_ALLOWED && !mobile)
		if (ScriptableState.overridesEnabled()) {
			var shouldAskFlashing = FlxG.save.data != null && FlxG.save.data.flashing == null && !FlashingState.leftState;
			if (shouldAskFlashing) {
				var flashingScript = ScriptableState.tryCreate('FlashingState', new FlashingState());
				if (flashingScript != null) {
					MusicBeatState.switchState(flashingScript);
					return;
				} else if (CustomState.hasScript('FlashingState')) {
					MusicBeatState.switchState(new CustomState('FlashingState'));
					return;
				}
			}

			var titleScript = ScriptableState.tryCreate('TitleState', new TitleState());
			if (titleScript != null) {
				MusicBeatState.switchState(titleScript);
				return;
			} else if (CustomState.hasScript('TitleState')) {
				MusicBeatState.switchState(new CustomState('TitleState'));
				return;
			}
		}
		#end

		// No mod states found, use default TitleState
		MusicBeatState.switchState(new TitleState());
	}
}
