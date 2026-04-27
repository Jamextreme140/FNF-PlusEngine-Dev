package funkin.ui.components;

import flixel.util.FlxDestroyUtil;
import flixel.math.FlxPoint;

class PsychUITab extends FlxSprite
{
	public var name(default, set):String;
	public var text:FlxText;
	public var menu:FlxSpriteGroup = new FlxSpriteGroup();

	var _drawWidth:Int = 1;
	var _drawHeight:Int = 1;

	public function new(name:String)
	{
		super();
		makeGraphic(1, 1, FlxColor.TRANSPARENT, true);

		@:bypassAccessor this.name = name;
		text = new FlxText(0, 0, 100, name);
		text.size = 8;
		text.alignment = CENTER;
		text.textField.wordWrap = true;
		text.textField.multiline = true;
		applyStyle(PsychUISkin.tabIdleStyle());
	}

	override function draw()
	{
		super.draw();

		if(visible && text != null && text.exists && text.visible)
		{
			text.x = x;
			text.y = y + height/2 - text.height/2;
			text.draw();
		}
	}

	override function destroy()
	{
		text = FlxDestroyUtil.destroy(text);
		menu = FlxDestroyUtil.destroy(menu);
		super.destroy();
	}
	
	public function updateMenu(parent:PsychUIBox, elapsed:Float)
	{
		if(menu != null && menu.exists && menu.active)
		{
			syncMenuPosition(parent);
			menu.update(elapsed);
		}
	}

	public function drawMenu(parent:PsychUIBox)
	{
		if(menu != null && menu.exists && menu.visible)
		{
			syncMenuPosition(parent);
			menu.draw();
		}
	}

	function syncMenuPosition(parent:PsychUIBox):Void
	{
		menu.x = parent.x;
		menu.y = parent.y + parent.tabHeight;
		menu.scrollFactor.set(parent.scrollFactor.x, parent.scrollFactor.y);
	}

	public function resize(width:Int, height:Int)
	{
		_drawWidth = width;
		_drawHeight = height;
		refreshTextLayout(width);
		applyStyle(PsychUISkin.tabIdleStyle());
	}

	public function recommendedHeight(width:Int, minHeight:Int):Int
	{
		refreshTextLayout(width);
		return Std.int(Math.max(minHeight, Math.ceil(text.height) + 14));
	}

	function refreshTextLayout(width:Int):Void
	{
		text.size = width < 76 ? 7 : 8;
		text.fieldWidth = Std.int(Math.max(1, width - 16));
		text.text = name;
	}

	public function applyStyle(style:Dynamic):Void
	{
		PsychUISkin.drawStyledRect(this, _drawWidth, _drawHeight, style);
		text.color = style.textColor;
	}

	function set_name(v:String)
	{
		text.text = v;
		return (name = v);
	}


	override function set_cameras(v:Array<FlxCamera>)
	{
		text.cameras = v;
		menu.cameras = v;
		return super.set_cameras(v);
	}

	override function set_camera(v:FlxCamera)
	{
		text.camera = v;
		menu.camera = v;
		return super.set_camera(v);
	}
}