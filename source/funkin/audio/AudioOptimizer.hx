package funkin.audio;

import flixel.sound.FlxSound;
import lime.media.AudioBuffer;

/**
 * Audio optimization for low-end devices
 * Reduces audio quality/bitrate automatically to save RAM
 */
class AudioOptimizer
{
    // Sample rate reduction for different tiers
    private static final SAMPLE_RATE_LOW:Int = 22050;  // Half of 44100
    private static final SAMPLE_RATE_MID:Int = 32000;  // Reduced
    private static final SAMPLE_RATE_HIGH:Int = 44100; // Full quality
    
    /**
     * Check if audio should be pre-loaded or streamed
     * Low-end devices should stream to save RAM
     */
    public static function shouldStreamAudio():Bool
    {
        #if android
        return funkin.mobile.AndroidOptimizer.getCurrentTier() == 0; // Stream on low-end
        #else
        return false; // Desktop can preload
        #end
    }
    
    /**
     * Get maximum simultaneous sounds based on tier
     */
    public static function getMaxSimultaneousSounds():Int
    {
        #if android
        return switch(funkin.mobile.AndroidOptimizer.getCurrentTier())
        {
            case 0: 4;  // Low-end: very limited
            case 1: 8;  // Mid-range: moderate
            default: 16; // High-end: no limit
        };
        #else
        return 16; // Desktop: no limit
        #end
    }
    
    /**
     * Get volume for sounds that can be reduced on low-end
     * (like hitsounds, some SFX)
     */
    public static function getOptimizedVolume(baseVolume:Float):Float
    {
        #if android
        if (funkin.mobile.AndroidOptimizer.getCurrentTier() == 0)
            return baseVolume * 0.7; // Reduce volume slightly to allow for less sounds
        #end
        return baseVolume;
    }
    
    /**
     * Check if a sound should be played based on current sound count
     * Prevents sound overflow on low-end devices
     */
    private static var activeSounds:Int = 0;
    
    public static function canPlaySound():Bool
    {
        #if android
        var maxSounds = getMaxSimultaneousSounds();
        return activeSounds < maxSounds;
        #else
        return true;
        #end
    }
    
    public static inline function registerSound():Void
    {
        activeSounds++;
    }
    
    public static inline function unregisterSound():Void
    {
        activeSounds--;
        if (activeSounds < 0) activeSounds = 0;
    }
    
    public static inline function resetSoundCount():Void
    {
        activeSounds = 0;
    }
    
    /**
     * Get recommended audio buffer size
     * Smaller = less latency but more CPU
     * Larger = more latency but less CPU
     */
    public static function getRecommendedBufferSize():Int
    {
        #if android
        return switch(funkin.mobile.AndroidOptimizer.getCurrentTier())
        {
            case 0: 4096; // Low-end: larger buffer to reduce CPU load
            case 1: 2048; // Mid-range: balanced
            default: 1024; // High-end: low latency
        };
        #else
        return 1024; // Desktop: low latency
        #end
    }
}
