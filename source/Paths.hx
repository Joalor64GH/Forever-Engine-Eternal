package;

import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.display.BitmapData;
import openfl.display3D.textures.Texture;
import openfl.media.Sound;
import openfl.system.System;
import sys.FileSystem;
import sys.io.File;

#if cpp
import cpp.vm.Gc;
#elseif hl
import hl.Gc;
#elseif java
import java.vm.Gc;
#elseif neko
import neko.vm.Gc;
#end

using StringTools;

class Paths {
	// stealing my own code from psych engine
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function excludeAsset(key:String) {
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory() {
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys()) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key)) {
				var obj = currentTrackedAssets.get(key);
				if (obj != null) {
					var isTexture:Bool = currentTrackedTextures.exists(key);
					if (isTexture) {
						var texture = currentTrackedTextures.get(key);
						texture.dispose();
						texture = null;
						currentTrackedTextures.remove(key);
					}
					@:privateAccess
					if (openfl.Assets.cache.hasBitmapData(key)) {
						openfl.Assets.cache.removeBitmapData(key);
						FlxG.bitmap._cache.remove(key);
					}
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		gcRun(true);
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false) {
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys()) {
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key)) {
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys()) {
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null) {
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
	}

	public static function returnGraphic(key:String, ?library:String, ?preventDefAppend:Bool = false) {
		var folder:String = preventDefAppend ? key : 'images/${key}';
		var path:String = getPath(folder, IMAGE, library);
		if (FileSystem.exists(path)) {
			if (!currentTrackedAssets.exists(key)) {
				var bitmap = BitmapData.fromFile(path);
				var newGraphic:FlxGraphic;
				if (Init.trueSettings.get('GPU Rendering')) {
					var texture = FlxG.stage.context3D.createTexture(bitmap.width, bitmap.height, BGRA, true, 0);
					texture.uploadFromBitmapData(bitmap);
					currentTrackedTextures.set(key, texture);
					bitmap.dispose();
					bitmap.disposeImage();
					bitmap = null;
					newGraphic = FlxGraphic.fromBitmapData(BitmapData.fromTexture(texture), false, key, false);
				}
				else
					newGraphic = FlxGraphic.fromBitmapData(bitmap, false, key, false);
				newGraphic.persist = true;
				currentTrackedAssets.set(key, newGraphic);
			}
			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}
		print('graphic is returning null at path "${path}"', WARNING);
		return null;
	}

	public static function returnSound(key:String, ?library:String, ?preventDefAppend:Bool = false) {
		// I hate this so god damn much
		var folder:String = preventDefAppend ? key : 'sounds/${key}';
		var gottenPath:String = getPath(folder, SOUND, library);

		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		if (!currentTrackedSounds.exists(gottenPath))
			currentTrackedSounds.set(gottenPath, Sound.fromFile(gottenPath));
		localTrackedAssets.push(key);
		return currentTrackedSounds.get(gottenPath);
	}

	//
	inline public static function getPath(file:String, ?type:AssetType, ?library:Null<String>)
		return getPreloadPath(file, type, library);

	inline static function getPreloadPath(folder:String, ?type:AssetType, ?library:String) {
		var pathBase:String = 'assets';
		var actualFolder:String = '';
		// will be useful for mods later on @BeastlyGabi
		if (folder != null) {
			if (folder.startsWith("assets/"))
				pathBase = '';
			actualFolder = '/${folder}';
			if (library != null)
				actualFolder = '/${library}/${folder}';
		}
		var returnPath:String = type.cycleExtensions('${pathBase}${actualFolder}');
		return returnPath;
	}

	public static function getExtensionsFor(type:AssetType):Array<String>
		return type.getExtension();

	inline static public function data(file:String, type:AssetType = TXT, ?library:String)
		return getPath('data/${file}', type, library);

	/*inline static public function shader(file:String, ?library:String)
		return getPath('shaders/${file}', SHADER, library); */
	
	inline static public function shaderFragment(file:String, ?library:String)
		return getPath('shaders/${file}', SHADER_FRAGMENT, library);

	inline static public function shaderVertex(file:String, ?library:String)
		return getPath('shaders/${file}', SHADER_VERTEX, library);

	inline static public function file(file:String, type:AssetType = TXT, ?library:String)
		return getPath(file, type, library);

	inline static public function txt(key:String, ?library:String)
		return getPath('${key}', TXT, library);

	inline static public function xml(key:String, ?library:String)
		return getPath('data/${key}', XML, library);

	inline static public function offsetTxt(key:String, ?library:String)
		return getPath('images/characters/${key}', TXT, library);

	inline static public function json(key:String, ?library:String)
		return getPath('songs/${key}', JSON, library);

	inline static public function songJson(song:String, secondSong:String, ?library:String)
		return getPath('songs/${song.toLowerCase()}/${secondSong.toLowerCase()}', JSON, library);

	inline static public function songScript(song:String, secondSong:String, ?library:String)
		return getPath('songs/${song.toLowerCase()}/${secondSong.toLowerCase()}', SCRIPT, library);

	static public function sound(key:String, ?library:String, ?preventDefAppend:Bool = false):Dynamic
		return returnSound(key, library, preventDefAppend);

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
		return sound(key + FlxG.random.int(min, max), library);

	inline static public function music(key:String, ?library:String = 'music'):Dynamic
		return returnSound(key, library, true);

	inline static public function voices(song:String):Any
		return returnSound('${forever.Tools.swapSpaceDash(song.toLowerCase())}/Voices', 'songs', true);

	inline static public function inst(song:String):Any
		return returnSound('${forever.Tools.swapSpaceDash(song.toLowerCase())}/Inst', 'songs', true);

	inline static public function image(key:String, ?library:String, ?preventDefAppend:Bool = false)
	{
		if (dumpExclusions.contains(Paths.getPath('images/${key}', IMAGE)) && currentTrackedAssets.get(key) != null)
			return currentTrackedAssets.get(key);

		return returnGraphic(key, library, preventDefAppend);
	}

	/**
	 * Mind you, DON'T ADD THE EXTENSION BY YOURSELF LIKE "vcr.ttf"
	 *
	 * instead, simply specify the font name, extensions will be added automatically
	 */
	inline static public function font(key:String)
		return getPath('fonts/${key}', FONT);

	inline static public function getSparrowAtlas(key:String, ?library:String, ?preventDefAppend:Bool = false) {
		var folder:String = preventDefAppend ? key : 'images/${key}';
		return FlxAtlasFrames.fromSparrow(image(key, library, preventDefAppend), File.getContent(getPath(folder, XML, library)));
	}

	inline static public function getPackerAtlas(key:String, ?library:String, ?preventDefAppend:Bool = false) {
		var folder:String = preventDefAppend ? key : 'images/${key}';
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, preventDefAppend), getPath(folder, TXT, library));
	}

	public static function gcEnable():Void {
		#if (cpp || hl) Gc.enable(true); #end
	}

	public static function gcDisable():Void {
		#if (cpp || hl) Gc.enable(false); #end
	}

	public static function gcRun(major:Bool = false):Void {
		#if (cpp || java || neko)
		Gc.run(major);
		#elseif hl
		Gc.major();
		#else
		openfl.system.System.gc();
		#end

		#if cpp
		Gc.compact();
		#end
	}
}

