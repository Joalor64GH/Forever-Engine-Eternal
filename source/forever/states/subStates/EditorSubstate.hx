package forever.states.subStates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import forever.ui.Alphabet;

class EditorSubstate extends forever.music.MusicBeat.MusicBeatSubState {
	var optionsArray:Array<String> = ["Debug Console", "Character Editor", "Chart Editor"];
	var alphabetItems:Array<Alphabet> = [];
	var canSelect:Bool = false;
	var curSelected:Int = 0;

	override function create() {
		super.create();

		var grayBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, flixel.util.FlxColor.GRAY);
		grayBG.alpha = 0;
		add(grayBG);

		var devAlphabet = new Alphabet(0, -200, "Debug Tools", true, false, 0.85);
		devAlphabet.alpha = 0.8;
		devAlphabet.screenCenter(X);

		for (i in 0...optionsArray.length) {
			var newAlphabet = new Alphabet(0, 0, optionsArray[i], true, false, 0.85);
			newAlphabet.isMenuItem = newAlphabet.disableX = true;
			newAlphabet.alpha = 0.8;
			newAlphabet.xTo = -1000;
			newAlphabet.targetY = newAlphabet.ID = i;
			alphabetItems.push(newAlphabet);
		}

		FlxTween.tween(grayBG, {alpha: 0.8}, 0.25, {
			startDelay: 0.25,
			onComplete: function(_) {
				add(devAlphabet);
			}
		}).then(FlxTween.tween(devAlphabet, {y: 50}, 0.5, {
			ease: FlxEase.sineInOut,
			onComplete: function(_) {
				for (alphabet in alphabetItems) {
					add(alphabet);
					alphabet.xTo = 100 * -alphabet.ID;
					canSelect = true;
				}
				changeSelection();
			}
		}));
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		for (item in alphabetItems) {
			item.alpha = FlxMath.lerp(item.alpha, item.ID == curSelected ? 1 : 0.6, Tools.boundFPS(0.10));
			item.customLerp = Tools.boundFPS(FlxMath.bound(elapsed * 20, 0, 1)) * 2;
		}

		if (controls.justPressed("back"))
			close();

		if (controls.anyJustPressed(["up", "down"]))
			changeSelection(controls.justPressed("up") ? -1 : 1);

		if (controls.justPressed("accept")) {
			switch (optionsArray[curSelected].toLowerCase()) {
				case "debug console":
					forever.backend.Console.openConsole();
				case "character editor":
					Main.switchState(new forever.states.editors.CharacterEditor());
				case "chart editor":
					Main.switchState(new forever.states.editors.ChartEditor());
				default: // nothing
			}
		}
	}

	function changeSelection(change:Int = 0) {
		if (canSelect) {
			if (change != 0)
				FlxG.sound.play(Paths.sound("scrollMenu"));

			curSelected = FlxMath.wrap(curSelected + change, 0, alphabetItems.length - 1);

			var placement:Int = 0;
			for (item in alphabetItems) {
				item.targetY = placement - curSelected;
				item.xTo = item.ID == curSelected ? 250 : 100;
				placement++;
			}
		}
	}
}
