// Example CodeName HScript with Class Support
// Only works in advanced/ folder with hscript-improved

import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

class CustomMenuElement extends FlxSprite {
    public var amplitude:Float = 50;
    public var speed:Float = 2;
    
    public function new(x:Float, y:Float) {
        super(x, y);
        makeGraphic(100, 100, FlxColor.CYAN);
        
        // Fade in animation
        alpha = 0;
        FlxTween.tween(this, {alpha: 1}, 1, {ease: FlxEase.quadOut});
    }
    
    override function update(elapsed:Float) {
        super.update(elapsed);
        
        // Floating animation
        y += Math.sin(FlxG.game.ticks / 500 * speed) * amplitude * elapsed;
    }
}

function onCreate() {
    trace("Advanced State Script with Classes loaded!");
    
    // Create instance of our custom class
    var customElement = new CustomMenuElement(FlxG.width - 150, FlxG.height / 2 - 50);
    FlxG.state.add(customElement);
    
    // Store for later use
    setVar("customElement", customElement);
}

function onUpdate(elapsed:Float) {
    var element = getVar("customElement");
    if (element != null && keyboardJustPressed("SPACE")) {
        // Make it spin
        FlxTween.tween(element, {angle: element.angle + 360}, 0.5, {ease: FlxEase.backOut});
    }
}

function onDestroy() {
    trace("Advanced script cleaned up");
}
