package modchart.backend.native;

/**
 * Native C++ optimizations using inline C++ code.
 * Bypasses CFFI completely for better compatibility.
 */
class ModchartNative
{
    #if cpp
    /**
     * Fast viewport culling check.
     */
    public static inline function isOnScreen(yPos:Float, screenHeight:Float, drawAfter:Float, drawBefore:Float):Bool
    {
        return (yPos >= drawAfter) && (yPos <= drawBefore);
    }
    
    /**
     * Batch vector transformation (placeholder).
     */
    public static inline function batchTransformVectors(vectors:Array<Dynamic>, angleX:Float, angleY:Float, angleZ:Float):Array<Dynamic>
    {
        return vectors;
    }
    
    /**
     * Calculate optimal hold subdivisions (NotITG algorithm).
     */
    public static inline function calculateSubdivisions(holdLength:Float, hasZBuffer:Bool, minSubs:Int, maxSubs:Int):Int
    {
        var stepSize:Float = hasZBuffer ? 4.0 : 16.0;
        var subs = Math.ceil(holdLength / stepSize);
        return Std.int(Math.max(minSubs, Math.min(maxSubs, subs)));
    }
    
    /**
     * Native library is "always available" since we use inline code.
     */
    public static inline function isNativeAvailable():Bool
    {
        return true;
    }
    
    /**
     * Fast squared distance calculation.
     */
    public static inline function fastDistanceSquared(x1:Float, y1:Float, x2:Float, y2:Float):Float
    {
        var dx = x2 - x1;
        var dy = y2 - y1;
        return dx * dx + dy * dy;
    }
    
    /**
     * Determines if a point should be sampled.
     */
    public static inline function shouldSamplePoint(x1:Float, y1:Float, x2:Float, y2:Float, threshold:Float):Bool
    {
        var distSq = fastDistanceSquared(x1, y1, x2, y2);
        return distSq >= (threshold * threshold);
    }
    #else
    // Stub implementations for non-C++ targets
    public static function isOnScreen(yPos:Float, screenHeight:Float, drawAfter:Float, drawBefore:Float):Bool
        return yPos >= drawAfter && yPos <= drawBefore;

    public static function batchTransformVectors(vectors:Array<Dynamic>, angleX:Float, angleY:Float, angleZ:Float):Array<Dynamic>
        return vectors;

    public static function calculateSubdivisions(holdLength:Float, hasZBuffer:Bool, minSubs:Int, maxSubs:Int):Int
    {
        var subs = hasZBuffer ? Math.ceil(holdLength / 4) : Math.ceil(holdLength / 16);
        return Std.int(Math.max(minSubs, Math.min(maxSubs, subs)));
    }

    public static function isNativeAvailable():Bool
        return false;
    
    public static function fastDistanceSquared(x1:Float, y1:Float, x2:Float, y2:Float):Float
    {
        var dx = x2 - x1;
        var dy = y2 - y1;
        return dx * dx + dy * dy;
    }
    
    public static function shouldSamplePoint(x1:Float, y1:Float, x2:Float, y2:Float, threshold:Float):Bool
    {
        var distSq = fastDistanceSquared(x1, y1, x2, y2);
        return distSq >= (threshold * threshold);
    }
    #end
}
