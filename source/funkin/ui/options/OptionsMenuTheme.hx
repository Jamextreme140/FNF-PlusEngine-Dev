package funkin.ui.options;

import funkin.Preferences as ClientPrefs;
import funkin.ui.components.md3.MD3Theme;

typedef OptionsAccentPalette = {
	var name:String;
	var accent:Int;
	var strong:Int;
	var muted:Int;
	var pale:Int;
	var mist:Int;
}

class OptionsMenuTheme
{
	public static var ACCENT_CHOICES(default, null):Array<String> = ['Purple', 'Teal', 'Rose', 'Amber', 'Indigo', 'Green', 'Red'];

	public static function normalizeAccent(value:String):String
	{
		if (value == null || value.length == 0)
			return 'Purple';

		for (choice in ACCENT_CHOICES)
		{
			if (choice.toLowerCase() == value.toLowerCase())
				return choice;
		}

		return 'Purple';
	}

	public static function current():OptionsAccentPalette
	{
		return getPalette(ClientPrefs.data.menuAccentColor);
	}

	public static function getPalette(?value:String):OptionsAccentPalette
	{
		switch (normalizeAccent(value))
		{
			case 'Teal':
				return {
					name: 'Teal',
					accent: 0xFF1D8B91,
					strong: 0xFF155B60,
					muted: 0xFF4F7E84,
					pale: 0xFFBFE8EA,
					mist: 0xFFE9F9FA
				};
			case 'Rose':
				return {
					name: 'Rose',
					accent: 0xFFCC5F86,
					strong: 0xFF8B3456,
					muted: 0xFFA1647B,
					pale: 0xFFF2CAD8,
					mist: 0xFFFFEFF5
				};
			case 'Amber':
				return {
					name: 'Amber',
					accent: 0xFFB97819,
					strong: 0xFF7A4B00,
					muted: 0xFF9D7341,
					pale: 0xFFF0D7AC,
					mist: 0xFFFFF6E7
				};
			case 'Indigo':
				return {
					name: 'Indigo',
					accent: 0xFF5569C9,
					strong: 0xFF34418B,
					muted: 0xFF6673A8,
					pale: 0xFFD2D8F8,
					mist: 0xFFF1F3FF
				};
			case 'Green':
				return {
					name: 'Green',
					accent: 0xFF3B9A62,
					strong: 0xFF1D6A40,
					muted: 0xFF5B886D,
					pale: 0xFFCBEBD8,
					mist: 0xFFEFFAF3
				};
			case 'Red':
				return {
					name: 'Red',
					accent: 0xFFD25A52,
					strong: 0xFF8A302A,
					muted: 0xFFA66560,
					pale: 0xFFF4CBC8,
					mist: 0xFFFFF0EF
				};
			default:
				return {
					name: 'Purple',
					accent: 0xFF6F52D8,
					strong: 0xFF4D34A8,
					muted: 0xFF7F67C4,
					pale: 0xFFDCCFFB,
					mist: 0xFFF3ECFF
				};
		}
	}

	public static function syncAccent():Void
	{
		var palette = current();
		MD3Theme.setAccent(palette.accent);
	}
}