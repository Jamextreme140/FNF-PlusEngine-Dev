package lenin;

#if cpp
import lenin.slushithings.cpp.CPPInterface;
#end

/**
 * Gestor del sistema de Heavy Charts
 * Controla la activación y desactivación del modo de charts pesados
 * 
 * MEMORIA DINÁMICA:
 * - Cachea notas agresivamente basado en RAM disponible
 * - Usa ~0.5MB por nota aproximadamente
 * - Permite usar hasta 75% de RAM disponible para caché de notas
 */
class HeavyChartManager
{
	/**
	 * Determina si el heavy chart mode debe activarse
	 */
	public static function shouldUseHeavyCharts():Bool
	{
		// Verificar si está activado en las preferencias del cliente
		return ClientPrefs.data.heavyCharts == true;
	}

	/**
	 * Obtiene la memoria total disponible del sistema en bytes
	 * FIXED: Ahora usa detección de RAM real del sistema, no solo la RAM de la app
	 */
	private static function getTotalMemory():Int
	{
		#if cpp
		// Get REAL system RAM in MB, then convert to bytes
		var ramMB:Float = cast CPPInterface.getRAM();
		if (ramMB <= 0)
		{
			// Fallback if detection fails
			trace("[HeavyChartManager] RAM detection failed, using fallback value");
			return 8192 * 1024 * 1024; // Assume 8GB as fallback
		}
		return Std.int(ramMB * 1024 * 1024); // Convert MB to bytes
		#else
		// Non-CPP platforms: use conservative estimate
		return 4096 * 1024 * 1024; // 4GB fallback
		#end
	}

	/**
	 * Obtiene la memoria actual en uso por la aplicación en bytes
	 */
	private static function getCurrentMemory():Int
	{
		#if cpp
		return Std.int(cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE));
		#else
		// Fallback: use OpenFL's reported memory (app usage, not system total)
		return Std.int(openfl.system.System.totalMemory);
		#end
	}

	/**
	 * Calcula el límite dinámico de notas basado en RAM disponible
	 * Esto permite cachear más notas si el sistema tiene más RAM
	 */
	public static function getDynamicNoteLimit():Int
	{
		if (!shouldUseHeavyCharts())
			return 150; // Normal limit if heavy charts is disabled

		// Get REAL system RAM total
		var totalRAM:Int = getTotalMemory();
		
		// Calculate how much RAM can be used for note cache (50% of total)
		// We need space for other processes and game assets
		// Estimation: ~500 bytes per note (struct + overhead)
		var ramForNoteCache:Int = Std.int(totalRAM * 0.5);
		var bytesPerNote:Int = 500; // Approximate bytes per note
		
		// Calculate dynamic limit
		var dynamicLimit:Int = Std.int(ramForNoteCache / bytesPerNote);
		
		// Minimum 200 notes, maximum 2000 notes (avoid extremes)
		dynamicLimit = Std.int(Math.min(2000, Math.max(200, dynamicLimit)));
		
		var totalRAMMB:Int = Std.int(totalRAM / (1024 * 1024));
		var cacheBudgetMB:Int = Std.int(ramForNoteCache / (1024 * 1024));
		
		trace('[HeavyChartManager] System RAM: ${totalRAMMB}MB | Cache Budget: ${cacheBudgetMB}MB | Dynamic Limit: ${dynamicLimit} notes');
		
		return dynamicLimit;
	}

	/**
	 * Obtiene el límite de notas renderizadas simultáneamente (fallback estático)
	 */
	public static function getNoteRenderLimit():Int
	{
		// Mayor límite para heavy charts
		return shouldUseHeavyCharts() ? 300 : 150;
	}

	/**
	 * Obtiene el tiempo de spawn dinámico de notas
	 */
	public static function getDynamicSpawnTime():Bool
	{
		return ClientPrefs.getGameplaySetting('dynamicSpawnTime', true) == true;
	}

	/**
	 * Obtiene el multiplicador de tiempo de spawn
	 */
	public static function getNoteSpawnTimeMultiplier():Float
	{
		return ClientPrefs.getGameplaySetting('noteSpawnTime', 0.5);
	}

	/**
	 * Calcula el uso de memoria estimado de las notas
	 * Estimación: ~500KB por nota (struct + overhead de Flixel)
	 */
	public static function estimateMemoryUsage(noteCount:Int):String
	{
		// 500 bytes por nota aproximadamente
		var bytes:Float = noteCount * 500;
		var mb:Float = bytes / (1024 * 1024);
		return Math.round(mb * 100) / 100 + " MB";
	}

	/**
	 * Logea información sobre el chart cargado
	 */
	public static function logChartInfo(songName:String, noteCount:Int, useHeavy:Bool):Void
	{
		if (useHeavy)
		{
			var totalRAM:Int = getTotalMemory();
			var totalRAMMB:Int = Std.int(totalRAM / (1024 * 1024));
			var cacheBudgetMB:Int = Std.int((totalRAM * 0.5) / (1024 * 1024));
		}
	}

	/**
	 * Limpia las notas precargadas para liberar memoria
	 */
	public static function cleanupPreloadedNotes(unspawnNotes:Array<PreloadedChartNote>):Void
	{
		for (note in unspawnNotes)
		{
			if (note != null)
				note.dispose();
		}
		unspawnNotes = [];
		openfl.system.System.gc();
	}

	/**
	 * Obtiene estadísticas del chart actual
	 */
	public static function getChartStats(unspawnNotes:Array<PreloadedChartNote>):Dynamic
	{
		var stats = {
			totalNotes: unspawnNotes.length,
			normalNotes: 0,
			sustainNotes: 0,
			avgDensity: 0.0,
			maxDensity: 0.0
		};

		var densitySum:Float = 0;

		for (note in unspawnNotes)
		{
			if (note.isSustainNote)
				stats.sustainNotes++;
			else
				stats.normalNotes++;

			densitySum += 1;
			if (stats.maxDensity < 1)
				stats.maxDensity = 1;
		}

		if (stats.totalNotes > 0)
			stats.avgDensity = Math.round((densitySum / stats.totalNotes) * 100) / 100;

		return stats;
	}
}
