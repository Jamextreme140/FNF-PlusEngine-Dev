package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3TestState;
import funkin.ui.debug.MD3Test2State;
import funkin.ui.debug.MD3Test4State;
import funkin.ui.components.md3.*;

/**
 * MD3 component debug viewer — Page 4/4: Dialog, Menu, Snackbar, Tooltip.
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3Test3State extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 3;
	static inline var TOTAL_PAGES:Int = 7;

	var snackbar:MaterialSnackbar;
	var dialog:MaterialDialog;

	override function create():Void
	{
		super.create();
		Cursor.show();

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0xFFFEF7FF);
		add(bg);

		buildContent();

		var pageLabel = new FlxText(0, FlxG.height - 28, FlxG.width,
			'← → to navigate    Page ${PAGE_INDEX + 1} / $TOTAL_PAGES    ESC to exit', 14);
		pageLabel.setFormat(Paths.font("phantom.ttf"), 14, 0xFF49454F, CENTER);
		add(pageLabel);

		// Dialog renders above content but below snackbar
		if (dialog != null)
			add(dialog);

		// Snackbar always on top
		snackbar = new MaterialSnackbar(340);
		add(snackbar);

		addTouchPad('LEFT_RIGHT', 'B');
	}

	function sectionLabel(text:String, lx:Float, ly:Float):Void
	{
		var lbl = new FlxText(lx, ly, 0, text, 12);
		lbl.setFormat(Paths.font("phantom.ttf"), 12, 0xFF79747E, LEFT);
		add(lbl);
	}

	function buildContent():Void
	{
		// ---- Dialog ----
		sectionLabel("Dialog", 20, 12);

		dialog = new MaterialDialog(
			"Delete song?",
			"This will permanently remove the song and all its assets. This action cannot be undone.",
			"Delete", "Cancel",
			function() { snackbar.show("Song deleted!", 3); },
			function() { snackbar.show("Cancelled.", 2); }
		);

		var dlgBtn = new MaterialButton(20, 34, "Open Dialog", FILLED, 160, function() { dialog.open(); });
		add(dlgBtn);

		// ---- Menu ----
		sectionLabel("Menu (Dropdown)", 20, 96);

		var menuBtn = new MaterialButton(20, 116, "Open Menu ▼", OUTLINED, 160, null);
		var menu = new MaterialMenu(20, 160, ["New song", "Import chart", "Export", "Delete", "Properties"], 200,
			function(i, item) { snackbar.show('Menu: "$item"', 2); });
		menuBtn.onClick = function() { menu.toggle(); };
		add(menuBtn);
		add(menu);

		// ---- Snackbar ----
		sectionLabel("Snackbar", 260, 12);

		add(new MaterialButton(260, 34, "Show snackbar", FILLED, 170, function()
		{
			snackbar.show("Hello from snackbar!", 4, "UNDO", function() { snackbar.show("Undo pressed!", 2); });
		}));
		add(new MaterialButton(260, 84, "Persistent snack", OUTLINED, 170, function()
		{
			snackbar.show("Persistent — no auto-hide.", 0, "OK", function() {});
		}));

		// ---- Tooltip ----
		sectionLabel("Tooltip (hover button)", 20, 252);

		var tipBtn = new MaterialButton(20, 272, "Hover me", OUTLINED, 140);
		var tooltip = new MaterialTooltip("This is a tooltip!\nHover to trigger.");
		tooltip.attachTo(20, 272, 140, 40);
		add(tipBtn);
		add(tooltip);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
			FlxG.switchState(new MD3Test2State());
		if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
			FlxG.switchState(new MD3Test4State());
		if (controls.BACK)
			FlxG.switchState(new funkin.ui.title.TitleState());
	}
}
