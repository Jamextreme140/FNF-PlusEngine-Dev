package psychlua;

import haxe.ds.StringMap;

/**
 * Dynamic Class System for Lua
 * Allows creating custom classes from Lua scripts using metatables
 */
class LuaClass 
{
    public static var registeredClasses:StringMap<LuaClassDefinition> = new StringMap<LuaClassDefinition>();
    
    /**
     * Register a new class definition from Lua
     * @param className Name of the class
     * @param parentClass Optional parent class name to extend
     * @param interfaceClass Optional interface class name to implement
     * @param constructor Constructor function
     * @param methods Map of method names to functions
     * @param staticMethods Map of static method names to functions
     * @return The class definition
     */
    public static function registerClass(
        className:String, 
        ?parentClass:String = null,
        ?interfaceClass:String = null,
        ?constructor:Dynamic = null,
        ?methods:Dynamic = null,
        ?staticMethods:Dynamic = null
    ):LuaClassDefinition 
    {
        var classDef = new LuaClassDefinition(className, parentClass, interfaceClass);
        
        if (constructor != null)
            classDef.constructor = constructor;
        
        if (methods != null)
            classDef.methods = methods;
            
        if (staticMethods != null)
            classDef.staticMethods = staticMethods;
        
        registeredClasses.set(className, classDef);
        trace('Registered Lua class: $className' + (parentClass != null ? ' extends $parentClass' : ''));
        
        return classDef;
    }
    
    /**
     * Create an instance of a registered class
     * @param className Name of the class to instantiate
     * @param args Constructor arguments
     * @return Instance of the class
     */
    public static function createInstance(className:String, ?args:Array<Dynamic>):Dynamic 
    {
        if (!registeredClasses.exists(className)) 
        {
            trace('Error: Class $className not found!');
            return null;
        }
        
        var classDef = registeredClasses.get(className);
        return classDef.createInstance(args);
    }
    
    /**
     * Check if a class is registered
     * @param className Name of the class
     * @return True if class exists
     */
    public static function hasClass(className:String):Bool 
    {
        return registeredClasses.exists(className);
    }
    
    /**
     * Get a registered class definition
     * @param className Name of the class
     * @return Class definition or null
     */
    public static function getClass(className:String):LuaClassDefinition 
    {
        return registeredClasses.get(className);
    }
    
    /**
     * Call a static method on a class
     * @param className Name of the class
     * @param methodName Name of the method
     * @param args Method arguments
     * @return Return value
     */
    public static function callStatic(className:String, methodName:String, ?args:Array<Dynamic>):Dynamic 
    {
        if (!registeredClasses.exists(className)) 
        {
            trace('Error: Class $className not found!');
            return null;
        }
        
        var classDef = registeredClasses.get(className);
        return classDef.callStatic(methodName, args);
    }
}

/**
 * Represents a Lua class definition
 */
class LuaClassDefinition 
{
    public var className:String;
    public var parentClass:String;
    public var interfaceClass:String;
    public var constructor:Dynamic;
    public var methods:Dynamic;
    public var staticMethods:Dynamic;
    public var instances:Array<LuaClassInstance> = [];
    
    public function new(className:String, ?parentClass:String = null, ?interfaceClass:String = null) 
    {
        this.className = className;
        this.parentClass = parentClass;
        this.interfaceClass = interfaceClass;
    }
    
    /**
     * Create an instance of this class
     * @param args Constructor arguments
     * @return Instance
     */
    public function createInstance(?args:Array<Dynamic>):LuaClassInstance 
    {
        var instance = new LuaClassInstance(this);
        
        // Initialize with parent class methods if exists
        if (parentClass != null && LuaClass.hasClass(parentClass)) 
        {
            var parentDef = LuaClass.getClass(parentClass);
            if (parentDef.methods != null)
                instance.inheritMethods(parentDef.methods);
        }
        
        // Set methods
        if (methods != null)
            instance.setMethods(methods);
        
        // Call constructor
        if (constructor != null) 
        {
            if (args == null) args = [];
            Reflect.callMethod(instance, constructor, args);
        }
        
        instances.push(instance);
        return instance;
    }
    
    /**
     * Call a static method
     * @param methodName Method name
     * @param args Arguments
     * @return Return value
     */
    public function callStatic(methodName:String, ?args:Array<Dynamic>):Dynamic 
    {
        if (staticMethods == null || !Reflect.hasField(staticMethods, methodName)) 
        {
            trace('Error: Static method $methodName not found in class $className!');
            return null;
        }
        
        var method = Reflect.field(staticMethods, methodName);
        if (args == null) args = [];
        return Reflect.callMethod(null, method, args);
    }
}

/**
 * Represents an instance of a Lua class
 */
class LuaClassInstance 
{
    public var classDef:LuaClassDefinition;
    public var fields:Map<String, Dynamic> = new Map<String, Dynamic>();
    public var methods:Map<String, Dynamic> = new Map<String, Dynamic>();
    
    public function new(classDef:LuaClassDefinition) 
    {
        this.classDef = classDef;
    }
    
    /**
     * Set methods for this instance
     * @param methodsObj Object containing methods
     */
    public function setMethods(methodsObj:Dynamic):Void 
    {
        if (methodsObj == null) return;
        
        for (methodName in Reflect.fields(methodsObj)) 
        {
            var method = Reflect.field(methodsObj, methodName);
            methods.set(methodName, method);
        }
    }
    
    /**
     * Inherit methods from parent class
     * @param parentMethods Parent methods object
     */
    public function inheritMethods(parentMethods:Dynamic):Void 
    {
        if (parentMethods == null) return;
        
        for (methodName in Reflect.fields(parentMethods)) 
        {
            // Don't override if method already exists
            if (!methods.exists(methodName)) 
            {
                var method = Reflect.field(parentMethods, methodName);
                methods.set(methodName, method);
            }
        }
    }
    
    /**
     * Call a method on this instance
     * @param methodName Method name
     * @param args Arguments
     * @return Return value
     */
    public function callMethod(methodName:String, ?args:Array<Dynamic>):Dynamic 
    {
        if (!methods.exists(methodName)) 
        {
            trace('Error: Method $methodName not found in class ${classDef.className}!');
            return null;
        }
        
        var method = methods.get(methodName);
        if (args == null) args = [];
        return Reflect.callMethod(this, method, args);
    }
    
    /**
     * Set a field value
     * @param name Field name
     * @param value Field value
     */
    public function setField(name:String, value:Dynamic):Void 
    {
        fields.set(name, value);
    }
    
    /**
     * Get a field value
     * @param name Field name
     * @return Field value
     */
    public function getField(name:String):Dynamic 
    {
        return fields.get(name);
    }
    
    /**
     * Check if instance is of a specific class
     * @param className Class name to check
     * @return True if instance is of that class or extends it
     */
    public function isInstanceOf(className:String):Bool 
    {
        if (classDef.className == className)
            return true;
            
        // Check parent chain
        if (classDef.parentClass != null)
            return LuaClass.hasClass(classDef.parentClass) && 
                   LuaClass.getClass(classDef.parentClass).className == className;
        
        return false;
    }
}
