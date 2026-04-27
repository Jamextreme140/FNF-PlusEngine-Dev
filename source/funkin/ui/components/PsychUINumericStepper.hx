package funkin.ui.components;

class PsychUINumericStepper extends PsychUIInputText
{
	public static final CHANGE_EVENT = "numericstepper_change";
	static inline var BUTTON_SIZE:Int = 14;
	static inline var BUTTON_PADDING:Int = 2;
	static inline var TEXT_BUTTON_GAP:Int = 4;

	public var step:Float = 0;
	public var min(default, set):Float = 0;
	public var max(default, set):Float = 0;
	public var decimals(default, set):Int = 0;
	public var isPercent(default, set):Bool = false;
	public var buttonPlus:FlxSprite;
	public var buttonMinus:FlxSprite;
	public var plusLabel:FlxText;
	public var minusLabel:FlxText;

	var _plusPressed:Bool = false;
	var _minusPressed:Bool = false;
	var _buttonThemeSignature:String = null;

	public var onValueChange:Void->Void;
	public var value(default, set):Float;
	public function new(x:Float = 0, y:Float = 0, step:Float = 1, defValue:Float = 0, min:Float = -999, max:Float = 999, decimals:Int = 0, ?wid:Int = 60, ?isPercent:Bool = false)
	{
		super(x, y, wid, '');
		textObj.alignment = CENTER;
		fieldWidth = _drawWidth;
		@:bypassAccessor this.decimals = decimals;
		@:bypassAccessor this.isPercent = isPercent;
		@:bypassAccessor this.min = min;
		@:bypassAccessor this.max = max;
		this.step = step;
		_updateFilter();

		buttonPlus = new FlxSprite();
		add(buttonPlus);
		plusLabel = new FlxText(0, 0, BUTTON_SIZE, '+', 10);
		plusLabel.alignment = CENTER;
		add(plusLabel);
		
		buttonMinus = new FlxSprite();
		add(buttonMinus);
		minusLabel = new FlxText(0, 0, BUTTON_SIZE, '-', 10);
		minusLabel.alignment = CENTER;
		add(minusLabel);
		layoutStepper();
		redrawButtons();

		unfocus = function()
		{
			_updateValue();
			_internalOnChange();
		}
		value = defValue;
		refreshTextLayout();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		layoutStepper();
		refreshButtonTheme();

		if(FlxG.mouse.justPressed)
		{
			if(buttonPlus != null && buttonPlus.exists && FlxG.mouse.overlaps(buttonPlus, camera))
			{
				_plusPressed = true;
				redrawButtons();
				value += step;
				_internalOnChange();
			}
			else if(buttonMinus != null && buttonMinus.exists && FlxG.mouse.overlaps(buttonMinus, camera))
			{
				_minusPressed = true;
				redrawButtons();
				value -= step;
				_internalOnChange();
			}
		}
		else if(FlxG.mouse.released)
		{
			if(_plusPressed || _minusPressed)
			{
				_plusPressed = false;
				_minusPressed = false;
				redrawButtons();
			}
		}
	}

	function set_value(v:Float)
	{
		value = Math.max(min, Math.min(max, v));
		text = formatValueText(value);
		_updateValue();
		return value;
	}

	function set_min(v:Float)
	{
		min = v;
		@:bypassAccessor if(min > max) max = min;
		_updateFilter();
		_updateValue();
		return min;
	}

	function set_max(v:Float)
	{
		max = v;
		@:bypassAccessor if(max < min) min = max;
		_updateFilter();
		_updateValue();
		return max;
	}

	function set_decimals(v:Int)
	{
		decimals = v;
		_updateFilter();
		return decimals;
	}
	function set_isPercent(v:Bool)
	{
		var changed:Bool = (isPercent != v);
		isPercent = v;
		_updateFilter();

		if(changed)
		{
			text = Std.string(value * 100);
			_updateValue();
		}
		return isPercent;
	}

	function _updateValue()
	{
		var txt:String = text.replace('%', '');
		if(txt.indexOf('-') > 0)
			txt.replace('-', '');

		while(txt.indexOf('.') > -1 && txt.indexOf('.') != txt.lastIndexOf('.'))
		{
			var lastId = txt.lastIndexOf('.');
			txt = txt.substr(0, lastId) + txt.substring(lastId+1);
		}

		var val:Float = Std.parseFloat(txt);
		if(Math.isNaN(val))
			val = 0;

		if(isPercent) val /= 100;

		if(val < min) val = min;
		else if(val > max) val = max;
		val = FlxMath.roundDecimal(val, decimals);
		@:bypassAccessor value = val;

		text = formatValueText(val);

		if(caretIndex > text.length) caretIndex = text.length;
		if(selectIndex > text.length) selectIndex = text.length;
	}

