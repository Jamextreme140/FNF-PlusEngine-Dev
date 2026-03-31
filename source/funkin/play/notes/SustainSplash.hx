package funkin.play.notes;

import funkin.graphics.animation.PsychAnimationController;
import funkin.graphics.shaders.RGBPalette;
import flixel.graphics.frames.FlxAtlasFrames;

typedef HoldSplashAnim = {
	var name:String;
	var prefix:String;
	var fps:Int;
	var looped:Bool;
	var offsets:Array<Float>;
}

typedef HoldSplashConfig = {
	var animations:Map<String, HoldSplashAnim>;
	var scale:Float;
	var allowRGB:Bool;
	var allowPixel:Bool;
}

class SustainSplash extends FlxSprite
{
	public static var startCrochet:Float;
	public static var frameRate:Int;
	
	public static var defaultHoldSplash(default, never):String = "holdCovers/holdCover";
	public static var configs:Map<String, HoldSplashConfig> = new Map();
	
	public var strumNote:StrumNote;
	public var texture:String;
	public var config(default, set):HoldSplashConfig;
	public var rgbShader:funkin.play.notes.NoteSplash.PixelSplashShaderRef;

	var timer:FlxTimer;

	public function new(?holdSplash:String):Void
	{
		super();

		x = -50000;
		
		animation = new PsychAnimationController(this);
		
		rgbShader = new funkin.play.notes.NoteSplash.PixelSplashShaderRef();
		shader = rgbShader.shader;

		loadHoldSplash(holdSplash);
	}

	private function safeLoadAtlas(key:String):FlxAtlasFrames
	{
		if (key == null || key.trim().length < 1)
			return null;

		try
		{
			return Paths.getSparrowAtlas(key);
		}
		catch (e:Dynamic)
		{
			// Silently ignore and return null so callers can fall back gracefully
		}
		return null;
	}
	
	public function loadHoldSplash(?holdSplash:String)
	{
		config = null;
		
		var pixelPrefix:String = PlayState.isPixelStage ? 'pixelUI/' : '';
		
		if(holdSplash == null)
		{
			// NOTE: PlayState.SONG.splashSkin is for note splashes, NOT hold covers.
			// Hold covers have their own separate asset path (holdCovers/holdCover).
			holdSplash = pixelPrefix + defaultHoldSplash + getHoldSplashPostfix();
		}
		
		texture = holdSplash;
		frames = safeLoadAtlas(texture);
		if (frames == null)
		{
			texture = pixelPrefix + defaultHoldSplash + getHoldSplashPostfix();
			frames = safeLoadAtlas(texture);
			if (frames == null)
			{
				texture = pixelPrefix + defaultHoldSplash + '-Vanilla';
				frames = safeLoadAtlas(texture);
				if (frames == null)
				{
					visible = false;
					active = false;
				}
			}
		}
		
		var path:String = 'images/$texture';
		if (configs.exists(path))
		{
			this.config = configs.get(path);
			return;
		}
		else if (Paths.fileExists('$path.json', TEXT))
		{
			var configData:Dynamic = haxe.Json.parse(Paths.getTextFromFile('$path.json'));
			if (configData != null)
			{
				var tempConfig:HoldSplashConfig = {
					animations: new Map(),
					scale: configData.scale != null ? configData.scale : 1,
					allowRGB: configData.allowRGB != null ? configData.allowRGB : true,
					allowPixel: configData.allowPixel != null ? configData.allowPixel : true
				}
				
				for (i in Reflect.fields(configData.animations))
				{
					var anim:HoldSplashAnim = Reflect.field(configData.animations, i);
					tempConfig.animations.set(i, anim);
				}
				
				this.config = tempConfig;
				configs.set(path, this.config);
				return;
			}
		}
		
		// Default config if no JSON found
		var tempConfig:HoldSplashConfig = createConfig();
		addAnimationToConfig(tempConfig, 'hold', 'holdCover0', 24, true, [0, 0]);
		addAnimationToConfig(tempConfig, 'end', 'holdCoverEnd0', 24, false, [0, 0]);
		
		this.config = tempConfig;
		configs.set(path, this.config);
	}
	
	public static function getHoldSplashPostfix()
	{
		var skin:String = '';
		if(ClientPrefs.data.splashSkin != ClientPrefs.defaultData.splashSkin)
			skin = '-' + ClientPrefs.data.splashSkin.trim();
		else
			skin = '-Vanilla'; // Default to Vanilla skin
		return skin;
	}
	
	public static function createConfig():HoldSplashConfig
	{
		return {
			animations: new Map(),
			scale: 1,
			allowRGB: true,
			allowPixel: true
		}
	}
	
	public static function addAnimationToConfig(config:HoldSplashConfig, name:String, prefix:String, fps:Int, looped:Bool, offsets:Array<Float>):HoldSplashConfig
	{
		if (config == null) config = createConfig();
		
		config.animations.set(name, {
			name: name, 
			prefix: prefix, 
			fps: fps, 
			looped: looped, 
			offsets: offsets
		});
		return config;
	}
	
	function set_config(value:HoldSplashConfig):HoldSplashConfig 
	{
		if (value == null) value = createConfig();
		
		@:privateAccess
		animation.clearAnimations();
		
		for (i in value.animations)
		{
			var key:String = i.name;
			if (i.prefix.length > 0 && key != null && key.length > 0)
			{
				animation.addByPrefix(key, i.prefix, i.fps, i.looped);
			}
		}
		
		scale.set(value.scale, value.scale);
		return config = value;
	}

	override function update(elapsed)
	{
		super.update(elapsed);

		if (strumNote != null)
		{
			setPosition(strumNote.x, strumNote.y);
			visible = strumNote.visible;
		}
	}

