package funkin.ui.components.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import funkin.ui.components.md3.MD3Theme;

/**
 * Material Design 3 Button Component
 * Based on: https://m3.material.io/components/buttons/specs
 * 
 * Supports three variants: Filled, Outlined, and Text
 */
class MaterialButton extends FlxSpriteGroup
{
	public var label(default, set):String = "";
	public var enabled:Bool = true;
	public var onClick:Void->Void = null;
	
	public var buttonType:ButtonType = FILLED;
	
	// Visual components
	var container:FlxSprite;
	var outline:FlxSprite;
	var labelText:FlxText;
	
	// Dimensions (MD3 Medium size)
	public var buttonWidth:Float = 120;
	static inline var BUTTON_HEIGHT:Int = 40;
	static inline var CORNER_RADIUS:Int = 20;
	static inline var OUTLINE_WIDTH:Int = 1;
	static inline var PADDING_HORIZONTAL:Int = 24;
	
	// Colors (MD3)
	static inline var PRIMARY_COLOR:FlxColor = 0xFF6750A4;
	static inline var ON_PRIMARY_COLOR:FlxColor = 0xFFFFFFFF;
	static inline var OUTLINE_COLOR:FlxColor = 0xFF79747E;
	static inline var DISABLED_CONTAINER_COLOR:FlxColor = 0x1F1C1B1F;
	static inline var DISABLED_TEXT_COLOR:FlxColor = 0x611C1B1F;
	
	// State layers (overlay colors)
	static inline var HOVER_OVERLAY:FlxColor = 0x141C1B1F;
	static inline var PRESSED_OVERLAY:FlxColor = 0x1F1C1B1F;
	
	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;
	var stateLayer:FlxSprite;
	
	// Animation tweens
	var hoverTween:FlxTween;
	var pressTween:FlxTween;
	
