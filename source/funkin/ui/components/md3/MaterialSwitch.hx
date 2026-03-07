package funkin.ui.components.md3;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import funkin.ui.components.md3.MD3Theme;

/**
 * Material Design 3 Switch Component
 * Based on: https://m3.material.io/components/switch/guidelines
 */
class MaterialSwitch extends FlxSpriteGroup
{
	public var checked(default, set):Bool = false;
	public var enabled:Bool = true;
	public var onChange:Bool->Void = null;
	
	// Visual components
	var track:FlxSprite;
	var thumb:FlxSprite;
	var thumbIcon:FlxSprite;
	
	// Dimensions (Material Design 3 specs)
	static inline var TRACK_WIDTH:Int = 52;
	static inline var TRACK_HEIGHT:Int = 32;
	static inline var THUMB_SIZE:Int = 24;
	static inline var THUMB_SIZE_PRESSED:Int = 28;
	static inline var ICON_SIZE:Int = 16;
	
	// Colors (Material Design 3)
	static inline var TRACK_COLOR_ON:FlxColor = 0xFF6750A4;      // Purple
	static inline var TRACK_COLOR_OFF:FlxColor = 0xFFE7E0EC;     // Light gray
	static inline var THUMB_COLOR_ON:FlxColor = 0xFFFFFFFF;      // White
	static inline var THUMB_COLOR_OFF:FlxColor = 0xFF79747E;     // Gray
	static inline var ICON_COLOR_ON:FlxColor = 0xFF6750A4;       // Purple
	static inline var ICON_COLOR_OFF:FlxColor = 0xFFFFFFFF;      // White
	
	// Animation tweens
	var thumbTween:FlxTween;
	var trackColorTween:FlxTween;
	var thumbColorTween:FlxTween;
	var thumbScaleTween:FlxTween;
	
