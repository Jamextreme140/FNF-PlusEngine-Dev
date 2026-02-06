package funkin.util;

#if windows
import lenin.slushithings.windows.WindowsCPP;
#end

/**
 * Cross-platform system memory detection
 * Supports Windows, Mac, Linux, iOS, and Android
 */
@:buildXml('
<target id="haxe">
    <lib name="Kernel32.lib" if="windows" />
</target>
')
#if (cpp && !windows && !android)
@:cppInclude("sys/sysinfo.h")
@:cppInclude("unistd.h")
#end
#if (mac || ios)
@:cppInclude("sys/types.h")
@:cppInclude("sys/sysctl.h")
@:cppInclude("mach/mach.h")
@:cppInclude("mach/mach_host.h")
#end
class SystemMemory
{
    /**
     * Gets total system RAM installed (in MB)
     * Works on Windows, Mac, Linux, iOS, and Android
     * @return Total RAM in megabytes, or 0 if detection fails
     */
    public static function getTotalRAM():Int
    {
        #if windows
        return WindowsCPP.getTotalSystemRAM();
        #elseif android
        return getAndroidTotalRAM();
        #elseif (mac || ios)
        return getMacTotalRAM();
        #elseif linux
        return getLinuxTotalRAM();
        #else
        return 0;
        #end
    }

    /**
     * Gets available (free) system RAM (in MB)
     * Works on Windows, Mac, Linux, iOS, and Android
     * @return Available RAM in megabytes, or 0 if detection fails
     */
    public static function getAvailableRAM():Int
    {
        #if windows
        return WindowsCPP.getAvailableSystemRAM();
        #elseif android
        return getAndroidAvailableRAM();
        #elseif (mac || ios)
        return getMacAvailableRAM();
        #elseif linux
        return getLinuxAvailableRAM();
        #else
        return 0;
        #end
    }

    /**
     * Gets the number of CPU cores
     * Works on all platforms
     * @return Number of logical processors
     */
    public static function getCPUCores():Int
    {
        #if windows
        return WindowsCPP.getCPUCoreCount();
        #elseif (mac || ios)
        return getMacCPUCores();
        #elseif (linux || android)
        return getLinuxCPUCores();
        #elseif cpp
        return getGenericCPUCores();
        #else
        return 1;
        #end
    }

    // === Platform-specific implementations ===

    #if android
    /**
     * Gets total RAM on Android by reading /proc/meminfo
     */
    private static function getAndroidTotalRAM():Int
    {
        // Android is Linux-based, read from /proc/meminfo
        return readLinuxMemInfo(true);
    }

    /**
     * Gets available RAM on Android by reading /proc/meminfo
     */
    private static function getAndroidAvailableRAM():Int
    {
        return readLinuxMemInfo(false);
    }
    #end

    #if (mac || ios)
    /**
     * Gets total RAM on Mac/iOS using sysctl
     */
    @:functionCode('
        int64_t memsize = 0;
        size_t size = sizeof(memsize);
        
        if (sysctlbyname("hw.memsize", &memsize, &size, NULL, 0) == 0) {
            // Convert bytes to MB
            return (int)(memsize / 1024 / 1024);
        }
        
        return 0;
    ')
    private static function getMacTotalRAM():Int
    {
        return 0;
    }

    /**
     * Gets available RAM on Mac/iOS using mach
     */
    @:functionCode('
        mach_port_t host_port = mach_host_self();
        mach_msg_type_number_t host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
        vm_size_t pagesize;
        vm_statistics_data_t vm_stat;

        host_page_size(host_port, &pagesize);

        if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) == KERN_SUCCESS) {
            // Free memory in bytes
            int64_t free_memory = (int64_t)vm_stat.free_count * (int64_t)pagesize;
            // Convert bytes to MB
            return (int)(free_memory / 1024 / 1024);
        }

        return 0;
    ')
    private static function getMacAvailableRAM():Int
    {
        return 0;
    }

    /**
     * Gets CPU cores on Mac/iOS using sysconf
     */
    @:functionCode('
        #include <unistd.h>
        long cores = sysconf(_SC_NPROCESSORS_ONLN);
        return (cores > 0) ? (int)cores : 1;
    ')
    private static function getMacCPUCores():Int
    {
        return 1;
    }
    #end

    #if (linux || android)
    /**
     * Reads memory info from /proc/meminfo
     * Works on both Linux and Android (Android is Linux-based)
     * @param total If true, returns total RAM; if false, returns available RAM
     */
    private static function readLinuxMemInfo(total:Bool):Int
    {
        #if sys
        try
        {
            var content = sys.io.File.getContent("/proc/meminfo");
            var lines = content.split("\n");
            var searchKey = total ? "MemTotal:" : "MemAvailable:";
            
            for (line in lines)
            {
                if (line.indexOf(searchKey) == 0)
                {
                    // Format: MemTotal:       16384000 kB
                    var parts = line.split(":");
                    if (parts.length >= 2)
                    {
                        var valueStr = StringTools.trim(parts[1]).split(" ")[0];
                        var kb = Std.parseInt(valueStr);
                        if (kb != null)
                        {
                            // Convert KB to MB
                            return Std.int(kb / 1024);
                        }
                    }
                }
            }
        }
        catch (e:Dynamic)
        {
            trace('[SystemMemory] Failed to read /proc/meminfo: $e');
        }
        #end
        return 0;
    }
    
    /**
     * Gets total RAM on Linux by reading /proc/meminfo
     */
    private static function getLinuxTotalRAM():Int
    {
        return readLinuxMemInfo(true);
    }

    /**
     * Gets available RAM on Linux by reading /proc/meminfo
     */
    private static function getLinuxAvailableRAM():Int
    {
        return readLinuxMemInfo(false);
    }

    /**
     * Gets CPU cores on Linux using sysconf
     */
    @:functionCode('
        #include <unistd.h>
        long cores = sysconf(_SC_NPROCESSORS_ONLN);
        return (cores > 0) ? (int)cores : 1;
    ')
    private static function getLinuxCPUCores():Int
    {
        return 1;
    }
    #end

    /**
     * Generic CPU core detection for other cpp platforms
     */
    @:functionCode('
        // Try to get CPU cores using sysconf if available
        #ifdef _SC_NPROCESSORS_ONLN
            #include <unistd.h>
            long cores = sysconf(_SC_NPROCESSORS_ONLN);
            if (cores > 0) return (int)cores;
        #endif
        
        // Fallback to 1 core
        return 1;
    ')
    private static function getGenericCPUCores():Int
    {
        return 1;
    }

    /**
     * Checks if the current device is low-end based on RAM
     * @param threshold RAM threshold in MB (default: 4096 = 4GB)
     * @return True if device has less RAM than threshold
     */
    public static function isLowEndDevice(threshold:Int = 4096):Bool
    {
        var totalRAM = getTotalRAM();
        if (totalRAM <= 0)
        {
            // If detection fails, assume not low-end to be safe
            return false;
        }
        return totalRAM < threshold;
    }

    /**
     * Gets a human-readable string of total RAM
     * @return String like "8192 MB" or "8 GB"
     */
    public static function getTotalRAMString():String
    {
        var totalMB = getTotalRAM();
        if (totalMB <= 0)
            return "Unknown";
        
        if (totalMB >= 1024)
        {
            var gb = Math.round(totalMB / 1024 * 10) / 10;
            return gb + " GB";
        }
        return totalMB + " MB";
    }
}