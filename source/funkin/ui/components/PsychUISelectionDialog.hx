package funkin.ui.components;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import funkin.ui.MusicBeatSubstate;

class PsychUISelectionDialog extends MusicBeatSubstate
{
	var dialogWidth:Int;
	var dialogHeight:Int;
	var title:String;
	var options:Array<String>;
	var displayOptions:Array<String>;
	var selectedIndex:Int;
	var onSelected:Int->String->Void;
	var onClosed:Void->Void;

	var backdrop:FlxSprite;
	public var bg:FlxSprite;
	public var titleText:FlxText;
	var optionsGroup:PsychUIRadioGroup;
	var emptyText:FlxText;

	public function new(title:String, options:Array<String>, selectedIndex:Int, onSelected:Int->String->Void, ?onClosed:Void->Void, ?displayOptions:Array<String>)
	{
		this.title = title;
		this.options = options != null ? options.copy() : [];
		this.displayOptions = displayOptions != null ? displayOptions.copy() : this.options.copy();
		this.selectedIndex = selectedIndex;
		this.onSelected = onSelected;
		this.onClosed = onClosed;

		var visibleCount:Int = Std.int(Math.max(1, Math.min(7, this.options.length)));
		dialogWidth = 460;
		dialogHeight = 160 + (visibleCount * 26) + ((this.options.length > visibleCount) ? 28 : 0);
		if (this.options.length < 1)
			dialogHeight = 180;

		controls.isInSubstate = true;
		super();
	}

	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		backdrop = new FlxSprite().makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), 0xA0000000);
		backdrop.scrollFactor.set();
		backdrop.cameras = cameras;
		add(backdrop);

		bg = new FlxSprite();
		PsychUISkin.drawStyledRect(bg, dialogWidth, dialogHeight, PsychUISkin.panelStyle());
		bg.screenCenter();
		bg.cameras = cameras;
		add(bg);

		titleText = new FlxText(bg.x + 24, bg.y + 20, dialogWidth - 48, title, 18);
		titleText.alignment = CENTER;
		titleText.color = PsychUISkin.textPrimary();
		titleText.cameras = cameras;
		add(titleText);

		var closeButton:PsychUIButton = new PsychUIButton(bg.x + dialogWidth - 52, bg.y + 16, 'X', cancel, 36, 28);
		closeButton.useDynamicTheme = false;
		closeButton.normalStyle = PsychUISkin.buttonNormalStyle();
		closeButton.hoverStyle = PsychUISkin.buttonHoverStyle();
		closeButton.clickStyle = PsychUISkin.buttonPressedStyle();
		closeButton.resize(36, 28);
		closeButton.cameras = cameras;
		add(closeButton);

		if (options.length > 0)
		{
			var maxItems:Int = Std.int(Math.min(7, options.length));
			optionsGroup = new PsychUIRadioGroup(bg.x + 28, bg.y + 68, displayOptions, 26, maxItems, false, dialogWidth - 64);
			optionsGroup.cameras = cameras;
			if (selectedIndex < 0)
				selectedIndex = 0;
			if (selectedIndex >= options.length)
				selectedIndex = options.length - 1;

			var initialScroll:Int = Std.int(Math.max(0, Math.min(selectedIndex, Math.max(0, options.length - maxItems))));
			optionsGroup.curScroll = initialScroll;
			optionsGroup.checked = selectedIndex - initialScroll;
			add(optionsGroup);
		}
		else
		{
			emptyText = new FlxText(bg.x + 24, bg.y + 88, dialogWidth - 48, 'No options available.', 16);
			emptyText.alignment = CENTER;
			emptyText.color = PsychUISkin.textSecondary();
			emptyText.cameras = cameras;
			add(emptyText);
		}

		var cancelButton:PsychUIButton = new PsychUIButton(0, bg.y + dialogHeight - 52, 'Cancel', cancel, 110, 32);
		cancelButton.screenCenter(X);
		cancelButton.x += 70;
		cancelButton.cameras = cameras;
		add(cancelButton);

		var chooseButton:PsychUIButton = new PsychUIButton(0, bg.y + dialogHeight - 52, 'Select', confirmSelection, 110, 32);
		chooseButton.screenCenter(X);
		chooseButton.x -= 70;
		chooseButton.cameras = cameras;
		if (options.length < 1)
			chooseButton.active = chooseButton.visible = false;
		add(chooseButton);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (FlxG.keys.justPressed.ESCAPE)
			cancel();
	}

	function confirmSelection():Void
	{
		if (optionsGroup != null && options.length > 0)
		{
			var finalIndex:Int = optionsGroup.checked + optionsGroup.curScroll;
			finalIndex = Std.int(Math.max(0, Math.min(options.length - 1, finalIndex)));
			if (onSelected != null)
				onSelected(finalIndex, options[finalIndex]);
		}
		closeDialog();
	}

	function cancel():Void
	{
		closeDialog();
	}

	function closeDialog():Void
	{
		controls.isInSubstate = false;
		close();
		if (onClosed != null)
			onClosed();
	}

	public static function open(dialog:PsychUISelectionDialog):Void
	{
		var activeSubState:FlxSubState = FlxG.state.subState;
		if (activeSubState != null)
			activeSubState.openSubState(dialog);
		else
			FlxG.state.openSubState(dialog);
	}
}