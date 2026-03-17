package funkin.graphics.shaders;

class BlurEffect
{
	public var shader(default, null):BlurShader = new BlurShader();
	public var strength(default, set):Float = 0;

	public function new():Void
	{
		shader.strength.value = [0];
	}

	function set_strength(v:Float):Float
	{
		strength = v;
		shader.strength.value = [strength];
		return v;
	}
}

class BlurShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		
		// Optimized Gaussian blur shader adapted from Shadertoy
		// Original: https://www.shadertoy.com/view/4tSyzy
		
		uniform float strength;
		
		const float PI = 3.14159265359;
		const int samples = 7; // 7x7 kernel = 49 samples
		const float sigma = float(samples) * 0.25;
		
		float gaussian(vec2 i) {
			return exp(-.5 * dot(i /= sigma, i)) / (2.0 * PI * sigma * sigma);
		}
		
		vec4 blur(vec2 uv, float blurSize) {
			vec4 color = vec4(0.0);
			float accum = 0.0;
			
			// Gaussian blur with 7x7 kernel
			for (int x = -samples/2; x <= samples/2; x++) {
				for (int y = -samples/2; y <= samples/2; y++) {
					vec2 offset = vec2(float(x), float(y));
					float weight = gaussian(offset);
					color += flixel_texture2D(bitmap, uv + offset * blurSize * 0.001) * weight;
					accum += weight;
				}
			}
			
			return color / accum;
		}
		
		void main() {
			gl_FragColor = blur(openfl_TextureCoordv, strength);
		}
	')
	public function new()
	{
		super();
	}
}
