package funkin.external.android;

/**
 * Utility for opening the app's data folder in the system file explorer
 * Uses JNI to call native Kotlin functions for optimal performance
 * Works universally across all Android devices and manufacturers
 */
class DataFolderUtil
{
  /**
   * Open the app's data folder in the system file explorer
   * Opens: Android/data/com.leninasto.plusengine/files/
   * 
   * This uses native Android Intents to open the system file explorer
   * (Files, My Files, etc.) directly to the app's data directory.
   * 
   * When the user closes the file explorer, you can detect this via
   * the onActivityResult callback with requestCode = CallbackUtil.DATA_FOLDER_CLOSED
   */
  public static function openDataFolder():Void
  {
    #if android
    final openDataFolderJNI:Null<Dynamic> = JNIUtil.createStaticMethod('com/leninasto/plusengine/PlusEngineExtension', 'openDataFolder', '(I)V');

    if (openDataFolderJNI != null)
    {
      openDataFolderJNI(CallbackUtil.DATA_FOLDER_CLOSED);
    }
    else
    {
      trace('ERROR: Failed to create JNI binding for openDataFolder');
    }
    #else
    trace('DataFolderUtil.openDataFolder() is only available on Android');
    #end
  }

  /**
   * Open the mods folder in the system file explorer
   * Opens: Android/data/com.leninasto.plusengine/files/mods/
   */
  public static function openModsFolder():Void
  {
    #if android
    final openModsFolderJNI:Null<Dynamic> = JNIUtil.createStaticMethod('com/leninasto/plusengine/PlusEngineExtension', 'openModsFolder', '()V');

    if (openModsFolderJNI != null)
    {
      openModsFolderJNI();
    }
    else
    {
      trace('ERROR: Failed to create JNI binding for openModsFolder');
    }
    #end
  }

  /**
   * Open the saves folder in the system file explorer
   * Opens: Android/data/com.leninasto.plusengine/files/saves/
   */
  public static function openSavesFolder():Void
  {
    #if android
    final openSavesFolderJNI:Null<Dynamic> = JNIUtil.createStaticMethod('com/leninasto/plusengine/PlusEngineExtension', 'openSavesFolder', '()V');

    if (openSavesFolderJNI != null)
    {
      openSavesFolderJNI();
    }
    else
    {
      trace('ERROR: Failed to create JNI binding for openSavesFolder');
    }
    #end
  }

  /**
   * Open the logs folder in the system file explorer
   * Opens: Android/data/com.leninasto.plusengine/files/logs/
   */
  public static function openLogsFolder():Void
  {
    #if android
    final openLogsFolderJNI:Null<Dynamic> = JNIUtil.createStaticMethod('com/leninasto/plusengine/PlusEngineExtension', 'openLogsFolder', '()V');

    if (openLogsFolderJNI != null)
    {
      openLogsFolderJNI();
    }
    else
    {
      trace('ERROR: Failed to create JNI binding for openLogsFolder');
    }
    #end
  }
}
