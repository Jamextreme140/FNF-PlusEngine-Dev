package funkin.ui.components;

#if android
import funkin.mobile.backend.native.AndroidNativeDropDown;
#end

class PsychUIDropDownMenu extends FlxSpriteGroup
{
	public static final CLICK_EVENT = "dropdown_click";

	public var name:String;
	public var list(default, set):Array<String> = [];
	public var displayFunction(default, set):String->String = null;
	public var button:FlxSprite;
	public var buttonIcon:FlxText;
	public var bg:FlxSprite;
	public var fieldBg:FlxSprite;
	public var textObj:FlxText;
	public var onSelect:Int->String->Void;

	public var selectedIndex(default, set):Int = -1;
	public var selectedLabel(default, set):String = null;
	public var useDynamicTheme:Bool = true;

	var _width:Int = 100;
	var _height:Int = 20;
	var _buttonPressed:Bool = false;
	var _dialogOpen:Bool = false;
	var _themeSignature:String = null;
	var _hovered:Bool = false;
	var _lastVisualState:String = '';

	#if android
	var waitingNativeSelection:Bool = false;
	#end

	public function new(x:Float, y:Float, list:Array<String>, callback:Int->String->Void, ?width:Float = 100)
	{
		super(x, y);

		bg = new FlxSprite();
		add(bg);

		fieldBg = new FlxSprite(1, 1);
		add(fieldBg);

		textObj = new FlxText(6, 2, Math.max(1, Std.int(width) - 30), '', 8);
		textObj.alignment = LEFT;
		add(textObj);

		button = new FlxSprite();
		add(button);

		buttonIcon = new FlxText(0, 0, 20, 'v', 10);
		buttonIcon.alignment = CENTER;
		add(buttonIcon);

		onSelect = callback;
		setSize(Std.int(width), 20);
		@:bypassAccessor this.list = list != null ? list.copy() : [];
		selectedIndex = this.list.length > 0 ? 0 : -1;
		applyTheme(true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		layout();
		refreshTheme();

		var hovered:Bool = isMouseOverControl();

		if (hovered != _hovered)
		{
			_hovered = hovered;
			applyTheme();
		}

		#if android
		if(waitingNativeSelection)
		{
			var nativeSelection:Int = AndroidNativeDropDown.pollSelection();
			if(nativeSelection >= 0)
			{
				waitingNativeSelection = false;
				if(nativeSelection < list.length)
					clickedOn(nativeSelection, list[nativeSelection]);
				_dialogOpen = false;
				_buttonPressed = false;
				applyTheme(true);
			}
			else if(nativeSelection == AndroidNativeDropDown.CANCELED || !AndroidNativeDropDown.isDialogVisible())
			{
				waitingNativeSelection = false;
				_dialogOpen = false;
				_buttonPressed = false;
				applyTheme(true);
			}
		}
		#end

		if (FlxG.mouse.justPressed && hovered)
		{
			_buttonPressed = true;
			applyTheme();

			#if android
			if (tryOpenNativeDropDown())
				return;
			#end

			if (!_dialogOpen)
				openSelectionDialog();
		}
		else if (FlxG.mouse.released && _buttonPressed)
		{
			_buttonPressed = false;
			applyTheme();
		}
	}

	function isMouseOverControl():Bool
	{
		if (camera == null || !visible || !active)
			return false;

		var screenPos:FlxPoint = getScreenPosition(null, camera);
		var mousePos:FlxPoint = FlxG.mouse.getPositionInCameraView(camera);
		return (mousePos.x >= screenPos.x && mousePos.x < screenPos.x + _width)
			&& (mousePos.y >= screenPos.y && mousePos.y < screenPos.y + _height);
	}

	override public function setSize(width:Float, height:Float):Void
	{
		super.setSize(width, height);
		_width = Std.int(Math.max(36, width));
		_height = Std.int(Math.max(20, height));
		layout();
		applyTheme(true);
	}

	function layout():Void
	{
		bg.x = x;
		bg.y = y;
		fieldBg.x = x + 1;
		fieldBg.y = y + 1;
		button.x = x + _width - 21;
		button.y = y;
		textObj.x = fieldBg.x + 6;
		textObj.y = fieldBg.y + (_height - textObj.height) / 2 - 1;
		textObj.fieldWidth = Math.max(1, _width - 32);
		buttonIcon.x = button.x;
		buttonIcon.y = button.y + (_height - buttonIcon.height) / 2 - 1;
	}

	function refreshTheme(force:Bool = false):Void
	{
		if (!useDynamicTheme)
			return;

		var signature:String = PsychUISkin.signature();
		if (force || _themeSignature != signature)
			applyTheme(true);
	}

	function applyTheme(force:Bool = false):Void
	{
		var state:String = (_buttonPressed ? 'pressed' : (_hovered ? 'hover' : 'normal')) + ':' + (_dialogOpen ? 'open' : 'closed') + ':' + PsychUISkin.signature();
		if (!force && _lastVisualState == state)
			return;

		PsychUISkin.drawStyledRect(bg, _width, _height, PsychUISkin.inputOuterStyle(_dialogOpen, _hovered));
		PsychUISkin.drawStyledRect(fieldBg, _width - 22, _height - 2, {
			bgColor: PsychUISkin.inputInnerColor(_dialogOpen),
			textColor: PsychUISkin.textPrimary(),
			bgAlpha: 1.0,
			radius: PsychUISkin.CONTROL_RADIUS - 1
		});
		PsychUISkin.drawStyledRect(button, 20, _height, PsychUISkin.navButtonStyle(_buttonPressed));
		textObj.color = selectedLabel != null ? PsychUISkin.textPrimary() : PsychUISkin.textSecondary();
		buttonIcon.color = PsychUISkin.navButtonStyle(_buttonPressed).textColor;
		buttonIcon.text = 'v';
		_themeSignature = PsychUISkin.signature();
		_lastVisualState = state;
	}

	function openSelectionDialog():Void
	{
		_dialogOpen = true;
		applyTheme();
		PsychUISelectionDialog.open(new PsychUISelectionDialog(name != null && name.length > 0 ? name : 'Select an option', list, selectedIndex,
			function(index:Int, label:String)
			{
				clickedOn(index, label);
			},
			function()
			{
				_dialogOpen = false;
				_buttonPressed = false;
				applyTheme(true);
			},
			buildDisplayOptions()));
	}

	public var broadcastDropDownEvent:Bool = true;
	function clickedOn(num:Int, label:String):Void
	{
		selectedIndex = num;
		if (onSelect != null)
			onSelect(num, label);
		if (broadcastDropDownEvent)
			PsychUIEventHandler.event(CLICK_EVENT, this);
	}

	function set_selectedIndex(v:Int):Int
	{
		selectedIndex = v;
		if (selectedIndex < 0 || selectedIndex >= list.length)
			selectedIndex = -1;

		@:bypassAccessor selectedLabel = selectedIndex >= 0 ? list[selectedIndex] : null;
		textObj.text = selectedLabel != null ? getDisplayLabel(selectedLabel) : '';
		applyTheme(true);
		return selectedIndex;
	}

	function set_selectedLabel(v:String):String
	{
		var id:Int = list.indexOf(v);
		if (id >= 0)
		{
			@:bypassAccessor selectedIndex = id;
			selectedLabel = v;
		}
		else
		{
			@:bypassAccessor selectedIndex = -1;
			selectedLabel = null;
		}

		textObj.text = selectedLabel != null ? getDisplayLabel(selectedLabel) : '';
		applyTheme(true);
		return selectedLabel;
	}

	function buildDisplayOptions():Array<String>
	{
		var result:Array<String> = [];
		for (value in list)
			result.push(getDisplayLabel(value));
		return result;
	}

	inline function getDisplayLabel(value:String):String
	{
		if (value == null)
			return '';
		return displayFunction != null ? displayFunction(value) : value;
	}

	function set_list(v:Array<String>):Array<String>
	{
		var selected:String = selectedLabel;
		list = v != null ? v.copy() : [];

		if (selected != null && list.contains(selected))
			selectedLabel = selected;
		else
			selectedIndex = list.length > 0 ? 0 : -1;

		return v;
	}

	function set_displayFunction(v:String->String):String->String
	{
		displayFunction = v;
		textObj.text = selectedLabel != null ? getDisplayLabel(selectedLabel) : '';
		return v;
	}

	#if android
	inline function tryOpenNativeDropDown():Bool
	{
		if (list == null || list.length <= 0)
			return false;

		var nativeSelectedIndex:Int = selectedIndex >= 0 ? selectedIndex : 0;
		if (AndroidNativeDropDown.show(name != null ? name : 'Select option', list, nativeSelectedIndex))
		{
			waitingNativeSelection = true;
			_dialogOpen = true;
			FlxG.stage.window.textInputEnabled = false;
			return true;
		}

		return false;
	}
	#end
}
