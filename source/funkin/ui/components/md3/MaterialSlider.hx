package funkin.ui.components.md3;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import funkin.ui.components.md3.MD3Theme;

/**
 * Material Design 3 Slider Component
 * Based on: https://m3.material.io/components/sliders/guidelines
 */
class MaterialSlider extends FlxSpriteGroup
{
	public var value(default, set):Float = 0.5;
	public var min:Float = 0.0;
	public var max:Float = 1.0;
	public var enabled:Bool = true;
	public var onChange:Float->Void = null;
	
	// Visual components
	var trackInactive:FlxSprite;
	var trackActive:FlxSprite;
	var thumb:FlxSprite;
	var valueLabel:FlxSprite;
	var valueLabelText:flixel.text.FlxText;
	
	// Dimensions (Material Design 3 specs)
	public var sliderWidth:Float = 200;
	static inline var TRACK_INACTIVE_HEIGHT:Int = 4;
	static inline var TRACK_ACTIVE_HEIGHT:Int = 8;  // Thicker when filled
	static inline var SEPARATOR_WIDTH:Int = 4;
	static inline var SEPARATOR_HEIGHT:Int = 16;
	static inline var SEPARATOR_HEIGHT_PRESSED:Int = 20;
	static inline var LABEL_HEIGHT:Int = 28;
	static inline var LABEL_WIDTH:Int = 48;
	
	// Colors (Material Design 3)
	static inline var TRACK_ACTIVE_COLOR:FlxColor = 0xFF6750A4;      // Purple
	static inline var TRACK_INACTIVE_COLOR:FlxColor = 0xFFE7E0EC;   // Light gray
	static inline var THUMB_COLOR:FlxColor = 0xFF6750A4;            // Purple
	static inline var LABEL_BG_COLOR:FlxColor = 0xFF6750A4;         // Purple
	static inline var LABEL_TEXT_COLOR:FlxColor = 0xFFFFFFFF;       // White
	
	// Animation tweens
	var thumbTween:FlxTween;
	var thumbScaleTween:FlxTween;
	var labelTween:FlxTween;
	var trackHeightTween:FlxTween;
	
	// Interaction state
	var isDragging:Bool = false;
	var showLabel:Bool = false;
	
	public function new(x:Float = 0, y:Float = 0, width:Float = 200, ?value:Float = 0.5, ?min:Float = 0.0, ?max:Float = 1.0)
	{
		super(x, y);
		
		this.sliderWidth = width;
		this.min = min;
		this.max = max;
		
		var sliderX = x;
		var sliderY = y;
		
		// Create inactive track (full width, thin)
		trackInactive = new FlxSprite();
		trackInactive.makeGraphic(Std.int(sliderWidth), TRACK_INACTIVE_HEIGHT, FlxColor.WHITE);
		trackInactive.antialiasing = ClientPrefs.data.antialiasing;
		drawRoundedRect(trackInactive, Std.int(sliderWidth), TRACK_INACTIVE_HEIGHT, TRACK_INACTIVE_HEIGHT / 2);
		add(trackInactive);
		trackInactive.x = sliderX;
		trackInactive.y = sliderY;
		trackInactive.color = MD3Theme.surfaceVariant;
		
		// Create active track (variable width based on value, starts thin)
		trackActive = new FlxSprite();
		trackActive.makeGraphic(Std.int(sliderWidth), TRACK_INACTIVE_HEIGHT, FlxColor.WHITE);
		trackActive.antialiasing = ClientPrefs.data.antialiasing;
		drawRoundedRect(trackActive, Std.int(sliderWidth), TRACK_INACTIVE_HEIGHT, TRACK_INACTIVE_HEIGHT / 2);
		add(trackActive);
		trackActive.x = sliderX;
		trackActive.y = sliderY;
		trackActive.offset.set(0, 0);
		trackActive.color = MD3Theme.primary;
		
		// Create separator bar (vertical bar that divides active/inactive)
		thumb = new FlxSprite();
		thumb.makeGraphic(SEPARATOR_WIDTH, SEPARATOR_HEIGHT, FlxColor.WHITE);
		thumb.antialiasing = ClientPrefs.data.antialiasing;
		drawRoundedRect(thumb, SEPARATOR_WIDTH, SEPARATOR_HEIGHT, 2); // Rounded corners
		add(thumb);
		thumb.y = sliderY - (SEPARATOR_HEIGHT - TRACK_INACTIVE_HEIGHT) / 2;
		thumb.color = THUMB_COLOR;
		
		// Create value label (appears on drag)
		valueLabelText = new flixel.text.FlxText(0, 0, LABEL_WIDTH, "50", 12);
		valueLabelText.setFormat(Paths.font("phantom.ttf"), 12, LABEL_TEXT_COLOR, CENTER);
		valueLabelText.antialiasing = ClientPrefs.data.antialiasing;
		
		valueLabel = new FlxSprite();
		valueLabel.makeGraphic(LABEL_WIDTH, LABEL_HEIGHT, FlxColor.WHITE);
		valueLabel.antialiasing = ClientPrefs.data.antialiasing;
		drawRoundedRect(valueLabel, LABEL_WIDTH, LABEL_HEIGHT, 4);
		valueLabel.color = MD3Theme.primary;
		valueLabel.alpha = 0;
		add(valueLabel);
		
		// Set initial value
		this.value = value;
		updateVisuals(false);
		MD3Theme.addListener(_onThemeChange);
	}
	
