package flxanimate;

import flixel.util.FlxDestroyUtil;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxAtlasFrames;
import flxanimate.frames.FlxAnimateFrames;
import flxanimate.data.AnimationData;
import flxanimate.FlxAnimate as OriginalFlxAnimate;

class PsychFlxAnimate extends OriginalFlxAnimate
{
	public function loadAtlasEx(img:FlxGraphicAsset, pathOrStr:String = null, myJson:Dynamic = null)
	{
		var animJson:AnimAtlas = null;
		if(myJson != null && (myJson is String))
		{
			// Fix: check myJson itself (not pathOrStr) to decide if it's a file path
			var jsonStr:String = cast myJson;
			var trimmedJson:String = jsonStr.trim();
			trimmedJson = trimmedJson.substr(trimmedJson.length - 5).toLowerCase();
			if(trimmedJson == '.json') jsonStr = File.getContent(jsonStr); // is a path
			animJson = cast haxe.Json.parse(_removeBOM(jsonStr));
		}
		else if(myJson != null)
			animJson = cast myJson;

		var isXml:Null<Bool> = null;
		var myData:Dynamic = null;

		// Guard against null pathOrStr
		if(pathOrStr != null)
		{
			myData = pathOrStr;
			var trimmed:String = pathOrStr.trim();
			trimmed = trimmed.substr(trimmed.length - 5).toLowerCase();

			if(trimmed == '.json') // Path is json
			{
				myData = File.getContent(pathOrStr);
				isXml = false;
			}
			else if(trimmed.substr(1) == '.xml') // Path is xml
			{
				myData = File.getContent(pathOrStr);
				isXml = true;
			}
			myData = _removeBOM(myData);

			// Automatic detection if everything else fails
			switch(isXml)
			{
				case true:
					myData = Xml.parse(myData);
				case false:
					myData = haxe.Json.parse(myData);
				case null:
					try
					{
						myData = haxe.Json.parse(myData);
						isXml = false;
					}
					catch(e)
					{
						myData = Xml.parse(myData);
						isXml = true;
					}
			}
		}

		anim._loadAtlas(animJson);
		if(myData != null)
		{
			if(!isXml) frames = FlxAnimateFrames.fromSpriteMap(cast myData, img);
			else frames = FlxAnimateFrames.fromSparrow(cast myData, img);
		}
		origin = anim.curInstance.symbol.transformationPoint;
	}

	/**
	 * Load a multi-page Adobe Animate sprite atlas (multiple spritemap pages).
	 * All pages share the same Animation.json but each has its own spritemap image and JSON.
	 * @param imgs        One FlxGraphicAsset per spritemap page (e.g. spritemap1.png, spritemap2.png)
	 * @param spriteJsons One JSON content string per spritemap page
	 * @param myJson      Animation.json content (shared across all pages)
	 */
	public function loadAtlasExMulti(imgs:Array<FlxGraphicAsset>, spriteJsons:Array<String>, myJson:Dynamic = null)
	{
		var animJson:AnimAtlas = null;
		if(myJson != null && (myJson is String))
			animJson = cast haxe.Json.parse(_removeBOM(cast(myJson, String)));
		else if(myJson != null)
			animJson = cast myJson;

		anim._loadAtlas(animJson);

		if(spriteJsons == null || spriteJsons.length == 0 || imgs == null || imgs.length == 0)
			return;

		var firstFrames:FlxAtlasFrames = cast FlxAnimateFrames.fromSpriteMap(haxe.Json.parse(_removeBOM(spriteJsons[0])), imgs[0]);
		if(firstFrames == null) return;

		if(spriteJsons.length == 1)
		{
			frames = firstFrames;
		}
		else
		{
			// Merge all pages into one frames collection (same pattern as Paths.getMultiAtlas)
			var mergedFrames:FlxAtlasFrames = new FlxAtlasFrames(firstFrames.parent);
			mergedFrames.addAtlas(firstFrames);

			final pageCount:Int = Std.int(Math.min(spriteJsons.length, imgs.length));
			for(i in 1...pageCount)
			{
				var pageFrames:FlxAtlasFrames = cast FlxAnimateFrames.fromSpriteMap(haxe.Json.parse(_removeBOM(spriteJsons[i])), imgs[i]);
				if(pageFrames != null)
					mergedFrames.addAtlas(pageFrames);
			}

			frames = mergedFrames;
		}

		origin = anim.curInstance.symbol.transformationPoint;
	}

	override function draw()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}

	override function destroy()
	{
		try
		{
			super.destroy();
		}
		catch(e:haxe.Exception)
		{
			anim.curInstance = FlxDestroyUtil.destroy(anim.curInstance);
			anim.stageInstance = FlxDestroyUtil.destroy(anim.stageInstance);
			//anim.metadata = FlxDestroyUtil.destroy(anim.metadata);
			anim.metadata.destroy();
			anim.symbolDictionary = null;
		}
	}

	function _removeBOM(str:String) //Removes BOM byte order indicator
	{
		if (str.charCodeAt(0) == 0xFEFF) str = str.substr(1); //myData = myData.substr(2);
		return str;
	}

	public function pauseAnimation()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		anim.pause();
	}
	public function resumeAnimation()
	{
		if(anim.curInstance == null || anim.curSymbol == null) return;
		anim.play();
	}
}