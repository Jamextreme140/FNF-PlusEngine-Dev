package funkin.ui.debug.character.components;

import haxe.xml.Access;
import funkin.play.character.Character.CharacterFile;
import funkin.play.character.Character.AnimArray;

// Codename Engine XML Character Format
typedef CodenameCharacter = 
{
	var x:Float;
	var y:Float;
	var sprite:String;
	var scale:Float;
	var ?camx:Float;
	var ?camy:Float;
	var icon:String;
	var holdTime:Float;
	var ?isGF:Bool;
	var ?noteSkin:String;
	var ?flipX:Bool;
	var animations:Array<CodenameAnimation>;
}

typedef CodenameAnimation =
{
	var name:String;		// Animation name (idle, singLEFT, etc)
	var anim:String;		// XML animation name
	var x:Float;			// Offset X
	var y:Float;			// Offset Y
	var fps:Int;			// Frames per second
	var loop:Bool;			// Loop animation
	var ?indices:String;	// Indices string (e.g., "8..20" or "1,2,3,4")
}

class CodenameParse
{
	/**
	 * Convert Codename Engine XML character to Psych Engine JSON format
	 * @param xmlContent The XML file content as string
	 * @return CharacterFile in Psych Engine format
	 */
	public static function convertToPsych(xmlContent:String):CharacterFile
	{
		var xml:Access = null;
		try
		{
			xml = new Access(Xml.parse(xmlContent).firstElement());
		}
		catch(e:Dynamic)
		{
			trace('Error parsing XML: $e');
			return null;
		}

		if(xml == null || xml.name != 'character')
		{
			trace('Invalid Codename Engine character XML');
			return null;
		}

		// Parse character attributes
		var charData:CodenameCharacter = {
			x: getFloatAtt(xml, 'x', 0),
			y: getFloatAtt(xml, 'y', 0),
			sprite: getStringAtt(xml, 'sprite', 'characters/BOYFRIEND'),
			scale: getFloatAtt(xml, 'scale', 1),
			camx: getFloatAtt(xml, 'camx', 0),
			camy: getFloatAtt(xml, 'camy', 0),
			icon: getStringAtt(xml, 'icon', 'face'),
			holdTime: getFloatAtt(xml, 'holdTime', 4),
			isGF: getBoolAtt(xml, 'isGF', false),
			flipX: getBoolAtt(xml, 'flipX', false),
			animations: []
		};

		// Parse animations
		for (animNode in xml.nodes.anim)
		{
			var animName:String = getStringAtt(animNode, 'name', '');
			var animAnim:String = getStringAtt(animNode, 'anim', '');
			var animX:Float = getFloatAtt(animNode, 'x', 0);
			var animY:Float = getFloatAtt(animNode, 'y', 0);
			var animFps:Int = Std.int(getFloatAtt(animNode, 'fps', 24));
			var animLoop:Bool = getBoolAtt(animNode, 'loop', false);
			var indicesStr:String = getStringAtt(animNode, 'indices', null);

			charData.animations.push({
				name: animName,
				anim: animAnim,
				x: animX,
				y: animY,
				fps: animFps,
				loop: animLoop,
				indices: indicesStr
			});
		}

		// Convert to Psych Engine format
		return convertCodenameData(charData);
	}

	/**
	 * Convert Codename character data to Psych Engine CharacterFile format
	 */
	static function convertCodenameData(data:CodenameCharacter):CharacterFile
	{
		var psychAnims:Array<AnimArray> = [];

		// Convert animations
		for (anim in data.animations)
		{
			var indices:Array<Int> = [];
			if (anim.indices != null && anim.indices.length > 0)
			{
				indices = parseIndices(anim.indices);
			}

			psychAnims.push({
				anim: anim.name,
				name: anim.anim,
				fps: anim.fps,
				loop: anim.loop,
				indices: indices,
				offsets: [Std.int(anim.x), Std.int(anim.y)]
			});
		}

		// Generate health bar color from icon name
		var healthColor:Array<Int> = [161, 161, 161]; // Default gray color

		// Create Psych Engine character file
		var psychChar:CharacterFile = {
			animations: psychAnims,
			image: 'characters/' + data.sprite,
			scale: data.scale,
			sing_duration: data.holdTime,
			healthicon: data.icon,
			position: [data.x, data.y],
			camera_position: [data.camx != null ? data.camx : 0, data.camy != null ? data.camy : 0],
			flip_x: data.flipX == true,
			no_antialiasing: false,
			healthbar_colors: healthColor,
			vocals_file: null
		};

		return psychChar;
	}

	/**
	 * Parse indices string to array of integers
	 * Supports formats like "8..20" (range) or "1,2,3,4" (list)
	 */
	static function parseIndices(indicesStr:String):Array<Int>
	{
		var result:Array<Int> = [];
		
		if (indicesStr == null || indicesStr.length == 0)
			return result;

		// Check for range format (e.g., "8..20")
		if (indicesStr.indexOf('..') != -1)
		{
			var parts:Array<String> = indicesStr.split('..');
			if (parts.length == 2)
			{
				var start:Null<Int> = Std.parseInt(parts[0].trim());
				var end:Null<Int> = Std.parseInt(parts[1].trim());
				
				if (start != null && end != null)
				{
					for (i in start...end + 1)
					{
						result.push(i);
					}
				}
			}
		}
		// Check for comma-separated list (e.g., "1,2,3,4")
		else if (indicesStr.indexOf(',') != -1)
		{
			var parts:Array<String> = indicesStr.split(',');
			for (part in parts)
			{
				var num:Null<Int> = Std.parseInt(part.trim());
				if (num != null)
					result.push(num);
			}
		}
		// Single number
		else
		{
			var num:Null<Int> = Std.parseInt(indicesStr.trim());
			if (num != null)
				result.push(num);
		}

		return result;
	}

	// Helper functions to safely get XML attributes
	static function getStringAtt(xml:Access, name:String, defaultValue:String):String
	{
		return xml.has.resolve(name) ? xml.att.resolve(name) : defaultValue;
	}

	static function getFloatAtt(xml:Access, name:String, defaultValue:Float):Float
	{
		if (!xml.has.resolve(name))
			return defaultValue;
		
		var val:Null<Float> = Std.parseFloat(xml.att.resolve(name));
		return val != null ? val : defaultValue;
	}

	static function getBoolAtt(xml:Access, name:String, defaultValue:Bool):Bool
	{
		if (!xml.has.resolve(name))
			return defaultValue;
		
		var str:String = xml.att.resolve(name).toLowerCase();
		return str == 'true' || str == '1';
	}
}
