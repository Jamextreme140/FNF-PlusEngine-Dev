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
     * Only runs once per installation
     */
    public static function init():Void
    {
        if (hasBeenOptimized) return;
        
        // Check if optimizations were already applied in a previous session
        if (ClientPrefs.data.androidOptimizationsApplied == true)
        {
            hasBeenOptimized = true;
            return;
        }
        
        // Apply buffer optimization to prevent NO_BUFFER_AVAILABLE errors
        applyBufferOptimizations();
        
        // Detect device tier (GPU-based only)
        detectedTier = detectDeviceTier();
        
        // Apply optimizations based on tier
        applyOptimizations(detectedTier);
        
        // Mark as optimized (will be saved automatically by ClientPrefs system)
        hasBeenOptimized = true;
        ClientPrefs.data.androidOptimizationsApplied = true;
    }
    
    /**
     * Apply buffer optimizations to prevent NO_BUFFER_AVAILABLE errors
     * This synchronizes the framerate with the display refresh rate
     */
    private static function applyBufferOptimizations():Void
    {
        // Enable VSync through FlxG if available
        #if (!html5)
        try
        {
            // Sync with display refresh rate
            var refreshRate:Int = getDisplayRefreshRate();
            FlxG.stage.frameRate = refreshRate;
            
            // Ensure proper frame pacing
            FlxG.drawFramerate = refreshRate;
            FlxG.updateFramerate = refreshRate;
        }
        catch (e:Dynamic)
        {
            // Silent fail - default settings will be used
        }
        #end
    }
    
    /**
     * Get the display refresh rate (defaults to 60 if unable to detect)
     */
    private static function getDisplayRefreshRate():Int
    {
        try
        {
            // Try to get from Lime's display API
            #if lime
            var display = lime.system.System.getDisplay(0); // Get primary display
            if (display != null && display.currentMode != null)
            {
                var refreshRate = display.currentMode.refreshRate;
                if (refreshRate > 0)
                {
                    // Validate the rate (most displays are 60, 90, 120, or 144 Hz)
                    if (refreshRate >= 30 && refreshRate <= 165)
                    {
                        return refreshRate;
                    }
                }
            }
            #end
        }
        catch (e:Dynamic)
        {
            // Silent fail
        }
        
        // Default to 60Hz for compatibility
        return 60;
    }
    
    /**
     * Detects device performance tier based on GPU only
     * RAM detection is disabled as it's unreliable on Android
     */
    private static function detectDeviceTier():Int
    {
        var gpuName = funkin.util.Native.detectGPU();
        var cpuCores = getCPUCores();
        
        if (gpuName == null || gpuName == 'Unknown')
        {
            // Fallback to CPU core based detection only
            if (cpuCores >= 8) return GPU_TIER_HIGH;
            if (cpuCores >= 6) return GPU_TIER_MID;
            if (cpuCores >= 4) return GPU_TIER_MID;
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
                return cpuCores >= 6 ? GPU_TIER_MID : GPU_TIER_LOW;
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
        
        // Default to mid-tier if unknown, use CPU cores as fallback
        if (cpuCores >= 8) return GPU_TIER_HIGH;
        if (cpuCores >= 4) return GPU_TIER_MID;
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
            
            // Safe default
            return 4;
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
    }
    
    /**
     * Optimizations for low-end devices (Adreno 4xx, Mali-G3x, old PowerVR)
     * Maximum performance focus, minimum quality
     */
    private static function applyLowEndOptimizations():Void
    {
        
        // Graphics - Minimum quality for maximum performance
        ClientPrefs.data.lowQuality = true;
        ClientPrefs.data.antialiasing = false;
        ClientPrefs.data.shaders = false;
        ClientPrefs.data.cacheOnGPU = false; // GPU too weak
        ClientPrefs.data.framerate = Math.floor(getDisplayRefreshRate() / 2); // Half refresh rate for stability
        
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
    }
    
    /**
     * Optimizations for mid-range devices (Adreno 5xx-6xx, Mali-G5x-G6x, 3-6GB RAM)
     * Balanced performance and quality
     */
    private static function applyMidRangeOptimizations():Void
    {
        // Graphics - Balanced settings
        ClientPrefs.data.lowQuality = false;
        ClientPrefs.data.antialiasing = true;
        ClientPrefs.data.shaders = false; // Shaders still heavy for mid-range
        ClientPrefs.data.cacheOnGPU = true; // GPU can handle caching
        ClientPrefs.data.framerate = getDisplayRefreshRate(); // Match display refresh rate
        
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
    }
    
    /**
     * Optimizations for high-end devices (Adreno 650+, Mali-G7x+, 6GB+ RAM)
     * Maximum quality with good performance
     */
    private static function applyHighEndOptimizations():Void
    {
        // Graphics - Full quality
        ClientPrefs.data.lowQuality = false;
        ClientPrefs.data.antialiasing = true;
        ClientPrefs.data.shaders = true; // Enable shaders
        ClientPrefs.data.cacheOnGPU = true;
        ClientPrefs.data.framerate = getDisplayRefreshRate(); // Match display refresh rate
        
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
