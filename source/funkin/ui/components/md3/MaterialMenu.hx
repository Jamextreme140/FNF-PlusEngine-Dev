package funkin.ui.components.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Menu Component
 * Based on: https://m3.material.io/components/menus/overview
 *
 * A dropdown list of options anchored to a trigger element.
 * Call open() / close() manually, or set a trigger button.
 */
class MaterialMenu extends FlxSpriteGroup
{
	public var items:Array<String> = [];
	public var enabled:Bool = true;
	public var onSelect:Int->String->Void = null;

	public var isOpen(default, null):Bool = false;

	// Visual components
	var panel:FlxSprite;
	var itemContainers:Array<FlxSprite> = [];
	var itemLabels:Array<FlxText> = [];
	var dividers:Array<FlxSprite> = [];
	var stateLayerIndex:Int = -1;
	var hoveredLayer:FlxSprite;

	// Dimensions (MD3 specs)
	public var menuWidth:Float = 200;
	static inline var ITEM_HEIGHT:Int = 48;
	static inline var CORNER_RADIUS:Int = 4;
	static inline var PADDING_HORIZONTAL:Int = 12;
	static inline var LABEL_SIZE:Int = 14;

	// Colors (MD3)
	static inline var SURFACE_COLOR:FlxColor = 0xFFFEF7FF;
	static inline var SURFACE_TINT:FlxColor = 0xFFECE6F0;
	static inline var TEXT_COLOR:FlxColor = 0xFF1C1B1F;
	static inline var HOVER_OVERLAY:FlxColor = 0x146750A4;
	static inline var PRESSED_OVERLAY:FlxColor = 0x1F6750A4;
	static inline var DISABLED_COLOR:FlxColor = 0x611C1B1F;
	static inline var SHADOW_COLOR:FlxColor = 0x33000000;

	// Animation
	var openTween:FlxTween;

	public function new(x:Float = 0, y:Float = 0, items:Array<String>, ?width:Float = 200, ?onSelect:Int->String->Void = null)
	{
		super(x, y);

		this.items = items;
		this.menuWidth = width;
		this.onSelect = onSelect;

		var totalHeight = items.length * ITEM_HEIGHT;

		// Shadow / elevation simulation (offset darker rect)
		var shadow = new FlxSprite(2, 4);
		shadow.makeGraphic(Std.int(menuWidth), totalHeight, SHADOW_COLOR);
		drawRoundedRect(shadow, Std.int(menuWidth), totalHeight, CORNER_RADIUS);
		add(shadow);

		// Panel
		panel = new FlxSprite(0, 0);
		panel.makeGraphic(Std.int(menuWidth), totalHeight, SURFACE_TINT);
		drawRoundedRect(panel, Std.int(menuWidth), totalHeight, CORNER_RADIUS);
		add(panel);

		// Hover state layer (single reused sprite)
		hoveredLayer = new FlxSprite(0, 0);
		hoveredLayer.makeGraphic(Std.int(menuWidth), ITEM_HEIGHT, FlxColor.TRANSPARENT);
		hoveredLayer.color = HOVER_OVERLAY;
		hoveredLayer.alpha = 0;
		add(hoveredLayer);

		// Items
		for (i in 0...items.length)
		{
			var itemY = i * ITEM_HEIGHT;

			var container = new FlxSprite(0, itemY);
			container.makeGraphic(Std.int(menuWidth), ITEM_HEIGHT, FlxColor.TRANSPARENT);
			itemContainers.push(container);
			add(container);

			var label = new FlxText(PADDING_HORIZONTAL, itemY, menuWidth - PADDING_HORIZONTAL * 2, items[i], LABEL_SIZE);
			label.setFormat(Paths.font("phantom.ttf"), LABEL_SIZE, TEXT_COLOR, LEFT);
			label.antialiasing = ClientPrefs.data.antialiasing;
			label.y = itemY + (ITEM_HEIGHT - label.height) / 2;
			itemLabels.push(label);
			add(label);

			// Divider between items (not after last)
			if (i < items.length - 1)
			{
				var divider = new FlxSprite(PADDING_HORIZONTAL, itemY + ITEM_HEIGHT - 1);
				divider.makeGraphic(Std.int(menuWidth - PADDING_HORIZONTAL * 2), 1, 0xFFCAC4D0);
				dividers.push(divider);
				add(divider);
			}
		}

		// Start hidden
		visible = false;
		alpha = 0;
	}

	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Int):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);

		for (py in 0...height)
		{
			for (px in 0...width)
			{
				var inRect = true;
				if (px < radius && py < radius)
				{
					var dx = radius - px; var dy = radius - py;
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py < radius)
				{
					var dx = px - (width - radius); var dy = radius - py;
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px < radius && py >= height - radius)
				{
					var dx = radius - px; var dy = py - (height - radius);
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}
				else if (px >= width - radius && py >= height - radius)
				{
					var dx = px - (width - radius); var dy = py - (height - radius);
					inRect = (dx * dx + dy * dy) <= radius * radius;
				}

				if (inRect)
					graphics.setPixel32(px, py, 0xFFFFFFFF);
			}
		}
	}

	public function open():Void
	{
		if (isOpen) return;
		isOpen = true;
		visible = true;
		// Re-add at the end of the state's member list so the panel renders
		// above every other component (FlxTypedGroup.add() appends to the end).
		FlxG.state.remove(this, true);
		FlxG.state.add(this);
		if (openTween != null) openTween.cancel();
		openTween = FlxTween.tween(this, {alpha: 1}, 0.15, {ease: FlxEase.cubeOut});
	}

	public function close():Void
	{
		if (!isOpen) return;
		isOpen = false;
		if (openTween != null) openTween.cancel();
		openTween = FlxTween.tween(this, {alpha: 0}, 0.12, {
			ease: FlxEase.cubeIn,
			onComplete: function(_) { visible = false; }
		});
	}

	public function toggle():Void
	{
		if (isOpen) close() else open();
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!enabled || !isOpen) return;

		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		var totalHeight = items.length * ITEM_HEIGHT;
		var isOverMenu = mousePos.x >= x && mousePos.x <= x + menuWidth && mousePos.y >= y && mousePos.y <= y + totalHeight;

		if (isOverMenu)
		{
			var relY = mousePos.y - y;
			var hovIndex = Std.int(relY / ITEM_HEIGHT);

			// Update hover highlight position
			if (hovIndex >= 0 && hovIndex < items.length)
			{
				hoveredLayer.y = y + hovIndex * ITEM_HEIGHT;
				hoveredLayer.alpha = 1;

				if (FlxG.mouse.justReleased && onSelect != null)
				{
					onSelect(hovIndex, items[hovIndex]);
					close();
				}
			}
		}
		else
		{
			hoveredLayer.alpha = 0;

			// Close menu when clicking outside
			if (FlxG.mouse.justPressed)
				close();
		}
		#end
	}

	override function destroy():Void
	{
		if (openTween != null) openTween.cancel();
		super.destroy();
	}
}