	public function setupSusSplash(strum:StrumNote, daNote:Note, ?playbackRate:Float = 1):Void
	{
		
		// Load custom hold splash if specified in note
		if (daNote.noteSplashData.texture != null && daNote.noteSplashData.texture.length > 0)
		{
			var customSplash:String = 'holdCovers/' + daNote.noteSplashData.texture;
			if (texture != customSplash)
				loadHoldSplash(customSplash);
		}

		final lengthToGet:Int = !daNote.isSustainNote ? daNote.tail.length : daNote.parent.tail.length;
		final timeToGet:Float = !daNote.isSustainNote ? daNote.strumTime : daNote.parent.strumTime;
		final timeThingy:Float = (startCrochet * lengthToGet + (timeToGet - Conductor.songPosition + ClientPrefs.data.ratingOffset)) / playbackRate * .001;

		var tailEnd:Note = !daNote.isSustainNote ? daNote.tail[daNote.tail.length - 1] : daNote.parent.tail[daNote.parent.tail.length - 1];

		// Clear any previous callback before setting new one
		if (animation.finishCallback != null)
			animation.finishCallback = null;

		animation.play('hold', true, false, 0);
		if (animation.curAnim != null)
		{
			// Use fps from config if available, otherwise use frameRate
			if (config != null && config.animations.exists('hold'))
			{
				var holdAnim:HoldSplashAnim = config.animations.get('hold');
				animation.curAnim.frameRate = holdAnim.fps;
				animation.curAnim.looped = holdAnim.looped;
			}
			else
			{
				animation.curAnim.frameRate = frameRate;
				animation.curAnim.looped = true;
			}
		}
		
		// Apply offsets from config
		offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);
		if (config != null && config.animations.exists('hold'))
		{
			var holdAnim:HoldSplashAnim = config.animations.get('hold');
			if (holdAnim.offsets != null && holdAnim.offsets.length >= 2)
			{
				offset.x += holdAnim.offsets[0];
				offset.y += holdAnim.offsets[1];
			}
		}

		// Apply RGB shader (similar to NoteSplash)
		var tempShader:RGBPalette = null;
		if (config.allowRGB)
		{
			var noteData:Int = daNote.noteData % funkin.play.notes.Note.colArray.length;
			funkin.play.notes.Note.initializeGlobalRGBShader(noteData);
			
			if (daNote.noteSplashData.useRGBShader && (PlayState.SONG == null || !PlayState.SONG.disableNoteRGB))
			{
				tempShader = new RGBPalette();
				
				if (!daNote.noteSplashData.useGlobalShader)
				{
					var arr:Array<FlxColor> = ClientPrefs.data.arrowRGB[noteData];
					if (PlayState.isPixelStage) arr = ClientPrefs.data.arrowRGBPixel[noteData];
					
					tempShader.r = arr[0];
					tempShader.g = arr[1];
					tempShader.b = arr[2];
					
					if (daNote.noteSplashData.r != -1) tempShader.r = daNote.noteSplashData.r;
					if (daNote.noteSplashData.g != -1) tempShader.g = daNote.noteSplashData.g;
					if (daNote.noteSplashData.b != -1) tempShader.b = daNote.noteSplashData.b;
				}
				else tempShader.copyValues(funkin.play.notes.Note.globalRgbShaders[noteData]);
			}
			else
			{
				// nothing
			}
		}
		
		rgbShader.copyValues(tempShader);
		if (!config.allowPixel) rgbShader.pixelAmount = 1;
		else if (PlayState.isPixelStage) rgbShader.pixelAmount = 6;
		
		// Assign shader to sprite
		shader = rgbShader.shader;

		strumNote = strum;
		alpha = daNote.noteSplashData.a;
		
		antialiasing = ClientPrefs.data.antialiasing;
		antialiasing = daNote.noteSplashData.antialiasing;
		if (PlayState.isPixelStage && config.allowPixel) 
			antialiasing = false;

		if (timer != null)
			timer.cancel();

		if (alpha != 0)
			timer = new FlxTimer().start(timeThingy, (idk:FlxTimer) ->
			{
				if (!(daNote.isSustainNote ? daNote.parent.noteSplashData.disabled : daNote.noteSplashData.disabled) && animation != null && !daNote.hitByOpponent)
				{
					alpha = daNote.noteSplashData.a;
					
					// Clear any previous callback before setting new one
					if (animation.finishCallback != null)
						animation.finishCallback = null;
					
					animation.play('end', true, false, 0);
					
					// If 'end' animation does not exist / frames are missing, kill immediately.
					if (animation.curAnim == null)
					{

					}
					
					// Apply end animation offsets
					offset.set(PlayState.isPixelStage ? 112.5 : 106.25, 100);
					if (config != null && config.animations.exists('end'))
					{
						var endAnim:HoldSplashAnim = config.animations.get('end');
						if (endAnim.offsets != null && endAnim.offsets.length >= 2)
						{
							offset.x += endAnim.offsets[0];
							offset.y += endAnim.offsets[1];
						}
						
						if (animation.curAnim != null)
						{
							animation.curAnim.looped = endAnim.looped;
							animation.curAnim.frameRate = endAnim.fps;
						}
					}
					else if (animation.curAnim != null)
					{
						animation.curAnim.looped = false;
						animation.curAnim.frameRate = 24;
					}
					
					// Don't reset clipRect, keep it null
					animation.finishCallback = (idkEither:Dynamic) ->
					{
						kill();
					}
					return;
				}
				kill();
			});
	}
	
	override public function kill():Void
	{
		if (timer != null)
		{
			timer.cancel();
			timer = null;
		}
		if (animation != null && animation.finishCallback != null)
			animation.finishCallback = null;
		
		super.kill();
	}
}
