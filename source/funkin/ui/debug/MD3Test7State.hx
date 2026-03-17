package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3Test6State;
import funkin.ui.debug.MD3TestState;
import funkin.ui.components.md3.*;
import funkin.ui.components.md3.MaterialButton.ButtonType;
import funkin.ui.components.md3.MaterialChip.ChipType;

/**
 * MD3 component debug viewer — Page 8/8: MaterialBox demo.
 * Shows multiple MaterialBox panels with different configurations:
 *   Left box  — settings panel with slider/switch/checkbox inside
 *   Right box — info panel (read-only), demonstrating resize() + close
 *   Bottom    — tiny box demonstrating canMinimize (double-click title)
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3Test7State extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 7;
	static inline var TOTAL_PAGES:Int = 8;

	var settingsBox:MaterialBox;
	var infoBox:MaterialBox;
	var miniBox:MaterialBox;

	// Controls inside settingsBox
	var slider:MaterialSlider;
	var toggle:MaterialSwitch;
	var checkbox:MaterialCheckbox;
	var statusText:FlxText;

	// Log inside infoBox
	var logText:FlxText;
	var logLines:Array<String> = [];

	override function create():Void
	{
		super.create();
		Cursor.show();

		// Background
		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, MD3Theme.background);
		add(bg);

		// ----------------------------------------------------------------
		// Settings box (left) — has interactive controls inside
		// ----------------------------------------------------------------
		settingsBox = new MaterialBox(24, 40, 300, 260, "Settings");
		settingsBox.canMinimize = true;

		// Volume slider
		var volLabel = new FlxText(10, 12, 220, "Volume", 12);
		volLabel.setFormat(Paths.font("phantom.ttf"), 12, MD3Theme.onSurfaceVariant, LEFT);
		settingsBox.content.add(volLabel);

		slider = new MaterialSlider(10, 30, 260, 70, 0, 100);
		settingsBox.content.add(slider);

		// Fullscreen toggle
		var fsLabel = new FlxText(10, 72, 180, "Fullscreen", 12);
		fsLabel.setFormat(Paths.font("phantom.ttf"), 12, MD3Theme.onSurface, LEFT);
		settingsBox.content.add(fsLabel);

		toggle = new MaterialSwitch(236, 66, false);
		settingsBox.content.add(toggle);

		// Anti-aliasing checkbox
		checkbox = new MaterialCheckbox(10, 106, "Anti-aliasing", true, function(v) { log('AA: $v'); });
		settingsBox.content.add(checkbox);

		// Apply button
		var applyBtn = new MaterialButton(10, 150, "Apply", FILLED, 120, function()
		{
			log('Volume set to ${Std.int(slider.value)}');
		});
		settingsBox.content.add(applyBtn);

		// Reset button (tonal)
		var resetBtn = new MaterialButton(140, 150, "Reset", OUTLINED, 110, function()
		{
			slider.value = 70;
			log("Settings reset");
		});
		settingsBox.content.add(resetBtn);

		// Live status text at bottom of content
		statusText = new FlxText(10, 192, 280, "Double-click title bar to minimize", 11);
		statusText.setFormat(Paths.font("phantom.ttf"), 11, MD3Theme.onSurfaceVariant, LEFT);
		settingsBox.content.add(statusText);

		add(settingsBox);

		// ----------------------------------------------------------------
		// Info / log box (right) — shows a scrolling log, has close button
		// ----------------------------------------------------------------
		infoBox = new MaterialBox(340, 40, 260, 200, "Event Log");
		infoBox.canMinimize = true;
		infoBox.onClose = function()
		{
			infoBox.visible = false;
			log("[info box closed]");
		};

		logText = new FlxText(8, 8, 240, "", 11);
		logText.setFormat(Paths.font("phantom.ttf"), 11, MD3Theme.onSurface, LEFT);
		infoBox.content.add(logText);

		add(infoBox);

		// ----------------------------------------------------------------
		// Mini box (bottom center) — very small, minimizable only
		// ----------------------------------------------------------------
		miniBox = new MaterialBox(220, 330, 200, 150, "Mini Panel");
		miniBox.canMinimize = true;

		var miniChip = new MaterialChip("Chip A", ASSIST, false, null);
		miniChip.setPosition(8, 10);
		miniBox.content.add(miniChip);

		var miniChip2 = new MaterialChip("Chip B", FILTER, false, null);
		miniChip2.setPosition(90, 10);
		miniBox.content.add(miniChip2);

		var miniBtn = new MaterialButton(8, 55, "Action", TEXT, 160, function()
		{
			log("Mini panel action");
		});
		miniBox.content.add(miniBtn);

		var miniHint = new FlxText(8, 88, 180, "Double-click title to collapse", 10);
		miniHint.setFormat(Paths.font("phantom.ttf"), 10, MD3Theme.onSurfaceVariant, LEFT);
		miniBox.content.add(miniHint);

		add(miniBox);

		// ----------------------------------------------------------------
		// Accent color buttons (top-right strip)
		// ----------------------------------------------------------------
		buildAccentStrip();

		// ----------------------------------------------------------------
		// Page footer
		// ----------------------------------------------------------------
		var footer = new FlxText(0, FlxG.height - 28, FlxG.width,
			'← → to navigate    Page ${PAGE_INDEX + 1} / $TOTAL_PAGES    ESC to exit', 13);
		footer.setFormat(Paths.font("phantom.ttf"), 13, MD3Theme.onSurfaceVariant, CENTER);
		add(footer);

		addTouchPad('LEFT_RIGHT', 'B');

		log("MaterialBox demo loaded");
		log("Try dragging the title bars");
	}

	// ----------------------------------------------------------------
	// Compact accent strip (top-right)
	// ----------------------------------------------------------------

	static var ACCENT_STRIP:Array<Int> = [0xFF6750A4, 0xFF006B5F, 0xFFB3261E, 0xFF146C2E, 0xFFAA8000];
	var accentSwatches:Array<FlxSprite> = [];

	function buildAccentStrip():Void
	{
		var lbl = new FlxText(0, 6, FlxG.width - 10, "ACCENT →", 11);
		lbl.setFormat(Paths.font("phantom.ttf"), 11, MD3Theme.onSurfaceVariant, RIGHT);
		add(lbl);

		var sx = FlxG.width - 10 - ACCENT_STRIP.length * 30;
		var sy:Float = 20;
		for (i in 0...ACCENT_STRIP.length)
		{
			var swatch = new FlxSprite(sx + i * 30, sy);
			swatch.makeGraphic(24, 24, ACCENT_STRIP[i]);
			accentSwatches.push(swatch);
			add(swatch);
		}
	}

	// ----------------------------------------------------------------
	// Log helper
	// ----------------------------------------------------------------

	function log(msg:String):Void
	{
		logLines.push(msg);
		if (logLines.length > 10) logLines.shift();
		if (logText != null) logText.text = logLines.join("\n");
	}

	// ----------------------------------------------------------------
	// Update
	// ----------------------------------------------------------------

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Sync status text with slider value
		statusText.text = 'Volume: ${Std.int(slider.value)}   AA: ${checkbox.checked}   Fullscreen: ${toggle.checked}';

		#if FLX_MOUSE
		if (FlxG.mouse.justPressed)
		{
			var mx = FlxG.mouse.x;
			var my = FlxG.mouse.y;

			for (i in 0...accentSwatches.length)
			{
				var s = accentSwatches[i];
				if (mx >= s.x && mx <= s.x + s.width && my >= s.y && my <= s.y + s.height)
				{
					MD3Theme.setAccent(ACCENT_STRIP[i]);
					// Re-tint background to match new surface color
					cast(members[0], FlxSprite).color = MD3Theme.background;
					break;
				}
			}
		}
		#end

		if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
			FlxG.switchState(new MD3Test6State());
		if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
			FlxG.switchState(new MD3TestState());
		if (controls.BACK)
			FlxG.switchState(new funkin.ui.title.TitleState());
	}
}
