package forever.states.subStates;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import forever.music.Conductor;
import forever.music.MusicBeat.MusicBeatSubState;
import forever.objects.Character;
import forever.states.*;
import forever.states.menus.*;

class GameOverSubstate extends MusicBeatSubState {
	static var character:Character;

	var camFollow:FlxObject;

	public function new(x:Float, y:Float) {
		/*var daBoyfriendType = PlayState.current.player.curCharacter;
			var daBf:String = switch (daBoyfriendType)
			{
				case 'bf-og': daBoyfriendType;
				case 'bf-pixel': 'bf-pixel-dead';
				default: 'bf-dead';
		}*/

		super();

		Conductor.songPosition = 0;

		// bf.curVariant = PlayState.current.player.curVariant;
		character.setPosition(x, y + PlayState.current.player.height);
		add(character);

		PlayState.current.player.free();

		camFollow = new FlxObject(character.getGraphicMidpoint().x + 20, character.getGraphicMidpoint().y - 40, 1, 1);
		add(camFollow);

		Conductor.changeBPM(character.gameOverData.musicBPM);
		FlxG.camera.target = null;
		character.playAnim('firstDeath');

		FlxG.sound.play(Paths.sound(character.gameOverData.deathSound));
	}

	var musicIsPlaying:Bool = false;

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (musicIsPlaying)
			Conductor.songPosition = FlxG.sound.music.time;

		if (controls.justPressed("accept"))
			endBullshit();

		if (controls.justPressed("back")) {
			musicIsPlaying = false;
			FlxG.sound.music.stop();
			PlayState.deaths = 0;

			if (PlayState.isStoryMode)
				Main.switchState(new StoryMenuState());
			else
				Main.switchState(new FreeplayState());

			character.free();
		}

		if (character.animation != null && character.animation.curAnim.name == 'firstDeath') {
			if (character.animation.curAnim.curFrame == 12)
				FlxG.camera.follow(camFollow, LOCKON, 0.01);

			if (character.animation.curAnim.finished) {
				FlxG.sound.playMusic(Paths.music(character.gameOverData.music));
				musicIsPlaying = true;
			}
		}
	}

	override function beatHit() {
		super.beatHit();

		if (musicIsPlaying)
			character.playAnim('deathLoop', true);

		// FlxG.log.add('beat $curBeat');
	}

	var isEnding:Bool = false;

	function endBullshit():Void {
		if (!isEnding) {
			musicIsPlaying = false;
			isEnding = true;
			character.playAnim('deathConfirm', true);
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(character.gameOverData.confirmSound));
			new FlxTimer().start(0.7, function(tmr:FlxTimer) {
				FlxG.camera.fade(FlxColor.BLACK, 1, false, function() {
					Main.switchState(new PlayState());
					character.free();
				});
			});
		}
	}

	public static function preloadCharacter() {
		character = new Character(true, true);
		character.setCharacter(0, 0, PlayState.current.player.curCharacter + character.gameOverData.characterSuffix);
	}
}
