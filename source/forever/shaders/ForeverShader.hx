package forever.shaders;

import flixel.addons.display.FlxRuntimeShader;
import forever.scripting.FNFScript;
import sys.FileSystem;
import sys.io.File;

/**
 * Just a shader with a script.
 * @author Sword352
 */
class ForeverShader {
	public var shader:FlxRuntimeShader;
	public var script:FNFScript;

	public function new(shaderScript:String, ?parameters:Array<Dynamic>) {
		if (parameters == null)
			parameters = [];

		script = new FNFScript(Paths.data('shaders/${shaderScript}', SCRIPT));
		script.set("Conductor", forever.music.Conductor);
		script.set("PlayState", forever.states.PlayState);
		script.set("game", forever.states.PlayState.current);
		script.set("loadShader", function(path:String, glslVersion:Int = 120) {
			var frag:String = null;
			var vert:String = null;

			if (FileSystem.exists(Paths.shaderFragment(path)))
				frag = File.getContent(Paths.shaderFragment(path));

			if (FileSystem.exists(Paths.shaderVertex(path)))
				vert = File.getContent(Paths.shaderVertex(path));

			shader = new FlxRuntimeShader(frag, vert, glslVersion);
			script.set("shaderData", shader.data);
		});
		script.call("initShader", [parameters]);
	}

	public function call(func:String, ?args:Array<Dynamic>, ?warn:Bool = false) {
		if (script != null && script.exists(func))
			script.call(func, args);
		else if (warn)
			print('Could not find function ${func}.', WARNING);
	}

	public function destroy() {
		script.destroy();
		shader = null;
	}
}
