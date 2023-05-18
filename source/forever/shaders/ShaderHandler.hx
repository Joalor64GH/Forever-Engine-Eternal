package forever.shaders;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxSprite;
import forever.data.ObjectState;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;

typedef ShaderObject = flixel.util.typeLimit.OneOfTwo<FlxBasic, FlxGame>;

/**
 * A shader handler allows you to manage shaders for a certain object, useful for states and such.
 * @author Sword352
 */
class ShaderHandler extends FlxBasic {
	/**
	 * All of the shaders.
	 */
	public var shaders:Map<String, ForeverShader> = [];

	/**
	 * The camera filters. If you wanna access a filter, you'll be able to get the filter by using `filters['INDEX OF THE ORIGINAL SHADER'].`
	 */
	public var shaderFilters:Map<String, BitmapFilter> = [];

	/**
	 * Internal, a map to recycle shaders.
	 */
	var _recycledShaders:Map<String, ForeverShader> = [];

	/**
	 * Internal, a map to recycle shader filters.
	 */
	var _recycledFilters:Map<String, BitmapFilter> = [];

	/**
	 * Internal, stored shader objects.
	 */
	var _objects:Array<ShaderObject> = [];

	/**
	 * Internal, state of a shader object.
	 */
	var _state:ObjectState = NONE;

	/**
	 * Makes a new shader handler.
	 * @param clearCameras OPTIONAL - If true, clear the shaders of all the cameras of the game and of `FlxG.game` (does not include colorblind filters).
	 */
	public function new(clearCameras:Bool = true) {
		clearShaders(clearCameras);
		super();
		_state = ALIVE;
	}

	override public function update(elapsed:Float) {
		if (_state == DEAD)
			return;

		super.update(elapsed);

		for (shader in shaders)
			shader.call("update", [elapsed]);
	}

	public function updatePost(elapsed:Float) {
		if (_state == DEAD)
			return;

		for (shader in shaders)
			shader.call("updatePost", [elapsed]);
	}

	public function sectionHit(curSect:Int) {
		if (_state == DEAD)
			return;

		for (shader in shaders)
			shader.call("onSect", [curSect]);
	}

	public function stepHit(curStep:Int) {
		if (_state == DEAD)
			return;

		for (shader in shaders)
			shader.call("onStep", [curStep]);
	}

	public function beatHit(curBeat:Int) {
		if (_state == DEAD)
			return;

		for (shader in shaders)
			shader.call("onBeat", [curBeat]);
	}

	/**
	 * Adds a new shader and apply it to the objects of the `objects` array argument.
	 * @param index The index to map with the shader.
	 * @param shaderScript The shader script name.
	 * @param objects The objects to apply the shaders.
	 * @param parameters OPTIONAL - Extra parameters for the shader.
	 * @param recycle OPTIONAL - If true, try to recycle a shader for this new shader.
	 */
	@:access(flixel.addons.display.FlxRuntimeShader)
	public function addShader(index:String, shaderScript:String, objects:Array<ShaderObject>, parameters:Array<Dynamic> = null, recycle:Bool = true) {
		if (_state == DEAD)
			return;

		var shaderExists:Bool = shaders.exists(index);

		var newShader:ForeverShader = recycle ? recycleShader(index, function(shader) {}, shaderScript, parameters) : new ForeverShader(shaderScript, parameters);

		for (obj in objects) {
			if (Std.isOfType(obj, FlxSprite))
				cast(obj, FlxSprite).shader = newShader.shader;
			else if (Std.isOfType(obj, FlxCamera) || Std.isOfType(obj, FlxGame)) {
				var target:Dynamic = cast obj;

				@:privateAccess
				{
					if (target._filters == null)
						target._filters = [];

					var filter:BitmapFilter;
					if (shaderExists) {
						filter = shaderFilters.get(index);
					}
					else if (_recycledFilters.exists(index)) {
						filter = _recycledFilters[index];
						_recycledFilters.remove(index);
						filter = new ShaderFilter(newShader.shader);
						shaderFilters.set(index, filter);
					}
					else {
						filter = new ShaderFilter(newShader.shader);
						shaderFilters.set(index, filter);
					}

					target._filters.push(filter);
				}
			}

			this._objects.push(obj);
		}

		if (!shaderExists)
			shaders.set(index, newShader);
	}

