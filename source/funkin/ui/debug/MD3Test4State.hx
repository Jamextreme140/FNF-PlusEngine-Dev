package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3Test3State;
import funkin.ui.debug.MD3Test5State;
import funkin.ui.components.md3.*;

/**
 * MD3 component debug viewer — Page 5/6: Checkbox, Switch, Radio Button.
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3Test4State extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 4;
	static inline var TOTAL_PAGES:Int = 7;

	var snackbar:MaterialSnackbar;

	override function create():Void
	{
		super.create();
		Cursor.show();

		var bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0xFFFEF7FF);
		add(bg);

		// Snackbar must exist before buildContent() so callbacks don't null-crash
		snackbar = new MaterialSnackbar(340);

		buildContent();

		var pageLabel = new FlxText(0, FlxG.height - 28, FlxG.width,
			'← → to navigate    Page ${PAGE_INDEX + 1} / $TOTAL_PAGES    ESC to exit', 14);
		pageLabel.setFormat(Paths.font("phantom.ttf"), 14, 0xFF49454F, CENTER);
		add(pageLabel);

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
		// ---- CHECKBOX ----
		sectionLabel("Checkbox", 20, 12);

		var cb1 = new MaterialCheckbox(20, 34, "Unchecked", false, function(v) { snackbar.show('Checkbox 1: $v', 2); });
		add(cb1);

		var cb2 = new MaterialCheckbox(20, 80, "Checked", true, function(v) { snackbar.show('Checkbox 2: $v', 2); });
		add(cb2);

		var cb3 = new MaterialCheckbox(20, 126, "Disabled Off");
		cb3.enabled = false;
		add(cb3);

		var cb4 = new MaterialCheckbox(20, 172, "Disabled On", true);
		cb4.enabled = false;
		add(cb4);

		// ---- SWITCH ----
		sectionLabel("Switch", 260, 12);

		var sw1 = new MaterialSwitch(260, 34, false);
		sw1.onChange = function(v) { snackbar.show('Switch A: ${v ? "On" : "Off"}', 2); };
		add(sw1);
		sectionLabel("Off", 322, 42);

		var sw2 = new MaterialSwitch(260, 80, true);
		sw2.onChange = function(v) { snackbar.show('Switch B: ${v ? "On" : "Off"}', 2); };
		add(sw2);
		sectionLabel("On", 322, 88);

		var sw3 = new MaterialSwitch(260, 126, false);
		sw3.enabled = false;
		add(sw3);
		sectionLabel("Disabled", 322, 134);

		// ---- RADIO BUTTON ----
		sectionLabel("Radio Button  (Group 1)", 20, 224);

		var rb1 = new MaterialRadioButton(20, 248, "Option A", "A", "p5group1", true,
			function(v) { snackbar.show('Radio selected: $v', 2); });
		add(rb1);

		var rb2 = new MaterialRadioButton(20, 294, "Option B", "B", "p5group1", false,
			function(v) { snackbar.show('Radio selected: $v', 2); });
		add(rb2);

		var rb3 = new MaterialRadioButton(20, 340, "Option C", "C", "p5group1", false,
			function(v) { snackbar.show('Radio selected: $v', 2); });
		add(rb3);

		sectionLabel("Radio Button  (Group 2)", 260, 224);

		var rb4 = new MaterialRadioButton(260, 248, "Yes", "yes", "p5group2", true,
			function(v) { snackbar.show('Answer: $v', 2); });
		add(rb4);

		var rb5 = new MaterialRadioButton(260, 294, "No", "no", "p5group2", false,
			function(v) { snackbar.show('Answer: $v', 2); });
		add(rb5);

		var rb6 = new MaterialRadioButton(260, 340, "Maybe", "maybe", "p5group2", false,
			function(v) { snackbar.show('Answer: $v', 2); });
		add(rb6);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
			FlxG.switchState(new MD3Test3State());
		if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
			FlxG.switchState(new MD3Test5State());
		if (controls.BACK)
			FlxG.switchState(new funkin.ui.title.TitleState());
	}
}