	function drawRoundedRect(sprite:FlxSprite, width:Int, height:Int, radius:Float):Void
	{
		var graphics = sprite.pixels;
		graphics.fillRect(graphics.rect, FlxColor.TRANSPARENT);
		
		for (y in 0...height)
		{
			for (x in 0...width)
			{
				var inRoundedRect = false;
				
				if (x < radius && y < radius)
				{
					var dx = radius - x;
					var dy = radius - y;
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else if (x >= width - radius && y < radius)
				{
					var dx = x - (width - radius);
					var dy = radius - y;
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else if (x < radius && y >= height - radius)
				{
					var dx = radius - x;
					var dy = y - (height - radius);
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else if (x >= width - radius && y >= height - radius)
				{
					var dx = x - (width - radius);
					var dy = y - (height - radius);
					inRoundedRect = (dx * dx + dy * dy) <= (radius * radius);
				}
				else
				{
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
	
	function _onThemeChange():Void
	{
		trackInactive.color = MD3Theme.surfaceVariant;
		trackActive.color = MD3Theme.primary;
		thumb.color = MD3Theme.primary;
		valueLabel.color = MD3Theme.primary;
	}

	function updateVisuals(animate:Bool = true):Void
	{
		var duration = animate ? 0.15 : 0;
		
		// Calculate separator position based on value
		var normalizedValue = (value - min) / (max - min);
		var targetX = trackInactive.x + sliderWidth * normalizedValue;
		
		// Animate separator position
		if (animate && thumbTween != null) thumbTween.cancel();
		
		if (animate)
		{
			thumbTween = FlxTween.tween(thumb, {x: targetX}, duration, {ease: FlxEase.cubeOut});
		}
		else
		{
			thumb.x = targetX;
		}
		
		// Update active track width (scale to separator position)
		trackActive.scale.x = normalizedValue;
		trackActive.offset.x = 0;
		trackActive.updateHitbox();
		
		// Update value label position and text
		updateLabelPosition();
		updateLabelText();
	}
	
	function updateLabelPosition():Void
	{
		valueLabel.x = thumb.x + SEPARATOR_WIDTH / 2 - LABEL_WIDTH / 2;
		valueLabel.y = thumb.y - LABEL_HEIGHT - 8;
	}
	
	function updateLabelText():Void
	{
		// Format value based on range
		var displayValue:String;
		if (max - min >= 10)
			displayValue = Std.string(Std.int(value));
		else
			displayValue = Std.string(Math.round(value * 100) / 100);
		
		valueLabelText.text = displayValue;
		valueLabelText.x = valueLabel.x;
		valueLabelText.y = valueLabel.y + (LABEL_HEIGHT - valueLabelText.height) / 2;
	}
	
	function showValueLabel():Void
	{
		if (labelTween != null) labelTween.cancel();
		showLabel = true;
		labelTween = FlxTween.tween(valueLabel, {alpha: 1}, 0.15, {ease: FlxEase.cubeOut});
	}
	
	function hideValueLabel():Void
	{
		if (labelTween != null) labelTween.cancel();
		showLabel = false;
		labelTween = FlxTween.tween(valueLabel, {alpha: 0}, 0.15, {ease: FlxEase.cubeOut});
	}
	
	function expandTrack():Void
	{
		if (trackHeightTween != null) trackHeightTween.cancel();
		
		var scaleY = TRACK_ACTIVE_HEIGHT / TRACK_INACTIVE_HEIGHT;
		trackHeightTween = FlxTween.tween(trackActive.scale, {y: scaleY}, 0.1, {
			ease: FlxEase.cubeOut,
			onUpdate: function(_) {
				// Keep track centered vertically while expanding
				var currentHeight = TRACK_INACTIVE_HEIGHT * trackActive.scale.y;
				trackActive.offset.y = 0;
				trackActive.y = trackInactive.y - (currentHeight - TRACK_INACTIVE_HEIGHT) / 2;
			}
		});
	}
	
	function shrinkTrack():Void
	{
		if (trackHeightTween != null) trackHeightTween.cancel();
		
		trackHeightTween = FlxTween.tween(trackActive.scale, {y: 1}, 0.15, {
			ease: FlxEase.cubeOut,
			onUpdate: function(_) {
				// Keep track centered vertically while shrinking
				var currentHeight = TRACK_INACTIVE_HEIGHT * trackActive.scale.y;
				trackActive.offset.y = 0;
				trackActive.y = trackInactive.y - (currentHeight - TRACK_INACTIVE_HEIGHT) / 2;
			},
			onComplete: function(_) {
				// Ensure perfect alignment when done
				trackActive.scale.y = 1;
				trackActive.offset.y = 0;
				trackActive.y = trackInactive.y;
			}
		});
	}
	
	override function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (!enabled) return;
		
		#if FLX_MOUSE
		var mousePos = FlxG.mouse.getScreenPosition();
		
		// Check if mouse is over the slider (use larger hit area)
		var hitAreaHeight = 30; // Larger hit area for easier interaction
		var isOverSlider = mousePos.x >= trackInactive.x && mousePos.x <= trackInactive.x + sliderWidth &&
		                   mousePos.y >= trackInactive.y - hitAreaHeight / 2 && mousePos.y <= trackInactive.y + TRACK_INACTIVE_HEIGHT + hitAreaHeight / 2;
		
		// Start dragging
		if (FlxG.mouse.justPressed && isOverSlider)
		{
			isDragging = true;
			showValueLabel();
			expandTrack(); // Ensanchar el track activo
			
			// Separator press animation (grow taller)
			thumb.makeGraphic(SEPARATOR_WIDTH, SEPARATOR_HEIGHT_PRESSED, FlxColor.WHITE);
			drawRoundedRect(thumb, SEPARATOR_WIDTH, SEPARATOR_HEIGHT_PRESSED, 2);
			thumb.color = THUMB_COLOR;
			thumb.y = trackInactive.y - (SEPARATOR_HEIGHT_PRESSED - TRACK_INACTIVE_HEIGHT) / 2;
		}
		
		// Update value while dragging
		if (isDragging && FlxG.mouse.pressed)
		{
			var localX = mousePos.x - trackInactive.x;
			var normalizedValue = FlxMath.bound(localX / sliderWidth, 0, 1);
			var newValue = min + normalizedValue * (max - min);
			
			// Snap to increments if needed (optional)
			if (max - min <= 100)
			{
				newValue = Math.round(newValue * 100) / 100;
			}
			
			if (newValue != value)
			{
				this.value = newValue;
				
				if (onChange != null)
					onChange(value);
			}
		}
		
		// Stop dragging
		if (isDragging && FlxG.mouse.justReleased)
		{
			isDragging = false;
			hideValueLabel();
			shrinkTrack(); // Volver al tamaño normal
			
			// Separator release animation (return to normal height)
			thumb.makeGraphic(SEPARATOR_WIDTH, SEPARATOR_HEIGHT, FlxColor.WHITE);
			drawRoundedRect(thumb, SEPARATOR_WIDTH, SEPARATOR_HEIGHT, 2);
			thumb.color = THUMB_COLOR;
			thumb.y = trackInactive.y - (SEPARATOR_HEIGHT - TRACK_INACTIVE_HEIGHT) / 2;
		}
		
		// Update label position if dragging
		if (isDragging)
		{
			updateLabelPosition();
			updateLabelText();
		}
		#end
	}
	
	override function draw():Void
	{
		super.draw();
		
		// Draw value label text on top
		if (showLabel || isDragging)
		{
			valueLabelText.draw();
		}
	}
	
	function set_value(newValue:Float):Float
	{
		value = FlxMath.bound(newValue, min, max);
		updateVisuals(!isDragging); // Don't animate while dragging
		return value;
	}
	
	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (thumbTween != null) thumbTween.cancel();
		if (thumbScaleTween != null) thumbScaleTween.cancel();
		if (labelTween != null) labelTween.cancel();
		if (trackHeightTween != null) trackHeightTween.cancel();
		
		onChange = null;
		
		if (valueLabelText != null)
		{
			valueLabelText.destroy();
			valueLabelText = null;
		}
		
		super.destroy();
	}
}
