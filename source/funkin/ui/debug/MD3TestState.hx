package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3Test1State;
import funkin.ui.debug.MD3Test7State;
import funkin.ui.components.md3.*;

/**
 * MD3 component debug viewer — Page 1/4: Buttons, Icon Buttons, FABs, Dividers.
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3TestState extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 0;
	static inline var TOTAL_PAGES:Int = 8;

	var snackbar:MaterialSnackbar;

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
		sectionLabel("Buttons", 20, 12);

		var btnFilled = new MaterialButton(20, 36, "Filled", FILLED, 120, function() { snackbar.show("Filled button clicked!", 3); });
		add(btnFilled);
		var btnOutlined = new MaterialButton(155, 36, "Outlined", OUTLINED, 120, function() { snackbar.show("Outlined button clicked!", 3); });
		add(btnOutlined);
		var btnText = new MaterialButton(290, 36, "Text", TEXT, 100, function() { snackbar.show("Text button clicked!", 3); });
		add(btnText);
		var btnDisabled = new MaterialButton(405, 36, "Disabled", FILLED, 120);
		btnDisabled.enabled = false;
		add(btnDisabled);

		sectionLabel("Icon Buttons", 20, 96);

		add(new MaterialIconButton(20, 118, STANDARD, function() { snackbar.show("Icon: Standard", 2); }));
		add(new MaterialIconButton(72, 118, FILLED, function() { snackbar.show("Icon: Filled", 2); }));
		add(new MaterialIconButton(124, 118, FILLED_TONAL, function() { snackbar.show("Icon: Tonal", 2); }));
		add(new MaterialIconButton(176, 118, OUTLINED, function() { snackbar.show("Icon: Outlined", 2); }));

		sectionLabel("FAB", 20, 178);

		add(new MaterialFAB(20, 200, SMALL, "", function() { snackbar.show("FAB Small", 2); }));
		add(new MaterialFAB(72, 196, REGULAR, "", function() { snackbar.show("FAB Regular", 2); }));
		add(new MaterialFAB(136, 186, LARGE, "", function() { snackbar.show("FAB Large", 2); }));
		add(new MaterialFAB(256, 206, REGULAR, "New song", function() { snackbar.show("Extended FAB clicked", 2); }));

		sectionLabel("Dividers", 20, 300);

		add(new MaterialDivider(20, 320, 400, false));
		add(new MaterialDivider(20, 340, 400, false, 60, 60));
		sectionLabel("← inset", 430, 334);
		add(new MaterialDivider(20, 355, 100, true));
		sectionLabel("↕ vertical", 32, 358);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
			FlxG.switchState(new MD3Test7State());
		if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
			FlxG.switchState(new MD3Test1State());
		if (controls.BACK)
			FlxG.switchState(new funkin.ui.title.TitleState());
	}
}
