package forever.scripting;

import forever.data.inputs.MouseHandler;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUIState;
import forever.data.utils.FNFTransition;
import forever.shaders.ShaderHandler;
import sys.FileSystem;

class ScriptableState extends FlxUIState {
	public var scriptStack:Array<FNFScript> = [];
	public var shaderHandler:ShaderHandler;

	public static var mouseInputs:Array<MouseHandler> = [];

	/*
	// settings for overridable states with hscript
	public var overridableState:Bool = true;
	public var stateScript:FNFScript;
	*/

	/**
	 * Note:
	 * To allow a state to be scriptable, the hardcoded part of the menu (in case no script is found) should be in overrided functions like `defaultCreate`.
	 * To not allow a state to be scriptable, just set `overridableState` to false.
	 */
	public override function create():Void {
		super.create();

		for (handler in mouseInputs)
			handler.destroy();
		mouseInputs = [];

		if (!FlxTransitionableState.skipNextTransOut)
			openSubState(new FNFTransition(0.5, true));

		shaderHandler = new ShaderHandler();

		/*var unformattedStateName = Type.getClassName(Type.getClass(flixel.FlxG.state)); // to not return `ScriptableState`
		var stateName = unformattedStateName.substring(unformattedStateName.lastIndexOf(('.'), unformattedStateName.length));

		var potentialStateScript = Paths.data('states/${stateName}', SCRIPT);
		if (overridableState && sys.FileSystem.exists(potentialStateScript))
		{
			stateScript = new FNFScript(potentialStateScript);
			stateScript.set("addScript", addScript);
			stateScript.set("loadScriptsOn", loadScriptsOn);
			stateScript.set("hxsCall", hxsCall);
			stateScript.set("hxsSet", hxsSet);
			stateScript.call("create");
		}
		else*/
			// defaultCreate();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		shaderHandler.update(elapsed);
		updateMouseHandlers(elapsed);

		/*if (overridableState && stateScript != null)
			stateScript.call("update", [elapsed]);
		else*/
			// defaultUpdate(elapsed);
	}

	@:keep public inline function addScript(path:String):Void
		scriptStack.push(new FNFScript(path));

	@:keep public inline function loadScriptsOn(path:String):Void {
		if (FileSystem.exists(Paths.getPath(path))) {
			for (i in FileSystem.readDirectory(Paths.getPath((path))))
				for (j in Paths.getExtensionsFor(SCRIPT))
					if (i.endsWith(j))
						addScript(Paths.getPath('${path}/${i}', SCRIPT));
		}
	}

	@:keep public inline function hxsCall(_func:String, ?args:Array<Dynamic>):Void {
		if (args == null)
			args = [];
		for (i in scriptStack)
			i.call(_func, args);
	}

	@:keep public inline function hxsSet(_var:String, value:Dynamic):Void {
		for (i in scriptStack)
			i.set(_var, value);
	}

	@:allow(forever.scripting.ScriptableState.ScriptableSubState)
	@:keep private static inline function updateMouseHandlers(elapsed:Float):Void {
		for (handler in mouseInputs)
			handler.update(elapsed);
	}

	/*// override these functions for the hardcoded default menus! @Sword35
	public function defaultCreate() {}
	public function defaultUpdate(elapsed:Float) {}*/
}

class ScriptableSubState extends FlxSubState {
	public var scriptStack:Array<FNFScript> = [];
	public var shaderHandler:ShaderHandler;

	public function new():Void {
		super(0x00000000);
	}

	override function create() {
		super.create();
		shaderHandler = new ShaderHandler(false);
	}

	override function update(elapsed:Float) {
		super.update(elapsed);
		shaderHandler.update(elapsed);
		@:privateAccess ScriptableState.updateMouseHandlers(elapsed);
	}

	@:keep public inline function addScript(path:String):Void
		scriptStack.push(new FNFScript(path));

	@:keep public inline function hxsCall(_func:String, args:Array<Dynamic>):Void {
		if (args == null)
			args = [];
		for (i in scriptStack)
			i.call(_func, args);
	}

	@:keep public inline function hxsSet(_var:String, value:Dynamic):Void {
		for (i in scriptStack)
			i.set(_var, value);
	}
}
