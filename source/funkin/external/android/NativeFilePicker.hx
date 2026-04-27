package funkin.external.android;

/**
 * Native Android file picker — lets the user pick a text-based file
 * from the engine storage using the native Plus Explorer activity.
 *
 * Usage:
 *   1. Call NativeFilePicker.open() to launch the picker.
 *   2. Poll NativeFilePicker.getPickedPath() in your update loop (returns ""
 *      while waiting, a path once the user picks a file, or stays "" if cancelled).
 *   3. Call NativeFilePicker.clear() after you have handled the result so the
 *      next open() starts fresh.
 *
 * Example:
 *   NativeFilePicker.open();
 *
 *   // later, in update():
 *   var path = NativeFilePicker.getPickedPath();
 *   if (path != "") {
 *       trace("User picked: " + path);
 *       NativeFilePicker.clear();
 *   }
 */
class NativeFilePicker
{
  static inline final CLASS = 'com/leninasto/plusengine/PlusEngineExtension';

  /**
  * Opens the native engine file picker dialog.
  * Files are selected from the app storage and returned to Haxe.
   */
  public static function open():Void
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'openFilePicker', '()V');
    if (jni != null)
      jni();
    else
      trace('NativeFilePicker: Failed to bind openFilePicker');
    #else
    trace('NativeFilePicker.open() is only available on Android');
    #end
  }

  /**
   * Returns the display name (filename) of the last picked file.
   * Returns "" while the picker is open, if cancelled, or before any pick.
   * Use getPickedContent() to get the actual file contents.
   */
  public static function getPickedPath():String
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'getPickedFilePath', '()Ljava/lang/String;');
    if (jni != null)
      return (jni() : String) ?? '';
    return '';
    #else
    return '';
    #end
  }

  /**
   * Returns the raw text content of the last picked file.
   * The content is read directly from the ContentResolver (no filesystem access needed).
   * Returns "" if no file has been picked, the picker was cancelled, or reading failed.
   */
  public static function getPickedContent():String
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'getPickedFileContent', '()Ljava/lang/String;');
    if (jni != null)
      return (jni() : String) ?? '';
    return '';
    #else
    return '';
    #end
  }

  /**
   * Returns the current picker state.
   * 0 = waiting/no result, 1 = success, -1 = cancelled, -2 = error.
   */
  public static function getStatus():Int
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'getPickedFileStatus', '()I');
    if (jni != null)
      return (jni() : Int);
    return 0;
    #else
    return 0;
    #end
  }

  /**
   * Clears both the stored file name and content.
   * Call this after handling the result so getPickedPath() / getPickedContent()
   * return "" until the user makes a new selection.
   */
  public static function clear():Void
  {
    #if android
    final jni:Null<Dynamic> = JNIUtil.createStaticMethod(CLASS, 'clearPickedFile', '()V');
    if (jni != null)
      jni();
    #end
  }

  /**
   * Request code sent to onActivityResult for the file picker.
   * Matches CallbackUtil pattern; can be used to detect when the picker closes.
   */
  public static inline final REQUEST_CODE:Int = 2001;
}