// stealing my own code lol @BeastlyGabi
enum abstract AssetType(String) to String from String {
	var FONT:AssetType = 'font';
	var IMAGE:AssetType = 'image';
	var SOUND:AssetType = 'sound';
	// TEXT TYPES
	var XML:AssetType = 'xml';
	var JSON:AssetType = 'json';
	var YAML:AssetType = 'yaml';
	var SCRIPT:AssetType = 'script';
	var TXT:AssetType = 'txt';
	// var SHADER:AssetType = 'shader';
	var SHADER_FRAGMENT:AssetType = 'shader_fragment';
	var SHADER_VERTEX:AssetType = 'shader_vertex';

	public function cycleExtensions(path:String):String {
		if (getExtension() != null) {
			for (i in getExtension())
				if (sys.FileSystem.exists('${path}${i}'))
					return '${path}${i}';
		}

		return '${path}';
	}

	public function getExtension():Array<String> {
		return switch (this) {
			case IMAGE: ['.png', '.jpg', '.bmp'];
			case SOUND: ['.mp3', '.ogg', '.wav'];
			case SCRIPT: ['.hx', '.hxs', '.hxc', '.hsc', '.hscript', '.hxclass'];
			case FONT: ['.ttf', '.otf'];
			case TXT: ['.txt', '.ini'];
			case XML: ['.xml'];
			case JSON: ['.json'];
			case YAML: ['.yaml', '.yml'];
			// case SHADER: ['.frag', '.vert'];
			case SHADER_FRAGMENT: ['.frag'];
			case SHADER_VERTEX: ['.vert'];
			default: null;
		}
	}

	public function toOpenFL():openfl.utils.AssetType {
		return switch (this) {
			case IMAGE: openfl.utils.AssetType.IMAGE;
			case SOUND: openfl.utils.AssetType.SOUND;
			case TXT | XML | JSON | SCRIPT | SHADER_FRAGMENT | SHADER_VERTEX /*| SHADER */: openfl.utils.AssetType.TEXT;
			case FONT: openfl.utils.AssetType.FONT;
			default: openfl.utils.AssetType.BINARY;
		}
	}
}
