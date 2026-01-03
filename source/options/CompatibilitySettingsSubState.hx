package options;

class CompatibilitySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('compatibility_menu', 'Compatibility Settings');
		rpcTitle = 'Compatibility Settings Menu';

		// SScript Compatibility Option
		var option:Option = new Option('Use SScript for Psych 0.7.3 Mods',
			"If checked, uses SScript instead of hscript-iris for running Haxe code.\nEnable this if you're using mods from Psych Engine 0.6.x - 0.7.3\nthat have compatibility issues with hscript-iris. I can't guarantee that all Psych 0.7.3 mods will run well, sorry.",
			'useSScriptCompat',
			BOOL);
		addOption(option);

		// Legacy Memory Management Option
		option = new Option('Legacy Memory Management',
			"If checked, uses Psych 0.7.3 style memory management.\nDisables GPU texture disposal and uses simpler cleanup.\nEnable if old mods have memory-related crashes.",
			'legacyMemoryManagement',
			BOOL);
		addOption(option);

		// Legacy FileSystem Access Option
		option = new Option('Legacy FileSystem Access',
			"If checked, allows direct FileSystem.readDirectory access.\nEnable if old mods expect Psych 0.7.3 filesystem behavior.\nMay be needed for some custom mod loaders.",
			'legacyFileSystemAccess',
			BOOL);
		addOption(option);

		super();
	}
}

