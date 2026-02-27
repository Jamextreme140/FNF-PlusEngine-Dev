package funkin.graphics.shaders;

import flixel.FlxG;
import flixel.input.mouse.FlxMouse;
import flixel.math.FlxPoint;
import flixel.graphics.tile.FlxGraphicsShader;

using StringTools;

/**
 * Inherits all the standard flixel glsl nuts and bolts as defined in FlxGraphicsShader
 * injects shader toy mainImage in constructor
**/
class FlxShaderToyHack extends FlxGraphicsShader
{
	/**
	 * #pragma header injects from glFragmentHeader on FlxGraphicsShader
	**/
	@:glFragmentSource("#pragma header
		
		// shadertoy uniforms
		uniform vec3 iResolution;
		uniform float iTime;
		uniform float iTimeDelta;
		uniform float iFrame;
		uniform vec4 iMouse;
		// uniform float iChannelTime[4]; todo !
		// uniform vec3 iChannelResolution[4]; ! todo
		// uniform sampler2D iChanneli; ! todo
		
		//!voidmainImage
		
		void main()
		{
			// set the color untouched (do nothing), 
			gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
			
			// store coord so it can be altered (openfl_TextureCoordv is read only)
			vec2 coord = openfl_TextureCoordv;
			
			// flip y axis to match shader toy
			coord.y = 1.0 - coord.y;
			
			// shadertoy uses absolute coords not normalised 0-1 coords
			vec2 fragCoord = coord * iResolution.xy;
			
			// call the shader toy function
			mainImage(gl_FragColor, fragCoord);
		}
	")
	
	public var void_mainImage:String;

	public function new(mainImageFunction:String = "")
	{	
		var useDefaultFunction = mainImageFunction.length <= 0;
		
		if (useDefaultFunction)
		{
			/** the default glsl function that shadertoy uses when you make a new one **/
			mainImageFunction = '
		void mainImage( out vec4 fragColor, in vec2 fragCoord )
		{
			// Normalized pixel coordinates (from 0 to 1)
			vec2 uv = fragCoord/iResolution.xy;
			
			// Time varying pixel color
			vec3 col = 0.5 + 0.5*cos(iTime+uv.xyx+vec3(0,2,4));
			
			// Output to screen
			fragColor = vec4(col,1.0);
		}';
		}

		this.void_mainImage = mainImageFunction;

		// inject mainImage function
		glFragmentSource = glFragmentSource.replace("//!voidmainImage", void_mainImage);

		#if debug
		trace('glFragmentSource\n$glFragmentSource');
		#end
		
		super();

		// init uniforms so they can be used
		iResolution.value = [FlxG.camera.width, FlxG.camera.height, 0.0];
		iTime.value = [0.0];
		iTimeDelta.value = [0.0];
		iFrame.value = [0.0];
		mousePosition = FlxPoint.get();
		iMouse.value = [0.0, 0.0, 0.0, 0.0];
	}

	public function update(elapsed:Float, mouse:FlxMouse)
	{
		iTime.value[0] += elapsed;
		iTimeDelta.value[0] = elapsed;
		update_iMouse(mouse);
	}

	var mousePosition:FlxPoint;

	inline function update_iMouse(mouse:FlxMouse)
	{
		mouse.getPosition(mousePosition);
		
		// iMouse.xy is position
		iMouse.value[0] = mousePosition.x;
		iMouse.value[1] = FlxG.height - mousePosition.y;
		
		// iMouse.zw click state (left, right)
		if (mouse.pressed)
		{
			iMouse.value[2] = mousePosition.x;
			iMouse.value[3] = FlxG.height - mousePosition.y;
		}
	}
}
