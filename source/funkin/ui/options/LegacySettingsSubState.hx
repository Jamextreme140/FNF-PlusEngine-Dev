package funkin.ui.options;

class LegacySettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		title = Language.getPhrase('legacy_menu', 'Legacy Settings');
		rpcTitle = 'Legacy Settings Menu';

		// Legacy Memory Management Option
		var option = new Option('Legacy Memory Management',
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

		// Legacy Font Option
		option = new Option('Use Legacy Font',
			"If checked, uses the legacy VCR TTF font from Psych Engine 0.7.3 instead of Phantom.",
			'useLegacyFont',
			BOOL);
		addOption(option);

		// Legacy Shader Init Option
		option = new Option('Legacy Shader Init',
			"If checked, uses Psych 0.7.3 shader initialization system.\nUses glslVersion parameter and direct FlxRuntimeShader instead of\nErrorHandledRuntimeShader. Enable if old shader mods don't work.",
			'legacyShaderInit',
			BOOL);
		addOption(option);

		super();
	}
}

