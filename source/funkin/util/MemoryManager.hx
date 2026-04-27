package funkin.util;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets;
import openfl.system.System;
import funkin.util.SystemMemory;

#if sys
import sys.FileSystem;
#end

/**
 * Advanced memory management system, especially optimized for Android and low-end PCs.
 * Allows dynamic asset freeing to reduce RAM consumption.
 * 
 * Improved with Codename Engine techniques
 */
class MemoryManager
{
    #if android
    private static var isAndroid:Bool = true;
    #else
    private static var isAndroid:Bool = false;
    #end
    
    /**
     * Whether aggressive memory management is enabled
     * Auto-enabled on low-end devices
     */
    public static var aggressiveMode:Bool = false;
    
    /**
     * Threshold for automatic cleanup (in MB)
     */
    public static var autoCleanupThreshold:Float = 500;
    
    /**
     * Last time automatic cleanup was run
     */
    private static var lastAutoCleanup:Float = 0;

    private static var cleanupCooldown:Float = 0;
    private static var pendingCleanupLevel:Int = 0;
    private static var pendingCleanupAge:Float = 0;
    private static var timeSinceGameplayCritical:Float = 9999;

    static inline var QUICK_CLEANUP_LEVEL:Int = 1;
    static inline var AGGRESSIVE_CLEANUP_LEVEL:Int = 2;
    static inline var ULTRA_CLEANUP_LEVEL:Int = 3;
    static inline var DEFERRED_CLEANUP_MIN_DELAY:Float = 0.75;
    static inline var QUICK_CLEANUP_GRACE_DELAY:Float = 0.8;
    static inline var AGGRESSIVE_CLEANUP_GRACE_DELAY:Float = 2.0;
    static inline var ULTRA_CLEANUP_GRACE_DELAY:Float = 3.5;
    static inline var QUICK_CLEANUP_COOLDOWN:Float = 8;
    static inline var AGGRESSIVE_CLEANUP_COOLDOWN:Float = 15;
    static inline var ULTRA_CLEANUP_COOLDOWN:Float = 25;
    
    /**
     * Interval between automatic cleanups (in seconds)
     */
    public static var autoCleanupInterval:Float = 30;
    
    /**
     * Initialize memory manager
     * Call this at game startup
     */
    public static function init():Void
    {
        // Get total system RAM (works on all platforms)
        var totalSystemRAM = SystemMemory.getTotalRAM();
        var ramString = SystemMemory.getTotalRAMString();
        var cpuCores = SystemMemory.getCPUCores();
        
        trace('\n\nSystem Info:\nTotal RAM: $ramString ($totalSystemRAM MB)\nCPU Cores: $cpuCores\n');
        
        #if android
        // On Android, also check optimizer tier
        var tier = funkin.mobile.AndroidOptimizer.getCurrentTier();
        trace('  - Android Tier: $tier');
        
        if (tier == 0 || (totalSystemRAM > 0 && totalSystemRAM < 3072))
        {
            trace('Low-end Android device detected');
            enableAggressiveMode();
        }
        #else
        // On desktop/other platforms, use RAM threshold
        if (totalSystemRAM > 0 && totalSystemRAM < 4096)
        {
            trace('Low-end device detected (${totalSystemRAM}MB RAM < 4GB)');
            enableAggressiveMode();
        }
        else if (totalSystemRAM >= 4096)
        {
            trace('High-end device detected (${totalSystemRAM}MB RAM >= 4GB)');
        }
        #end
        
        trace('Initialized (Aggressive: $aggressiveMode)');
    }
    
    /**
     * Enable aggressive memory management
     */
    public static function enableAggressiveMode():Void
    {
        aggressiveMode = true;
        autoCleanupThreshold = 300; // Lower threshold
        autoCleanupInterval = 20; // More frequent cleanups
        trace('[MemoryManager] Aggressive mode ENABLED');
    }
    
    /**
     * Disable aggressive memory management
     */
    public static function disableAggressiveMode():Void
    {
        aggressiveMode = false;
        autoCleanupThreshold = 500;
        autoCleanupInterval = 30;
        trace('[MemoryManager] Aggressive mode DISABLED');
    }
    
