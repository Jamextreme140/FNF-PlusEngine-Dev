package funkin.mobile;

#if android
import flixel.FlxG;
import openfl.system.System;

/**
 * Sistema automático de optimización para dispositivos Android
 * Ajusta configuraciones basándose en el hardware del dispositivo
 */
class AndroidOptimizer
{
    // GPU Tiers for automatic quality adjustment
    public static var GPU_TIER_LOW:Int = 0;
    public static var GPU_TIER_MID:Int = 1;
    public static var GPU_TIER_HIGH:Int = 2;
    
    private static var detectedTier:Int = -1;
    private static var hasBeenOptimized:Bool = false;
    
    /**
     * Main initialization - Call this on game startup
     */
    public static function init():Void
    {
        if (hasBeenOptimized) return;
        
        trace('AndroidOptimizer: Initializing auto-optimization...');
        
        // Detect device tier
        detectedTier = detectDeviceTier();
        
        // Apply optimizations based on tier
        applyOptimizations(detectedTier);
        
        hasBeenOptimized = true;
        trace('AndroidOptimizer: Optimization complete. Device tier: $detectedTier');
    }
    
    /**
     * Detects device performance tier based on GPU and RAM
     */
    private static function detectDeviceTier():Int
    {
        var gpuName = Native.detectGPU();
        var totalRAM = getTotalRAM();
        
        trace('AndroidOptimizer: GPU: $gpuName, RAM: ${totalRAM}MB');
        
        if (gpuName == null || gpuName == 'Unknown')
        {
            // Fallback to RAM-based detection
            if (totalRAM >= 6000) return GPU_TIER_HIGH;
            if (totalRAM >= 3000) return GPU_TIER_MID;
            return GPU_TIER_LOW;
        }
        
        var gpu = gpuName.toLowerCase();
        
        // Qualcomm Adreno detection
        if (gpu.indexOf('adreno') != -1)
        {
            var modelMatch = ~/(\d{3})/;
            if (modelMatch.match(gpu))
            {
                var model = Std.parseInt(modelMatch.matched(1));
                // Adreno 7xx+ and 6xx high-end = High tier
                if (model >= 650) return GPU_TIER_HIGH;
                // Adreno 6xx low-end and 5xx = Mid tier
                if (model >= 500) return GPU_TIER_MID;
                // Adreno 4xx and below = Low tier
                return GPU_TIER_LOW;
            }
        }
        
        // ARM Mali detection
        if (gpu.indexOf('mali') != -1)
        {
            // Mali-G7x and G8x = High tier
            if (gpu.indexOf('g7') != -1 || gpu.indexOf('g8') != -1)
                return GPU_TIER_HIGH;
            // Mali-G5x and G6x = Mid tier
            if (gpu.indexOf('g5') != -1 || gpu.indexOf('g6') != -1)
                return GPU_TIER_MID;
            // Older Mali = Low tier
            return GPU_TIER_LOW;
        }
        
        // PowerVR, Tegra, and other GPUs
        if (gpu.indexOf('powervr') != -1 || gpu.indexOf('sgx') != -1)
            return GPU_TIER_LOW;
            
        if (gpu.indexOf('tegra') != -1)
            return GPU_TIER_MID;
        
        // Default to mid-tier if unknown
        return GPU_TIER_MID;
    }
    
    /**
     * Apply optimizations based on device tier
     */
    private static function applyOptimizations(tier:Int):Void
    {
        switch(tier)
        {
            case 0: // Low-end devices
                applyLowEndOptimizations();
            case 1: // Mid-range devices
                applyMidRangeOptimizations();
            case 2: // High-end devices
                applyHighEndOptimizations();
            default:
                applyMidRangeOptimizations(); // Safe default
        }
        
        // Initialize optimization systems
        ObjectPool.init();
        AudioOptimizer.resetSoundCount();
        
        trace('AndroidOptimizer: Core optimization systems initialized');
    }
    
    /**
     * Optimizations for low-end devices (Adreno 4xx, Mali-G3x, old PowerVR, <3GB RAM)
     */
    private static function applyLowEndOptimizations():Void
    {
        trace('AndroidOptimizer: Applying LOW-END optimizations');
        
        // Graphics
        ClientPrefs.data.lowQuality = true;
        ClientPrefs.data.antialiasing = false;
        ClientPrefs.data.shaders = false;
        ClientPrefs.data.cacheOnGPU = false; // GPU too weak
        ClientPrefs.data.framerate = 30; // Lower FPS for better stability
        
        // Gameplay
        ClientPrefs.data.camZooms = false; // Disable camera zooms
        ClientPrefs.data.splashAlpha = 0.0; // Disable note splashes
        ClientPrefs.data.hideSustainSplash = true;
        
        // Modchart optimizations
        ClientPrefs.data.camera3dEnabled = false;
        ClientPrefs.data.optimizeHolds = true; // Enable hold optimization
        ClientPrefs.data.holdCacheEnabled = false; // Disable cache to save RAM
        ClientPrefs.data.holdAlphaDivisions = 10; // Minimum divisions
        ClientPrefs.data.renderArrowPaths = false;
        ClientPrefs.data.styledArrowPaths = false;
        ClientPrefs.data.holdSubdivisions = 2; // Lower subdivision
        
        // UI
        ClientPrefs.data.showFPS = false; // Disable FPS counter overhead
        ClientPrefs.data.fpsDebugLevel = 0;
        
        // Memory
        ClientPrefs.data.heavyCharts = true; // Enable heavy chart mode for better memory management
    }
    
