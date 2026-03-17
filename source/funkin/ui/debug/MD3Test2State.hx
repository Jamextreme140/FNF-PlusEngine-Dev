package funkin.ui.debug;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.ui.MusicBeatState;
import funkin.ui.debug.MD3Test1State;
import funkin.ui.debug.MD3Test3State;
import funkin.ui.components.md3.*;

/**
 * MD3 component debug viewer — Page 3/4: Cards, Progress Indicators.
 * Navigate with LEFT/RIGHT arrow keys. Press BACK/ESC to exit.
 */
class MD3Test2State extends MusicBeatState
{
	static inline var PAGE_INDEX:Int = 2;
	static inline var TOTAL_PAGES:Int = 7;

	var snackbar:MaterialSnackbar;

	// Determinate progress indicators animated in update()
	var linearDet:MaterialProgressIndicator;
	var circularDet:MaterialProgressIndicator;
	var progressTimer:Float = 0;

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
		sectionLabel("Cards", 20, 12);

		// Elevated card
		var cardEl = new MaterialCard(20, 34, ELEVATED, 180, 100, function() { snackbar.show("Elevated card clicked!", 2); });
		var elLbl = new FlxText(12, 12, 156, "Elevated Card\nClick me!", 13);
		elLbl.setFormat(Paths.font("phantom.ttf"), 13, 0xFF1C1B1F, LEFT);
		cardEl.addContent(elLbl);
		add(cardEl);

		// Filled card
		var cardFi = new MaterialCard(218, 34, FILLED, 180, 100, function() { snackbar.show("Filled card clicked!", 2); });
		var fiLbl = new FlxText(12, 12, 156, "Filled Card\nClick me!", 13);
		fiLbl.setFormat(Paths.font("phantom.ttf"), 13, 0xFF1C1B1F, LEFT);
		cardFi.addContent(fiLbl);
		add(cardFi);

		// Outlined card
		var cardOu = new MaterialCard(416, 34, OUTLINED, 180, 100, function() { snackbar.show("Outlined card clicked!", 2); });
		var ouLbl = new FlxText(12, 12, 156, "Outlined Card\nClick me!", 13);
		ouLbl.setFormat(Paths.font("phantom.ttf"), 13, 0xFF1C1B1F, LEFT);
		cardOu.addContent(ouLbl);
		add(cardOu);

		sectionLabel("Progress  Linear", 20, 152);

		// Linear determinate (auto-animated in update)
		linearDet = new MaterialProgressIndicator(20, 172, LINEAR, 300);
		add(linearDet);
		sectionLabel("determinate (auto-fills)", 332, 168);

		// Linear indeterminate
		var linearInd = new MaterialProgressIndicator(20, 204, LINEAR, 300);
		linearInd.indeterminate = true;
		add(linearInd);
		sectionLabel("indeterminate", 332, 200);

		sectionLabel("Progress  Circular", 20, 234);

		// Circular determinate (auto-animated in update)
		circularDet = new MaterialProgressIndicator(20, 254, CIRCULAR);
		add(circularDet);
		sectionLabel("determinate", 82, 274);

		// Circular indeterminate
		var circularInd = new MaterialProgressIndicator(175, 254, CIRCULAR);
		circularInd.indeterminate = true;
		add(circularInd);
		sectionLabel("indeterminate", 237, 274);

		sectionLabel("Loading Indicator  (M3)", 20, 318);

		// Default loading indicator (48 px, no container)
		var li1 = new MaterialLoadingIndicator(20, 340);
		add(li1);
		sectionLabel("default", 84, 366);

		// With container background
		var li2 = new MaterialLoadingIndicator(175, 340, 48, true);
		add(li2);
		sectionLabel("with container", 239, 366);

		// Larger size (64 px)
		var li3 = new MaterialLoadingIndicator(370, 332, 64);
		add(li3);
		sectionLabel("64 dp", 448, 366);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// Animate determinate bars
		progressTimer += elapsed * 0.3;
		if (progressTimer > 1) progressTimer = 0;
		if (linearDet != null) linearDet.value = progressTimer;
		if (circularDet != null) circularDet.value = progressTimer;

		if (controls.UI_LEFT_P || FlxG.keys.justPressed.LEFT)
			FlxG.switchState(new MD3Test1State());
		if (controls.UI_RIGHT_P || FlxG.keys.justPressed.RIGHT)
			FlxG.switchState(new MD3Test3State());
		if (controls.BACK)
			FlxG.switchState(new funkin.ui.title.TitleState());
	}
}
