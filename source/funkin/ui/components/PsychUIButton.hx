package funkin.ui.components;

import funkin.ui.components.PsychUIBox.UIStyleData;

class PsychUIButton extends FlxSpriteGroup
{
	public static final CLICK_EVENT = 'button_click';

	public var name:String;
	public var label(default, set):String;
	public var bg:FlxSprite;
	public var text:FlxText;

	public var onChangeState:String->Void;
	public var onClick:Void->Void;
	public var useDynamicTheme:Bool = true;
	
	public var clickStyle:UIStyleData = {
		bgColor: FlxColor.BLACK,
		textColor: FlxColor.WHITE,
		bgAlpha: 1
	};
	public var hoverStyle:UIStyleData = {
		bgColor: FlxColor.WHITE,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};
	public var normalStyle:UIStyleData = {
		bgColor: 0xFFAAAAAA,
		textColor: FlxColor.BLACK,
		bgAlpha: 1
	};

	public function new(x:Float = 0, y:Float = 0, label:String = '', ?onClick:Void->Void = null, ?wid:Int = 80, ?hei:Int = 20)
	{
		super(x, y);
		bg = new FlxSprite();
		add(bg);

		text = new FlxText(0, 0, 1, '');
		text.alignment = CENTER;
		add(text);
		applyThemeDefaults();
		resize(wid, hei);
		this.label = label;
		
		this.onClick = onClick;
		forceCheckNext = true;
	}

	public var isClicked:Bool = false;
	public var forceCheckNext:Bool = false;
	public var broadcastButtonEvent:Bool = true;
	var _firstFrame:Bool = true;
	var _themeSignature:String = null;
	var _lastVisualState:String = '';
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		refreshTheme();

		// Prevent updates if camera or background sprite is null/destroyed
		if(camera == null || bg == null || !bg.exists || !bg.alive)
			return;
		
		// Check if camera is still valid and in the cameras list
		if(!FlxG.cameras.list.contains(camera))
			return;

		if(_firstFrame)
		{
			applyStyle(normalStyle, 'normal');
			_firstFrame = false;
		}
		
		if(isClicked && FlxG.mouse.released)
		{
			forceCheckNext = true;
			isClicked = false;
		}

		if(forceCheckNext || FlxG.mouse.justMoved || FlxG.mouse.justPressed)
		{
			var overlapped:Bool = false;
			try 
			{
				overlapped = FlxG.mouse.overlaps(bg, camera);
			}
			catch(e:Any)
			{
				return; // Exit early if overlap check fails
			}

			forceCheckNext = false;

			if(!isClicked)
			{
				var style:UIStyleData = (overlapped) ? hoverStyle : normalStyle;
				applyStyle(style, overlapped ? 'hover' : 'normal');
			}

			if(overlapped && FlxG.mouse.justPressed)
			{
				isClicked = true;
				applyStyle(clickStyle, 'click');
				if(onClick != null) onClick();
				if(broadcastButtonEvent) PsychUIEventHandler.event(CLICK_EVENT, this);
			}
		}
	}

	public function resize(width:Int, height:Int)
	{
		PsychUISkin.drawStyledRect(bg, width, height, normalStyle);
		text.fieldWidth = width;
		text.x = bg.x;
		text.y = bg.y + height/2 - text.height/2;
		_lastVisualState = '';
		applyStyle(isClicked ? clickStyle : normalStyle, isClicked ? 'click' : 'normal');
	}

	function applyThemeDefaults():Void
	{
		if (!useDynamicTheme)
			return;

		normalStyle = PsychUISkin.buttonNormalStyle();
		hoverStyle = PsychUISkin.buttonHoverStyle();
		clickStyle = PsychUISkin.buttonPressedStyle();
		_themeSignature = PsychUISkin.signature();
	}

	function refreshTheme(force:Bool = false):Void
	{
		if (!useDynamicTheme)
			return;

		var signature:String = PsychUISkin.signature();
		if (force || _themeSignature != signature)
		{
			applyThemeDefaults();
			_lastVisualState = '';
			applyStyle(isClicked ? clickStyle : normalStyle, isClicked ? 'click' : 'normal');
		}
	}

	function applyStyle(style:UIStyleData, state:String):Void
	{
		if (_lastVisualState == state && state.length > 0)
			return;

		PsychUISkin.drawStyledRect(bg, Std.int(Math.max(1, bg.width)), Std.int(Math.max(1, bg.height)), style);
		text.color = style.textColor;
		_lastVisualState = state;
	}

	function set_label(v:String)
	{
		if(text != null && text.exists) text.text = v;
		return (label = v);
	}
}