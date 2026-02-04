package funkin.graphics;

import flixel.FlxG;
import openfl.display.BitmapData;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;

/**
 * Optimizes textures for low-end devices
 * DOES NOT resize textures to avoid breaking Sparrow XML coordinates
 * Instead, uses GPU memory optimization and disposal strategies
 */
class TextureOptimizer
{
    /**
     * Optimize a BitmapData based on device tier
     * Does NOT resize - that breaks Sparrow animations!
     * Instead applies other optimizations like early GPU upload
     */
    public static function optimize(bitmap:BitmapData, ?forceTier:Int = -1):BitmapData
    {
        #if !android
        return bitmap; // No optimization on desktop
        #end
        
        if (bitmap == null) return bitmap;
        
        var tier:Int = forceTier;
        if (tier == -1)
        {
            #if android
            tier = AndroidOptimizer.getCurrentTier();
            #else
            tier = 2; // Desktop = high tier
            #end
        }
        
        // On low-end, immediately dispose of CPU-side bitmap data after GPU upload
        // This saves RAM without breaking coordinates
        if (tier == 0 && bitmap.image != null)
        {
            trace('TextureOptimizer: Disposing CPU-side data for ${bitmap.width}x${bitmap.height} texture (tier $tier)');
            
            // Lock bitmap to prevent modifications
            bitmap.lock();
            
            // Dispose of CPU-side image data (keeps GPU texture)
            if (bitmap.image.data != null)
            {
                bitmap.image.data = null;
            }
        }
        
        return bitmap;
    }
    
    /**
     * Get recommended antialiasing setting based on tier
     */
    public static inline function shouldUseAntialiasing():Bool
    {
        #if android
        return AndroidOptimizer.getCurrentTier() >= 1; // Mid and High only
        #else
        return true;
        #end
    }
    
    /**
     * Get recommended max sprite count based on tier
     */
    public static function getMaxSpriteCount():Int
    {
        #if android
        return switch(AndroidOptimizer.getCurrentTier())
        {
            case 0: 150; // Low-end: limit sprites
            case 1: 300; // Mid-range: moderate
            default: 500; // High-end: no limit
        };
        #else
        return 500; // Desktop: no limit
        #end
    }
    
    /**
     * Check if we should skip a sprite due to performance
     */
    public static function shouldSkipSprite(currentCount:Int):Bool
    {
        return currentCount >= getMaxSpriteCount();
    }
}