	inline function formatValueText(v:Float):String
	{
		return isPercent ? (Std.string(FlxMath.roundDecimal(v * 100, decimals)) + '%') : Std.string(FlxMath.roundDecimal(v, decimals));
	}
	
	function _updateFilter()
	{
		if(min < 0)
		{
			if(decimals > 0)
			{
				if(isPercent)
					customFilterPattern = ~/[^0-9.%\-]*/g;
				else
					customFilterPattern = ~/[^0-9.\-]*/g;
			}
			else
			{
				if(isPercent)
					customFilterPattern = ~/[^0-9%\-]*/g;
				else
					customFilterPattern = ~/[^0-9\-]*/g;
			}
		}
		else
		{
			if(decimals > 0)
			{
				if(isPercent)
					customFilterPattern = ~/[^0-9.%]*/g;
				else
					customFilterPattern = ~/[^0-9.]*/g;
			}
			else
			{
				if(isPercent)
					customFilterPattern = ~/[^0-9%]*/g;
				else
					customFilterPattern = ~/[^0-9]*/g;
			}
		}
	}

	public var broadcastStepperEvent:Bool = true;
	function _internalOnChange()
	{
		if(onValueChange != null) onValueChange();
		if(broadcastStepperEvent) PsychUIEventHandler.event(CHANGE_EVENT, this);
	}

	override function setGraphicSize(width:Float = 0, height:Float = 0)
	{
		super.setGraphicSize(width, height);
		if (buttonPlus == null || buttonMinus == null || plusLabel == null || minusLabel == null)
			return;
		setInnerDrawSize(Std.int(Math.max(1, width - 2)), Std.int(Math.max(1, height - 2)));
		layoutStepper();
		redrawButtons();
	}

	function refreshTextLayout():Void
	{
		var horizontalReserved:Int = (BUTTON_SIZE + BUTTON_PADDING + TEXT_BUTTON_GAP) * 2;
		textObj.fieldWidth = Std.int(Math.max(1, _innerDrawWidth - horizontalReserved));
		textObj.x = behindText.x + BUTTON_SIZE + BUTTON_PADDING + TEXT_BUTTON_GAP;
		textObj.y = behindText.y + (_innerDrawHeight - textObj.height) / 2 - 1;
	}

	function layoutStepper():Void
	{
		if (buttonPlus == null || buttonMinus == null || plusLabel == null || minusLabel == null)
			return;

		buttonPlus.x = behindText.x + BUTTON_PADDING;
		buttonPlus.y = behindText.y + (_innerDrawHeight - BUTTON_SIZE) / 2;
		buttonMinus.x = behindText.x + _innerDrawWidth - BUTTON_PADDING - BUTTON_SIZE;
		buttonMinus.y = buttonPlus.y;
		refreshTextLayout();
		textObj.updateHitbox();
	}

	function refreshButtonTheme():Void
	{
		if (_buttonThemeSignature != PsychUISkin.signature())
			redrawButtons();
	}

	function redrawButtons():Void
	{
		PsychUISkin.drawStyledRect(buttonPlus, BUTTON_SIZE, BUTTON_SIZE, PsychUISkin.navButtonStyle(_plusPressed));
		PsychUISkin.drawStyledRect(buttonMinus, BUTTON_SIZE, BUTTON_SIZE, PsychUISkin.navButtonStyle(_minusPressed));
		buttonPlus.updateHitbox();
		buttonMinus.updateHitbox();
		plusLabel.color = PsychUISkin.navButtonStyle(_plusPressed).textColor;
		minusLabel.color = PsychUISkin.navButtonStyle(_minusPressed).textColor;
		plusLabel.x = buttonPlus.x;
		plusLabel.y = buttonPlus.y + buttonPlus.height / 2 - plusLabel.height / 2;
		minusLabel.x = buttonMinus.x;
		minusLabel.y = buttonMinus.y + buttonMinus.height / 2 - minusLabel.height / 2;
		plusLabel.updateHitbox();
		minusLabel.updateHitbox();
		_buttonThemeSignature = PsychUISkin.signature();
	}
}