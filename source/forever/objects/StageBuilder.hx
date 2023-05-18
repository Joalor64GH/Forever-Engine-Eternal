package forever.objects;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import forever.Tools.SpriteAnimation;
import forever.data.utils.FNFSprite;
import forever.scripting.FNFScript;
import forever.states.PlayState;
import sys.FileSystem;
import sys.io.File;

typedef StageData = {
	var playerPosition:Array<Float>; // bf
	var opponentPosition:Array<Float>; // dad
	var crowdPosition:Array<Float>; // gf

	var ?playerCamera:Array<Float>;
	var ?opponentCamera:Array<Float>;
	var ?crowdCamera:Array<Float>;
	var ?destroyGF:Bool;
	var ?stageCameraZoom:Null<Float>;
	var ?ratingPosition:Array<Float>;
	var stageObjects:Array<StageObject>;
}

typedef StageObject = {
	var name:String; // identifier
	var ?image:String; // actual image that the object uses
	var ?solidGraphic:Array<Int>;
	var ?library:String; // the image's library (e.g: stages/week3)
	var position:Array<Float>; // object position
	var ?animations:Array<SpriteAnimation>;
	var ?defaultAnim:String;

	var ?flipX:Bool;
	var ?flipY:Bool;
	var ?antialiasing:Bool;
	var ?updateHitbox:Bool;
	var ?layer:String; // fg, bg, gf
	var ?type:String; // img, defaultGraphic, sparrow, packer
	var ?parallax:Array<Float>; // object scroll factor
	var ?alpha:Null<Float>; // object alpha
	var ?scale:Array<Float>; // object scale
	var ?size:Null<Float>; // object size
	var ?active:Null<Bool>; // object active bool
}

class StageBuilder extends FlxTypedGroup<FlxBasic> {
	public final game:PlayState = PlayState.current;

	// to add above girlfriend, use gfLayer.add(); instead of add();
	public var gfLayer:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();
	// to apply to foreground use foreground.add(); instead of add();
	public var foreground:FlxTypedGroup<FlxBasic> = new FlxTypedGroup<FlxBasic>();

	public var gfVer:String = 'gf';

	public var stageData:StageData;
	public var stageScript:FNFScript;
	public var stageObjects:Map<String, FNFSprite> = [];

	/**
	 * Helper Function for setting the name of the stage if the song doesn't have it set already
	 * also serves as a fix for base game (0.2.8) charts, which don't have the stage variable for songs
	 */
	public static function setFromSong(song:String = 'bopeebo'):String {
		return switch (Tools.spaceToDash(song)) {
			case 'tutorial' | 'test' | 'bopeebo' | 'fresh' | 'dadbattle' | 'dad-battle': 'stage';
			case 'spookeez' | 'south' | 'monster': 'spooky-house';
			case 'pico' | 'blammed' | 'philly-nice': 'philly';
			case 'milf' | 'satin-panties' | 'high': 'highway';
			case 'cocoa' | 'eggnog': 'mall';
			case 'winter-horrorland': 'red-mall';
			case 'senpai' | 'roses': 'school';
			case 'thorns': 'school-glitch';
			case 'ugh' | 'guns' | 'stress': 'military';
			default: 'unknown';
		}
	}

