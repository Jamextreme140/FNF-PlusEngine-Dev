package funkin.play.substates;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import haxe.Http;

import funkin.ui.mainmenu.MainMenuState;
import funkin.util.UpdateManager;
import funkin.util.VersionUtil;

class OutdatedSubState extends MusicBeatSubstate
{
	var leftState:Bool = false;
	var changelogLoaded:Bool = false;
	var changelog:String = "";

	var bg:FlxSprite;
	var titleText:FlxText;
	var versionText:FlxText;
	var changelogText:FlxText;
	var controlsText:FlxText;
	var platformText:FlxText;

	override function create()
	{
		controls.isInSubstate = true;
		final enter:String = (controls.mobileC) ? 'A' : 'ENTER';
		final back:String = (controls.mobileC) ? 'B' : 'BACK';

		super.create();

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.scrollFactor.set();
		bg.alpha = 0.0;
		add(bg);

		// Title text - "Update Available!"
		titleText = new FlxText(0, 30, FlxG.width, 
			Language.getPhrase('update_available_title', "Update Available!")
		);
		titleText.setFormat(Paths.font('phantom.ttf'), 48, FlxColor.YELLOW, CENTER);
		titleText.scrollFactor.set();
		titleText.alpha = 0.0;
		add(titleText);

		// Version comparison text with semantic versioning
		var currentVer = UpdateManager.currentVersion;
		var latestVer = UpdateManager.latestVersion;
		versionText = new FlxText(0, 90, FlxG.width,
			Language.getPhrase('version_comparison', "Current: {1} → New: {2}", 
				[currentVer, latestVer])
		);
		versionText.setFormat(Paths.font('phantom.ttf'), 26, FlxColor.WHITE, CENTER);
		versionText.scrollFactor.set();
		versionText.alpha = 0.0;
		add(versionText);

		// Platform text
		platformText = new FlxText(0, 130, FlxG.width,
			Language.getPhrase('platform_text', "Platform: {1}", [UpdateManager.getPlatformName()])
		);
		platformText.setFormat(Paths.font('phantom.ttf'), 20, FlxColor.LIME, CENTER);
		platformText.scrollFactor.set();
		platformText.alpha = 0.0;
		add(platformText);

		// Changelog text (will be loaded from GitHub)
		changelogText = new FlxText(40, 170, FlxG.width - 80,
			Language.getPhrase('loading_changelog', "Loading changelog...")
		);
		changelogText.setFormat(Paths.font('phantom.ttf'), 18, FlxColor.CYAN, LEFT);
		changelogText.scrollFactor.set();
		changelogText.alpha = 0.0;
		add(changelogText);

		// Controls text - Different instructions for mobile and PC
		#if mobile
		controlsText = new FlxText(0, FlxG.height - 100, FlxG.width,
			Language.getPhrase('update_controls_mobile',
				"Press A to download update\nPress B to continue\nDisable this in Options"
			)
		);
		#else
		controlsText = new FlxText(0, FlxG.height - 100, FlxG.width,
			Language.getPhrase('update_controls',
				"Press ENTER to download update\nPress ESC to continue\nDisable this in Options"
			)
		);
		#end
		controlsText.setFormat(Paths.font('phantom.ttf'), 18, FlxColor.WHITE, CENTER);
		controlsText.scrollFactor.set();
		controlsText.alpha = 0.0;
		add(controlsText);

		// TouchPad for mobile devices with visible animation
		#if mobile
		addTouchPad("NONE", "A_B");
		touchPad.alpha = 1.0;
		#end

		// Start animations
		FlxTween.tween(bg, { alpha: 0.8 }, 0.6, { ease: FlxEase.sineIn });
		FlxTween.tween(titleText, { alpha: 1.0 }, 0.6, { ease: FlxEase.sineIn });
		FlxTween.tween(versionText, { alpha: 1.0 }, 0.8, { ease: FlxEase.sineIn });
		FlxTween.tween(platformText, { alpha: 1.0 }, 0.9, { ease: FlxEase.sineIn });
		FlxTween.tween(changelogText, { alpha: 1.0 }, 1.0, { ease: FlxEase.sineIn });
		FlxTween.tween(controlsText, { alpha: 1.0 }, 1.2, { ease: FlxEase.sineIn });

		// Load changelog from GitHub using UpdateManager URL
		loadChangelog();
    }

	function loadChangelog():Void
	{
		var http = new Http(UpdateManager.changelogURL);
		
		http.onData = function(data:String) {
			changelog = data;
			changelogLoaded = true;
			updateChangelogDisplay();
		};
		
		http.onError = function(error:String) {
			changelog = Language.getPhrase('changelog_error', "Error loading changelog: {1}", [error]);
			changelogLoaded = true;
			updateChangelogDisplay();
		};
		
		http.request();
	}

	function updateChangelogDisplay():Void
	{
		if (changelogLoaded && changelogText != null) {
			changelogText.text = Language.getPhrase('changelog_title', "What's New:\n{1}", [changelog]);
		}
	}

	override function update(elapsed:Float)
	{
		if(!leftState) {
			if (controls.ACCEPT) {
				leftState = true;
				// Open download page using UpdateManager
				UpdateManager.openDownloadPage();
			}
			else if(controls.BACK) {
				leftState = true;
			}
			if(leftState)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				
				// Animate touchPad to fade out on mobile
				#if mobile
				if (touchPad != null) {
					FlxTween.tween(touchPad, { alpha: 0.0 }, 0.5, { ease: FlxEase.sineOut });
				}
				#end
				
				FlxTween.tween(bg, { alpha: 0.0 }, 0.9, { ease: FlxEase.sineOut });
				FlxTween.tween(titleText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
				FlxTween.tween(versionText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
				FlxTween.tween(platformText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
				FlxTween.tween(changelogText, {alpha: 0}, 1, { ease: FlxEase.sineOut });
				FlxTween.tween(controlsText, {alpha: 0}, 1, {
					ease: FlxEase.sineOut,
					onComplete: function (twn:FlxTween) {
						FlxG.state.persistentUpdate = true;
						controls.isInSubstate = false;
						close();
					}
				});
			}
		}
		super.update(elapsed);
	}
}