	public function new(x:Float = 0, y:Float = 0, ?checked:Bool = false)
	{
		super(x, y);
		
		// Create track (background pill shape)
		track = new FlxSprite();
		track.makeGraphic(TRACK_WIDTH, TRACK_HEIGHT, FlxColor.WHITE);
		track.antialiasing = ClientPrefs.data.antialiasing;
		drawRoundedRect(track, TRACK_WIDTH, TRACK_HEIGHT, TRACK_HEIGHT / 2);
		add(track);
		track.x = x;
		track.y = y;
		
		// Create thumb (sliding circle)
		thumb = new FlxSprite();
		thumb.makeGraphic(THUMB_SIZE, THUMB_SIZE, FlxColor.WHITE);
		thumb.antialiasing = ClientPrefs.data.antialiasing;
		drawCircle(thumb, THUMB_SIZE);
		add(thumb);
		thumb.x = x + 4; // Offset from track
		thumb.y = y + (TRACK_HEIGHT - THUMB_SIZE) / 2;
		
		// Create thumb icon (centered inside thumb)
		thumbIcon = new FlxSprite();
		thumbIcon.makeGraphic(ICON_SIZE, ICON_SIZE, FlxColor.TRANSPARENT, true);
		thumbIcon.antialiasing = ClientPrefs.data.antialiasing;
		add(thumbIcon);
		thumbIcon.x = thumb.x + (THUMB_SIZE - ICON_SIZE) / 2;
		thumbIcon.y = thumb.y + (THUMB_SIZE - ICON_SIZE) / 2;
		
		// Set initial state without animation
		this.checked = checked;
		updateVisuals(false);
		MD3Theme.addListener(_onThemeChange);
	}
	
	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Float):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		// Draw rounded rectangle using simple approximation
		for (y in 0...height)
		{
			for (x in 0...width)
			{
				var inRoundedRect = false;
				
				// Check corners
				if (x < radius && y < radius)
				{
					// Top-left corner
					var dx = radius - x;
					var dy = radius - y;
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else if (x >= width - radius && y < radius)
				{
					// Top-right corner
					var dx = x - (width - radius);
					var dy = radius - y;
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else if (x < radius && y >= height - radius)
				{
					// Bottom-left corner
					var dx = radius - x;
					var dy = y - (height - radius);
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else if (x >= width - radius && y >= height - radius)
				{
					// Bottom-right corner
					var dx = x - (width - radius);
					var dy = y - (height - radius);
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else
				{
					// Inside the main body
					inRoundedRect = true;
				}
				
				if (inRoundedRect)
					graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
	}
	
	function drawCircle(sprite:FlxSprite, size:Int):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		var radius = size / 2;
		var center = size / 2;
		
		for (y in 0...size)
		{
			for (x in 0...size)
			{
				var dx = x - center;
				var dy = y - center;
				if (dx * dx + dy * dy <= radius * radius)
					graphics.setPixel32(x, y, 0xFFFFFFFF);
			}
		}
	}
	
	function drawIcon(sprite:FlxSprite, isCheck:Bool):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		var lineWidth = 2;
		
		if (isCheck)
		{
			// Draw checkmark
			// Starting point of checkmark
			var startX = 3;
			var startY = 8;
			var midX = 6;
			var midY = 11;
			var endX = 13;
			var endY = 4;
			
			// Draw first line (down-left to middle)
			drawLine(graphics, startX, startY, midX, midY, lineWidth);
			// Draw second line (middle to up-right)
			drawLine(graphics, midX, midY, endX, endY, lineWidth);
		}
		else
		{
			// Draw X
			var padding = 4;
			// Draw first diagonal
			drawLine(graphics, padding, padding, ICON_SIZE - padding, ICON_SIZE - padding, lineWidth);
			// Draw second diagonal
			drawLine(graphics, ICON_SIZE - padding, padding, padding, ICON_SIZE - padding, lineWidth);
		}
	}
	
	function drawLine(graphics:openfl.display.BitmapData, x1:Int, y1:Int, x2:Int, y2:Int, thickness:Int):Void
	{
		var dx = Math.abs(x2 - x1);
		var dy = Math.abs(y2 - y1);
		var sx = x1 < x2 ? 1 : -1;
		var sy = y1 < y2 ? 1 : -1;
		var err = dx - dy;
		
		var x = x1;
		var y = y1;
		
		while (true)
		{
			// Draw thick point
			for (ty in -Std.int(thickness/2)...Std.int(thickness/2) + 1)
			{
				for (tx in -Std.int(thickness/2)...Std.int(thickness/2) + 1)
				{
					var px = x + tx;
					var py = y + ty;
					if (px >= 0 && px < ICON_SIZE && py >= 0 && py < ICON_SIZE)
						graphics.setPixel32(px, py, 0xFFFFFFFF);
				}
			}
			
			if (x == x2 && y == y2) break;
			
			var e2 = 2 * err;
			if (e2 > -dy)
			{
				err -= dy;
				x += sx;
			}
			if (e2 < dx)
			{
				err += dx;
				y += sy;
			}
		}
	}
	
	function updateVisuals(animate:Bool = true):Void
	{
		var duration = animate ? 0.2 : 0;
		
		// Cancel existing tweens
		if (thumbTween != null) thumbTween.cancel();
		if (trackColorTween != null) trackColorTween.cancel();
		if (thumbColorTween != null) thumbColorTween.cancel();
		
		// Calculate thumb position (relative to track)
		var targetX = track.x + (checked ? (TRACK_WIDTH - THUMB_SIZE - 4) : 4);
		
		// Animate thumb position
		if (animate)
		{
			thumbTween = FlxTween.tween(thumb, {x: targetX}, duration, {
				ease: FlxEase.cubeOut,
				onComplete: function(_) {
					updateIconPosition();
				}
			});
		}
		else
		{
			thumb.x = targetX;
			updateIconPosition();
		}
		
		// Animate colors
		var targetTrackColor:FlxColor = checked ? MD3Theme.primary : MD3Theme.surfaceVariant;
		var targetThumbColor:FlxColor = checked ? MD3Theme.onPrimary : MD3Theme.outline;
		var targetIconColor:FlxColor = checked ? MD3Theme.primary : MD3Theme.onPrimary;
		
		if (animate)
		{
			animateColor(track, track.color, targetTrackColor, duration);
			animateColor(thumb, thumb.color, targetThumbColor, duration);
			animateColor(thumbIcon, thumbIcon.color, targetIconColor, duration);
		}
		else
		{
			track.color = targetTrackColor;
			thumb.color = targetThumbColor;
			thumbIcon.color = targetIconColor;
		}
		
		// Update icon
		drawIcon(thumbIcon, checked);
	}
	
	function animateColor(sprite:FlxSprite, fromColor:FlxColor, toColor:FlxColor, duration:Float):Void
	{
		var startR = fromColor.red;
		var startG = fromColor.green;
		var startB = fromColor.blue;
		
		var endR = toColor.red;
		var endG = toColor.green;
		var endB = toColor.blue;
		
		FlxTween.num(0, 1, duration, {ease: FlxEase.cubeOut}, function(t:Float) {
			var r = Std.int(FlxMath.lerp(startR, endR, t));
			var g = Std.int(FlxMath.lerp(startG, endG, t));
			var b = Std.int(FlxMath.lerp(startB, endB, t));
			sprite.color = FlxColor.fromRGB(r, g, b);
		});
	}
	
	function updateIconPosition():Void
	{
		thumbIcon.x = thumb.x + (THUMB_SIZE - ICON_SIZE) / 2;
		thumbIcon.y = thumb.y + (THUMB_SIZE - ICON_SIZE) / 2;
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		updateIconPosition();
		
		#if FLX_MOUSE
		if (enabled && FlxG.mouse.justPressed)
		{
			if (overlapsPoint(FlxG.mouse.getScreenPosition()))
			{
				toggle();
			}
		}
		#end
	}
	
	public function toggle():Void
	{
		if (!enabled) return;
		
		checked = !checked;
		
		// Thumb press animation
		if (thumbScaleTween != null) thumbScaleTween.cancel();
		
		var originalSize = THUMB_SIZE;
		var pressedSize = THUMB_SIZE_PRESSED;
		
		// Scale up
		thumbScaleTween = FlxTween.tween(thumb.scale, {x: pressedSize / originalSize, y: pressedSize / originalSize}, 0.1, {
			ease: FlxEase.cubeOut,
			onComplete: function(_) {
				// Scale back down
				thumbScaleTween = FlxTween.tween(thumb.scale, {x: 1, y: 1}, 0.15, {ease: FlxEase.cubeOut});
			}
		});
		
		if (onChange != null)
			onChange(checked);
	}
	
	function _onThemeChange():Void
	{
		updateVisuals(false);
	}

	function set_checked(value:Bool):Bool
	{
		if (checked != value)
		{
			checked = value;
			updateVisuals(true);
		}
		return checked;
	}
	
	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (thumbTween != null) thumbTween.cancel();
		if (trackColorTween != null) trackColorTween.cancel();
		if (thumbColorTween != null) thumbColorTween.cancel();
		if (thumbScaleTween != null) thumbScaleTween.cancel();
		
		onChange = null;
		
		super.destroy();
	}
}
