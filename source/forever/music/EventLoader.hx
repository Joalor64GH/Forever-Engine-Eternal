package forever.music;

import forever.scripting.FNFScript;
import flixel.addons.ui.FlxUIState;
import forever.music.ChartFormat;
import forever.objects.Character;

class EventLoader {
	var game:Dynamic;

	public var playerMap:Map<String, Character> = new Map<String, Character>();
	public var opponentMap:Map<String, Character> = new Map<String, Character>();
	public var crowdMap:Map<String, Character> = new Map<String, Character>();

	public var scriptPack:Map<String, FNFScript> = new Map<String, FNFScript>();

	public function new(state:FlxUIState):Void {
		game = state;
	}

	public function solvePreload(event:GameplayEvent):Void {
		switch (event.event) {
			case ChangeChar(whose, newCharacter):
				var invisChar:Character = new Character(whose == 1);
				invisChar.setCharacter(0, 0, newCharacter);
				invisChar.alpha = Tools.invisibleAlpha;
				var characterMap:Map<String, Character> = getCharacterMap(whose);
				characterMap.set(newCharacter, invisChar);
				print('preloaded "${newCharacter}" for event Change Character');

			case CustomEvent(name, script, args):
				var newScript = new FNFScript(Paths.data('events/$script', SCRIPT));
				newScript.set("game", game);
				if (game.shaderHandler != null)
					newScript.set("shaderHandler", game.shaderHandler);
				scriptPack.set(name, newScript);
				newScript.call("solvePreload", [args]);

			default: // do nothing
		}
	}

	public function solveTrigger(event:GameplayEvent):Void {
		switch (event.event) {
			case ChangeChar(whose, newCharacter):
				var characterMap:Map<String, Character> = getCharacterMap(whose);
				getCharacter(whose).setCharacter(getCharacter(whose).x, getCharacter(whose).y, newCharacter);
				game.uiHUD.reloadHealthBar(true);
				characterMap.remove(newCharacter);

			case PlayHeyAnim(whose):
				if (getCharacter(whose).animation.getByName('hey') != null)
					getCharacter(whose).playAnim('hey');
				else if (getCharacter(whose).animation.getByName('cheer') != null)
					getCharacter(whose).playAnim('cheer');
				getCharacter(whose).animEndTime = 0.6;

			case MoveCamToChar(whose):
				var char = whose == 1 ? game.player : game.opponent;
				var stageOff:Array<Float> = game.stageBuild.stageData.opponentCamera;

				var getCenterX = char.getMidpoint().x + 100;
				var getCenterY = char.getMidpoint().y - 100;

				game.camFollow.setPosition(getCenterX + char.cameraOffset.x + stageOff[0], getCenterY + char.cameraOffset.y + stageOff[1]);

			case CustomEvent(name, script, args):
				if (scriptPack.get(name) != null)
					scriptPack.get(name).call("solveTrigger", [args]);
				else
					print('Cound not find custom event ${name} (${script}).', WARNING);
			default: // do nothing
		}
	}

	private function getCharacter(whose:Int):Character {
		return switch (whose) {
			case 1: game.player;
			case 2: game.crowd;
			default: game.opponent;
		}
	}

	private function getCharacterMap(whose:Int):Map<String, Character> {
		return switch (whose) {
			case 1: playerMap;
			case 2: crowdMap;
			default: opponentMap;
		}
	}
}
