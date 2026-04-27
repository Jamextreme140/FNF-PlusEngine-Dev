package funkin.external.android;

#if android
import lime.system.JNI;
#end

/**
 * Utility class for creating JNI method bindings to Kotlin/Java code
 * Provides type-safe access to native Android functionality
 */
class JNIUtil
{
  /**
   * Create a static method binding to a Kotlin/Java function
   * @param className Full class path (e.g., "com/leninasto/plusengine/PlusEngineExtension")
   * @param methodName Name of the static method to call
   * @param signature JNI method signature (e.g., "(I)V" for method taking int, returning void)
   * @return Function that can be called from Haxe, or null if binding fails
   */
  public static function createStaticMethod(className:String, methodName:String, signature:String):Null<Dynamic>
  {
    #if android
    try
    {
      return JNI.createStaticMethod(className, methodName, signature);
    }
    catch (e:Dynamic)
    {
      trace('Failed to create JNI binding for $className.$methodName: $e');
      return null;
    }
    #else
    return null;
    #end
  }

  /**
   * Create an instance method binding to a Kotlin/Java function
   * @param className Full class path
   * @param methodName Name of the method to call
   * @param signature JNI method signature
   * @return Function that can be called from Haxe, or null if binding fails
   */
  public static function createMemberMethod(className:String, methodName:String, signature:String):Null<Dynamic>
  {
    #if android
    try
    {
      return JNI.createMemberMethod(className, methodName, signature);
    }
    catch (e:Dynamic)
    {
      trace('Failed to create JNI member binding for $className.$methodName: $e');
      return null;
    }
    #else
    return null;
    #end
  }
}
