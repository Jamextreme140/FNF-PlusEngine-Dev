package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3TestState;
import funkin.ui.debug.MD3Test2State;
import funkin.ui.components.md3.*;

/**
 * MD3 component debug viewer — Page 2/4: Chips, Tabs, Badges.
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3Test1State extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 1;
	static inline var TOTAL_PAGES:Int = 7;

	var snackbar:MaterialSnackbar;
	var filterChips:Array<MaterialChip> = [];

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
		sectionLabel("Chips", 20, 12);

		add(new MaterialChip(20, 36, "Assist", ASSIST, false, function() { snackbar.show("Assist chip tapped", 2); }));
		add(new MaterialChip(120, 36, "Suggestion", SUGGESTION, false, function() { snackbar.show("Suggestion chip tapped", 2); }));
		add(new MaterialChip(260, 36, "Input chip", INPUT, false, null, function() { snackbar.show("Input chip deleted!", 2); }));

		sectionLabel("Filter chips (toggle)", 20, 78);

		var filterLabels = ["Hard", "Expert", "Normal", "Easy"];
		filterChips = [];
		for (i in 0...filterLabels.length)
		{
			var chip = new MaterialChip(20 + i * 106, 100, filterLabels[i], FILTER, i == 0, function()
			{
				var selected = filterChips.filter(c -> c.selected).map(c -> c.label);
				snackbar.show("Selected: " + (selected.length > 0 ? selected.join(", ") : "none"), 2);
			});
			filterChips.push(chip);
			add(chip);
		}

		sectionLabel("Tabs (Primary)", 20, 152);

		var tabsPrimary = new MaterialTabs(20, 174, ["Songs", "Characters", "Stages", "Options"], PRIMARY, 460, function(i, name)
		{
			snackbar.show('Tab: "$name"', 2);
		});
		add(tabsPrimary);

		sectionLabel("Tabs (Secondary)", 20, 232);

		var tabsSec = new MaterialTabs(20, 254, ["Info", "Settings", "Logs"], SECONDARY, 300, function(i, name)
		{
			snackbar.show('Secondary tab: "$name"', 2);
		});
		add(tabsSec);

		sectionLabel("Badge", 20, 316);

		// Badge centers are all aligned to y_center = 347.
		// Dot (6 px tall): y = 347 - 3 = 344.  Numeric (16 px tall): y = 347 - 8 = 339.
		var dotBadge = new MaterialBadge(20, 344, -1);
		add(dotBadge);
		sectionLabel("dot", 30, 340);

		var numBadge = new MaterialBadge(88, 339, 5);
		add(numBadge);
		sectionLabel("5", 108, 340);

		var bigBadge = new MaterialBadge(158, 339, 1337); // displays "999+"
		add(bigBadge);
		sectionLabel("1337 →999+", 210, 340);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
			FlxG.switchState(new MD3TestState());
		if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
			FlxG.switchState(new MD3Test2State());
		if (controls.BACK)
			FlxG.switchState(new funkin.ui.title.TitleState());
	}
}