	public function new(?stageName:String, cameraZoom:Float = 1.05, gfVer:String = 'gf') {
		super();

		if (stageName != null)
			PlayState.current.curStage = stageName;
		this.gfVer = gfVer;

		// build stage
		stageData = {
			playerPosition: [750, 850],
			opponentPosition: [50, 850],
			crowdPosition: [300, 730],

			playerCamera: [0, 0],
			opponentCamera: [0, 0],
			crowdCamera: [0, 0],

			destroyGF: false,
			stageCameraZoom: cameraZoom,
			ratingPosition: [0, 0],
			stageObjects: [],
		};

		var pathBase:String = 'stages/${stageName}';
		if (FileSystem.exists(Paths.getPath('${pathBase}/${stageName}', SCRIPT))) {
			stageScript = new FNFScript(Paths.getPath('${pathBase}/${stageName}', SCRIPT));
			stageScript.set('stage', this);
			stageScript.set('game', game);
			stageScript.set('shaderHandler', game.shaderHandler);
			stageScript.set('addBehind', function(object:FlxObject, toAdd:FlxObject) {
				insert(this.members.indexOf(object), toAdd);
			});
			stageScript.set('addFront', function(object:FlxObject, toAdd:FlxObject) {
				insert(this.members.indexOf(object) + 1, toAdd);
			});
			stageScript.call('create', []);
		}

		if (FileSystem.exists(Paths.getPath('${pathBase}/${stageName}', YAML))) {
			var parsedFile:String = File.getContent(Paths.getPath('${pathBase}/${stageName}', YAML));
			var parsedData:StageData = cast yaml.Yaml.parse(parsedFile, yaml.Parser.options().useObjects());
			if (parsedData != null) {
				// do i need those null checks at all? @BeastlyGabi
				if (parsedData.playerPosition != null)
					stageData.playerPosition = parsedData.playerPosition;
				if (parsedData.opponentPosition != null)
					stageData.opponentPosition = parsedData.opponentPosition;
				if (parsedData.crowdPosition != null)
					stageData.crowdPosition = parsedData.crowdPosition;

				if (parsedData.playerCamera != null)
					stageData.playerCamera = parsedData.playerCamera;
				if (parsedData.opponentCamera != null)
					stageData.opponentCamera = parsedData.opponentCamera;
				if (parsedData.crowdCamera != null)
					stageData.crowdCamera = parsedData.crowdCamera;

				if (parsedData.destroyGF != null)
					stageData.destroyGF = parsedData.destroyGF;
				if (parsedData.stageCameraZoom != null)
					stageData.stageCameraZoom = parsedData.stageCameraZoom;
				if (parsedData.ratingPosition != null)
					stageData.ratingPosition = [parsedData.ratingPosition[0], parsedData.ratingPosition[1]];

				if (parsedData.stageObjects != null) {
					for (object in parsedData.stageObjects) {
						var newObject:FNFSprite = new FNFSprite();
						var objectFolder:String = 'stages/${stageName}';
						if (object.library != null)
							objectFolder = object.library;
						switch (object.type) {
							case "sparrow":
								newObject.frames = Paths.getSparrowAtlas('${object.image}', objectFolder);
							case "packer":
								newObject.frames = Paths.getPackerAtlas('${object.image}', objectFolder);
							case "defaultGraphic":
								newObject.makeSolid(object.solidGraphic[0], object.solidGraphic[1], object.solidGraphic[2]);
							default:
								newObject.loadGraphic(Paths.image('${object.image}', objectFolder));
						}

						if (object.animations != null) {
							for (anim in object.animations) {
								if (object.type == "sparrow" || object.type == "packer") {
									if (anim.indices != null)
										newObject.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.fps, anim.loop);
									else
										newObject.animation.addByPrefix(anim.name, anim.prefix, anim.fps, anim.loop);
								}
								else if (anim.frames != null)
									newObject.animation.add(anim.name, anim.frames, anim.fps, anim.loop);

								if (anim.offset != null) {
									for (i in 0...1)
										if (anim.offset[i] == null)
											anim.offset[i] = 0;

									newObject.addOffset(anim.name, anim.offset[0], anim.offset[1]);
								}

								if (object.defaultAnim != null)
									newObject.animation.play(object.defaultAnim);
							}
						}

						if (object.position != null)
							newObject.setPosition(object.position[0], object.position[1]);
						if (object.parallax != null)
							newObject.scrollFactor.set(object.parallax[0], object.parallax[1]);

						if (object.scale != null)
							newObject.scale.set(object.scale[0], object.scale[1]);
						if (object.size != null)
							newObject.setGraphicSize(Std.int(newObject.width * object.size));
						if (object.updateHitbox)
							newObject.updateHitbox();
						newObject.flipX = object.flipX;
						newObject.flipY = object.flipY;
						if (object.alpha != null)
							newObject.alpha = object.alpha;
						newObject.antialiasing = object.antialiasing;

						if (object.active != null)
							newObject.active = object.active;

						var objectName:String = object.image;
						if (object.name != null)
							objectName = object.name;

						stageObjects.set(objectName, newObject);
						if (stageScript != null)
							stageScript.set(objectName, newObject);

						var objectLayer:String = '';
						if (object.layer != null)
							objectLayer = object.layer;

						switch (object.layer) {
							case 'gf', 'girlfriend', 'above-gf', 'gf-front', 'front-gf':
								gfLayer.add(newObject);
							case 'fg', 'foreground', 'front', 'characters-front', 'players-front':
								foreground.add(newObject);
							default:
								add(newObject);
						}
					}
				}
			}
		}
	}

	// overrideable function for child classes
	public function createPost():Void {
		if (stageScript != null)
			stageScript.call('createPost', []);
	}

	public override function update(elapsed:Float):Void {
		super.update(elapsed);

		if (stageScript != null)
			stageScript.call('update', [elapsed]);
	}

	public function updatePost(elapsed:Float) {
		if (stageScript != null)
			stageScript.call('updatePost', [elapsed]);
	}

	public function onBeat(curBeat:Int) {
		if (stageScript != null)
			stageScript.call('onBeat', [curBeat]);
	}

	public function onStep(curStep:Int) {
		if (stageScript != null)
			stageScript.call('onStep', [curStep]);
	}

	public function onSect(curSect:Int) {
		if (stageScript != null)
			stageScript.call('onSect', [curSect]);
	}

	/* // later tho
		public function cutsceneStart()
		{
			if (stageScript != null)
				stageScript.call('cutsceneStart', []);
		}

		public function cutsceneEnd()
		{
			if (stageScript != null)
				stageScript.call('cutsceneEnd', []);
		}
	 */
	public function countdownStart() {
		if (stageScript != null)
			stageScript.call('countdownStart', []);
	}

	public function countdownTick(tick:Int) {
		if (stageScript != null)
			stageScript.call('countdownTick', [tick]);
	}

	public function songStart() {
		if (stageScript != null)
			stageScript.call('songStart', []);
	}

	public function songEnd() {
		if (stageScript != null)
			stageScript.call('songEnd', []);
	}

	override function add(Object:FlxBasic):FlxBasic {
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
