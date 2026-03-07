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
 * Material Design 3 Checkbox Component
 * Based on: https://m3.material.io/components/checkbox/specs
 */
class MaterialCheckbox extends FlxSpriteGroup
{
	public var checked(default, set):Bool = false;
	public var enabled:Bool = true;
	public var label:String = "";
	public var onChange:Bool->Void = null;
	
	// Visual components
	var container:FlxSprite;
	var checkIcon:FlxSprite;
	var stateLayer:FlxSprite;
	var labelText:FlxText;
	
	// Dimensions (MD3 specs)
	static inline var CONTAINER_SIZE:Int = 18;
	static inline var CORNER_RADIUS:Int = 2;
	static inline var STATE_LAYER_SIZE:Int = 40;
	static inline var ICON_SIZE:Int = 18;
	static inline var LABEL_SPACING:Int = 8;
	
	// Colors (MD3)
	static inline var PRIMARY_COLOR:FlxColor = 0xFF6750A4;
	static inline var ON_PRIMARY_COLOR:FlxColor = 0xFFFFFFFF;
	static inline var ON_SURFACE_VARIANT:FlxColor = 0xFF49454F;
	static inline var OUTLINE_COLOR:FlxColor = 0xFF79747E;
	static inline var DISABLED_COLOR:FlxColor = 0x611C1B1F;
	
	// State layers
	static inline var HOVER_OVERLAY:FlxColor = 0x146750A4;
	static inline var PRESSED_OVERLAY:FlxColor = 0x1F6750A4;
	
	// State
	var isHovered:Bool = false;
	var isPressed:Bool = false;
	
	// Animation tweens
	var checkTween:FlxTween;
	var hoverTween:FlxTween;
	var pressTween:FlxTween;
	
	public function new(x:Float = 0, y:Float = 0, ?label:String = "", ?checked:Bool = false, ?onChange:Bool->Void = null)
	{
		super(x, y);
		trace('[MaterialCheckbox] new() start label="$label" checked=$checked');
		
		this.label = label;
		this.onChange = onChange;
		// NOTE: do NOT assign this.checked here — sprites are not created yet
		
		// Create state layer (for hover/press effects)
		trace('[MaterialCheckbox] creating stateLayer');
		var layerOffset = (STATE_LAYER_SIZE - CONTAINER_SIZE) / 2;
		stateLayer = new FlxSprite(-layerOffset, -layerOffset);
		stateLayer.makeGraphic(STATE_LAYER_SIZE, STATE_LAYER_SIZE, FlxColor.TRANSPARENT);
		drawCircle(stateLayer, STATE_LAYER_SIZE / 2, STATE_LAYER_SIZE / 2, STATE_LAYER_SIZE / 2);
		stateLayer.alpha = 0;
		add(stateLayer);
		
		// Create container
		trace('[MaterialCheckbox] creating container');
		container = new FlxSprite(0, 0);
		container.makeGraphic(CONTAINER_SIZE, CONTAINER_SIZE, FlxColor.WHITE);
		drawRoundedRect(container, CONTAINER_SIZE, CONTAINER_SIZE, CORNER_RADIUS);
		add(container);
		
		// Create check icon
		trace('[MaterialCheckbox] creating checkIcon');
		checkIcon = new FlxSprite(0, 0);
		checkIcon.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT, true);
		checkIcon.alpha = 0;
		add(checkIcon);
		
		// Create label text if provided
		if (label.length > 0)
		{
			trace('[MaterialCheckbox] creating labelText');
			labelText = new FlxText(CONTAINER_SIZE + LABEL_SPACING, 0, 0, label, 14);
			labelText.setFormat(Paths.font("phantom.ttf"), 14, ON_SURFACE_VARIANT, LEFT);
			labelText.antialiasing = ClientPrefs.data.antialiasing;
			labelText.y = (CONTAINER_SIZE - labelText.height) / 2;
			add(labelText);
		}
		
		// Assign checked AFTER all sprites are created
		trace('[MaterialCheckbox] assigning checked=$checked after sprite creation');
		this.checked = checked;
		
