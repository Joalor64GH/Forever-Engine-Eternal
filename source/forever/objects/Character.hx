package forever.objects;

import forever.scripting.FNFScript;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import forever.Tools.SpriteAnimation;
import forever.data.utils.FNFSprite;
import forever.music.Conductor;
import sys.FileSystem;
import sys.io.File;

typedef CharacterData = {
	var image:String;
	var healthColor:Dynamic;
	var animations:Array<SpriteAnimation>;
	//
	var size:Null<Float>;
	var scale:Array<Null<Float>>;
	var positionOffset:Array<Null<Float>>;
	var cameraOffset:Array<Null<Float>>;
	//
	var ?flipX:Bool;
	var ?flipY:Bool;
	var ?antialiasing:Bool;
	//
	var ?danceBeat:Int;
	var ?singDuration:Int;
	//
	var ?deathProperties:GameOverData;
	var ?extra:Dynamic;
}

typedef GameOverData = {
	var characterSuffix:String;
	var ?music:String;
	var ?deathSound:String;
	var ?confirmSound:String;
	var ?musicBPM:Float;
}

class Character extends FNFSprite {
	public var stunned:Bool = false;
	public var debugMode:Bool = false;
	public var allowDanceOnDebug:Bool = false;

	public var healthColor:Null<FlxColor> = null;

	public var positionOffset:FlxPoint = new FlxPoint(0, 0);
	public var cameraOffset:FlxPoint = new FlxPoint(0, 0);

	public var danceBeat:Int = 2;
	public var singDuration:Float = 4;

	public var isPlayer:Bool = false;
	public var characterIcon:String = null;
	public var curCharacter:String = 'bf';
	public var curVariant:String = '';
	public var gameOverData:GameOverData = {
		characterSuffix: "-dead",
		music: 'gameOver',
		deathSound: 'fnf_loss_sfx',
		confirmSound: 'gameOverEnd',
		musicBPM: 100
	};

	public var holdTimer:Float = 0;
	public var animEndTime:Float = 0; // TODO: make this better.

	public var adjustPos:Bool = true;

	public var extraData:Dynamic;
	public var script:FNFScript = null;

	public function new(?isPlayer:Bool = false, ?stunned:Bool = false) {
		super(x, y);
		this.isPlayer = isPlayer;
		this.stunned = stunned;
	}

	public function setCharacter(x:Float, y:Float, character:String):Character {
		curCharacter = character;
		characterIcon = curCharacter;
		antialiasing = true;

		if (character.contains('-') && character.lastIndexOf('-') == character.indexOf('-')) {
			var variantName:String = character.substring(character.lastIndexOf('-') + 1, character.length);
			if (variantName != character)
				curVariant = character.substring(character.lastIndexOf('-') + 1, character.length);
		}

		var characterFile:String = Paths.getPath(getCharacterFolder(true), YAML);
		var characterScript:String = Paths.getPath(getCharacterFolder(false), SCRIPT);
		switch (curCharacter) {
			default:
				if (FileSystem.exists(characterFile)) {
					var parsedData:CharacterData = cast yaml.Yaml.parse(File.getContent(characterFile), yaml.Parser.options().useObjects());
					if (parsedData != null)
						parseDataFile(parsedData);

					if (FileSystem.exists(characterScript)) {
						script = new FNFScript(characterScript);
						script.setScriptObject(this);
						script.call('init');
					}
				}
				else
					loadBoyfriend();
		}

		if (healthColor == null)
			healthColor = isPlayer ? FlxColor.LIME : FlxColor.RED;

		dance();

		if (isPlayer) // fuck you ninjamuffin lmao
		{
			flipX = !flipX;
			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
				flipLeftRight();
		}
		else if (curCharacter.startsWith('bf'))
			flipLeftRight();

		if (adjustPos) {
			x += positionOffset.x;
			y += (positionOffset.y - (frameHeight * scale.y));
		}

		this.x = x;
		this.y = y;

		return this;
	}

