package funkin.external.android;

/**
 * Constants for Android activity result request codes
 * Used to identify which activity was closed when onActivityResult is called
 */
class CallbackUtil
{
  /**
   * Request code for when the data folder browser is closed
   */
  public static inline final DATA_FOLDER_CLOSED:Int = 1001;

  /**
   * Request code for when the mods folder browser is closed
   */
  public static inline final MODS_FOLDER_CLOSED:Int = 1002;

  /**
   * Request code for when the saves folder browser is closed
   */
  public static inline final SAVES_FOLDER_CLOSED:Int = 1003;

  /**
   * Request code for when the logs folder browser is closed
   */
  public static inline final LOGS_FOLDER_CLOSED:Int = 1004;
}
