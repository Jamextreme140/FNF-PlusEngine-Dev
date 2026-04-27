package funkin.ui.debug.charting.components;

import flixel.util.FlxDestroyUtil;
import funkin.ui.components.PsychUISkin;

// Exit confirmation prompt used on all editors, for convenience
class ExitConfirmationPrompt extends Prompt
{
	public function new(?finishCallback:Void->Void)
	{
		super('There\'s unsaved progress,\nare you sure you want to exit?', function()
		{
			Cursor.hide();
			MusicBeatState.switchState(new funkin.ui.debug.MasterEditorMenu());
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
			if(finishCallback != null) finishCallback();
		}, 'Exit');
	}
}

// A Simple Prompt with "OK" and "Cancel" that covers most case usages
class Prompt extends BasePrompt
{
	var yesFunction:Void->Void;
	var noFunction:Void->Void;
	var _yesTxt:String = 'OK';
	var _noTxt:String = 'Cancel';
	public function new(title:String, yesFunction:Void->Void, ?noFunction:Void->Void, ?_yesTxt:String, ?_noTxt:String)
	{
		if(_yesTxt != null) this._yesTxt = _yesTxt;
		if(_noTxt != null) this._noTxt = _noTxt;
		this.yesFunction = yesFunction;
		controls.isInSubstate = true;
		this.noFunction = noFunction;
		super(title, promptCreate);
	}

	function promptCreate(_)
	{
		var btnY = 390;
		var btn:PsychUIButton = new PsychUIButton(0, btnY, _yesTxt, function() {
			yesFunction();
			controls.isInSubstate = false;
			close();
		});
		btn.useDynamicTheme = false;
		btn.normalStyle = {
			bgColor: 0xFFC74B56,
			textColor: FlxColor.WHITE,
			bgAlpha: 1,
			strokeColor: 0xFFC74B56,
			radius: 12
		};
		btn.hoverStyle = {
			bgColor: 0xFFD75A66,
			textColor: FlxColor.WHITE,
			bgAlpha: 1,
			strokeColor: 0xFFD75A66,
			radius: 12
		};
		btn.clickStyle = {
			bgColor: 0xFFA93A44,
			textColor: FlxColor.WHITE,
			bgAlpha: 1,
			strokeColor: 0xFFA93A44,
			radius: 12
		};
		btn.resize(110, 32);
		btn.screenCenter(X);
		btn.x -= 100;
		btn.cameras = cameras;
		add(btn);

		var btn2:PsychUIButton = new PsychUIButton(0, btnY, _noTxt, close);
		btn2.resize(110, 32);
		btn2.screenCenter(X);
		btn2.x += 100;
		btn2.cameras = cameras;
		add(btn2);
	}

	override function close()
	{
		if(noFunction != null) noFunction();
		super.close();
	}
}

class BasePrompt extends MusicBeatSubstate
{
	var _sizeX:Float = 0;
	var _sizeY:Float = 0;
	var _title:String;
	var _themeSignature:String = null;

	public var onCreate:BasePrompt->Void;
	public var onUpdate:BasePrompt->Float->Void;
	public function new(?sizeX:Float = 420, ?sizeY:Float = 160, title:String, ?onCreate:BasePrompt->Void, ?onUpdate:BasePrompt->Float->Void)
	{
		this._sizeX = sizeX;
		this._sizeY = sizeY;
		this._title = title;
		this.onCreate = onCreate;
		this.onUpdate = onUpdate;
		super();
	}

	public var bg:FlxSprite;
	public var backdrop:FlxSprite;
	public var titleText:FlxText;
	override function create()
	{
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		backdrop = new FlxSprite().makeGraphic(Std.int(FlxG.width), Std.int(FlxG.height), 0x96000000);
		backdrop.cameras = cameras;
		backdrop.scrollFactor.set();
		add(backdrop);

		bg = new FlxSprite();
		PsychUISkin.drawStyledRect(bg, Std.int(_sizeX), Std.int(_sizeY), PsychUISkin.panelStyle());
		bg.screenCenter();
		bg.cameras = cameras;
		add(bg);
		
		var headerBar:FlxSprite = new FlxSprite(bg.x + 18, bg.y + 14);
		PsychUISkin.drawStyledRect(headerBar, Std.int(bg.width - 36), 8, {
			bgColor: PsychUISkin.accent(),
			textColor: FlxColor.WHITE,
			bgAlpha: 1.0,
			radius: PsychUISkin.PILL_RADIUS
		});
		headerBar.cameras = cameras;
		add(headerBar);

		titleText = new FlxText(bg.x + 24, bg.y + 34, Std.int(bg.width - 48), _title, 16);
		titleText.alignment = CENTER;
		titleText.color = PsychUISkin.textPrimary();
		titleText.textField.wordWrap = true;
		titleText.textField.multiline = true;
		titleText.cameras = cameras;
		add(titleText);
		
		if(onCreate != null)
			onCreate(this);
		super.create();
	}

	var _blockInput:Float = 0.1;
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		refreshThemeTexts();

		_blockInput = Math.max(0, _blockInput - elapsed);
		if(_blockInput <= 0 && FlxG.keys.justPressed.ESCAPE)
		{
			controls.isInSubstate = false;
			close();
			return;
		}

		if(onUpdate != null)
			onUpdate(this, elapsed);
	}

	function refreshThemeTexts(force:Bool = false):Void
	{
		var signature:String = PsychUISkin.signature();
		if(!force && _themeSignature == signature)
			return;

		for(member in members)
		{
			if(member != null && member.exists && Std.isOfType(member, FlxText))
				cast(member, FlxText).color = PsychUISkin.textPrimary();
		}
		_themeSignature = signature;
	}

	override function destroy()
	{
		for (member in members) FlxDestroyUtil.destroy(member);
		super.destroy();
	}
}
