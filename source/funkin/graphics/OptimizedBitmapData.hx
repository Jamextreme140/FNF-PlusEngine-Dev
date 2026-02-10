package funkin.graphics;

import openfl.display.BitmapData;
import lime.graphics.Image;
import flixel.FlxG;

#if !macro
/**
 * Optimized BitmapData class that immediately uploads textures to GPU
 * and disposes of CPU-side data to save RAM, especially on low-end devices.
 * 
 * Based on Codename Engine's implementation but adapted for PlusEngine.
 * This is crucial for Android and low-end PCs with limited RAM.
 */
class OptimizedBitmapData extends BitmapData
{
    /**
     * Whether to aggressively dispose CPU data after GPU upload
     * Enabled by default on Android and low-end devices
     */
    public static var aggressiveOptimization:Bool = #if android true #else false #end;
    
    /**
     * Whether to force GPU upload on creation
     */
    public static var forceGPUUpload:Bool = true;
    
    @SuppressWarnings("checkstyle:Dynamic")
    @:noCompletion 
    private override function __fromImage(image:#if lime Image #else Dynamic #end):Void
    {
        #if lime
        if (image != null && image.buffer != null)
        {
            this.image = image;
            width = image.width;
            height = image.height;
            rect = new openfl.geom.Rectangle(0, 0, image.width, image.height);

            __textureWidth = width;
            __textureHeight = height;

            #if sys
            // Prepare for GPU upload
            image.format = BGRA32;
            image.premultiplied = true;
            #end

            __isValid = true;
            readable = true;

            // Immediately upload to GPU if context exists
            if (forceGPUUpload && FlxG.stage != null && FlxG.stage.context3D != null) 
            {
                lock();
                
                // Force GPU texture creation
                getTexture(FlxG.stage.context3D);
                getSurface();

                // On low-end devices or Android, dispose CPU data immediately
                if (aggressiveOptimization)
                {
                    readable = true;
                    
                    // Dispose CPU-side image data to save RAM
                    // The GPU texture is already uploaded, so this is safe
                    #if (cpp || neko)
                    if (image.data != null)
                    {
                        this.image = null;
                        
                        // Force small GC to clean up immediately
                        #if cpp
                        cpp.vm.Gc.run(false);
                        #elseif neko
                        neko.vm.Gc.run(false);
                        #end
                    }
                    #end
                }
            }
        }
        #end
    }

    @SuppressWarnings("checkstyle:Dynamic")
    @:dox(hide) 
    public override function getSurface():#if lime lime.graphics.cairo.CairoImageSurface #else Dynamic #end
    {
        #if lime
        if (__surface == null)
        {
            __surface = lime.graphics.cairo.CairoImageSurface.fromImage(image);
        }
        return __surface;
        #else
        return null;
        #end
    }
    
    /**
     * Enable aggressive optimization mode
     * Call this at game startup for low-end devices
     */
    public static function enableAggressiveMode():Void
    {
        aggressiveOptimization = true;
        forceGPUUpload = true;
        trace('[OptimizedBitmapData] Aggressive optimization enabled');
    }
    
    /**
     * Disable aggressive optimization mode
     * Use this if experiencing texture issues
     */
    public static function disableAggressiveMode():Void
    {
        aggressiveOptimization = false;
        forceGPUUpload = false;
        trace('[OptimizedBitmapData] Aggressive optimization disabled');
    }
}
#end
