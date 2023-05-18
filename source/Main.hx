package;

import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import forever.data.*;
import forever.data.utils.FNFTransition;
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
import haxe.io.Path;
import openfl.Lib;
import openfl.display.Sprite;
import sys.FileSystem;
import sys.io.File;
// test to see if pr's works or not
class Main extends Sprite {
	// class action variables
	public static var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	public static var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).

	public static var mainClassState:Class<FlxState> = Init; // Determine the main class state of the game
	public static var framerate:Int = 120; // How many frames per second the game should run at.

	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	#if (flixel < "5.0.0")
	var zoom:Float = -1; // [FLIXEL VERSIONS BELOW 5.0.0 ONLY] If -1, zoom is automatically calculated to fit the window dimensions.
	#end

	/**
	 * Version Scheme goes as: MAJOR.MINOR,
	 * patch versions simply add more numbers to the minor version,
	 * eg. 1.01
	 */
	public static var gameVersionDebug:SematicVersion = new SematicVersion(1, 0, 0, true);
	public static var gameVersion:SematicVersion = new SematicVersion(1, 0, 0);
	public static var funkinVersion:SematicVersion = new SematicVersion(0, 2, 8);

	public static var game:FNFGame; // the main game
	public static var infoCounter:FPSOverlay; // initialize the heads up display that shows information before creating it.

	public static var gameWeeks:Array<Dynamic> = [];

	// most of these variables are just from the base game!
	// be sure to mess around with these if you'd like.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
		
		@:privateAccess
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, function(e) game.exceptionCaughtOpenFL(e));
	}

	// calls a function to set the game up
	public function new() {
		super();

		#if (html5 || neko)
		framerate = 60;
		#end

		#if (flixel < "5.0.0")
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (zoom == -1) {
			var ratioX:Float = stageWidth / gameWidth;
			var ratioY:Float = stageHeight / gameHeight;
			zoom = Math.min(ratioX, ratioY);
			gameWidth = Math.ceil(stageWidth / zoom);
			gameHeight = Math.ceil(stageHeight / zoom);
		}
		#end

		FlxTransitionableState.skipNextTransIn = true;

		game = new FNFGame(gameWidth, gameHeight, mainClassState, #if (flixel < "5.0.0") zoom, #end framerate, framerate, skipSplash); // here we create the base game
		addChild(game); // initializing the game 

		// begin the discord rich presence
		Discord.initializeRPC();
		Discord.changePresence('');

		infoCounter = new FPSOverlay(8, 6);
		addChild(infoCounter);
		addChild(new forever.backend.ForeverConsole());
	}

	/*  This is used to switch "rooms," to put it basically. Imagine you are in the main menu, and press the freeplay button.
		That would change the game's main class to freeplay, as it is the active class at the moment.
	 */
	public static function switchState(target:FlxState) {
		// Custom made Trans in
		if (!FlxTransitionableState.skipNextTransIn) {
			FlxG.state.openSubState(new FNFTransition(0.35, false));
			FNFTransition.finishCallback = function() FlxG.switchState(target);
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		// load the state
		FlxG.switchState(target);
	}

	public static function updateFramerate(newFramerate:Int) {
		// flixel will literally throw errors at me if I dont separate the orders
		if (newFramerate > FlxG.updateFramerate) {
			FlxG.updateFramerate = newFramerate;
			FlxG.drawFramerate = newFramerate;
		}
		else {
			FlxG.drawFramerate = newFramerate;
			FlxG.updateFramerate = newFramerate;
		}
	}
}

class FNFGame extends FlxGame {
	/**
	 * Used to instantiate the guts of the flixel game object once we have a valid reference to the root.
	 */
	override function create(_):Void {
		try super.create(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e);
	}

	/**
	 * Called when the user on the game window
	 */
	override function onFocus(_):Void {
		try super.onFocus(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e);
	}

	/**
	 * Called when the user clicks off the game window
	 */
	override function onFocusLost(_):Void {
		try super.onFocusLost(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e);
	}

	/**
	 * Handles the `onEnterFrame` call and figures out how many updates and draw calls to do.
	 */
	override function onEnterFrame(_):Void {
		try super.onEnterFrame(_)
		catch (e:haxe.Exception)
			return exceptionCaught(e);
	}

	/**
	 * This function is called by `step()` and updates the actual game state.
	 * May be called multiple times per "frame" or draw call.
	 */
	override function update():Void {
		try super.update()
		catch (e:haxe.Exception)
			return exceptionCaught(e);
	}

	/**
	 * Goes through the game state and draws all the game objects and special effects.
	 */
	override function draw():Void {
		try super.draw()
		catch (e:haxe.Exception)
			return exceptionCaught(e);
	}

	private function exceptionCaught(e:haxe.Exception) {
		var callStack:CallStack = CallStack.exceptionStack(true);

		final formattedMessage:String = getCallStack().join("\n");
		var errorMessage = formattedMessage + '\nUncaught Error: ${e.message}\nPlease report this error to the GitHub page: ${EternalGithubRepoURL}';

		writeLog(getLogPath(), errorMessage);

		forever.music.Conductor.songPosition = 0;
		forever.Tools.killMusic([FlxG.sound.music]);

		// doing visuals later, just force switch this thing for now
		Lib.application.window.alert(errorMessage + '\n\nPress OK to go back to the game.', "Forever Engine: Eternal - Exception Report");
		goToExceptionState(e.message, formattedMessage, true, callStack);
	}

	private function exceptionCaughtOpenFL(e:UncaughtErrorEvent) {
		var callStack:CallStack = CallStack.exceptionStack(true);

		final formattedMessage:String = getCallStack().join("\n");
		var errorMessage = formattedMessage + '\nUncaught Error: ${e.error}\nPlease report this error to the GitHub page: ${EternalGithubRepoURL}';

		writeLog(getLogPath(), errorMessage);

		forever.music.Conductor.songPosition = 0;
		forever.Tools.killMusic([FlxG.sound.music]);

		// doing visuals later, just force switch this thing for now
		Lib.application.window.alert(errorMessage + '\n\nPress OK to go back to the game.', "Forever Engine: Eternal - Exception Report");
		goToExceptionState(e.error, formattedMessage, true, callStack);
	}

	private function getCallStack():Array<String> {
		var caughtErrors:Array<String> = [];

		for (stackItem in CallStack.exceptionStack(true)) {
			switch (stackItem) {
				case CFunction:
					caughtErrors.push('Non-Haxe (C) Function');
				case Module(moduleName):
					caughtErrors.push('Module (${moduleName})');
				case FilePos(s, file, line, column):
					caughtErrors.push('${file} (line ${line})');
				case Method(className, method):
					caughtErrors.push('${className} (method ${method})');
				case LocalFunction(name):
					caughtErrors.push('Local Function (${name})');
			}

			print(stackItem, ERROR);
		}

		return caughtErrors;
	}

	private function goToExceptionState(exception:String, errorMsg:String, shouldGithubReport:Bool, ?callStack:CallStack) {
		var arguments:Array<Dynamic> = [exception, errorMsg, shouldGithubReport];
		if (callStack != null)
			arguments.push(callStack);

		_requestedState = Type.createInstance(forever.states.ExceptionState, arguments);
		switchState();
	}

	private function writeLog(path:String, errMsg:String) {
		if (!FileSystem.exists("crash/"))
			FileSystem.createDirectory("crash/");
		File.saveContent(path, '${errMsg}\n');

		print(errMsg, ERROR);
		print('Crash dump saved in ${Path.normalize(path)}', ERROR);
	}

	private function getLogPath():String {
		return "crash/" + "FE_" + formatDate() + ".txt";
	}

	private function formatDate():String {
		var dateNow:String = Date.now().toString();
		dateNow = StringTools.replace(dateNow, " ", "_");
		dateNow = StringTools.replace(dateNow, ":", "'");
		return dateNow;
	}
}
