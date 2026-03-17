package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3Test4State;
import funkin.ui.debug.MD3Test6State;
import funkin.ui.debug.MD3TestState;
import funkin.ui.components.md3.*;

/**
 * MD3 component debug viewer — Page 6/6: Slider, Outlined TextField, Filled TextField.
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3Test5State extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 5;
	static inline var TOTAL_PAGES:Int = 7;

	var snackbar:MaterialSnackbar;

	// Text fields kept as class vars so update() can check focused state
	var tf1:MaterialTextField;
	var tf2:MaterialTextField;
	var ff1:FilledTextField;
	var ff2:FilledTextField;

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
		// ---- SLIDER ----
		sectionLabel("Slider  (continuous 0 – 1)", 20, 12);

		var slider1 = new MaterialSlider(20, 40, 280, 0.5, 0, 1);
		slider1.onChange = function(v) { snackbar.show('Slider: ${Math.round(v * 100)}%', 1); };
		add(slider1);

		sectionLabel("Slider  (integer 0 – 100)", 20, 96);

		var slider2 = new MaterialSlider(20, 124, 280, 50, 0, 100);
		slider2.onChange = function(v) { snackbar.show('Volume: ${Std.int(v)}', 1); };
		add(slider2);

		sectionLabel("Slider  (disabled)", 20, 180);

		var slider3 = new MaterialSlider(20, 208, 280, 0.7, 0, 1);
		slider3.enabled = false;
		add(slider3);

		// ---- OUTLINED TEXT FIELD ----
		sectionLabel("Outlined Text Field", 360, 12);

		tf1 = new MaterialTextField(360, 36, 220, "Username");
		add(tf1);

		tf2 = new MaterialTextField(360, 116, 220, "Email");
		add(tf2);

		// ---- FILLED TEXT FIELD ----
		sectionLabel("Filled Text Field", 360, 196);

		ff1 = new FilledTextField(360, 220, 220, "Search");
		add(ff1);

		ff2 = new FilledTextField(360, 300, 220, "Notes");
		add(ff2);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Block navigation while any text field is focused
		var anyFocused:Bool = (tf1 != null && tf1.focused)
			|| (tf2 != null && tf2.focused)
			|| (ff1 != null && ff1.focused)
			|| (ff2 != null && ff2.focused);

		if (!anyFocused)
		{
			if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
				FlxG.switchState(new MD3Test4State());
			if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
				FlxG.switchState(new MD3Test6State());
			if (controls.BACK)
				FlxG.switchState(new funkin.ui.title.TitleState());
		}
	}
}
