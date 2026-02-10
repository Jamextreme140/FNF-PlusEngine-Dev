package funkin.mobile;

#if android
import flixel.FlxG;
import openfl.system.System;

/**
 * Sistema automático de optimización para dispositivos Android
 * Ajusta configuraciones basándose en el hardware del dispositivo
 */
#if cpp
@:cppInclude("unistd.h")
#end
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
     * Improved detection for more GPU models and better accuracy
     */
    private static function detectDeviceTier():Int
    {
        var gpuName = funkin.util.Native.detectGPU();
        var totalRAM = getTotalRAM();
        var cpuCores = getCPUCores();
        
        trace('AndroidOptimizer: GPU: $gpuName, RAM: ${totalRAM}MB, CPU Cores: $cpuCores');
        
        if (gpuName == null || gpuName == 'Unknown')
        {
            // Fallback to RAM + CPU core based detection
            if (totalRAM >= 8000 && cpuCores >= 8) return GPU_TIER_HIGH;
            if (totalRAM >= 6000 && cpuCores >= 6) return GPU_TIER_HIGH;
            if (totalRAM >= 4000 && cpuCores >= 4) return GPU_TIER_MID;
            if (totalRAM >= 3000) return GPU_TIER_MID;
            return GPU_TIER_LOW;
        }
        
        var gpu = gpuName.toLowerCase();
        
        // Qualcomm Adreno detection (improved)
        if (gpu.indexOf('adreno') != -1)
        {
            var modelMatch = ~/(\d{3})/;
            if (modelMatch.match(gpu))
            {
                var model = Std.parseInt(modelMatch.matched(1));
                // Adreno 7xx+ = Flagship tier
                if (model >= 730) return GPU_TIER_HIGH;
                // Adreno 650-725 = High tier
                if (model >= 650) return GPU_TIER_HIGH;
                // Adreno 6xx low-end and 5xx = Mid tier
                if (model >= 510) return GPU_TIER_MID;
                // Adreno 4xx and below = Low tier
                return GPU_TIER_LOW;
            }
        }
        
        // ARM Mali detection (expanded)
        if (gpu.indexOf('mali') != -1)
        {
            // Mali-G7x, G8x, G9x = High tier (newer gens)
            if (gpu.indexOf('g7') != -1 || gpu.indexOf('g8') != -1 || gpu.indexOf('g9') != -1)
                return GPU_TIER_HIGH;
            // Mali-G5x and G6x = Mid tier
            if (gpu.indexOf('g5') != -1 || gpu.indexOf('g6') != -1)
                return GPU_TIER_MID;
            // Mali-G4x = Low-Mid tier
            if (gpu.indexOf('g4') != -1)
                return totalRAM >= 4000 ? GPU_TIER_MID : GPU_TIER_LOW;
            // Older Mali (T series, etc) = Low tier
            return GPU_TIER_LOW;
        }
        
        // Qualcomm Snapdragon integrated GPUs (older naming)
        if (gpu.indexOf('snapdragon') != -1)
        {
            var modelMatch = ~/(\d{3})/;
            if (modelMatch.match(gpu))
            {
                var model = Std.parseInt(modelMatch.matched(1));
                if (model >= 870) return GPU_TIER_HIGH;
                if (model >= 730) return GPU_TIER_MID;
                return GPU_TIER_LOW;
            }
        }
        
        // PowerVR detection (Apple devices on Android emulation or old devices)
        if (gpu.indexOf('powervr') != -1 || gpu.indexOf('sgx') != -1)
        {
            // Modern PowerVR Rogue = Mid tier
            if (gpu.indexOf('rogue') != -1)
                return GPU_TIER_MID;
            // Older PowerVR = Low tier
            return GPU_TIER_LOW;
        }
        
        // NVIDIA Tegra detection
        if (gpu.indexOf('tegra') != -1)
        {
            // Tegra X1+ = High tier (Shield, some tablets)
            if (gpu.indexOf('x1') != -1 || gpu.indexOf('x2') != -1)
                return GPU_TIER_HIGH;
            // Older Tegra = Mid tier
            return GPU_TIER_MID;
        }
        
        // Intel GPUs (rare on Android but possible)
        if (gpu.indexOf('intel') != -1)
        {
            if (gpu.indexOf('iris') != -1) return GPU_TIER_MID;
            return GPU_TIER_LOW;
        }
        
        // Vivante, IMG (Imagination), and other less common GPUs
        if (gpu.indexOf('vivante') != -1 || gpu.indexOf('img') != -1)
            return GPU_TIER_LOW;
        
        // Default to mid-tier if unknown but with RAM consideration
        if (totalRAM >= 6000) return GPU_TIER_HIGH;
        if (totalRAM >= 3000) return GPU_TIER_MID;
        return GPU_TIER_LOW;
    }
    
    /**
     * Get CPU core count for better tier detection
     */
    private static function getCPUCores():Int
    {
        #if cpp
        try
        {
            // Get CPU cores using sysconf
            var cores:Int = untyped __cpp__('sysconf(_SC_NPROCESSORS_ONLN)');
            if (cores > 0) return cores;
            
            // Fallback: estimate based on RAM
            var ram = getTotalRAM();
            if (ram >= 8000) return 8;
            if (ram >= 6000) return 6;
            if (ram >= 4000) return 4;
            return 2;
        }
        catch (e:Dynamic)
        {
            return 4; // Safe default
        }
        #else
        return 4; // Default
        #end
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
        funkin.audio.AudioOptimizer.resetSoundCount();
        
        trace('AndroidOptimizer: Core optimization systems initialized');
    }
    
    /**
     * Optimizations for low-end devices (Adreno 4xx, Mali-G3x, old PowerVR, <3GB RAM)
     * Maximum performance focus, minimum quality
     */
    private static function applyLowEndOptimizations():Void
    {
        trace('AndroidOptimizer: Applying LOW-END optimizations');
        
        // Graphics - Minimum quality for maximum performance
        ClientPrefs.data.lowQuality = true;
        ClientPrefs.data.antialiasing = false;
        ClientPrefs.data.shaders = false;
        ClientPrefs.data.cacheOnGPU = false; // GPU too weak
        ClientPrefs.data.framerate = 30; // Lower FPS for better stability
        
        // Gameplay - Disable heavy effects
        ClientPrefs.data.camZooms = false; // Disable camera zooms
        ClientPrefs.data.splashAlpha = 0.0; // Disable note splashes
        ClientPrefs.data.hideSustainSplash = true;
        ClientPrefs.data.hideHud = false; // Keep HUD but minimal
        ClientPrefs.data.flashing = false; // Disable flashing lights
        
        // Modchart optimizations - Maximum optimization
        ClientPrefs.data.camera3dEnabled = false;
        ClientPrefs.data.optimizeHolds = true; // Enable hold optimization
        ClientPrefs.data.holdCacheEnabled = false; // Disable cache to save RAM
        ClientPrefs.data.holdAlphaDivisions = 8; // Minimum divisions
        ClientPrefs.data.renderArrowPaths = false;
        ClientPrefs.data.styledArrowPaths = false;
        ClientPrefs.data.holdSubdivisions = 1; // Lowest subdivision
        
        // UI - Minimal overhead
        ClientPrefs.data.showFPS = false; // Disable FPS counter overhead
        ClientPrefs.data.fpsDebugLevel = 0;
        ClientPrefs.data.pauseMusic = 'None'; // No pause music to save memory
        
        // Memory - Aggressive management
        ClientPrefs.data.heavyCharts = true; // Enable heavy chart mode
        ClientPrefs.data.legacyMemoryManagement = false; // Use modern memory management
        
        // Enable aggressive bitmap optimization
        #if !macro
        funkin.graphics.OptimizedBitmapData.enableAggressiveMode();
        #end
        
        // Set thread pool to minimum
        #if (target.threaded && sys)
        funkin.util.ThreadUtil.setMaxThreads(1);
        #end
        
        trace('AndroidOptimizer: LOW-END mode active - Maximum optimization enabled');
    }
    
    /**
     * Optimizations for mid-range devices (Adreno 5xx-6xx, Mali-G5x-G6x, 3-6GB RAM)
     * Balanced performance and quality
     */
    private static function applyMidRangeOptimizations():Void
    {
        trace('AndroidOptimizer: Applying MID-RANGE optimizations');
        
        // Graphics - Balanced settings
        ClientPrefs.data.lowQuality = false;
        ClientPrefs.data.antialiasing = true;
        ClientPrefs.data.shaders = false; // Shaders still heavy for mid-range
        ClientPrefs.data.cacheOnGPU = true; // GPU can handle caching
        ClientPrefs.data.framerate = 60; // Full 60 FPS
        
        // Gameplay - Most effects enabled
        ClientPrefs.data.camZooms = true;
        ClientPrefs.data.splashAlpha = 0.4; // Reduced splash opacity
        ClientPrefs.data.hideSustainSplash = false;
        ClientPrefs.data.flashing = true;
        
        // Modchart optimizations - Moderate
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
        
        // Memory - Balanced
        ClientPrefs.data.heavyCharts = false;
        ClientPrefs.data.legacyMemoryManagement = false;
        
        // Normal bitmap optimization
        #if !macro
        funkin.graphics.OptimizedBitmapData.aggressiveOptimization = false;
        funkin.graphics.OptimizedBitmapData.forceGPUUpload = true;
        #end
        
        // Set thread pool to moderate
        #if (target.threaded && sys)
        funkin.util.ThreadUtil.setMaxThreads(2);
        #end
        
        trace('AndroidOptimizer: MID-RANGE mode active - Balanced optimization');
    }
    
    /**
     * Optimizations for high-end devices (Adreno 650+, Mali-G7x+, 6GB+ RAM)
     * Maximum quality with good performance
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
        
        // Gameplay - All effects enabled
        ClientPrefs.data.camZooms = true;
        ClientPrefs.data.splashAlpha = 0.6; // Full splash opacity
        ClientPrefs.data.hideSustainSplash = false;
        ClientPrefs.data.flashing = true;
        
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
        ClientPrefs.data.fpsDebugLevel = 1; // Show more debug info
        
        // Memory - Less aggressive
        ClientPrefs.data.heavyCharts = false;
        ClientPrefs.data.legacyMemoryManagement = false;
        
        // Disable aggressive optimization for quality
        #if !macro
        funkin.graphics.OptimizedBitmapData.aggressiveOptimization = false;
        funkin.graphics.OptimizedBitmapData.forceGPUUpload = true;
        #end
        
        // Set thread pool to maximum
        #if (target.threaded && sys)
        funkin.util.ThreadUtil.setMaxThreads(4);
        #end
        
        trace('AndroidOptimizer: HIGH-END mode active - Maximum quality enabled');
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
