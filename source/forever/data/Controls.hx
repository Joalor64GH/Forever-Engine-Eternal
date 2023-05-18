package forever.data;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;
import flixel.util.FlxSignal.FlxTypedSignal;
import openfl.events.KeyboardEvent;

typedef KeyFormat = {
	var keys:Array<FlxKey>;
	var ?buttons:Array<FlxGamepadInputID>;
}

typedef KeyCall = (Int, String) -> Void; // for convenience

class Controls {
	public static final defaultKeys:Map<String, KeyFormat> = [
		"left" => {keys: [A, LEFT], buttons: [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, LEFT_TRIGGER]},
		"down" => {keys: [S, DOWN], buttons: [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, LEFT_SHOULDER]},
		"up" => {keys: [W, UP], buttons: [DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_SHOULDER]},
		"right" => {keys: [D, RIGHT], buttons: [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_TRIGGER]},
		"accept" => {keys: [ENTER, SPACE], buttons: #if switch [B, Y] #else [A, X] #end},
		"back" => {keys: [ESCAPE, BACKSPACE], buttons: #if switch [A] #else [B] #end},
		"pause" => {keys: [ENTER, ESCAPE], buttons: [START]},
		"reset" => {keys: [R, NONE], buttons: #if switch [X] #else [Y] #end},
		"cheat" => {keys: [SEVEN, EIGHT]}
	];

	public var actions(default, null):Map<String, KeyFormat> = [];
	public var onKeyPressed(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();
	public var onKeyReleased(default, null):FlxTypedSignal<KeyCall> = new FlxTypedSignal<KeyCall>();

	public var currentAction:String = 'none';
	public var gamepadMode:Bool = false;

	var keysHeld:Array<Int> = [];

	public function justPressed(action:String):Bool {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		for (key in actions.get(action).keys)
			if (key != NONE && FlxG.keys.checkStatus(key, JUST_PRESSED)) {
				currentAction = action;
				return true;
			}

		if (gamepad != null && actions.get(action).buttons != null) {
			for (button in actions.get(action).buttons)
				if (gamepad.checkStatus(button, JUST_PRESSED)) {
					gamepadMode = true;
					currentAction = action;
					return true;
				}
		}

		return false;
	}

	public function anyJustPressed(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			for (key in actions.get(action).keys)
				if (key != NONE && FlxG.keys.checkStatus(key, JUST_PRESSED)) {
					currentAction = action;
					return true;
				}

			if (gamepad != null && actions.get(action).buttons != null) {
				for (button in actions.get(action).buttons)
					if (gamepad.checkStatus(button, JUST_PRESSED)) {
						gamepadMode = true;
						currentAction = action;
						return true;
					}
			}
		}

		return false;
	}

	public function pressed(action:String):Bool {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		for (key in actions.get(action).keys)
			if (key != NONE && FlxG.keys.checkStatus(key, PRESSED)) {
				currentAction = action;
				return true;
			}

		if (gamepad != null && actions.get(action).buttons != null) {
			for (button in actions.get(action).buttons) {
				if (gamepad.checkStatus(button, PRESSED)) {
					gamepadMode = true;
					currentAction = action;
					return true;
				}
			}
		}

		return false;
	}

	public function anyPressed(actionArray:Array<String>):Bool {
		for (action in actionArray) {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			for (key in actions.get(action).keys)
				if (key != NONE && FlxG.keys.checkStatus(key, PRESSED)) {
					currentAction = action;
					return true;
				}

			if (gamepad != null && actions.get(action).buttons != null) {
				for (button in actions.get(action).buttons) {
					if (gamepad.checkStatus(button, PRESSED)) {
						gamepadMode = true;
						currentAction = action;
						return true;
					}
				}
			}
		}

		return false;
	}

	public function justReleased(action:String):Bool {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		for (key in actions.get(action).keys)
			if (key != NONE && FlxG.keys.checkStatus(key, JUST_RELEASED)) {
				currentAction = 'none';
				return true;
			}

		if (gamepad != null && actions.get(action).buttons != null) {
			for (button in actions.get(action).buttons)
				if (gamepad.checkStatus(button, JUST_RELEASED)) {
					gamepadMode = false;
					currentAction = 'none';
					return true;
				}
		}

		return false;
	}

	public function anyJustReleased(actionArray:Array<String>):Bool {
		if (!FlxG.state.active || !FlxG.state.persistentUpdate)
			return false;

		for (action in actionArray) {
			var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

			for (key in actions.get(action).keys)
				if (key != NONE && FlxG.keys.checkStatus(key, JUST_RELEASED)) {
					currentAction = 'none';
					return true;
				}

			if (gamepad != null && actions.get(action).buttons != null) {
				for (button in actions.get(action).buttons)
					if (gamepad.checkStatus(button, JUST_RELEASED)) {
						gamepadMode = false;
						currentAction = 'none';
						return true;
					}
			}
		}

		return false;
	}

	public function getActionFromKey(key:Int):String {
		for (id => action in actions) {
			if (action != null) {
				var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

				for (i in 0...action.keys.length)
					if (action.keys.contains(key))
						return id;

				if (gamepad != null && action.buttons != null) {
					for (i in 0...action.buttons.length)
						if (action.buttons.contains(key))
							return id;
				}
			}
		}

		return null;
	}

	function updateGamepadEvents():Void {
		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null) {
			for (id => action in actions) {
				if (action.buttons != null) {
					for (key in action.buttons) {
						if (gamepad.checkStatus(key, JUST_PRESSED))
							onKeyPressed.dispatch(key, id);
						if (gamepad.checkStatus(key, JUST_RELEASED))
							onKeyReleased.dispatch(key, id);
					}
				}
			}
		}
	}

	function onKeyDown(evt:KeyboardEvent):Void {
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate) && !keysHeld.contains(evt.keyCode)) {
			keysHeld.push(evt.keyCode);
			onKeyPressed.dispatch(evt.keyCode, getActionFromKey(evt.keyCode));
		}
	}

	function onKeyUp(evt:KeyboardEvent):Void {
		if (FlxG.keys.enabled && (FlxG.state.active || FlxG.state.persistentUpdate) && keysHeld.contains(evt.keyCode)) {
			keysHeld.remove(evt.keyCode);
			onKeyReleased.dispatch(evt.keyCode, getActionFromKey(evt.keyCode));
		}
	}

	// <=========== INITIALIZERS ===========> //
	public static var current:Controls;

	public function new():Void {
		actions = defaultKeys.copy();
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
		FlxG.signals.preUpdate.add(updateGamepadEvents);
	}

	public static function destroy():Void {
		current.actions = null;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, current.onKeyDown);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, current.onKeyUp);
		FlxG.signals.preUpdate.remove(current.updateGamepadEvents);
	}

	public static function refreshKeys():Void {
		// workaround
		for (key in Init.gameControls.keys()) {
			if (Controls.current.actions.exists(key.toLowerCase()))
				for (i in 0...Init.gameControls.get(key)[0].length)
					Controls.current.actions.get(key.toLowerCase()).keys[i] = Init.gameControls.get(key)[0][i];
		}
	}
}
