package objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.sound.FlxSound;

class AudioVisualizer extends FlxSprite
{
    public var sound:FlxSound;
    public var barCount:Int = 64;
    public var sensitivity:Float = 1.0;
    public var falloffSpeed:Float = 0.85;
    
    var _width:Int;
    var _height:Int;
    var _barWidth:Float;
    var _gap:Int = 2;
    var _color:FlxColor;
    
    var frequencyData:Array<Float> = [];
    var falloffValues:Array<Float> = [];
    var graphicsData:Array<FlxSprite> = [];
    
    var updateTimer:Float = 0;
    var smoothing:Float = 0.65;

    var targetFPS:Int = 60;
    
    public function new(sound:FlxSound = null, x:Float = 0, y:Float = 0, width:Int = 400, height:Int = 100, barCount:Int = 64, color:FlxColor = FlxColor.WHITE)
    {
        super(x, y);
        
        this.sound = sound;
        this._width = width;
        this._height = height;
        this.barCount = barCount;
        this._color = color;
        
        makeGraphic(width, height, FlxColor.TRANSPARENT);
        
        _barWidth = (width / barCount) - _gap;

        for (i in 0...barCount)
        {
            frequencyData[i] = 0;
            falloffValues[i] = 0;
        }

        setTargetFPS();
        
        setupBars();
    }
    
    function setTargetFPS():Void
    {
        #if android
        import backend.AndroidOptimizer;

        var tier = AndroidOptimizer.getCurrentTier();

        switch (tier)
        {
            case 0:
                targetFPS = 30;
                trace('AudioVisualizer: Using 30 FPS for low-end device');
            case 1, 2:
                targetFPS = 60;
                trace('AudioVisualizer: Using 60 FPS for mid/high-end device');
            default:
                targetFPS = 60;
        }
        #else
        targetFPS = 60;
        #end
    }
    
    function setupBars()
    {
        for (bar in graphicsData)
        {
            remove(bar);
            bar.destroy();
        }
        graphicsData = [];

        for (i in 0...barCount)
        {
            var bar = new FlxSprite(x + (i * (_barWidth + _gap)), y);
            bar.makeGraphic(Std.int(_barWidth), 1, _color);
            bar.origin.set(0, 0);
            graphicsData.push(bar);
        }
    }
    
    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        updateTimer += elapsed;
        var updateInterval = 1.0 / targetFPS;
        
        if (updateTimer >= updateInterval)
        {
            updateTimer = 0;
            
            if (sound != null && sound.playing)
            {
                updateAudioData();
            }
            else
            {
                applyFalloff();
            }
            
            applySmoothing();
            updateBars();
        }
    }
    
    function updateAudioData()
    {
        var time = FlxG.game.ticks / 1000;
        var volume = sound.volume * FlxG.sound.volume;
        
        for (i in 0...barCount)
        {
            var freq = 1 + i * 0.2;
            var bass = Math.sin(time * 1.5) * 0.3 + 0.3;
            var mid = Math.sin(time * freq) * 0.2 + 0.2;
            var high = Math.sin(time * freq * 3) * 0.1 + 0.1;
            
            var value = bass + mid + high;
            value += Math.random() * 0.1 - 0.05;
            
            value = FlxMath.bound(value * volume * sensitivity, 0, 1);
            frequencyData[i] = value;
        }
    }
    
    function applyFalloff()
    {
        for (i in 0...barCount)
        {
            frequencyData[i] *= falloffSpeed;
            if (frequencyData[i] < 0.01) frequencyData[i] = 0;
        }
    }
    
    function applySmoothing()
    {
        for (i in 0...barCount)
        {
            var target = frequencyData[i];
            var current = falloffValues[i];
            falloffValues[i] = FlxMath.lerp(current, target, 1 - Math.pow(smoothing, 1));
        }
    }
    
    function updateBars()
    {
        for (i in 0...barCount)
        {
            var bar = graphicsData[i];
            if (bar != null)
            {
                var value = falloffValues[i];
                var targetHeight = Math.max(_height / 40, value * _height);
                bar.scale.y = FlxMath.lerp(bar.scale.y, targetHeight, 0.3);
                bar.y = y - bar.scale.y;
                bar.color = _color;
            }
        }
    }
    
    public function setColor(color:FlxColor)
    {
        _color = color;
        for (bar in graphicsData)
        {
            bar.color = color;
        }
    }
    
    public function setBarCount(count:Int)
    {
        if (barCount != count)
        {
            barCount = count;
            _barWidth = (_width / barCount) - _gap;
            setupBars();
        }
    }
    
    public function setSensitivity(value:Float)
    {
        sensitivity = FlxMath.bound(value, 0.1, 3.0);
    }
    
    public function setFalloffSpeed(value:Float)
    {
        falloffSpeed = FlxMath.bound(value, 0.5, 0.99);
    }
    
    public function getAverageLevel():Float
    {
        var sum = 0.0;
        for (value in frequencyData) sum += value;
        return sum / frequencyData.length;
    }
    
    override function draw()
    {
        for (bar in graphicsData)
        {
            bar.draw();
        }
        super.draw();
    }
    
    override function destroy()
    {
        for (bar in graphicsData)
        {
            bar.destroy();
        }
        graphicsData = null;
        frequencyData = null;
        falloffValues = null;
        
        super.destroy();
    }
}