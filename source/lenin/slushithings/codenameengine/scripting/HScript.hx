package lenin.slushithings.codenameengine.scripting;

import haxe.io.Path;
import hscript.Interp;
import hscript.Parser;
import hscript.Expr;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

/**
 * CodeName Engine HScript implementation
 */
class HScript extends Script
{
	public var interp:Interp;
	public var parser:Parser;
	public var expr:Expr;
	public var code:String;

	public static function initParser()
	{
		var p = new Parser();
		p.allowJSON = p.allowMetadata = p.allowTypes = true;
		return p;
	}

	public override function onCreate(path:String)
	{
		super.onCreate(path);

		interp = new Interp();

		try
		{
			#if sys
			if (FileSystem.exists(rawPath))
				code = File.getContent(rawPath);
			#else
			code = openfl.utils.Assets.getText(path);
			#end
		}
		catch (e)
		{
			trace('Error while reading $path: ${Std.string(e)}');
		}
		
		parser = initParser();

		interp.errorHandler = _errorHandler;

		interp.variables.set("trace", Reflect.makeVarArgs((args) -> {
			var v:String = Std.string(args.shift());
			for (a in args)
				v += ", " + Std.string(a);
			script_trace(v);
		}));

		if (GlobalScript != null)
			GlobalScript.call("onScriptCreated", [this, "hscript"]);
			
		loadFromString(code);
	}

	public override function loadFromString(code:String)
	{
		try
		{
			if (code != null && code.trim() != "")
				expr = parser.parseString(code, Path.withoutDirectory(fileName));
		}
		catch (e:Dynamic)
		{
			trace('Error parsing script: ${Std.string(e)}');
		}

		return this;
	}

	private function _errorHandler(error:Dynamic)
	{
		var errorMsg = Std.string(error);
		trace('Script Error in $fileName: $errorMsg');
		
		#if HSCRIPT_ALLOWED
		if (PlayState.instance != null)
			PlayState.instance.addTextToDebug('Script Error in $fileName: $errorMsg', 0xFFFF0000);
		#end
	}

	public override function setParent(parent:Dynamic)
	{
		// Set parent for script context
		interp.variables.set("this", parent);
	}

	public override function onLoad()
	{
		if (expr != null)
		{
			try
			{
				interp.execute(expr);
				call("onCreate", []);
			}
			catch (e:Dynamic)
			{
				_errorHandler(e);
			}
		}
	}

	public override function reload()
	{
		// Save variables
		var savedVariables:Map<String, Dynamic> = new Map<String, Dynamic>();
		if (interp != null && interp.variables != null)
		{
			for (k in interp.variables.keys())
			{
				var e = interp.variables.get(k);
				if (!Reflect.isFunction(e))
					savedVariables.set(k, e);
			}
		}
		
		var oldParent = interp != null ? interp.variables.get("this") : null;
		onCreate(path);

		load();
		if (oldParent != null) setParent(oldParent);

		for (k in savedVariables.keys())
			interp.variables.set(k, savedVariables.get(k));
	}

	public override function call(funcName:String, ?parameters:Array<Dynamic>):Dynamic
	{
		if (interp == null) return null;
		if (funcName == null || !interp.variables.exists(funcName)) return null;

		var func = interp.variables.get(funcName);
		if (func != null && Reflect.isFunction(func))
		{
			if (parameters == null) parameters = [];
			try
			{
				return Reflect.callMethod(null, func, parameters);
			}
			catch (e:Dynamic)
			{
				_errorHandler(e);
			}
		}

		return null;
	}

	public override function get(val:String):Dynamic
	{
		return interp.variables.get(val);
	}

	public override function set(val:String, value:Dynamic)
	{
		interp.variables.set(val, value);
	}

	public override function setPublicMap(map:Map<String, Dynamic>)
	{
		for (k => v in map)
			interp.variables.set(k, v);
	}

	override public function destroy()
	{
		if (interp != null && interp.variables != null)
			interp.variables.clear();
		
		interp = null;
		parser = null;
		expr = null;
		code = null;
		
		super.destroy();
	}
}