		updateAppearance();
		MD3Theme.addListener(updateAppearance);
		trace('[MaterialCheckbox] new() complete');
	}
	
	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
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
		
		// Draw small rounded corners
		for (y in 0...radius)
		{
			for (x in 0...radius)
			{
				var dx = radius - x;
				var dy = radius - y;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
		
		for (y in 0...radius)
		{
			for (x in 0...radius)
			{
				var dx = x;
				var dy = radius - y;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(width - 1 - x, y, 0xFFFFFFFF);
			}
		}
		
		for (y in 0...radius)
		{
			for (x in 0...radius)
			{
				var dx = radius - x;
				var dy = y;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(x, height - 1 - y, 0xFFFFFFFF);
			}
		}
		
		for (y in 0...radius)
		{
			for (x in 0...radius)
			{
				var dx = x;
				var dy = y;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(width - 1 - x, height - 1 - y, 0xFFFFFFFF);
			}
		}
	}
	
	function drawCircle(sprite:FlxSprite, cx:Float, cy:Float, radius:Float):Void
	{
		var graphics = sprite.pixels;
		var w:Int = Std.int(graphics.width);
		var h:Int = Std.int(graphics.height);
		for (y in 0...h)
		{
			for (x in 0...w)
			{
				var dx = x - cx;
				var dy = y - cy;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
	}
	
	function drawCheckmark(sprite:FlxSprite, color:FlxColor):Void
	{
		if (sprite == null || sprite.pixels == null) return;
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		// Draw checkmark path (simplified)
		// Short stroke going down-right
		for (i in 0...2)
		{
			for (j in 0...5)
			{
				graphics.setPixel32(5 + i, 8 + j, color);
			}
		}
		
		// Long stroke going up-right
		for (i in 0...2)
		{
			for (j in 0...10)
			{
				var x = 6 + i + Std.int(j * 0.6);
				var y = 12 - j;
				if (x < ICON_SIZE && y >= 0)
					graphics.setPixel32(x, y, color);
			}
		}
	}
	
	function updateAppearance():Void
	{
		if (container == null || checkIcon == null)
		{
			trace('[MaterialCheckbox] updateAppearance: container=${container != null ? "ok" : "NULL"} checkIcon=${checkIcon != null ? "ok" : "NULL"} — skipping');
			return;
		}
		
		if (!enabled)
		{
			container.color = checked ? MD3Theme.primary : FlxColor.WHITE;
			container.alpha = 0.38;
			checkIcon.alpha = checked ? 1 : 0;
			drawCheckmark(checkIcon, DISABLED_COLOR);
			if (labelText != null)
				labelText.color = DISABLED_COLOR;
		}
		else
		{
			if (checked)
			{
				container.color = MD3Theme.primary;
				container.alpha = 1;
				checkIcon.alpha = 1;
				drawCheckmark(checkIcon, MD3Theme.onPrimary);
			}
			else
			{
				container.color = FlxColor.TRANSPARENT;
				container.alpha = 1;
				// Draw outline for unchecked state
				if (container.pixels == null) return;
				var graphics = container.pixels;
				graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
				
				// Draw border
				for (y in 0...CONTAINER_SIZE)
				{
					for (x in 0...CONTAINER_SIZE)
					{
						var isBorder = (x < 2 || x >= CONTAINER_SIZE - 2 || y < 2 || y >= CONTAINER_SIZE - 2);
						var isInside = (x >= 2 && x < CONTAINER_SIZE - 2 && y >= 2 && y < CONTAINER_SIZE - 2);
						
						if (isBorder && !isInside)
						{
							// Check if within rounded corners
							var inCorner = false;
							if (x < CORNER_RADIUS && y < CORNER_RADIUS)
							{
								var dx = CORNER_RADIUS - x;
								var dy = CORNER_RADIUS - y;
								inCorner = (dx * dx + dy * dy > CORNER_RADIUS * CORNER_RADIUS);
							}
							else if (x >= CONTAINER_SIZE - CORNER_RADIUS && y < CORNER_RADIUS)
							{
								var dx = x - (CONTAINER_SIZE - CORNER_RADIUS - 1);
								var dy = CORNER_RADIUS - y;
								inCorner = (dx * dx + dy * dy > CORNER_RADIUS * CORNER_RADIUS);
							}
							else if (x < CORNER_RADIUS && y >= CONTAINER_SIZE - CORNER_RADIUS)
							{
								var dx = CORNER_RADIUS - x;
								var dy = y - (CONTAINER_SIZE - CORNER_RADIUS - 1);
								inCorner = (dx * dx + dy * dy > CORNER_RADIUS * CORNER_RADIUS);
							}
							else if (x >= CONTAINER_SIZE - CORNER_RADIUS && y >= CONTAINER_SIZE - CORNER_RADIUS)
							{
								var dx = x - (CONTAINER_SIZE - CORNER_RADIUS - 1);
								var dy = y - (CONTAINER_SIZE - CORNER_RADIUS - 1);
								inCorner = (dx * dx + dy * dy > CORNER_RADIUS * CORNER_RADIUS);
							}
							
						if (!inCorner)
							graphics.setPixel32(x, y, MD3Theme.outline);
						}
					}
				}
				
				checkIcon.alpha = 0;
			}
			
			if (labelText != null)
				labelText.color = MD3Theme.onSurfaceVariant;
		}
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!enabled) return;
		
		#if FLX_MOUSE
		var checkboxWidth = labelText != null ? (CONTAINER_SIZE + LABEL_SPACING + labelText.width) : CONTAINER_SIZE;
		var mousePos = FlxG.mouse.getScreenPosition();
		var isOver = mousePos.x >= x && mousePos.x <= x + checkboxWidth &&
		             mousePos.y >= y && mousePos.y <= y + CONTAINER_SIZE;
		
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
		if (FlxG.mouse.justReleased && isOver)
		{
			checked = !checked;
		}
		#end
	}
	
	function set_checked(value:Bool):Bool
	{
		trace('[MaterialCheckbox] set_checked value=$value checkIcon=${checkIcon != null ? "ok" : "NULL"}');
		var oldValue = checked;
		checked = value;
		
		if (checkIcon == null)
		{
			trace('[MaterialCheckbox] set_checked: checkIcon is null, skipping tween');
			return checked;
		}
		
		if (checkTween != null) checkTween.cancel();
		
		var targetAlpha = checked ? 1.0 : 0.0;
		checkTween = FlxTween.num(checkIcon.alpha, targetAlpha, 0.15, {ease: FlxEase.cubeOut}, function(v) {
			if (checkIcon != null) checkIcon.alpha = v;
		});
		checkTween.onComplete = function(_) { updateAppearance(); };
		
		updateAppearance();
		
		if (oldValue != checked && onChange != null)
			onChange(checked);
		
		return checked;
	}
	
	override function destroy():Void
	{
		MD3Theme.removeListener(updateAppearance);
		if (checkTween != null) checkTween.cancel();
		if (hoverTween != null) hoverTween.cancel();
		if (pressTween != null) pressTween.cancel();
		
		super.destroy();
	}
}