    /**
     * Optimizations for mid-range devices (Adreno 5xx-6xx, Mali-G5x-G6x, 3-6GB RAM)
     */
    private static function applyMidRangeOptimizations():Void
    {
        trace('AndroidOptimizer: Applying MID-RANGE optimizations');
        
        // Graphics - Balanced
        ClientPrefs.data.lowQuality = false;
        ClientPrefs.data.antialiasing = true;
        ClientPrefs.data.shaders = false; // Shaders still heavy for mid-range
        ClientPrefs.data.cacheOnGPU = true; // GPU can handle caching
        ClientPrefs.data.framerate = 60; // Full 60 FPS
        
        // Gameplay
        ClientPrefs.data.camZooms = true;
        ClientPrefs.data.splashAlpha = 0.4; // Reduced splash opacity
        ClientPrefs.data.hideSustainSplash = false;
        
        // Modchart optimizations
        ClientPrefs.data.camera3dEnabled = true;
        ClientPrefs.data.optimizeHolds = false;
        ClientPrefs.data.holdCacheEnabled = true;
        ClientPrefs.data.holdAlphaDivisions = 15; // Medium divisions
        ClientPrefs.data.renderArrowPaths = false; // Still disable paths
        ClientPrefs.data.styledArrowPaths = false;
        ClientPrefs.data.holdSubdivisions = 3;
        
        // UI
        ClientPrefs.data.showFPS = true;
        ClientPrefs.data.fpsDebugLevel = 0;
        
        // Memory
        ClientPrefs.data.heavyCharts = false;
    }
    
    /**
     * Optimizations for high-end devices (Adreno 650+, Mali-G7x+, 6GB+ RAM)
     */
    private static function applyHighEndOptimizations():Void
    {
        trace('AndroidOptimizer: Applying HIGH-END optimizations');
        
        // Graphics - Full quality
        ClientPrefs.data.lowQuality = false;
        ClientPrefs.data.antialiasing = true;
        ClientPrefs.data.shaders = true; // Enable shaders
        ClientPrefs.data.cacheOnGPU = true;
        ClientPrefs.data.framerate = 60;
        
        // Gameplay
        ClientPrefs.data.camZooms = true;
        ClientPrefs.data.splashAlpha = 0.6; // Full splash opacity
        ClientPrefs.data.hideSustainSplash = false;
        
        // Modchart - Full features
        ClientPrefs.data.camera3dEnabled = true;
        ClientPrefs.data.optimizeHolds = false;
        ClientPrefs.data.holdCacheEnabled = true;
        ClientPrefs.data.holdAlphaDivisions = 20; // Maximum divisions
        ClientPrefs.data.renderArrowPaths = true;
        ClientPrefs.data.styledArrowPaths = true;
        ClientPrefs.data.holdSubdivisions = 4;
        
        // UI
        ClientPrefs.data.showFPS = true;
        ClientPrefs.data.fpsDebugLevel = 1;
        
        // Memory
        ClientPrefs.data.heavyCharts = false;
    }
    
    /**
     * Get total device RAM in MB
     */
    private static function getTotalRAM():Int
    {
        #if cpp
        // Try to get system memory
        var totalMem:Float = System.totalMemory / (1024 * 1024);
        
        // Estimate total system RAM (current memory * 4 is a rough estimate)
        var estimatedRAM:Int = Std.int(totalMem * 4);
        
        // Clamp between reasonable values
        if (estimatedRAM < 1000) estimatedRAM = 2000; // Minimum 2GB assumption
        if (estimatedRAM > 16000) estimatedRAM = 8000; // Cap at 8GB for mobile
        
        return estimatedRAM;
        #else
        return 4000; // Default 4GB assumption
        #end
    }
    
    /**
     * Get current device tier
     */
    public static function getCurrentTier():Int
    {
        if (detectedTier == -1)
            init();
        return detectedTier;
    }
    
    /**
     * Get tier name as string
     */
    public static function getTierName():String
    {
        return switch(getCurrentTier())
        {
            case 0: "Low-End";
            case 1: "Mid-Range";
            case 2: "High-End";
            default: "Unknown";
        }
    }
    
    /**
     * Manual override for testing
     */
    public static function forceOptimizationTier(tier:Int):Void
    {
        trace('AndroidOptimizer: Forcing tier $tier');
        applyOptimizations(tier);
    }
}
#else
// Dummy class for non-Android platforms
class AndroidOptimizer
{
    public static function init():Void {}
    public static function getCurrentTier():Int { return 2; }
    public static function getTierName():String { return "Desktop"; }
    public static function forceOptimizationTier(tier:Int):Void {}
}
#end
