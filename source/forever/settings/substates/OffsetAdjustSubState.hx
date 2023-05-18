package forever.settings.substates;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import forever.music.Conductor;
import forever.music.MusicBeat.MusicBeatSubState;
import forever.objects.notes.Strumline;

class OffsetAdjustSubState extends MusicBeatSubState {
	public var background:FlxSprite;
	public var milliText:FlxText;
	public var strumline:Strumline;

	public var textFields:FlxTypedGroup<FlxText>;

	public var lockedMovement:Bool = true;

	public override function create():Void {
		super.create();

		background = new FlxSprite().loadGraphic(Paths.image('menus/menuDesat'));
		background.color = 0xFF505050;
		background.scrollFactor.set();
		background.screenCenter(XY);
		add(background);

		strumline = new Strumline(FlxG.width / 2, Init.trueSettings.get('Downscroll') ? FlxG.height - 200 : 0, null, false, true, 4);
		add(strumline);

		textFields = new FlxTypedGroup<FlxText>();
		add(textFields);

		var textPlacement:Float = (Init.trueSettings.get('Downscroll') ? 15 : FlxG.height - 115);
		var infoText:FlxText = new FlxText(0, textPlacement, 0, '[ADJUST NOTE OFFSET]');
		infoText.setFormat(Paths.font('vcr'), 32);
		infoText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		infoText.screenCenter(X);
		textFields.add(infoText);

		var infoText2:FlxText = new FlxText(0, infoText.y + 35, 0, 'NEGATIVE = EARLIER | POSITIVE = LATE');
		infoText2.setFormat(Paths.font('vcr'), 32);
		infoText2.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		infoText2.screenCenter(X);
		textFields.add(infoText2);

		milliText = new FlxText(0, 350, 0, '0ms');
		milliText.setFormat(Paths.font('vcr'), 32);
		milliText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		textFields.add(milliText);

		infoText.alpha = 0;
		infoText2.alpha = 0;
		milliText.alpha = 0;
		background.alpha = 0;

		FlxTween.tween(background, {alpha: 0.6}, 0.6, {ease: FlxEase.cubeOut});
		for (text in textFields.members)
			FlxTween.tween(text, {alpha: 1}, 0.8, {ease: FlxEase.cubeOut, onComplete: function(twn:FlxTween) lockedMovement = false});
	}

	var holdTimer:Float = 0;
	var tempOffset:Float = Init.trueSettings['Offset'];

	public override function update(elapsed:Float) {
		super.update(elapsed);
		Conductor.songPosition += elapsed * 1000;

		if (milliText.alpha > 0) {
			milliText.text = "< " + Math.floor(tempOffset * 10) / 10 + "ms >";
			milliText.screenCenter(X);

			if (tempOffset > 10.1 || tempOffset < -10)
				tempOffset = 0;
		}

		if (!lockedMovement) {
			if (controls.anyJustPressed(["left", "right"])) {
				var move:Int = controls.justPressed("left") ? -1 : controls.justPressed("right") ? 1 : 0;
				if (move != 0)
					tempOffset += move * 0.1;
				holdTimer = 0;
			}

			var timerCalc:Int = Std.int((holdTimer / 1) * 5);

			if (controls.anyPressed(["left", "right"])) {
				holdTimer += elapsed;

				var timerCalcPost:Int = Std.int((holdTimer / 1) * 5);
				var move:Int = controls.pressed("right") ? -1 : controls.pressed("left") ? 1 : 0;

				if (holdTimer > 0.5 && move != 0)
					tempOffset += (timerCalc - timerCalcPost) * move * 0.1;
			}

			if (controls.justPressed("back")) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				Init.trueSettings['Offset'] = tempOffset;
				Init.saveSettings();

				lockedMovement = true;
				for (text in textFields.members)
					FlxTween.tween(text, {alpha: 0}, 0.6);

				for (i in 0...strumline.receptors.members.length) {
					var receptor:Receptor = strumline.receptors.members[i];
					FlxTween.tween(receptor, {y: -10, alpha: 0}, 0.6,
						{ease: FlxEase.circOut, startDelay: 0.2 * i, onComplete: function(twn:FlxTween) close()});
				}
			}
		}
	}

	override function beatHit() {
		print('hey');
		if (strumline != null && strumline.visible) {
			Conductor.songPosition = -(Conductor.stepCrochet);
			strumline.push(SkinManager.generateArrow(2, FlxG.random.int(0, 3), ""));
		}
	}
}