    /**
     * Update function - call this in game loop for automatic cleanup
     */
    public static function update(elapsed:Float):Void
    {
        var gameplayCritical:Bool = isGameplayCritical();

        if (gameplayCritical)
            timeSinceGameplayCritical = 0;
        else
            timeSinceGameplayCritical += elapsed;

        if (cleanupCooldown > 0)
            cleanupCooldown = Math.max(0, cleanupCooldown - elapsed);

        if (pendingCleanupLevel > 0)
        {
            pendingCleanupAge += elapsed;
            if (pendingCleanupAge >= DEFERRED_CLEANUP_MIN_DELAY && canRunCleanupLevel(pendingCleanupLevel))
                runPendingCleanup();
        }

        if (!aggressiveMode) return;
        
        lastAutoCleanup += elapsed;
        
        if (lastAutoCleanup >= autoCleanupInterval)
        {
            lastAutoCleanup = 0;
            
            var currentMem = getMemoryUsage();
            if (currentMem > autoCleanupThreshold)
            {
                trace('[MemoryManager] Auto-cleanup triggered (${Math.round(currentMem)}MB > ${autoCleanupThreshold}MB)');
                quickCleanup();
            }
        }
    }

    private static function isGameplayCritical():Bool
    {
        if (PlayState.instance == null || FlxG.state == null)
            return false;

        if (FlxG.state != cast PlayState.instance)
            return false;

        return !PlayState.instance.paused
            && !PlayState.instance.endingSong
            && !PlayState.instance.startingSong
            && !PlayState.instance.inCutscene
            && !PlayState.instance.isDead;
    }

    private static function queueCleanup(level:Int):Void
    {
        if (level > pendingCleanupLevel)
            pendingCleanupLevel = level;

        pendingCleanupAge = 0;
    }

    private static function getCleanupCooldown(level:Int):Float
    {
        return switch (level)
        {
            case 1: QUICK_CLEANUP_COOLDOWN;
            case 2: AGGRESSIVE_CLEANUP_COOLDOWN;
            case 3: ULTRA_CLEANUP_COOLDOWN;
            default: QUICK_CLEANUP_COOLDOWN;
        };
    }

    private static function getCleanupGraceDelay(level:Int):Float
    {
        return switch (level)
        {
            case 1: QUICK_CLEANUP_GRACE_DELAY;
            case 2: AGGRESSIVE_CLEANUP_GRACE_DELAY;
            case 3: ULTRA_CLEANUP_GRACE_DELAY;
            default: QUICK_CLEANUP_GRACE_DELAY;
        };
    }

    private static function canRunCleanupLevel(level:Int):Bool
    {
        if (cleanupCooldown > 0 || isGameplayCritical())
            return false;

        return timeSinceGameplayCritical >= getCleanupGraceDelay(level);
    }

    private static function shouldDelayCleanup(level:Int):Bool
    {
        if (!canRunCleanupLevel(level))
        {
            queueCleanup(level);
            return true;
        }

        return false;
    }

    private static function finishCleanup(level:Int):Void
    {
        cleanupCooldown = getCleanupCooldown(level);
        pendingCleanupLevel = 0;
        pendingCleanupAge = 0;
    }

    private static function runPendingCleanup():Void
    {
        var level:Int = pendingCleanupLevel;
        pendingCleanupLevel = 0;
        pendingCleanupAge = 0;

        switch (level)
        {
            case 1:
                performQuickCleanup();
            case 2:
                performAggressiveCleanup();
            case 3:
                performUltraCleanup();
        }
    }

    /**
     * Elimina una imagen específica de todos los cachés (OpenFL, FlxG y Paths tracking)
     * @param path Ruta de la imagen sin extensión (ej: "stages/philly/sky")
     * @param removeInstantly Si es true, destruye el gráfico inmediatamente. Si es false, lo marca para destrucción posterior
     */
    public static function removeImageFromMemory(path:String, removeInstantly:Bool = true):Void
    {
        if (path == null || path == '') return;

        // Agregar extensión si no la tiene
        var imagePath:String = path;
        if (!imagePath.endsWith('.png'))
            imagePath = 'images/$path.png';

        // Buscar en assets de OpenFL
        var foundPath:String = Paths.getPath(imagePath, IMAGE);
        
        // Limpiar caché de OpenFL Assets
        if (Assets.cache.hasBitmapData(foundPath))
            Assets.cache.removeBitmapData(foundPath);

        // Buscar en caché de FlxG
        var graphic:FlxGraphic = FlxG.bitmap.get(foundPath);
        if (graphic == null)
        {
            // Intentar con ruta de mods
            #if MODS_ALLOWED
            foundPath = Paths.modsImages(path);
            graphic = FlxG.bitmap.get(foundPath);
            #end
        }

        if (graphic != null)
        {
            // Remover de tracking de Paths
            if (Paths.currentTrackedAssets.exists(foundPath))
                Paths.currentTrackedAssets.remove(foundPath);
            
            if (Paths.localTrackedAssets.contains(foundPath))
                Paths.localTrackedAssets.remove(foundPath);

            // Marcar para destrucción
            graphic.persist = false;
            graphic.destroyOnNoUse = true;

            if (removeInstantly)
            {
                FlxG.bitmap.remove(graphic);
                graphic.destroy();
            }
        }
    }

