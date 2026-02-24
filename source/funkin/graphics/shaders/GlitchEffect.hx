package funkin.graphics.shaders;

// Wrapper class for GlitchShader, following the WiggleEffect pattern
class GlitchEffect
{
	public var shader(default, null):GlitchShader = new GlitchShader();
	public var binaryIntensity(default, set):Float = 0.0;
	public var negativity(default, set):Float = 0.0;
	public var time:Float = 0.0;

	public function new(binaryIntensity:Float = 0.0, negativity:Float = 0.0):Void
	{
		this.binaryIntensity = binaryIntensity;
		this.negativity = negativity;
	}

	public function update(elapsed:Float):Void
	{
		time += elapsed;
		shader.iTime.value = [time];
	}

	function set_binaryIntensity(v:Float):Float
	{
		binaryIntensity = v;
		shader.binaryIntensity.value = [v];
		return v;
	}

	function set_negativity(v:Float):Float
	{
		negativity = v;
		shader.negativity.value = [v];
		return v;
	}
}

class GlitchShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		uniform float binaryIntensity;
		uniform float negativity;
		uniform float iTime;
		
		void main() {
			vec2 uv = openfl_TextureCoordv;
			
			// If intensity is too low, just show original texture
			if (binaryIntensity < 0.01) {
				vec4 color = flixel_texture2D(bitmap, uv);
				gl_FragColor = color;
				return;
			}
			
			// Add time-based offset for animation
			float timeOffset = sin(iTime * 2.0 + uv.y * 10.0) * 0.005 * binaryIntensity;
			uv.x += timeOffset;
			
			// get snapped position
			float psize = 0.04 * binaryIntensity;
			float psq = 1.0 / psize;
			
			float px = floor(uv.x * psq + 0.5) * psize;
			float py = floor(uv.y * psq + 0.5) * psize;
			
			vec4 colSnap = flixel_texture2D(bitmap, vec2(px, py));
			
			float lum = pow(1.0 - (colSnap.r + colSnap.g + colSnap.b) / 3.0, binaryIntensity);
			
			float qsize = psize * lum;
			float qsq = 1.0 / qsize;
			
			float qx = floor(uv.x * qsq + 0.5) * qsize;
			float qy = floor(uv.y * qsq + 0.5) * qsize;
			
			float rx = (px - qx) * lum + uv.x;
			float ry = (py - qy) * lum + uv.y;
			
			vec4 mierdaColor = flixel_texture2D(bitmap, vec2(rx, ry));
			
			// Apply negativity effect while preserving alpha
			vec4 negativeColor = vec4(1.0 - mierdaColor.r, 1.0 - mierdaColor.g, 1.0 - mierdaColor.b, mierdaColor.a);
			gl_FragColor = mix(mierdaColor, negativeColor, negativity);
		}
	')

	public function new()
	{
		super();
	}
}