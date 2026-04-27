package funkin.ui.components;

class PsychUICheckBox extends FlxSpriteGroup
{
	public static final CLICK_EVENT = 'checkbox_click';

	public var name:String;
	public var box:FlxSprite;
	public var indicator:FlxSprite;
	public var text:FlxText;
	public var label(get, set):String;

	public var checked(default, set):Bool = false;
	public var onClick:Void->Void = null;
	public var useDynamicTheme:Bool = true;

	var _themeSignature:String = null;
	var _lastHovered:Bool = false;

	public function new(x:Float, y:Float, label:String, ?textWid:Int = 100, ?callback:Void->Void)
	{
		super(x, y);

		box = new FlxSprite();
		indicator = new FlxSprite();
		boxGraphic();
		add(box);
		add(indicator);

		text = new FlxText(box.width + 4, 0, textWid, label);
		text.y += box.height/2 - text.height/2;
		add(text);

		this.onClick = callback;
		applyTheme(true);
	}

	public function boxGraphic()
	{
		redrawControl(false);
	}

	public var broadcastCheckBoxEvent:Bool = true;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		refreshTheme();

		if(FlxG.mouse.justPressed)
		{
			var screenPos:FlxPoint = getScreenPosition(null, camera);
			var mousePos:FlxPoint = FlxG.mouse.getPositionInCameraView(camera);
			if((mousePos.x >= screenPos.x && mousePos.x < screenPos.x + width) &&
				(mousePos.y >= screenPos.y && mousePos.y < screenPos.y + height))
			{
				checked = !checked;
				if(onClick != null) onClick();
				if(broadcastCheckBoxEvent) PsychUIEventHandler.event(CLICK_EVENT, this);
			}
		}
	}

	function set_checked(v:Any)
	{
		var v:Bool = (v != null && v != false);
		@:bypassAccessor checked = v;
		redrawControl();
		return checked;
	}

	function refreshTheme(force:Bool = false):Void
	{
		if (!useDynamicTheme)
			return;

		var signature:String = PsychUISkin.signature();
		var hovered:Bool = false;
		if (camera != null)
		{
			try
			{
				hovered = FlxG.mouse.overlaps(box, camera);
			}
			catch (e:Any) {}
		}

		if (force || _themeSignature != signature || hovered != _lastHovered)
			applyTheme(true);
	}

	function applyTheme(forceRedraw:Bool = false):Void
	{
		text.color = PsychUISkin.textPrimary();
		_themeSignature = PsychUISkin.signature();
		if (forceRedraw)
			redrawControl();
	}

	function isRadioControl():Bool
	{
		return false;
	}

	function redrawControl(?forcedHover:Null<Bool>):Void
	{
		var hovered:Bool = forcedHover == null ? false : forcedHover;
		if (forcedHover == null && camera != null)
		{
			try
			{
				hovered = FlxG.mouse.overlaps(box, camera);
			}
			catch (e:Any) {}
		}

		var style = PsychUISkin.toggleStyle(checked, hovered);
		PsychUISkin.drawStyledRect(box, 16, 16, style);
		indicator.visible = checked;
		if (checked)
		{
			PsychUISkin.drawStyledRect(indicator, 8, 8, {
				bgColor: PsychUISkin.contrastText(PsychUISkin.accent()),
				textColor: PsychUISkin.contrastText(PsychUISkin.accent()),
				bgAlpha: 1.0,
				radius: isRadioControl() ? PsychUISkin.PILL_RADIUS : 3.0
			});
			indicator.x = box.x + (box.width - indicator.width) / 2;
			indicator.y = box.y + (box.height - indicator.height) / 2;
		}
		_lastHovered = hovered;
	}

	function get_label():String {
		return text.text;
	}
	function set_label(v:String):String {
		return (text.text = v);
	}
}