package pao_py;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween.FlxTweenType;
import openfl.display.BlendMode;
import Type.ValueType;

class PythonUtils
{
	public static final Function_StopPy:String = "##PYTHON_FUNCTIONSTOPPY";
	public static final Function_Stop:String = "##PYTHON_FUNCTIONSTOP";
	public static final Function_Continue:String = "##PYTHON_FUNCTIONCONTINUE";

	public static inline function isOfTypes(value:Any, types:Array<Dynamic>):Bool {
		for (type in types) {
			if(Std.isOfType(value, type)) return true;
		}
		return false;
	}

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any {
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1) {
			var target:Dynamic = null;
			if(MusicBeatState.getVariables().exists(splitProps[0])) {
				var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				if(i >= splitProps.length-1)
					target[j] = value;
				else
					target = target[j];
			}
			return target;
		}

		if(instance is MusicBeatState && MusicBeatState.getVariables().exists(variable)) {
			MusicBeatState.getVariables().set(variable, value);
			return value;
		}
		Reflect.setProperty(instance, variable, value);
		return value;
	}

	public static function getVarInArray(instance:Dynamic, variable:String):Any {
		var splitProps:Array<String> = variable.split('[');
		if(splitProps.length > 1) {
			var target:Dynamic = null;
			if(MusicBeatState.getVariables().exists(splitProps[0])) {
				var retVal:Dynamic = MusicBeatState.getVariables().get(splitProps[0]);
				if(retVal != null)
					target = retVal;
			}
			else
				target = Reflect.getProperty(instance, splitProps[0]);

			for (i in 1...splitProps.length) {
				var j:Dynamic = splitProps[i].substr(0, splitProps[i].length - 1);
				target = target[j];
			}
			return target;
		}

		if(instance is MusicBeatState && MusicBeatState.getVariables().exists(variable))
			return MusicBeatState.getVariables().get(variable);

		return Reflect.getProperty(instance, variable);
	}

	public static function getTweenEaseByString(?ease:String = ''):EaseFunction {
		if(ease == null || ease.length < 1) ease = 'linear';
		ease = ease.trim().toLowerCase();

		switch(ease) {
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	public static function getTweenTypeByString(?type:String = ''):FlxTweenType {
		if(type == null || type.length < 1) type = 'oneshot';
		type = type.trim().toLowerCase();

		switch(type) {
			case 'backward': return FlxTweenType.BACKWARD;
			case 'looping' | 'loop': return FlxTweenType.LOOPING;
			case 'persist': return FlxTweenType.PERSIST;
			case 'pingpong': return FlxTweenType.PINGPONG;
		}
		return FlxTweenType.ONESHOT;
	}

	public static function blendModeFromString(blend:String):BlendMode {
		switch(blend.toLowerCase().trim()) {
			case 'add': return BlendMode.ADD;
			case 'alpha': return BlendMode.ALPHA;
			case 'darken': return BlendMode.DARKEN;
			case 'difference': return BlendMode.DIFFERENCE;
			case 'erase': return BlendMode.ERASE;
			case 'hardlight': return BlendMode.HARDLIGHT;
			case 'invert': return BlendMode.INVERT;
			case 'layer': return BlendMode.LAYER;
			case 'lighten': return BlendMode.LIGHTEN;
			case 'multiply': return BlendMode.MULTIPLY;
			case 'overlay': return BlendMode.OVERLAY;
			case 'screen': return BlendMode.SCREEN;
			case 'shader': return BlendMode.SHADER;
			case 'subtract': return BlendMode.SUBTRACT;
		}
		return BlendMode.NORMAL;
	}

	public static function typeToString(type:ValueType):String {
		switch(type) {
			case ValueType.TNull: return "null";
			case ValueType.TBool: return "boolean";
			case ValueType.TInt: return "integer";
			case ValueType.TFloat: return "float";
			case ValueType.TClass(_): return "class";
			case ValueType.TObject: return "object";
			case ValueType.TFunction: return "function";
			case ValueType.TEnum(_): return "enum";
			default: return "unknown";
		}
	}

	// Android-specific optimizations
	#if android
	public static inline function shouldSkipHeavyOperation():Bool {
		// Skip heavy operations if FPS is too low
		return FlxG.drawFramerate < 30;
	}
	#end
}
