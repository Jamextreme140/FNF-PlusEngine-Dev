package funkin.ui.components.md3;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;

/**
 * Material Design 3 Dialog Component
 * Based on: https://m3.material.io/components/dialogs/guidelines
 *
 * Modal dialog with title, body text, and up to two action buttons.
 * Blocks interaction with content behind it via a scrim overlay.
 */
class MaterialDialog extends FlxSpriteGroup
{
	public var isOpen(default, null):Bool = false;
	public var onConfirm:Void->Void = null;
	public var onDismiss:Void->Void = null;

	// Visual components
	var scrim:FlxSprite;
	var panel:FlxSprite;
	var titleText:FlxText;
	var bodyText:FlxText;
	var confirmButton:MaterialButton;
	var dismissButton:MaterialButton;

	// Dimensions (MD3 specs)
	static inline var DIALOG_WIDTH:Int = 312;
	static inline var CORNER_RADIUS:Int = 28;
	static inline var PADDING:Int = 24;
	static inline var TITLE_SIZE:Int = 24;
	static inline var BODY_SIZE:Int = 14;
	static inline var BUTTON_SPACING:Int = 8;
	static inline var BUTTON_WIDTH:Float = 120;

	// Colors (MD3)
	static inline var PANEL_COLOR:FlxColor = 0xFFFEF7FF;
	static inline var SCRIM_COLOR:FlxColor = 0x52000000;
	static inline var TITLE_COLOR:FlxColor = 0xFF1C1B1F;
	static inline var BODY_COLOR:FlxColor = 0xFF49454F;

	// Animation
	var openTween:FlxTween;
	var scrimTween:FlxTween;

	public function new(?title:String = "Dialog", ?body:String = "", ?confirmLabel:String = "Confirm", ?dismissLabel:String = "Cancel",
		?onConfirm:Void->Void = null, ?onDismiss:Void->Void = null)
	{
		super(0, 0);

		this.onConfirm = onConfirm;
		this.onDismiss = onDismiss;

		// Compute panel height dynamically based on body text
		var bodyTextTemp = new FlxText(0, 0, DIALOG_WIDTH - PADDING * 2, body, BODY_SIZE);
		var bodyHeight = Std.int(bodyTextTemp.height);
		var panelHeight = PADDING + TITLE_SIZE + 16 + bodyHeight + 16 + 40 + PADDING;
		bodyTextTemp.destroy();

		var screenW = FlxG.width;
		var screenH = FlxG.height;
		var panelX = (screenW - DIALOG_WIDTH) / 2;
		var panelY = (screenH - panelHeight) / 2;

		// Scrim (full-screen overlay)
		scrim = new FlxSprite(0, 0);
		scrim.makeGraphic(screenW, screenH, SCRIM_COLOR);
		scrim.alpha = 0;
		add(scrim);

		// Panel
		panel = new FlxSprite(panelX, panelY);
		panel.makeGraphic(DIALOG_WIDTH, panelHeight, FlxColor.WHITE);
		drawRoundedRect(panel, DIALOG_WIDTH, panelHeight, CORNER_RADIUS);
		panel.color = MD3Theme.surfaceContainerHigh;
		panel.alpha = 0;
		add(panel);

		// Title
		var titleY = panelY + PADDING;
		titleText = new FlxText(panelX + PADDING, titleY, DIALOG_WIDTH - PADDING * 2, title, TITLE_SIZE);
		titleText.setFormat(Paths.font("phantom.ttf"), TITLE_SIZE, MD3Theme.onSurface, LEFT);
		titleText.antialiasing = ClientPrefs.data.antialiasing;
		titleText.alpha = 0;
		add(titleText);

		// Body text
		var bodyY = titleY + TITLE_SIZE + 16;
		bodyText = new FlxText(panelX + PADDING, bodyY, DIALOG_WIDTH - PADDING * 2, body, BODY_SIZE);
		bodyText.setFormat(Paths.font("phantom.ttf"), BODY_SIZE, MD3Theme.onSurfaceVariant, LEFT);
		bodyText.antialiasing = ClientPrefs.data.antialiasing;
		bodyText.alpha = 0;
		add(bodyText);

		// Buttons row (bottom-right aligned)
		var buttonRowY = panelY + panelHeight - PADDING - 40;

		dismissButton = new MaterialButton(
			panelX + DIALOG_WIDTH - PADDING - BUTTON_WIDTH * 2 - BUTTON_SPACING,
			buttonRowY, dismissLabel, TEXT, BUTTON_WIDTH,
			function()
			{
				close();
				if (this.onDismiss != null) this.onDismiss();
			}
		);
		dismissButton.alpha = 0;
		add(dismissButton);

		confirmButton = new MaterialButton(
			panelX + DIALOG_WIDTH - PADDING - BUTTON_WIDTH,
			buttonRowY, confirmLabel, FILLED, BUTTON_WIDTH,
			function()
			{
				close();
				if (this.onConfirm != null) this.onConfirm();
			}
		);
		confirmButton.alpha = 0;
		add(confirmButton);

		// Start hidden
		visible = false;
		MD3Theme.addListener(_onThemeChange);
	}

	function _onThemeChange():Void
	{
		if (panel != null) panel.color = MD3Theme.surfaceContainerHigh;
		if (titleText != null) titleText.color = MD3Theme.onSurface;
		if (bodyText != null) bodyText.color = MD3Theme.onSurfaceVariant;
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

		if (openTween != null) openTween.cancel();
		if (scrimTween != null) scrimTween.cancel();

		scrimTween = FlxTween.tween(scrim, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		openTween = FlxTween.tween(panel, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(titleText, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(bodyText, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(confirmButton, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
		FlxTween.tween(dismissButton, {alpha: 1}, 0.2, {ease: FlxEase.cubeOut});
	}

	public function close():Void
	{
		if (!isOpen) return;
		isOpen = false;

		if (openTween != null) openTween.cancel();
		if (scrimTween != null) scrimTween.cancel();

		scrimTween = FlxTween.tween(scrim, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		openTween = FlxTween.tween(panel, {alpha: 0}, 0.15, {
			ease: FlxEase.cubeIn,
			onComplete: function(_) { visible = false; }
		});
		FlxTween.tween(titleText, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		FlxTween.tween(bodyText, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		FlxTween.tween(confirmButton, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
		FlxTween.tween(dismissButton, {alpha: 0}, 0.15, {ease: FlxEase.cubeIn});
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isOpen) return;

		#if FLX_MOUSE
		// Click on scrim to dismiss
		if (FlxG.mouse.justPressed)
		{
			var mousePos = FlxG.mouse.getScreenPosition();
			var panelX = panel.x;
			var panelY = panel.y;
			var isOverPanel = mousePos.x >= panelX && mousePos.x <= panelX + DIALOG_WIDTH
				&& mousePos.y >= panelY && mousePos.y <= panelY + panel.height;

			if (!isOverPanel)
			{
				close();
				if (onDismiss != null) onDismiss();
			}
		}
		#end
	}

	override function destroy():Void
	{
		MD3Theme.removeListener(_onThemeChange);
		if (openTween != null) openTween.cancel();
		if (scrimTween != null) scrimTween.cancel();
		super.destroy();
	}
}