    /**
     * Elimina múltiples imágenes de memoria de una vez
     * @param paths Array de rutas de imágenes
     * @param removeInstantly Si es true, destruye los gráficos inmediatamente
     */
    public static function removeImagesFromMemory(paths:Array<String>, removeInstantly:Bool = true):Void
    {
        if (paths == null) return;
        
        for (path in paths)
            removeImageFromMemory(path, removeInstantly);
    }

    /**
     * Elimina un personaje específico del mapa de personajes y libera su memoria
     * @param characterName Nombre del personaje (ej: "bf", "dad", "gf")
     * @param removeInstantly Si es true, destruye el gráfico inmediatamente
     */
    public static function removeCharacterFromMemory(characterName:String, removeInstantly:Bool = true):Void
    {
        if (PlayState.instance == null || characterName == null) return;

        var imageFile:String = null;
        var char:funkin.play.character.Character = null;

        // Buscar en boyfriend map
        if (PlayState.instance.boyfriendMap.exists(characterName))
        {
            char = PlayState.instance.boyfriendMap.get(characterName);
            PlayState.instance.boyfriendGroup.remove(char, true);
            PlayState.instance.boyfriendMap.remove(characterName);
        }
        // Buscar en dad map
        else if (PlayState.instance.dadMap.exists(characterName))
        {
            char = PlayState.instance.dadMap.get(characterName);
            PlayState.instance.dadGroup.remove(char, true);
            PlayState.instance.dadMap.remove(characterName);
        }
        // Buscar en gf map
        else if (PlayState.instance.gfMap.exists(characterName))
        {
            char = PlayState.instance.gfMap.get(characterName);
            PlayState.instance.gfGroup.remove(char, true);
            PlayState.instance.gfMap.remove(characterName);
        }

        // Si encontramos el personaje, destruirlo y liberar su imagen
        if (char != null)
        {
            imageFile = char.imageFile;
            char.kill();
            char.destroy();

            if (imageFile != null && imageFile != '')
                removeImageFromMemory(imageFile, removeInstantly);
        }
    }

    /**
     * Clears unused UI assets (pixel UI vs normal UI)
     * Works on all platforms to save memory
     */
    public static function clearUnusedUI():Void
    {
        if (PlayState.instance == null) return;

        if (!PlayState.isPixelStage)
        {
            // Clear pixel UI if we're on normal stage
            Assets.cache.clear('assets/shared/images/pixelUI');
            removeImageFromMemory('pixelUI/arrows-pixels');
            removeImageFromMemory('pixelUI/arrows-pixels-ends');
            removeImageFromMemory('pixelUI/NOTE_assets');
        }
        else
        {
            // Clear normal UI if we're on pixel stage
            removeImageFromMemory('NOTE_assets');
            removeImageFromMemory('noteSplashes');
        }
    }

    /**
     * Clears preloaded characters that are not in use
     * Useful for low-end devices (mobile and desktop)
     */
    public static function clearPreloadedCharacters():Void
    {
        // Death character rarely used
        removeCharacterFromMemory('bf-dead', true);
        
        // Menu logo
        removeImageFromMemory('logoBumpin', true);
    }

    /**
     * Quick cleanup - lighter than aggressive cleanup
     * Good for periodic automatic cleanup
     */
    public static function quickCleanup():Void
    {
        if (shouldDelayCleanup(QUICK_CLEANUP_LEVEL))
            return;

        performQuickCleanup();
    }

    private static function performQuickCleanup():Void
    {
        trace('[MemoryManager] Running quick cleanup...');
        
        // Clear Paths unused memory
        Paths.clearUnusedMemory(false);
        
        // Clear temp frames cache
        Paths.clearTempFramesCache();
        
		finishCleanup(QUICK_CLEANUP_LEVEL);
        trace('[MemoryManager] Quick cleanup complete');
    }

    /**
     * Aggressive cleanup - full memory cleanup
     * Combines all cleanup functions and forces garbage collection
     * Use sparingly as it's expensive
     */
        public static function aggressiveCleanup(force:Bool = false):Void
    {
		if (!force && shouldDelayCleanup(AGGRESSIVE_CLEANUP_LEVEL))
			return;

		performAggressiveCleanup();
	}

