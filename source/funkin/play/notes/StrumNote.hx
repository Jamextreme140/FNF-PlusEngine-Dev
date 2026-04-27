package funkin.play.notes;

import funkin.graphics.animation.PsychAnimationController;

import funkin.graphics.shaders.ColorSwap;
import funkin.graphics.shaders.RGBPalette.RGBShaderReference;
class StrumNote extends FlxSprite
{
	public var rgbShader:RGBShaderReference;
	public var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	private var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	private var player:Int;
	
	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public var useRGBShader:Bool = true;
	public var animateOnBeat:Bool = false; // Para sincronizar animación estática con el beat (NotITG)

	function getLegacyHSV():Array<Float>
	{
		var index:Int = noteData % ClientPrefs.data.arrowHSV.length;
		if (index < 0) index += ClientPrefs.data.arrowHSV.length;
		return ClientPrefs.data.arrowHSV[index];
	}

	public function refreshLegacyColorSwap():Void
	{
		if (colorSwap == null) return;

		var values:Array<Float> = getLegacyHSV();
		colorSwap.hue = values[0] / 360;
		colorSwap.saturation = values[1] / 100;
		colorSwap.brightness = values[2] / 100;
	}

	function canUseRGBShader():Bool
	{
		return ClientPrefs.data.noteRGB && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
	}

	function canUseLegacyColorSwap():Bool
	{
		return !ClientPrefs.data.noteRGB && !ClientPrefs.data.colorQuantization && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB);
	}

	public function refreshColorMode():Void
	{
		var skinLower:String = texture != null ? texture.toLowerCase() : '';
		var isSpecialSkin:Bool = skinLower.contains('notitg');

		if (isSpecialSkin)
		{
			useRGBShader = false;
			animateOnBeat = true;
			if (rgbShader != null)
			{
				rgbShader.forceDisabled = true;
				rgbShader.enabled = false;
			}
			shader = null;
			return;
		}

		animateOnBeat = false;
		refreshLegacyColorSwap();

		if (canUseLegacyColorSwap())
		{
			useRGBShader = false;
			if (rgbShader != null)
			{
				rgbShader.forceDisabled = true;
				rgbShader.enabled = false;
			}
			shader = colorSwap != null ? colorSwap.shader : null;
			return;
		}

		useRGBShader = canUseRGBShader();
		if (rgbShader != null)
		{
			rgbShader.forceDisabled = false;
			rgbShader.enabled = useRGBShader && animation.curAnim != null && animation.curAnim.name != 'static';
		}
		shader = (rgbShader != null && rgbShader.enabled) ? rgbShader.parent.shader : null;
	}
	
	public function new(x:Float, y:Float, leData:Int, player:Int) {
		animation = new PsychAnimationController(this);

		noteData = leData;
		this.player = player;
		this.noteData = leData;
		this.ID = noteData;
		super(x, y);

		var skin:String = null;
		if(PlayState.SONG != null && PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) skin = PlayState.SONG.arrowSkin;
		else 
		{
			skin = Note.getDefaultNoteSkin();
		}

		var skinPostfix:String = (skin == Note.legacyNoteSkin && !ClientPrefs.data.noteRGB) ? '' : Note.getNoteSkinPostfix();
		var customSkin:String = skin + skinPostfix;
		if(Paths.fileExists('images/$customSkin.png', IMAGE)) skin = customSkin;
		
		// Detect special skins first, before configuring the shader.
		var isNotITG:Bool = skin.toLowerCase().contains('notitg');
		
		// Create shader.
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		rgbShader.enabled = false;
		colorSwap = new ColorSwap();
		refreshLegacyColorSwap();
		
		// NotITG skins keep RGB shader disabled from the start.
		if(isNotITG)
		{
			useRGBShader = false;
			animateOnBeat = true;
			rgbShader.enabled = false;
			rgbShader.forceDisabled = true; // Keep shader activation blocked.
			shader = null; // Do not apply shader.
		}
		else
		{
			// Only assign RGB colors when it's not a special skin.
			var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[leData];
			if(PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[leData];
			
			if(leData <= arr.length)
			{
				@:bypassAccessor
				{
					rgbShader.r = arr[0];
					rgbShader.g = arr[1];
					rgbShader.b = arr[2];
				}
			}
		}

		texture = skin; //Load texture and anims
		
		scrollFactor.set();
		playAnim('static');
	}
	
	public function checkNotITGSkin():Void
	{
		refreshColorMode();
	}

	public function reloadNote()
	{
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;

		// NotITG skins have no pixel variant - treat them as normal skins on any stage
		var textureLower:String = texture.toLowerCase();
		var isSpecialSkin:Bool = textureLower.contains('notitg');

		if(PlayState.isPixelStage && !isSpecialSkin)
		{
			loadGraphic(Paths.image('pixelUI/' + texture));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + texture), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(texture);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.data.antialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData) % 4)
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
			}
		}
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
		
		// Re-check special skin after reloading.
		checkNotITGSkin();
	}

	public function playerPosition(?overridePlayer:Null<Int> = null)
	{
		var playerValue:Int = overridePlayer != null ? overridePlayer : player;
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * playerValue);
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false) {
		animation.play(anim, force);
		if(animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}
		refreshColorMode();
	}
}
