package forever.states;

import haxe.CallStack;
import forever.ui.ScrollableText;
import flixel.FlxState;
import forever.data.Controls;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * Exception state for the crash handler
 * @author Sword352
 */
class ExceptionState extends FlxState {
	var statesStringArray:Array<String> = ["Main Menu", "Story Menu", "Freeplay Menu", "Options Menu", "PlayState"];
	var curSelected:Int = 0;

	var stateSelector:FlxText;
	var errorText:FlxText;

	public function new(exception:String, errorMsg:String, shouldGithubReport:Bool, ?callStack:CallStack) {
		super();

		var errorScrollable:ScrollableText = new ScrollableText(0, FlxG.height * 0.05, FlxG.width, FlxG.height * 0.75);

		errorText = new FlxText(0, 200, 0, "Forever Engine: Eternal - Exception Report\n").setFormat(Paths.font('vcr'), 28, FlxColor.WHITE, CENTER);
		errorText.text += 'Exception: ${exception}\n${errorMsg}\n';
		if (callStack != null)
			errorText.text += '\nCallStack: ${try CallStack.toString(callStack) catch(e) "Unknown (Failed parsing CallStack)"}\n';
		if (shouldGithubReport)
			errorText.text += '\nConsider reporting this error to the GitHub page!';
		errorText.text += '\n[SPACE] Go To The Github Page\n[ACCEPT] Go To The Selected Destination';
		errorText.screenCenter(X);
		errorScrollable.add(errorText);

		add(errorScrollable);

		stateSelector = new FlxText(0, 0, 0, "< State State State >").setFormat(Paths.font('vcr'), 40, FlxColor.GREEN);
		stateSelector.y = FlxG.height - stateSelector.height - 100;
		add(stateSelector);

		errorText.antialiasing = stateSelector.antialiasing = true;

		changeSelection();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (Controls.current.anyJustPressed(["left", "right"]))
			changeSelection(Controls.current.justPressed("left") ? -1 : 1);

		if (FlxG.keys.justPressed.SPACE)
			Tools.openURL(EternalGithubRepoURL);

		if (Controls.current.justPressed('accept')) {
			var newState:FlxState = switch (statesStringArray[curSelected].toLowerCase()) {
				case "main menu": new forever.states.menus.MainMenuState();
				case "story menu": new forever.states.menus.StoryMenuState();
				case "freeplay menu": new forever.states.menus.FreeplayState();
				case "options menu": new forever.settings.OptionsState(false);
				case "playstate": new forever.states.PlayState();
				default: new forever.states.TitleState(); // idk i was forced to do that @Sword352
			};

			Main.switchState(newState);
		}
	}

	private function changeSelection(change:Int = 0) {
		curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, statesStringArray.length - 1);
		stateSelector.text = '< ${statesStringArray[curSelected]} >';
		stateSelector.screenCenter(X);
	}
}
