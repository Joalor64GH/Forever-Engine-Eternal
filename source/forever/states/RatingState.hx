package forever.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import forever.data.Timings;
import forever.music.MusicBeat.MusicBeatState;

class RatingState extends MusicBeatState {
	var texts:Map<String, FlxText> = [];
	var judgementText:FlxText;

	var amounts:Map<String, Int> = ["sick" => 0, "good" => 0, "bad" => 0, "shit" => 0, "miss" => 0];
	var oldAmounts:Map<String, Int> = ["sick" => 0, "good" => 0, "bad" => 0, "shit" => 0, "miss" => 0];

	var canLerp:Bool = false;

	override function create() {
		super.create();
		// Timings.callAccuracy();
		Timings.gottenJudgements["sick"] = 10000; // for testing
		Timings.gottenJudgements["good"] = 1000;
		Timings.gottenJudgements["bad"] = 100;

		add(new FlxSprite().loadGraphic(Paths.image("menus/menuBG")));
		var backdrop:FlxBackdrop = new FlxBackdrop(Paths.image("menus/gridPurple"));
		backdrop.color = FlxColor.ORANGE;
		backdrop.moves = true;
		backdrop.velocity.set(-3.5);
		backdrop.alpha = 0.4;
		add(backdrop);

		var scrollThing = new FlxSprite().makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		scrollThing.y = FlxG.height - scrollThing.height;
		add(scrollThing);

		var text = new FlxText().setFormat(Paths.font('vcr'), 32);
		text.text = '${PlayState.current.curSong.toUpperCase()} ${forever.backend.LevelData.curDifficulties[PlayState.storyDifficulty]}';
		text.screenCenter(X).y = FlxG.height - scrollThing.height;
		add(text);

		var animArrays = ["sick", "good", "bad", "shit", "miss"];
		var pos = 150;
		for (i in 0...animArrays.length) {
			pos += 75;
			var rating:FlxSprite = new FlxSprite(-1000, pos);
			rating.frames = Paths.getSparrowAtlas("menus/rating/judgements");
			rating.animation.addByPrefix("static", animArrays[i], 1);
			rating.animation.play("static");
			rating.scale.set(0.5, 0.5);
			rating.updateHitbox();
			add(rating);

			var ratingText:FlxText = new FlxText(rating.x + 200, rating.y + rating.height / 2.5, 0, "N/A").setFormat(Paths.font("splatter"), 42);
			ratingText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
			add(ratingText);
			texts[animArrays[i]] = ratingText;

			FlxTween.tween(rating, {x: 10}, 1.2, {
				startDelay: 0.1 * i,
				ease: FlxEase.sineInOut,
				onUpdate: twn -> ratingText.x = rating.x + 200,
				onComplete: function(_) {
					if (animArrays[i] == "miss")
						canLerp = true;
				}
			});
		}

		judgementText = new FlxText(0, 0, "? - 0").setFormat(Paths.font("splatter"), 52);
		judgementText.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
		judgementText.screenCenter();
		add(judgementText);
	}

	var accuracy:Int = 0;
	var oldAccuracy:Int = 0;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (canLerp) {
			for (amount in amounts.keys()) {
				amounts[amount] = Math.round(FlxMath.lerp(amounts[amount], Timings.gottenJudgements[amount], elapsed * 6));
				if (oldAmounts[amount] == amounts[amount] && amounts[amount] != Timings.gottenJudgements[amount])
					amounts[amount] >= Timings.gottenJudgements[amount] ? amounts[amount]-- : amounts[amount]++;
				oldAmounts[amount] = amounts[amount];

				texts[amount].text = Std.string(amounts[amount]);
			}

			var accuracyLetter:String = "?";

			accuracy = Math.round(FlxMath.lerp(accuracy, Timings.trueAccuracy, elapsed * 6));
			if (oldAccuracy == accuracy && accuracy != Timings.trueAccuracy)
				accuracy >= Timings.trueAccuracy ? accuracy-- : accuracy++;

			for (key in Timings.scoreRating.keys()) {
				if (accuracy >= Timings.scoreRating[key])
					accuracyLetter = key;
			}

			judgementText.text = '$accuracyLetter - $accuracy';
		}

		if (controls.justPressed("accept"))
			Main.switchState(new forever.states.menus.FreeplayState());
	}
}