	private static function performAggressiveCleanup():Void
	{
		trace('[MemoryManager] Running aggressive cleanup...');

        // Clear Paths caches
    Paths.clearUnusedMemory(false);
        Paths.clearStoredMemory();
        Paths.clearTempFramesCache();
        
        // Clear UI not in use
        clearUnusedUI();
        
        // Clear preloaded characters
        clearPreloadedCharacters();
        
        // Clear shaders
        clearShaders();

		performGarbageCollection(true, false);

		finishCleanup(AGGRESSIVE_CLEANUP_LEVEL);
		trace('[MemoryManager] Aggressive cleanup complete');
    }
    
    /**
     * Ultra cleanup - nuclear option
     * Clears almost everything possible
     * WARNING: May cause visual glitches temporarily
     */
        public static function ultraCleanup(force:Bool = false):Void
    {
		if (!force && shouldDelayCleanup(ULTRA_CLEANUP_LEVEL))
			return;

		performUltraCleanup();
	}

	private static function performUltraCleanup():Void
	{
    trace('[MemoryManager] Running ultra cleanup...');

    // Run the same cache release steps as aggressive cleanup first.
    Paths.clearUnusedMemory(false);
    Paths.clearStoredMemory();
    Paths.clearTempFramesCache();
    clearUnusedUI();
    clearPreloadedCharacters();
    clearShaders();
        
        // Clear FlxG bitmap cache (careful!)
        @:privateAccess
        {
            for (key in FlxG.bitmap._cache.keys())
            {
                var graphic = FlxG.bitmap.get(key);
                if (graphic != null && !graphic.persist && graphic.useCount == 0)
                {
                    FlxG.bitmap.remove(graphic);
                    graphic.destroy();
                }
            }
        }
        
        // Clear all sound caches
        Assets.cache.clear();

        performGarbageCollection(true, true);

		finishCleanup(ULTRA_CLEANUP_LEVEL);
    }

    private static function performGarbageCollection(major:Bool, compact:Bool):Void
    {
        #if cpp
        cpp.vm.Gc.run(major);
        if (compact)
            cpp.vm.Gc.compact();
        #elseif hl
        hl.Gc.major();
        #elseif neko
        neko.vm.Gc.run(major);
        #else
        System.gc();
        #end
    }
    
    /**
     * Gets total system RAM installed (in MB)
     * Works on Windows, Mac, Linux, iOS, and Android
     */
    public static function getTotalSystemRAM():Int
    {
        return SystemMemory.getTotalRAM();
    }
    
    /**
     * Gets current memory usage in MB (only on supported systems)
     * This is the RAM currently being used by the application
     */
    public static function getMemoryUsage():Float
    {
        #if cpp
        return System.totalMemory / 1024 / 1024;
        #else
        return 0;
        #end
    }
    
    /**
     * Gets available (free) system RAM in MB
     * Works on Windows, Mac, Linux, iOS, and Android
     */
    public static function getAvailableRAM():Int
    {
        return SystemMemory.getAvailableRAM();
    }

    /**
     * Reports current memory usage to console (useful for debugging)
     * Works on all platforms that support memory reporting
     */
    public static function reportMemoryUsage():Void
    {
        var memoryMB:Float = getMemoryUsage();
        if (memoryMB > 0)
            trace('Current memory usage: ${Math.round(memoryMB)}MB');
        else
            trace('Memory usage reporting not available on this platform');
    }

    /**
     * Clears all loaded shaders (very useful on low-end devices where shaders consume lots of RAM)
     * Works on all platforms - especially helpful for low-end desktop PCs
     */
    public static function clearShaders():Void
    {
        if (PlayState.instance == null) return;
        
        // Clear stage shaders
        if (PlayState.instance.camGame != null && PlayState.instance.camGame.filters != null)
            PlayState.instance.camGame.filters = [];
        
        if (PlayState.instance.camHUD != null && PlayState.instance.camHUD.filters != null)
            PlayState.instance.camHUD.filters = [];
        
        if (PlayState.instance.camOther != null && PlayState.instance.camOther.filters != null)
            PlayState.instance.camOther.filters = [];
        
    }

    /**
     * Automatic memory monitoring for low-end devices (mobile and desktop)
     * Runs automatic cleanup if usage exceeds specified threshold
     * @param thresholdMB Threshold in MB (default 500MB)
     */
    public static function autoMonitor(thresholdMB:Float = 500):Void
    {
        var currentMemory:Float = getMemoryUsage();
        
        if (currentMemory > 0 && currentMemory > thresholdMB)
        {
            if (aggressiveMode)
                aggressiveCleanup();
            else
                quickCleanup();
        }
    }
}