	/**
	 * Remove a shader
	 * @param index The index of the shader.
	 */
	public function removeShader(index:String) {
		if (_state == DEAD)
			return;

		if (shaders[index] != null) {
			for (obj in _objects) {
				if (obj is FlxSprite) {
					var sprite = cast(obj, FlxSprite);
					if (sprite.shader == shaders[index].shader)
						sprite.shader = null;
				}
				else if (obj is FlxCamera || obj is FlxGame) {
					var target:Dynamic = cast obj;

					@:privateAccess
					{
						var potentialShader:BitmapFilter = target._filters[target._filters.indexOf(shaderFilters[index])];
						if (potentialShader != null) {
							target._filters.remove(potentialShader);
							shaderFilters.remove(index);
							potentialShader = null;
							_recycledFilters.set(index, potentialShader);
						}
					}
				}
			}

			var shader = shaders[index];
			shaders.remove(index);
			shader.destroy();
			shader = null;
			_recycledShaders.set(index, shader);
		}
		else
			print('Cannot remove a shader that is null.', WARNING);
	}

	/**
	 * Clear all of the shaders
	 * @param clearAllCameras OPTIONAL - If true, clear the shaders of all the cameras of the game and of `FlxG.game` (does not include colorblind filters).
	 */
	public function clearShaders(clearAllCameras:Bool = true) {
		if (_state == DEAD)
			return;

		if (clearAllCameras) {
			for (cam in FlxG.cameras.list)
				cam.setFilters([]);
		}

		for (obj in _objects) {
			if (obj is FlxSprite)
				cast(obj, FlxSprite).shader = null;
			else if (obj is FlxCamera)
				cast(obj, FlxCamera).setFilters([]);
			else if (obj is FlxGame)
				cast(obj, FlxGame).setFilters([]);
		}

		Init.reloadColorblindFilters();

		for (key in shaders.keys()) {
			var shader = shaders[key];
			shaders.remove(key);
			shader.destroy();
		}

		if (shaders != null)
			shaders.clear();

		for (filter in shaderFilters)
			filter = null;

		_recycledShaders = [];
		_recycledFilters = [];
		_objects = [];
		shaderFilters = [];
		shaders = [];
	}

	/**
	 * Recycles an already existing shader or null shader for multiple uses.
	 * @param index The potential shader.
	 * @param functionToRun A function to run if the shader is null.
	 * @param shaderScript The shader script of the new ForeverShader if no shader has been recycled.
	 * @param parameters The shader parameters of the new ForeverShader if no shader has been recycled.
	 * @return If index exists, the shader, else if recycledn the recycled shader, otherwise a new `ForeverShader`.
	 */
	public function recycleShader(index:String, functionToRun:ForeverShader->Void, shaderScript:String, ?parameters:Array<Dynamic>):ForeverShader {
		if (_state == DEAD)
			return null;

		var shader = shaders.get(index);

		if (shader != null && shaders.exists(index)) {
			return shader;
		}
		else if (_recycledShaders.exists(index)) {
			var recycledShader = _recycledShaders[index];
			_recycledShaders.remove(index);
			recycledShader = new ForeverShader(shaderScript, parameters);
			functionToRun(recycledShader);
			return recycledShader;
		}

		return new ForeverShader(shaderScript, parameters);
	}

	/**
	 * Destroys this shader handler.
	 */
	override public function destroy() {
		if (_state == DEAD)
			return;

		clearShaders(false);
		_state = DEAD;
		active = false;
		shaders = null;
		shaderFilters = null;
		_objects = null;
		_recycledShaders = null;
		_recycledFilters = null;

		super.destroy();
	}
}
