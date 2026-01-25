package backend;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import objects.Note;

/**
 * Advanced object pooling system to reduce GC pressure
 * Automatically adjusts pool sizes based on device tier
 */
class ObjectPool
{
    // Sprite pools
    private static var spritePool:Array<FlxSprite> = [];
    private static var maxSpritePoolSize:Int = 50;
    
    // Note pools (separated by type)
    private static var notePool:Array<Note> = [];
    private static var maxNotePoolSize:Int = 200;
    
    private static var initialized:Bool = false;
    
    /**
     * Initialize pools with sizes based on device tier
     */
    public static function init():Void
    {
        if (initialized) return;
        
        #if android
        var tier = AndroidOptimizer.getCurrentTier();
        switch(tier)
        {
            case 0: // Low-end
                maxSpritePoolSize = 30;
                maxNotePoolSize = 150;
            case 1: // Mid-range
                maxSpritePoolSize = 50;
                maxNotePoolSize = 200;
            default: // High-end
                maxSpritePoolSize = 100;
                maxNotePoolSize = 300;
        }
        #else
        maxSpritePoolSize = 100;
        maxNotePoolSize = 300;
        #end
        
        trace('ObjectPool: Initialized with sprite pool: $maxSpritePoolSize, note pool: $maxNotePoolSize');
        initialized = true;
    }
    
    /**
     * Get a sprite from pool or create new one
     */
    public static function getSprite():FlxSprite
    {
        if (!initialized) init();
        
        if (spritePool.length > 0)
        {
            var sprite = spritePool.pop();
            sprite.revive();
            return sprite;
        }
        
        return new FlxSprite();
    }
    
    /**
     * Return sprite to pool
     */
    public static function returnSprite(sprite:FlxSprite):Void
    {
        if (sprite == null) return;
        
        sprite.kill();
        sprite.loadGraphic(null); // Clear texture reference
        
        if (spritePool.length < maxSpritePoolSize)
        {
            spritePool.push(sprite);
        }
        else
        {
            sprite.destroy(); // Pool is full, destroy sprite
        }
    }
    
    /**
     * Clear all pools and free memory
     */
    public static function clear():Void
    {
        for (sprite in spritePool)
            if (sprite != null) sprite.destroy();
        spritePool = [];
        
        for (note in notePool)
            if (note != null) note.destroy();
        notePool = [];
        
        trace('ObjectPool: Cleared all pools');
    }
    
    /**
     * Prewarm pools (create objects ahead of time)
     * Call during loading screens
     */
    public static function prewarm(?spriteCount:Int, ?noteCount:Int):Void
    {
        if (!initialized) init();
        
        if (spriteCount == null) spriteCount = Std.int(maxSpritePoolSize / 2);
        if (noteCount == null) noteCount = Std.int(maxNotePoolSize / 2);
        
        // Only prewarm on mid/high-end devices
        #if android
        if (AndroidOptimizer.getCurrentTier() == 0) return;
        #end
        
        trace('ObjectPool: Prewarming $spriteCount sprites...');
        for (i in 0...spriteCount)
        {
            var sprite = new FlxSprite();
            sprite.kill();
            spritePool.push(sprite);
        }
    }
    
    /**
     * Get pool statistics for debugging
     */
    public static function getStats():String
    {
        return 'ObjectPool Stats:\n' +
               '  Sprites: ${spritePool.length}/$maxSpritePoolSize\n' +
               '  Notes: ${notePool.length}/$maxNotePoolSize';
    }
}
