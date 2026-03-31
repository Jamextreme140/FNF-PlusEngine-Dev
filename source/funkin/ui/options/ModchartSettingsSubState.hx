package funkin.ui.options;

/**
 * Submenu for modcharting-related options.
 * Allows users to configure settings that affect modchart performance and quality.
 * Note: Modchart Manager is now automatically enabled when onInitModchart() function is detected.
 */
class ModchartSettingsSubState extends BaseOptionsMenu
{
	public function new()
	{
		// Is necesary add translate here?
		title = Language.getPhrase('modchart_menu', 'Modchart Settings');
		rpcTitle = 'Modchart Options Menu'; // for Discord Rich Presence

		// ========== CAMERA & RENDERING SECTION ==========
		
		// 3D Camera option
		var option:Option = new Option('Enable 3D Cameras',
			'If checked: Enables 3D camera transformations and depth effects.\nIf unchecked: Disables 3D features for better performance.',
			'camera3dEnabled',
			BOOL);
		addOption(option);

		// Z Scale option
		var option:Option = new Option('Z Axis Depth Scale',
			'Controls the perceived depth of 3D effects.\nHigher = More dramatic depth\nLower = Flatter appearance',
			'zScale',
			FLOAT);
		option.scrollSpeed = 10;
		option.minValue = 0.1;
		option.maxValue = 5.0;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		// ========== ARROW PATH RENDERING ==========
		
		// Render Arrow Paths option
		var option:Option = new Option('Render Arrow Paths',
			'If checked: Shows trajectory lines of arrows.\nWARNING: May impact performance significantly.',
			'renderArrowPaths',
			BOOL);
		addOption(option);

		// Styled Arrow Paths option
		var option:Option = new Option('Styled Arrow Paths',
			'Applies colors, transparency, and scaling to arrow paths.\nRequires "Render Arrow Paths" to be enabled.',
			'styledArrowPaths',
			BOOL);
		addOption(option);

		// ========== HOLD NOTE SETTINGS ==========
		
		// Optimize Holds option
		var option:Option = new Option('Optimize Hold Rendering',
			'Reduces hold note calculations for ~2x better performance.\nNOT recommended with complex modcharts (may cause visual glitches).',
			'optimizeHolds',
			BOOL);
		addOption(option);

		// Holds Behind Strum option
		var option:Option = new Option('Holds Behind Strums',
			'If checked: Sustains render behind strum line.\nIf unchecked: Sustains render above strum line.',
			'holdsBehindStrum',
			BOOL);
		addOption(option);

		// Hold End Scale option
		var option:Option = new Option('Hold End Scale',
			'Multiplier for the size of hold note tail caps.\n1.0 = Default size',
			'holdEndScale',
			FLOAT);
		option.scrollSpeed = 10;
		option.minValue = 0.1;
		option.maxValue = 3.0;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		// Prevent Scaled Hold End option
		var option:Option = new Option('Prevent Scaled Hold Ends',
			'Keeps hold ends at constant size regardless of modifiers.\nWARNING: Adds extra calculations, may reduce FPS with many holds.',
			'preventScaledHoldEnd',
			BOOL);
		addOption(option);

		// ========== PERFORMANCE & MODIFIERS ==========
		
		// Column Specific Modifiers option
		var option:Option = new Option('Column Specific Modifiers',
			'Allows modifiers to affect individual note lanes.\nDisabling improves performance by reducing per-lane calculations.',
			'columnSpecificModifiers',
			BOOL);
		addOption(option);

		super();
	}
}