	public function new(x:Float = 0, y:Float = 0, label:String = "Button", ?buttonType:ButtonType = FILLED, ?width:Float = 120, ?onClick:Void->Void = null)
	{
		super(x, y);
		trace('[MaterialButton] new() start label="$label" type=$buttonType');
		
		this.label = label;
		this.buttonType = buttonType;
		this.buttonWidth = width;
		this.onClick = onClick;
		
		// Create container background
		container = new FlxSprite(0, 0);
		container.makeGraphic(Std.int(buttonWidth), BUTTON_HEIGHT, FlxColor.WHITE);
		drawRoundedRect(container, Std.int(buttonWidth), BUTTON_HEIGHT, CORNER_RADIUS);
		add(container);
		
		// Create state layer (for hover/press effects)
		stateLayer = new FlxSprite(0, 0);
		stateLayer.makeGraphic(Std.int(buttonWidth), BUTTON_HEIGHT, FlxColor.TRANSPARENT);
		drawRoundedRect(stateLayer, Std.int(buttonWidth), BUTTON_HEIGHT, CORNER_RADIUS);
		stateLayer.alpha = 0;
		add(stateLayer);
		
		// Create outline (for outlined variant)
		outline = new FlxSprite(0, 0);
		outline.makeGraphic(Std.int(buttonWidth), BUTTON_HEIGHT, FlxColor.TRANSPARENT, true);
		add(outline);
		
		// Create label text
		labelText = new FlxText(0, 0, buttonWidth, this.label, 14);
		labelText.setFormat(Paths.font("phantom.ttf"), 14, FlxColor.WHITE, CENTER);
		labelText.antialiasing = ClientPrefs.data.antialiasing;
		labelText.y = (BUTTON_HEIGHT - labelText.height) / 2;
		add(labelText);
		
		updateAppearance();
		MD3Theme.addListener(updateAppearance);
		trace('[MaterialButton] new() complete');
	}
	
	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		// Fill main rectangle (excluding corners)
		for (y in radius...(height - radius))
		{
			for (x in 0...width)
			{
				graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
		
		// Fill top and bottom areas between corners
		for (y in 0...radius)
		{
			for (x in radius...(width - radius))
			{
				graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
		
		for (y in (height - radius)...height)
		{
			for (x in radius...(width - radius))
			{
				graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
		
		// Draw rounded corners
		// corner index controls angle offset: 0=lower-right, 1=lower-left, 2=upper-left, 3=upper-right
		drawCorner(graphics, radius, radius, radius, 2);                     // Top-left
		drawCorner(graphics, width - radius, radius, radius, 3);             // Top-right
		drawCorner(graphics, radius, height - radius, radius, 1);            // Bottom-left
		drawCorner(graphics, width - radius, height - radius, radius, 0);    // Bottom-right
	}
	
	function drawCorner(graphics:openfl.display.BitmapData, cx:Int, cy:Int, radius:Int, corner:Int):Void
	{
		for (angle in 0...90)
		{
			var rad = angle * Math.PI / 180 + corner * Math.PI / 2;
			for (r in 0...radius)
			{
				var px = Std.int(cx + Math.cos(rad) * r);
				var py = Std.int(cy + Math.sin(rad) * r);
				if (px >= 0 && px < graphics.width && py >= 0 && py < graphics.height)
					graphics.setPixel32(px, py, 0xFFFFFFFF);
			}
		}
	}
	
	function drawOutline(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		var color = enabled ? MD3Theme.outline : DISABLED_TEXT_COLOR;
		
		// Draw outline using rectangles for each side
		for (i in 0...OUTLINE_WIDTH)
		{
			// Top
			for (x in radius...(width - radius))
				graphics.setPixel32(x, i, color);
			
			// Bottom
			for (x in radius...(width - radius))
				graphics.setPixel32(x, height - 1 - i, color);
			
			// Left
			for (y in radius...(height - radius))
				graphics.setPixel32(i, y, color);
			
			// Right
			for (y in radius...(height - radius))
				graphics.setPixel32(width - 1 - i, y, color);
		}
		
		// Draw rounded corner outlines
		drawCornerOutline(graphics, radius, radius, radius, color, 2);                     // Top-left
		drawCornerOutline(graphics, width - radius, radius, radius, color, 3);             // Top-right
		drawCornerOutline(graphics, radius, height - radius, radius, color, 1);            // Bottom-left
		drawCornerOutline(graphics, width - radius, height - radius, radius, color, 0);    // Bottom-right
	}
	
	function drawCornerOutline(graphics:openfl.display.BitmapData, cx:Int, cy:Int, radius:Int, color:FlxColor, corner:Int):Void
	{
		for (angle in 0...90)
		{
			var rad = angle * Math.PI / 180 + corner * Math.PI / 2;
			for (r in (radius - OUTLINE_WIDTH)...radius)
			{
				var px = Std.int(cx + Math.cos(rad) * r);
				var py = Std.int(cy + Math.sin(rad) * r);
				if (px >= 0 && px < graphics.width && py >= 0 && py < graphics.height)
					graphics.setPixel32(px, py, color);
			}
		}
	}
	
	function updateAppearance():Void
	{
		if (container == null || labelText == null || outline == null)
		{
			trace('[MaterialButton] updateAppearance: container=${container != null ? "ok" : "NULL"} labelText=${labelText != null ? "ok" : "NULL"} outline=${outline != null ? "ok" : "NULL"} — skipping');
			return;
		}
		
		if (!enabled)
		{
			// Disabled state
			switch (buttonType)
			{
				case FILLED:
					container.color = FlxColor.WHITE;
					container.alpha = 0.12;
					outline.visible = false;
					labelText.color = DISABLED_TEXT_COLOR;
				case OUTLINED:
					container.visible = false;
					outline.visible = true;
					drawOutline(outline, Std.int(buttonWidth), BUTTON_HEIGHT, CORNER_RADIUS);
					labelText.color = DISABLED_TEXT_COLOR;
				case TEXT:
					container.visible = false;
					outline.visible = false;
					labelText.color = DISABLED_TEXT_COLOR;
			}
		}
		else
		{
			// Enabled state
			switch (buttonType)
			{
				case FILLED:
					container.color = MD3Theme.primary;
					container.alpha = 1;
					container.visible = true;
					outline.visible = false;
					labelText.color = MD3Theme.onPrimary;
				case OUTLINED:
					container.visible = false;
					outline.visible = true;
					drawOutline(outline, Std.int(buttonWidth), BUTTON_HEIGHT, CORNER_RADIUS);
					labelText.color = MD3Theme.primary;
				case TEXT:
					container.visible = false;
					outline.visible = false;
					labelText.color = MD3Theme.primary;
			}
		}
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!enabled) return;
		
		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOver = mousePos.x >= x && mousePos.x <= x + buttonWidth &&
		             mousePos.y >= y && mousePos.y <= y + BUTTON_HEIGHT;
		
		// Hover effect
		if (isOver && !isHovered)
		{
			isHovered = true;
			if (hoverTween != null) hoverTween.cancel();
			stateLayer.color = HOVER_OVERLAY;
			hoverTween = FlxTween.num(stateLayer.alpha, 1, 0.15, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		else if (!isOver && isHovered)
		{
			isHovered = false;
			if (hoverTween != null) hoverTween.cancel();
			hoverTween = FlxTween.num(stateLayer.alpha, 0, 0.15, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		
		// Press effect
		if (FlxG.mouse.pressed && isOver && !isPressed)
		{
			isPressed = true;
			if (pressTween != null) pressTween.cancel();
			stateLayer.color = PRESSED_OVERLAY;
			pressTween = FlxTween.num(stateLayer.alpha, 1, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		else if (!FlxG.mouse.pressed && isPressed)
		{
			isPressed = false;
			if (pressTween != null) pressTween.cancel();
			stateLayer.color = isHovered ? HOVER_OVERLAY : FlxColor.TRANSPARENT;
			var targetAlpha = isHovered ? 1.0 : 0.0;
			pressTween = FlxTween.num(stateLayer.alpha, targetAlpha, 0.1, {ease: FlxEase.cubeOut}, function(v) { stateLayer.alpha = v; });
		}
		
		// Click event
		if (FlxG.mouse.justReleased && isOver && onClick != null)
		{
			onClick();
		}
		#end
	}
	
	function set_label(value:String):String
	{
		label = value;
		if (labelText != null)
		{
			labelText.text = value;
			labelText.y = (BUTTON_HEIGHT - labelText.height) / 2;
		}
		return label;
	}
	
	override function destroy():Void
	{
		MD3Theme.removeListener(updateAppearance);
		if (hoverTween != null) hoverTween.cancel();
		if (pressTween != null) pressTween.cancel();
		
		super.destroy();
	}
}

enum ButtonType
{
	FILLED;
	OUTLINED;
	TEXT;
}
