package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3Test5State;
import funkin.ui.debug.MD3Test7State;
import funkin.ui.components.md3.*;
import funkin.ui.components.md3.MaterialButton.ButtonType;

/**
 * MD3 component debug viewer — Page 7/7: Live accent color theme switcher.
 * Tap any accent swatch to regenerate the full M3 palette; all components update instantly.
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3Test6State extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 6;
	static inline var TOTAL_PAGES:Int = 8;

	// Predefined accent colors from MD3Theme
	static var ACCENT_NAMES:Array<String> = ["Purple", "Teal", "Red", "Green", "Amber", "Indigo", "Pink"];
	static var ACCENT_COLORS:Array<Int> = [
		0xFF6750A4, // Purple
		0xFF006B5F, // Teal
		0xFFB3261E, // Red
		0xFF146C2E, // Green
		0xFFAA8000, // Amber
		0xFF3F51B5, // Indigo
		0xFF7D3255  // Pink
	];

	// Palette row labels and role accessors
	static var ROLE_LABELS:Array<String> = [
		"Primary", "On Primary", "Primary Cont.", "On P.Cont.",
		"Secondary", "On Secondary", "Sec. Cont.", "On Sec.Cont.",
		"Tertiary", "On Tertiary", "Tert. Cont.", "On T.Cont.",
		"Surface", "On Surface", "Surf. Var.", "On S.Var.",
		"Outline", "Outline Var.", "Inv. Surface", "Inv. Primary"
	];

	// Live demo components that respond to theme changes
	var demoButton:MaterialButton;
	var demoSwitch:MaterialSwitch;
	var demoChip:MaterialChip;
	var demoFAB:MaterialFAB;
	var demoProgress:MaterialProgressIndicator;

	// Palette swatches (updated on theme change)
	var swatches:Array<FlxSprite> = [];
	var swatchLabels:Array<FlxText> = [];

	// Active accent button highlight
	var accentHighlight:FlxSprite;
	var accentButtons:Array<FlxSprite> = [];
	var activeAccentIndex:Int = 0;

	override function create():Void
	{
		super.create();
		Cursor.show();

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0xFFFEF7FF);
		add(bg);

		buildAccentPicker();
		buildPaletteGrid();
		buildLiveDemos();

		var pageLabel = new FlxText(0, FlxG.height - 28, FlxG.width,
			'← → to navigate    Page ${PAGE_INDEX + 1} / $TOTAL_PAGES    ESC to exit', 14);
		pageLabel.setFormat(Paths.font("phantom.ttf"), 14, 0xFF49454F, CENTER);
		add(pageLabel);

		addTouchPad('LEFT_RIGHT', 'B');
	}

	function sectionLabel(text:String, lx:Float, ly:Float):Void
	{
		var lbl = new FlxText(lx, ly, 0, text, 12);
		lbl.setFormat(Paths.font("phantom.ttf"), 12, 0xFF79747E, LEFT);
		add(lbl);
	}

	function buildAccentPicker():Void
	{
		sectionLabel("ACCENT COLORS — tap to change theme", 16, 10);

		// Highlight box behind active swatch
		accentHighlight = new FlxSprite();
		accentHighlight.makeGraphic(46, 46, 0xFF000000);
		add(accentHighlight);

		var startX:Float = 16;
		var startY:Float = 30;
		var gap:Float = 54;

		for (i in 0...ACCENT_COLORS.length)
		{
			var swatch = new FlxSprite(startX + i * gap, startY);
			swatch.makeGraphic(42, 42, ACCENT_COLORS[i]);
			add(swatch);

			var lbl = new FlxText(startX + i * gap, startY + 44, 48, ACCENT_NAMES[i], 9);
			lbl.setFormat(Paths.font("phantom.ttf"), 9, 0xFF49454F, CENTER);
			add(lbl);

			accentButtons.push(swatch);
		}

		// Position highlight on default (index 0)
		updateHighlight(0);

		// A hint label
		var hintLbl = new FlxText(startX + ACCENT_COLORS.length * gap + 8, startY + 8, 180,
			"Changing accent regenerates\nthe full M3 palette.", 11);
		hintLbl.setFormat(Paths.font("phantom.ttf"), 11, 0xFF79747E, LEFT);
		add(hintLbl);
	}

	function buildPaletteGrid():Void
	{
		sectionLabel("COLOR PALETTE", 16, 102);

		var cols:Int = 10;
		var sW:Int = 62;
		var sH:Int = 32;
		var gapX:Int = 2;
		var gapY:Int = 22;
		var startX:Float = 16;
		var startY:Float = 120;

		for (i in 0...ROLE_LABELS.length)
		{
			var col = i % cols;
			var row = Std.int(i / cols);
			var sx = startX + col * (sW + gapX);
			var sy = startY + row * (sH + gapY);

			var swatch = new FlxSprite(sx, sy);
			swatch.makeGraphic(sW, sH, FlxColor.WHITE);
			add(swatch);
			swatches.push(swatch);

			var lbl = new FlxText(sx, sy + sH + 2, sW, ROLE_LABELS[i], 9);
			lbl.setFormat(Paths.font("phantom.ttf"), 9, 0xFF49454F, CENTER);
			add(lbl);
			swatchLabels.push(lbl);
		}

		refreshPaletteSwatches();
		MD3Theme.addListener(refreshPaletteSwatches);
	}

	function buildLiveDemos():Void
	{
		sectionLabel("LIVE DEMO  (updates with theme)", 16, 228);

		demoButton = new MaterialButton(16, 250, "Filled Button", FILLED, 140);
		add(demoButton);

		demoSwitch = new MaterialSwitch(220, 258, true);
		add(demoSwitch);

		demoChip = new MaterialChip(280, 252, "Filter Chip", FILTER, true);
		add(demoChip);

		demoFAB = new MaterialFAB(450, 244, REGULAR, "", null);
		add(demoFAB);

		demoProgress = new MaterialProgressIndicator(16, 320, LINEAR, 380);
		demoProgress.value = 0.65;
		add(demoProgress);

		var circProg = new MaterialProgressIndicator(420, 296, CIRCULAR);
		circProg.value = 0.72;
		add(circProg);
	}

	function refreshPaletteSwatches():Void
	{
		var roles:Array<Int> = [
			MD3Theme.primary, MD3Theme.onPrimary, MD3Theme.primaryContainer, MD3Theme.onPrimaryContainer,
			MD3Theme.secondary, MD3Theme.onSecondary, MD3Theme.secondaryContainer, MD3Theme.onSecondaryContainer,
			MD3Theme.tertiary, MD3Theme.onTertiary, MD3Theme.tertiaryContainer, MD3Theme.onTertiaryContainer,
			MD3Theme.surface, MD3Theme.onSurface, MD3Theme.surfaceVariant, MD3Theme.onSurfaceVariant,
			MD3Theme.outline, MD3Theme.outlineVariant, MD3Theme.inverseSurface, MD3Theme.inversePrimary
		];

		for (i in 0...swatches.length)
		{
			if (i < roles.length)
				swatches[i].color = roles[i];
		}
	}

	function applyAccent(index:Int):Void
	{
		activeAccentIndex = index;
		MD3Theme.setAccent(ACCENT_COLORS[index]);
		updateHighlight(index);
		refreshPaletteSwatches();
	}

	function updateHighlight(index:Int):Void
	{
		if (accentButtons.length == 0) return;
		var target = accentButtons[index];
		accentHighlight.x = target.x - 2;
		accentHighlight.y = target.y - 2;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if FLX_MOUSE
		if (FlxG.mouse.justPressed)
		{
			var mx = FlxG.mouse.x;
			var my = FlxG.mouse.y;
			for (i in 0...accentButtons.length)
			{
				var btn = accentButtons[i];
				if (mx >= btn.x && mx <= btn.x + btn.width && my >= btn.y && my <= btn.y + btn.height)
				{
					applyAccent(i);
					break;
				}
			}
		}
		#end

		if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
			FlxG.switchState(new MD3Test5State());
		if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
			FlxG.switchState(new MD3Test7State());
		if (controls.BACK)
			FlxG.switchState(new funkin.ui.title.TitleState());
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(refreshPaletteSwatches);
		super.destroy();
	}
}
