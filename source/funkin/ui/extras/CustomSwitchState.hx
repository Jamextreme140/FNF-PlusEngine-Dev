package extras;

// This Shit is Not Optimized 😭
class CustomSwitchState
{
    public static function switchMenus(StatePrefix:String, ?skipTrans:Bool = false, ?skipTransCustom:String = '')
	{
	    FunkinLua.FPSCounterText = null;
	    if (skipTransCustom == 'TransIn' || skipTrans) FlxTransitionableState.skipNextTransIn = true;
        if (skipTransCustom == 'TransOut' || skipTrans) FlxTransitionableState.skipNextTransOut = true;
        
        var CP = ClientPrefs.data;
        var switchState = MusicBeatState.switchState;

    	//OMG 😱 Rewrited?
    	switch (StatePrefix)
		{
		    case 'Freeplay':
		        if (CP.FreeplayStyle == 'NF') switchState(new FreeplayStateNF());
                else if (CP.FreeplayStyle == 'NovaFlare') switchState(new FreeplayStateNOVA());
                else switchState(new FreeplayState());
            case 'MainMenu':
                if (CP.MainMenuStyle == '0.6.3' || CP.MainMenuStyle == 'Extended') switchState(new MainMenuStateOld());
                else if (CP.MainMenuStyle == 'NovaFlare') switchState(new MainMenuStateNOVA());
                else switchState(new MainMenuState());
            case 'StoryMenu':
                switchState(new StoryMenuState());
            case 'Options':
                LoadingState.loadAndSwitchState(new options.OptionsState());
            case 'Credits':
                switchState(new CreditsState());
            case 'Title':
                switchState(new TitleState());
            case 'MasterEditor':
                switchState(new editors.MasterEditorMenu());
            case 'NoteOffset':
                switchState(new options.NoteOffsetState());
            case 'ModsMenu':
                switchState(new ModsMenuState());
            #if ACHIEVEMENTS_ALLOWED
            case 'AchievementsMenu':
                LoadingState.loadAndSwitchState(new AchievementsMenuState());
            #end
        }
      //}
	}
}