	function parseDataFile(file:CharacterData):Character {
		if (file == null || file.image == null)
			return loadBoyfriend();

		frames = Paths.getSparrowAtlas(file.image, getCharacterFolder(false), true);
		if (file.antialiasing != null)
			antialiasing = file.antialiasing;

		flipX = file.flipX;
		flipY = file.flipY;

		if (file.size != null)
			setGraphicSize(Std.int(width * file.size));
		if (file.scale != null)
			scale.set(file.scale[0], file.scale[1]);
		if (file.healthColor != null)
			healthColor = parseHealthbarColor(file.healthColor);

		for (i in 0...1) {
			if (file.positionOffset[i] == null || file.positionOffset == null)
				file.positionOffset[i] = 0;
			if (file.cameraOffset[i] == null || file.cameraOffset == null)
				file.cameraOffset[i] = 0;
		}

		positionOffset.set(file.positionOffset[0], file.positionOffset[1]);
		cameraOffset.set(file.cameraOffset[0], file.cameraOffset[1]);

		if (file.animations != null) {
			for (anim in file.animations) {
				if (anim.indices != null)
					animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.fps, anim.loop);
				else
					animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);

				if (anim.offset != null) {
					for (i in 0...1)
						if (anim.offset[i] == null)
							anim.offset[i] = 0;

					addOffset(anim.name, anim.offset[0], anim.offset[1]);
				}
			}
		}

		if (file.deathProperties != null) {
			if (file.deathProperties.characterSuffix != null)
				gameOverData.characterSuffix = file.deathProperties.characterSuffix;

			if (file.deathProperties.confirmSound != null)
				gameOverData.confirmSound = file.deathProperties.confirmSound;

			if (file.deathProperties.deathSound != null)
				gameOverData.deathSound = file.deathProperties.deathSound;

			if (file.deathProperties.music != null) {
				gameOverData.music = file.deathProperties.music;
				gameOverData.musicBPM = file.deathProperties.musicBPM != null ? file.deathProperties.musicBPM : 100;
			}
		}

		if (file.singDuration != null)
			singDuration = file.singDuration;

		if (file.danceBeat != null)
			danceBeat = file.danceBeat;

		if (file.extra != null)
			extraData = file.extra;

		return this;
	}

	function getCharacterFolder(setup:Bool = false):String {
		var baseFolder:String = 'characters/${simplifyCharacter()}';
		var folderAdd:String = '';

		folderAdd = '';
		if (curVariant != null && curVariant.length > 0)
			folderAdd += '/${curVariant}';

		if (stunned && isPlayer) {
			// weird workaround for variants
			if (FileSystem.exists(Paths.getPath('${baseFolder}${folderAdd}/dead'))) {
				folderAdd += '/dead';
				print('success, found death anim for variant ${curVariant}');
			}
			else {
				folderAdd = '/dead';
				print('could not find death anim for variant ${curVariant}', WARNING);
			}
		}

		if (setup) // for yaml
			folderAdd += '/${curCharacter}';

		// print('${baseFolder}${folderAdd} - on setup? ${setup}');
		return '${baseFolder}${folderAdd}';
	}

	function flipLeftRight():Void {

		if (animation.exists('singLEFT') && animation.exists('singRIGHT'))
		{
			// get the old right sprite
		    var oldRight = animation.getByName('singRIGHT').frames;
		    // set the right to the left
		    animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
		    // set the left to the old right
		    animation.getByName('singLEFT').frames = oldRight;
		}

		// insert ninjamuffin screaming I think idk I'm lazy as hell

		if (animation.exists('singRIGHTmiss') && animation.exists('singLEFTmiss')) {
			var oldMiss = animation.getByName('singRIGHTmiss').frames;
			animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
			animation.getByName('singLEFTmiss').frames = oldMiss;
		}
	}

	override function update(elapsed:Float) {
		call('update', [elapsed]);

		if (!debugMode) {
			if (!isPlayer) {
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;

				if (holdTimer >= Conductor.stepCrochet * singDuration * 0.001) {
					dance();
					holdTimer = 0;
				}
			}
			else if (isPlayer) {
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;
				else
					holdTimer = 0;

				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
					playAnim('idle', true, false, 10);

				if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
					playAnim('deathLoop');
			}

			if (animEndTime > 0) {
				// print(animEndTime);
				animEndTime -= 1 * elapsed;
			}
			else if (animEndTime < 0) {
				dance(true);
				animEndTime = 0;
			}

			var curCharSimplified:String = simplifyCharacter();
			switch (curCharSimplified) {
				case 'gf':
					if (animation.curAnim.name == 'hairFall' && animation.curAnim.finished)
						playAnim('danceRight');
					if ((animation.curAnim.name.startsWith('sad')) && (animation.curAnim.finished))
						playAnim('danceLeft');
			}

			// Post idle animation (think Week 4 and how the player and mom's hair continues to sway after their idle animations are done!)
			if (animation.getByName(animation.curAnim.name + '-post') != null && animation.curAnim.finished)
				animation.play(animation.curAnim.name + '-post', true, false, 0);
		}

		call('updatePost', [elapsed]);
		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(?forced:Bool = false) {
		call('dance');
		if (!debugMode || allowDanceOnDebug) {
			var curCharSimplified:String = simplifyCharacter();
			switch (curCharSimplified) {
				case 'gf':
					if ((!animation.curAnim.name.startsWith('hair')) && (!animation.curAnim.name.startsWith('sad'))) {
						danced = !danced;

						if (danced)
							playAnim('danceRight', forced);
						else
							playAnim('danceLeft', forced);
					}
				default:
					// Left/right dancing, think Skid & Pump
					if (animation.getByName('danceLeft') != null && animation.getByName('danceRight') != null) {
						danced = !danced;
						if (danced)
							playAnim('danceRight', forced);
						else
							playAnim('danceLeft', forced);
					}
					else
						playAnim('idle', forced);
			}
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		call('playAnim', [AnimName, Force, Reversed, Frame]);
		if (animation.getByName(AnimName) != null)
			super.playAnim(AnimName, Force, Reversed, Frame);

		if (curCharacter == 'gf') {
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}
	}

	public function simplifyCharacter():String {
		var base = curCharacter;
		if (base.contains('-'))
			base = base.substring(0, base.indexOf('-'));
		return base;
	}

	public function loadBoyfriend():Character {
		curCharacter = 'bf';

		frames = Paths.getSparrowAtlas('BOYFRIEND', 'characters/bf', true);

		animation.addByPrefix('idle', 'BF idle dance', 24, false);
		animation.addByPrefix('singUP', 'BF NOTE UP0', 24, false);
		animation.addByPrefix('singLEFT', 'BF NOTE LEFT0', 24, false);
		animation.addByPrefix('singRIGHT', 'BF NOTE RIGHT0', 24, false);
		animation.addByPrefix('singDOWN', 'BF NOTE DOWN0', 24, false);
		animation.addByPrefix('singUPmiss', 'BF NOTE UP MISS', 24, false);
		animation.addByPrefix('singLEFTmiss', 'BF NOTE LEFT MISS', 24, false);
		animation.addByPrefix('singRIGHTmiss', 'BF NOTE RIGHT MISS', 24, false);
		animation.addByPrefix('singDOWNmiss', 'BF NOTE DOWN MISS', 24, false);
		animation.addByPrefix('hey', 'BF HEY', 24, false);
		animation.addByPrefix('scared', 'BF idle shaking', 24);
		playAnim('idle');

		flipX = true;
		positionOffset.y = 70;

		return this;
	}

	public function call(_func:String, ?args:Array<Dynamic>)
	{
		if (script != null)
			script.call(_func, args);
	}

	public static function parseHealthbarColor(color:Dynamic):FlxColor
	{
		var parsedColor:FlxColor = FlxColor.GRAY;
			
		if (Std.isOfType(color, Array)) {
			var colorArray:Array<Int> = cast color;
			parsedColor = FlxColor.fromRGB(colorArray[0], colorArray[1], colorArray[2]);
		}
		else if (Std.isOfType(color, String))
			parsedColor = FlxColor.fromString(cast(color, String));
	
		return parsedColor;
	}
}
