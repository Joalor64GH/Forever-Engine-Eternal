package forever.states;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import forever.backend.LevelData;
import forever.data.*;
import forever.music.*;
import forever.music.ChartFormat.GameplayEvent;
import forever.music.ChartLoader.SongMetadata;
import forever.music.EventLoader;
import forever.music.MusicBeat.MusicBeatState;
import forever.objects.*;
import forever.objects.notes.*;
import forever.objects.notes.Strumline.Receptor;
import forever.states.editors.ChartEditor;
import forever.states.menus.*;
import forever.states.subStates.*;
import forever.ui.*;
import sys.FileSystem;

class PlayState extends MusicBeatState {
	public static var current:PlayState;

	public var SONG:ChartFormat;

	public var songMeta(get, never):SongMetadata;

	function get_songMeta():SongMetadata
		return ChartLoader.songMeta;

	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 2;
	public static var campaignScore:Int = 0;

	public var songMusic:FlxSound;
	public var vocals:FlxSound;

	public var opponent:Character;
	public var crowd:Character;
	public var player:Character;

	public var crowdType:String = 'gf';

	public var eventManager:EventLoader;

	private var unspawnNotes:Array<Note> = [];
	private var myEventList:Array<GameplayEvent> = [];
	private var allSicks:Bool = true;

	// if you ever wanna add more keys
	private var numberOfKeys:Int = 4;

	public var camFollow:FlxObject;
	public var camFollowPos:FlxObject;

	// Discord RPC variables
	public var songDetails:String = "";
	public var detailsSub:String = "";
	public var detailsPausedText:String = "";
	public var iconRPC:String = "";
	public var songLength:Float = 0;

	public var curSong:String = "";

	private var gfSpeed:Int = 1;
	public var songScore:Int = 0;
	public var health:Float = 1; // mario
	public var combo:Int = 0;
	public var misses:Int = 0;
	public static var deaths:Int = 0;

	public var generatedMusic:Bool = false;
	public var displayCountdown:Bool = true;

	var paused:Bool = false;
	var startingSong:Bool = true;
	var startedCountdown:Bool = false;
	var endedCountdown:Bool = false;
	var inCutscene:Bool = false;

	var canPause:Bool = true;
	var validScore:Bool = true;

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var dialogueHUD:FlxCamera;
	public var pauseCamera:FlxCamera;

	public var cameraSpeed:Float = 1.0;

	public var curStage:String = '';

	// for the secret pause substate
	public var lastSongPosition:Float = 0;
	public var lastBPM:Float = 0;

	// Objects
	public var stageBuild:StageBuilder;
	public var uiHUD:GameplayUI;

	public static final daPixelZoom:Float = 6;

	// strumlines
	public var opponentStrums:Strumline;
	public var playerStrums:Strumline;

	public var modchartHelper:ModchartHelper;

	public var strumLines:FlxTypedGroup<Strumline>;
	public var strumHUD:Array<FlxCamera> = [];
	public var notesHUD:Array<FlxCamera> = [];
	public var sustainsHUD:Array<FlxCamera> = [];

	private var allUIs:Array<FlxCamera> = [];

	// stores the last judgement object
	public var lastRating:FlxSprite;
	// stores the last combo objects in an array
	public var lastCombo:Array<FlxSprite> = [];

	private var holdControls:Array<Bool> = [];

	private var timeBeforeSwitching:Float;

	public function new(songName:String = 'test', difficulty:String = 'normal', ?customChart:ChartFormat):Void {
		timeBeforeSwitching = openfl.Lib.getTimer();

		// may be slower but this is temporary
		SONG = customChart != null ? customChart : ChartLoader.loadChart(songName, difficulty);
		super();
	}

	override public function create() {
		super.create();

		current = this;

		SkinManager.assetStyle = "base";

		Timings.callAccuracy();

		// stop any existing music tracks playing
		resetMusic();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// create the game camera
		camGame = new FlxCamera();

		// create the hud camera (separate so the hud stays on screen)
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		allUIs.push(camHUD);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		eventManager = new EventLoader(this);

		// call the song's stage if it exists
		if (songMeta.stage != null)
			curStage = songMeta.stage;
		else
			StageBuilder.setFromSong(songMeta.rawName.toLowerCase());

		if (songMeta.characters[2] != null)
			crowdType = songMeta.characters[2];

		if (songMeta.skin != null && songMeta.skin.length > 1)
			SkinManager.assetStyle = songMeta.skin;
		else if ((curStage.startsWith("school")))
			SkinManager.assetStyle = 'pixel';

		loadScriptsOn('songs/${songMeta.rawName}/scripts'); // song scripts
		loadScriptsOn('data/scripts/game'); // global scripts

		hxsSet('game', this);
		hxsSet('curBeat', curBeat);
		hxsSet('curStep', curStep);
		hxsSet('curSect', curSect);
		hxsSet('shaderHandler', shaderHandler); // just in case
		hxsSet('settings', Init.trueSettings);

		hxsCall('create', []);

		stageBuild = new StageBuilder('stage');
		add(stageBuild);

		// set up characters here too
		var crowdPos:Array<Float> = stageBuild.stageData.crowdPosition;
		if (!stageBuild.stageData.destroyGF) {
			crowd = new Character().setCharacter(crowdPos[0], crowdPos[1], crowdType);
			crowd.scrollFactor.set(0.95, 0.95);
			crowd.adjustPos = false;
		}

		var playerPos:Array<Float> = stageBuild.stageData.playerPosition;
		var opponentPos:Array<Float> = stageBuild.stageData.opponentPosition;
		opponent = new Character(false).setCharacter(opponentPos[0], opponentPos[1], songMeta.characters[1]);
		player = new Character(true).setCharacter(playerPos[0], playerPos[1], songMeta.characters[0]);

		var camPos:FlxPoint = new FlxPoint(opponent.getMidpoint().x - 100, player.getMidpoint().y - 100);

		if (opponent.curCharacter == crowdType) {
			opponent.setPosition(crowdPos[0], crowdPos[1]);
			if (crowd != null)
				crowd.free();
		}
		else if (crowd != null)
			add(crowd);

		add(stageBuild.gfLayer);

		add(opponent);
		add(player);

		add(stageBuild.foreground);

		stageBuild.createPost();

		// cache shit
		GameOverSubstate.preloadCharacter();
		displayRating('sick', false, true);
		popUpCombo(true);
		//

		// set song position before beginning
		Conductor.songPosition = -(Conductor.crochet * 4);

		// EVERYTHING SHOULD GO UNDER THIS, IF YOU PLAN ON SPAWNING SOMETHING LATER ADD IT TO STAGEBUILD OR FOREGROUND
		// darken everything but the arrows and ui via a flxsprite
		var darknessBG:FlxSprite = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		darknessBG.alpha = (100 - Init.trueSettings.get('Stage Opacity')) / 100;
		darknessBG.scrollFactor.set(0, 0);
		add(darknessBG);

		// strum setup
		strumLines = new FlxTypedGroup<Strumline>();

		// generate the song
		generateSong(songMeta.rawName);

		// set the camera position to the center of the stage
		camPos.set(player.x + (player.frameWidth / 4), player.y + (player.frameHeight / 4));

		// create the game camera
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);
		add(camFollow);
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 3.5);
		FlxG.camera.zoom = stageBuild.stageData.stageCameraZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		//
		var placement:Float = (FlxG.width / 2);
		var placementY:Float = (Init.trueSettings.get('Downscroll') ? FlxG.height - 185 : 35);
		opponentStrums = new Strumline(placement - (FlxG.width / 3.5), placementY, opponent, false, true, 4);
		opponentStrums.visible = !Init.trueSettings.get('Centered Notefield');
		playerStrums = new Strumline(placement + (!Init.trueSettings.get('Centered Notefield') ? (FlxG.width / 4) : 0), placementY, player, true, false, 4);

		strumLines.add(opponentStrums);
		strumLines.add(playerStrums);

		// strumline camera setup
		for (i in 0...strumLines.length) {
			strumHUD[i] = new FlxCamera();
			strumHUD[i].bgColor.alpha = 0;
			allUIs.push(strumHUD[i]);
			FlxG.cameras.add(strumHUD[i], false);
			strumLines.members[i].receptors.cameras = [strumHUD[i]];

			sustainsHUD[i] = new FlxCamera(); // generate a new camera
			sustainsHUD[i].bgColor.alpha = 0; // hiding the bg color
			allUIs.push(sustainsHUD[i]); // pushing it to the allUIs array
			FlxG.cameras.add(sustainsHUD[i], false); // adding the camera
			strumLines.members[i].holdsGroup.cameras = [sustainsHUD[i]]; // set this strumline's sustains group camera to the designated camera

			// and thats basically the same thing for the other cameras
			notesHUD[i] = new FlxCamera();
			notesHUD[i].bgColor.alpha = 0;
			allUIs.push(notesHUD[i]);
			FlxG.cameras.add(notesHUD[i], false);
			strumLines.members[i].notesGroup.cameras = strumLines.members[i].splashNotes.cameras = [notesHUD[i]];
		}
		add(strumLines);

		// making the pause camera
		pauseCamera = new FlxCamera();
		pauseCamera.bgColor.alpha = 0;
		FlxG.cameras.add(pauseCamera, false);

		modchartHelper = new ModchartHelper(songMeta.rawName, strumLines.members);

		uiHUD = new GameplayUI();
		uiHUD.cameras = [camHUD];
		add(uiHUD);

		// create a hud over the hud camera for dialogue
		dialogueHUD = new FlxCamera();
		dialogueHUD.bgColor.alpha = 0;
		FlxG.cameras.add(dialogueHUD, false);

		controls.onKeyPressed.add(onKeyPress);
		controls.onKeyReleased.add(onKeyRelease);

		Paths.clearUnusedMemory();

		hxsCall('createPost', []);

		// call the funny intro cutscene depending on the song
		if (!skipCutscenes())
			songIntroCutscene();
		else
			startCountdown();

		print('Took ${openfl.Lib.getTimer() - timeBeforeSwitching}ms to load', DEBUG);
	}

	public function onKeyPress(key:Int, action:String):Void {
		if (playerStrums.autoplay || paused)
			return;

		if (action != null && Receptor.dirs.contains(action)) {
			var index:Int = Receptor.dirs.indexOf(action);
			hxsCall('keyPress', [key, index, action]);
			holdControls[index] = true;

			if (generatedMusic) {
				// improved this a little bit, maybe its a lil
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				playerStrums.allNotes.forEachAlive(function(daNote:Note) {
					if ((daNote.direction == index) && daNote.canBeHit && !daNote.isSustain && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});
				possibleNoteList.sort((a, b) -> Std.int(a.timeStep - b.timeStep));

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0) {
					var eligable = true;
					var firstNote = true;
					// loop through the possible notes
					for (coolNote in possibleNoteList) {
						for (noteDouble in pressedNotes) {
							if (Math.abs(noteDouble.timeStep - coolNote.timeStep) < 10)
								firstNote = false;
							else
								eligable = false;
						}

						if (eligable) {
							goodNoteHit(coolNote, player, playerStrums, firstNote); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}
					//
				}
				else // else just call bad notes
					if (!Init.trueSettings.get('Ghost Tapping'))
						missNoteCheck(true, index, player, true);
			}

			if (playerStrums.receptors.members[index] != null && playerStrums.receptors.members[index].animation.curAnim.name != 'confirm')
				playerStrums.receptors.members[index].playAnim('pressed');

			hxsCall('keyPressPost', [key, index, action]);
		}
	}

	public function onKeyRelease(key:Int, action:String):Void {
		if (playerStrums.autoplay || paused)
			return;

		if (Receptor.dirs.contains(action)) {
			var index:Int = Receptor.dirs.indexOf(action);
			hxsCall('keyRelease', [key, index, action]);
			holdControls[index] = false;

			// receptor reset
			if (playerStrums.receptors.members[index] != null)
				playerStrums.receptors.members[index].playAnim('static');
		}
	}

	override public function destroy() {
		controls.onKeyPressed.remove(onKeyPress);
		controls.onKeyReleased.remove(onKeyRelease);
		hxsCall("destroy", []);
		super.destroy();
	}

	var camPositionExtend:FlxPoint = new FlxPoint();

	override public function update(elapsed:Float) {
		super.update(elapsed);

		hxsSet('_delta', FlxG.elapsed); // updating the delta value @Sword352
		hxsCall('update', [elapsed]);

		if (health > 2)
			health = 2;

		// dialogue checks
		if (dialogueBox != null && dialogueBox.alive) {
			// wheee the shift closes the dialogue
			if (FlxG.keys.justPressed.SHIFT)
				dialogueBox.closeDialog();

			// the change I made was just so that it would only take accept inputs
			if (controls.justPressed("accept") && dialogueBox.textStarted) {
				FlxG.sound.play(Paths.sound('cancelMenu'));
				dialogueBox.curPage += 1;

				if (dialogueBox.curPage == dialogueBox.dialogueData.dialogue.length)
					dialogueBox.closeDialog()
				else
					dialogueBox.updateDialog();
			}
		}

		if (!inCutscene) {
			if (controls.justPressed("pause") && startedCountdown && !startingSong && canPause)
				pauseGame();

			// make sure you're not cheating lol
			if (!isStoryMode) {
				if ((FlxG.keys.justPressed.SIX)) {
					playerStrums.autoplay = !playerStrums.autoplay;
					uiHUD.autoplayMark.visible = playerStrums.autoplay;
					validScore = false;
				}

				if (FlxG.keys.justPressed.SEVEN)
					Main.switchState(new ChartEditor(songMeta.rawName, LevelData.curDifficulties[storyDifficulty]));

				#if debug
				if (FlxG.keys.justPressed.EIGHT)
					endSong();
				#end
			}

			Conductor.songPosition += elapsed * 1000;
			if (startingSong && startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else {
				if (!paused) {
					songTime += FlxG.game.ticks - previousFrameTime;
					previousFrameTime = FlxG.game.ticks;

					// Interpolation type beat
					if (Conductor.lastSongPos != Conductor.songPosition) {
						songTime = (songTime + Conductor.songPosition) / 2;
						Conductor.lastSongPos = Conductor.songPosition;
					}
				}
			}

			if (generatedMusic && SONG.sections[curSect] != null) {
				/*
					for (cameraEvent in SONG.sections[curSect].events)
						if (Type.enumIndex(cameraEvent.event) == Type.enumIndex(MoveCamToChar(0)))
							eventManager.solveTrigger(event[0]);
				 */
			}

			var lerpVal = (elapsed * 2) * cameraSpeed;
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x + camPositionExtend.x, lerpVal),
				FlxMath.lerp(camFollowPos.y, camFollow.y + camPositionExtend.y, lerpVal));
			camPositionExtend.set();

			var easeLerp = 1 - Tools.boundFPS(0.05);
			// camera stuffs
			FlxG.camera.zoom = FlxMath.lerp(stageBuild.stageData.stageCameraZoom, FlxG.camera.zoom, easeLerp);
			for (hud in allUIs)
				hud.zoom = FlxMath.lerp(1, hud.zoom, easeLerp);

			FlxG.camera.angle = FlxMath.lerp(0, FlxG.camera.angle, easeLerp);
			for (hud in allUIs)
				hud.angle = FlxMath.lerp(0, hud.angle, easeLerp);

			// Controls

			// RESET = Quick Game Over Screen
			if (!Init.trueSettings.get("Disable Reset Button") && controls.justPressed("reset") && !startingSong && !isStoryMode)
				health = 0;

			if (health <= 0 && startedCountdown) {
				paused = true;
				player.stunned = true;
				persistentUpdate = false;
				persistentDraw = false;

				resetMusic();

				deaths += 1;

				openSubState(new GameOverSubstate(player.getScreenPosition().x, player.getScreenPosition().y));

				Discord.changePresence("Game Over - " + songDetails, detailsSub, iconRPC);
			}

			// spawn in the notes from the array
			if ((unspawnNotes[0] != null) && ((unspawnNotes[0].timeStep - Conductor.songPosition) < 3500)) {
				var dunceNote:Note = unspawnNotes[0];
				// push note to its correct strumline
				strumLines.members[Math.floor((dunceNote.direction + (dunceNote.mustPress ? 4 : 0)) / numberOfKeys)].push(dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}

			noteCalls(elapsed);
		}

		stageBuild.updatePost(elapsed);

		shaderHandler.updatePost(elapsed);

		hxsCall('updatePost', [elapsed]);
	}

	function noteCalls(delta:Float) {
		// reset strums
		for (strumline in strumLines) {
			// handle strumline stuffs
			for (uiNote in strumline.receptors) {
				if (strumline.autoplay)
					strumCallsAuto(uiNote);
			}
		}

		// if the song is generated
		if (generatedMusic && startedCountdown) {
			for (strumline in strumLines) {
				strumline.allNotes.forEachAlive(function(daNote:Note) {
					// hell breaks loose here, we're using nested scripts!
					mainControls(daNote, strumline.character, strumline, strumline.autoplay);

					if (!daNote.tooLate && daNote.timeStep < Conductor.songPosition - (Timings.msThreshold) && !daNote.wasGoodHit) {
						if ((!daNote.tooLate) && (daNote.mustPress)) {
							if (!daNote.isSustain) {
								daNote.tooLate = true;
								for (note in daNote.childrenNotes)
									note.tooLate = true;

								vocals.volume = 0;
								missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.direction, player, true);
								// ambiguous name
								Timings.updateAccuracy(0);
							}
							else if (daNote.isSustain) {
								if (daNote.parentNote != null) {
									var parentNote = daNote.parentNote;
									if (!parentNote.tooLate) {
										var breakFromLate:Bool = false;
										for (note in parentNote.childrenNotes)
											if (note.tooLate && !note.wasGoodHit)
												breakFromLate = true;
										if (!breakFromLate) {
											missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.direction, player, true);
											for (note in parentNote.childrenNotes)
												note.tooLate = true;
										}
										//
									}
								}
							}
						}
					}
				});

				if (modchartHelper != null)
					modchartHelper.update(delta);
			}
		}

		// reset bf's animation
		if ((player != null && player.animation != null)
			&& (player.holdTimer > Conductor.stepCrochet * (4 / 1000) && (!holdControls.contains(true) || playerStrums.autoplay))) {
			if (player.animation.curAnim.name.startsWith('sing') && !player.animation.curAnim.name.endsWith('miss'))
				player.dance();
		}
	}

	function goodNoteHit(coolNote:Note, character:Character, characterStrums:Strumline, ?canDisplayJudgement:Bool = true) {
		if (!coolNote.wasGoodHit) {
			coolNote.wasGoodHit = true;
			vocals.volume = 1;

			var callName:String = "goodNoteHit";
			if (!coolNote.mustPress)
				callName = "opponentNoteHit";

			hxsCall(callName, [coolNote, coolNote.timeStep, coolNote.direction, coolNote.type]);

			characterPlayAnimation(coolNote, character);
			if (characterStrums.receptors.members[coolNote.direction] != null)
				characterStrums.receptors.members[coolNote.direction].playAnim('confirm', true);

			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (canDisplayJudgement && !characterStrums.autoplay) {
				var late:Bool = false;
				var noteDiff:Float = Math.abs(coolNote.timeStep - Conductor.songPosition);
				if (coolNote.timeStep < Conductor.songPosition)
					late = true;

				// loop through all avaliable judgements
				var foundRating:String = 'miss';
				var lowestThreshold:Float = Math.POSITIVE_INFINITY;
				for (myRating in Timings.judgementsMap.keys()) {
					var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
					if (noteDiff <= myThreshold && (myThreshold < lowestThreshold)) {
						foundRating = myRating;
						lowestThreshold = myThreshold;
					}
				}

				if (!coolNote.isSustain) {
					increaseCombo(foundRating, coolNote.direction, character);
					popUpScore(foundRating, late, characterStrums, coolNote);
					if (coolNote.childrenNotes.length > 0)
						Timings.notesHit++;
					healthCall(Timings.judgementsMap.get(foundRating)[3]);
				}
				else if (coolNote.isSustain) {
					// call updated accuracy stuffs
					if (coolNote.parentNote != null) {
						Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
						healthCall(100 / coolNote.parentNote.childrenNotes.length);
					}
				}
			}

			if (!coolNote.isSustain)
				characterStrums.destroyNote(coolNote);
			//
		}
	}

	function missNoteCheck(?includeAnimation:Bool = false, direction:Int = 0, character:Character, popMiss:Bool = false, lockMiss:Bool = false) {
		hxsCall("noteMiss", [character, direction, popMiss, lockMiss]);

		if (includeAnimation) {
			var stringDirection:String = Receptor.dirs[direction];
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			character.playAnim('sing' + stringDirection.toUpperCase() + 'miss', lockMiss);
		}
		decreaseCombo(popMiss);
	}

	function characterPlayAnimation(coolNote:Note, character:Character) {
		var altString:String = '';
		var baseString = 'sing' + Receptor.dirs[coolNote.direction].toUpperCase();

		// this is messy as shit
		if (SONG.sections[curSect] != null && SONG.sections[curSect].animation.startsWith('-'))
			if (character.animOffsets.exists(baseString + SONG.sections[curSect].animation))
				altString = SONG.sections[curSect].animation;

		character.playAnim(baseString + altString, true);
		character.holdTimer = 0;
	}

	private function strumCallsAuto(cStrum:Receptor, ?callType:Int = 1, ?daNote:Note):Void {
		switch (callType) {
			case 1:
				// end the animation if the calltype is 1 and it is done
				if ((cStrum.animation.finished) && (cStrum.canFinishAnimation))
					cStrum.playAnim('static');
			default:
				// check if it is the correct strum
				if (daNote.direction == cStrum.ID) {
					// if (cStrum.animation.curAnim.name != 'confirm')
					cStrum.playAnim('confirm'); // play the correct strum's confirmation animation (haha rhymes)

					// stuff for sustain notes
					if ((daNote.isSustain) && (!daNote.animation.curAnim.name.endsWith('holdend')))
						cStrum.canFinishAnimation = false; // basically, make it so the animation can't be finished if there's a sustain note below
					else
						cStrum.canFinishAnimation = true;
				}
		}
	}

	private function mainControls(daNote:Note, char:Character, strumline:Strumline, autoplay:Bool):Void {
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (autoplay) {
			// check if the note was a good hit
			if (daNote.timeStep <= Conductor.songPosition) {
				// kill the note, then remove it from the array
				var canDisplayJudgement = false;
				if (strumline.displayJudgements) {
					canDisplayJudgement = true;
					for (noteDouble in notesPressedAutoplay)
						if (noteDouble.direction == daNote.direction)
							canDisplayJudgement = false;
					notesPressedAutoplay.push(daNote);
				}
				goodNoteHit(daNote, char, strumline, canDisplayJudgement);
			}
			//
		}

		if (!autoplay) {
			// check if anything is held
			if (holdControls.contains(true)) {
				// check notes that are alive
				strumline.allNotes.forEachAlive(function(coolNote:Note) {
					if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
						&& coolNote.canBeHit
						&& coolNote.mustPress
						&& !coolNote.tooLate
						&& coolNote.isSustain
						&& holdControls[coolNote.direction])
						goodNoteHit(coolNote, char, strumline);
				});
			}
		}

		if (!Init.trueSettings.get('Disable Camera Panning') && SONG.sections[curSect] != null && !paused) {
			switch ((SONG.sections[curSect].cameraPoints == 1 ? player : opponent).animation.curAnim.name) {
				case "singLEFT":
					camPositionExtend.x = -20;
				case "singDOWN":
					camPositionExtend.y = 20;
				case "singUP":
					camPositionExtend.y = -20;
				case "singRIGHT":
					camPositionExtend.x = 20;
			}
		}
	}

	public function pauseGame() {
		// pause discord rpc
		updateRPC(true);

		// pause game
		paused = true;

		// update drawing stuffs
		persistentUpdate = false;
		persistentDraw = true;

		// stop all tweens and timers
		Tools.pauseEveryTween();
		Tools.pauseEveryTimer();

		// open pause substate
		if (FlxG.random.bool(0.1)) // secret pause substate
		{
			lastSongPosition = Conductor.songPosition;
			lastBPM = Conductor.bpm;
			openSubState(new GitarooPauseSubState());
		}
		else
			openSubState(new PauseSubState(player.getScreenPosition().x, player.getScreenPosition().y));
	}

	override public function onFocus():Void {
		if (!paused)
			updateRPC(false);
		super.onFocus();
	}

	override public function onFocusLost():Void {
		if (canPause && !paused && !playerStrums.autoplay && !Init.trueSettings.get('Auto Pause'))
			pauseGame();
		updateRPC(true);
		super.onFocusLost();
	}

	public function updateRPC(pausedRPC:Bool) {
		#if DISCORD_RPC
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (health > 0) {
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	function popUpScore(baseRating:String, lateHit:Bool, strumline:Strumline, coolNote:Note) {
		var score:Int = 50;
		if (baseRating == "sick" && strumline.splashNotes != null)
			strumline.popSplash(coolNote.direction);
		else if (allSicks)
			allSicks = false;

		displayRating(baseRating, lateHit);
		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);
		songScore += score;

		popUpCombo();
	}

	private var createdColor = FlxColor.fromRGB(204, 66, 66);

	function popUpCombo(?cache:Bool = false) {
		var comboString:String = Std.string(combo);
		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");
		// deletes all combo sprites prior to initalizing new ones
		if (lastCombo != null) {
			while (lastCombo.length > 0) {
				lastCombo[0].kill();
				lastCombo.remove(lastCombo[0]);
			}
		}

		for (scoreInt in 0...stringArray.length) {
			var numScore = SkinManager.generateCombo(stringArray[scoreInt], (!negative ? allSicks : false), negative, createdColor, scoreInt);
			numScore.visible = !cache;
			numScore.x += stageBuild.stageData.ratingPosition[0];
			numScore.y += stageBuild.stageData.ratingPosition[1];
			add(numScore);
			// hardcoded lmao
			if (!Init.trueSettings.get('Simply Judgements')) {
				add(numScore);
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween) {
						numScore.kill();
					},
					startDelay: Conductor.crochet * 0.002
				});
			}
			else {
				add(numScore);
				// centers combo
				numScore.y += 10;
				numScore.x -= 95;
				numScore.x -= ((comboString.length - 1) * 22);
				lastCombo.push(numScore);
				FlxTween.tween(numScore, {y: numScore.y + 20}, 0.1, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
			}
			// hardcoded lmao
			if (Init.trueSettings.get('Fixed Judgements')) {
				if (!cache)
					numScore.cameras = [camHUD];
				numScore.y += 50;
			}
			numScore.x += 100;
		}
	}

	function decreaseCombo(?popMiss:Bool = false) {
		// painful if statement
		if (crowd != null)
			if (((combo > 5) || (combo < 0)) && (crowd.animOffsets.exists('sad')))
				crowd.playAnim('sad');

		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		songScore -= 10;
		misses++;

		// display negative combo
		if (popMiss) {
			// doesnt matter miss ratings dont have timings
			displayRating("miss", true);
			healthCall(Timings.judgementsMap.get("miss")[3]);
		}
		popUpCombo();

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?direction = 0, ?character:Character) {
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null) {
			if (Timings.judgementsMap.get(baseRating)[3] > 0) {
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else
				missNoteCheck(true, direction, character, false, true);
		}
	}

	public function displayRating(daRating:String, lateHit:Bool, ?cache:Bool = false) {
		/* so you might be asking
			"oh but if the rating isn't sick why not just reset it"
			because miss judgements can pop, and they dont mess with your sick combo
		 */
		var rating = SkinManager.generateRating(daRating, allSicks, lateHit);
		rating.visible = !cache;
		rating.x += stageBuild.stageData.ratingPosition[0];
		rating.y += stageBuild.stageData.ratingPosition[1];
		add(rating);

		if (!Init.trueSettings.get('Simply Judgements')) {
			add(rating);

			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween) {
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		else {
			if (lastRating != null) {
				lastRating.kill();
			}
			add(rating);
			lastRating = rating;
			FlxTween.tween(rating, {y: rating.y + 20}, 0.2, {type: FlxTweenType.BACKWARD, ease: FlxEase.circOut});
			FlxTween.tween(rating, {"scale.x": 0, "scale.y": 0}, 0.1, {
				onComplete: function(tween:FlxTween) {
					rating.kill();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		// */

		if (!cache) {
			if (Init.trueSettings.get('Fixed Judgements')) {
				// bound to camera
				rating.cameras = [camHUD];
				rating.screenCenter();
			}

			// return the actual rating to the array of judgements
			Timings.gottenJudgements.set(daRating, Timings.gottenJudgements.get(daRating) + 1);

			// set new smallest rating
			if (Timings.smallestRating != daRating) {
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(daRating)[0])
					Timings.smallestRating = daRating;
			}
		}
	}

	function healthCall(?ratingMultiplier:Float = 0) {
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function startSong():Void {
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		if (!paused) {
			songMusic.play();
			songMusic.onComplete = endSong;
			vocals.play();

			stageBuild.songStart();

			var tweenableUIObjects:Array<Dynamic> = [uiHUD.centerMark];
			/*
				if (Init.trueSettings.get("Song Timer"))
				{
						// tweenableUIObjects.push(uiHUD.timeBarBG);
						tweenableUIObjects.push(uiHUD.timeBar);
				}
			 */

			if (Init.trueSettings.get("Song Timer")) {
				var i:Int = tweenableUIObjects.length - 1;
				FlxTween.tween(tweenableUIObjects[i], {alpha: 1}, 0.6, {ease: FlxEase.circOut});
			}

			#if desktop
			// Song duration in a float, useful for the time left feature
			songLength = songMusic.length;

			// Updating Discord Rich Presence (with Time Left)
			updateRPC(false);
			#end
		}
	}

	private function generateSong(dataPath:String):Void {
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		songDetails = Tools.dashToSpace(songMeta.name) + ' - ' + LevelData.curDifficulties[storyDifficulty];

		// String for when the game is paused
		detailsPausedText = "Paused - " + songDetails;

		// set details for song stuffs
		detailsSub = "";

		// Updating Discord Rich Presence.
		updateRPC(false);

		curSong = songMeta.name;
		songMusic = new FlxSound().loadEmbedded(Paths.inst(songMeta.rawName), false, true);
		vocals = new FlxSound().loadEmbedded(Paths.voices(songMeta.rawName), false, true);

		FlxG.sound.list.add(songMusic);
		FlxG.sound.list.add(vocals);

		// generate the chart
		unspawnNotes = ChartLoader.loadChartNotes(SONG);
		// sometime my brain farts dont ask me why these functions were separated before

		for (event in myEventList) {
			eventManager.solvePreload(event);
			break;
		}

		// sort through them
		unspawnNotes.sort(sortByShit);
		// give the game the heads up to be able to start
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.timeStep, Obj2.timeStep);

	function resyncVocals(resyncInst:Bool = false):Void {
		if (resyncInst)
			songMusic.pause();
		vocals.pause();
		Conductor.songPosition = songMusic.time;
		vocals.time = Conductor.songPosition;
		if (resyncInst)
			songMusic.play();
		vocals.play();
	}

	override function sectHit() {
		super.sectHit();
		shaderHandler.sectionHit(curSect);
		modchartHelper.call("onSect", [curSect]);
		hxsCall("onSect", [curSect]);
	}

	override function stepHit() {
		super.stepHit();

		if (songMusic != null
			&& Math.abs(songMusic.time - Conductor.songPosition) > 20
			|| (vocals != null && Math.abs(vocals.time - Conductor.songPosition) > 20))
			resyncVocals();

		if (myEventList.length > 0 && myEventList[0] != null && myEventList[0].step != null) {
			if (curStep >= myEventList[0].step) {
				eventManager.solveTrigger(myEventList[0]);
				myEventList.shift();
			}
		}

		shaderHandler.stepHit(curStep);
		modchartHelper.call("onStep", [curStep]);
		hxsCall("onStep", [curStep]);
		stageBuild.onStep(curStep);
	}

	private function charactersDance(curBeat:Int) {
		if (crowd != null)
			if ((curBeat % Math.round(gfSpeed * crowd.danceBeat) == 0)
				&& ((crowd.animation.curAnim.name.startsWith("idle") || crowd.animation.curAnim.name.startsWith("dance"))))
				crowd.dance();

		if ((player.animation.curAnim.name.startsWith("idle") || player.animation.curAnim.name.startsWith("dance"))
			&& (curBeat % player.danceBeat == 0))
			player.dance();

		// added this for opponent cus it wasn't here before and skater would just freeze
		if ((opponent.animation.curAnim.name.startsWith("idle") || opponent.animation.curAnim.name.startsWith("dance"))
			&& (curBeat % opponent.danceBeat == 0))
			opponent.dance();
	}

	override function beatHit() {
		super.beatHit();

		if ((FlxG.camera.zoom < 1.35 && curBeat % 4 == 0) && (!Init.trueSettings.get('Reduced Movements'))) {
			FlxG.camera.zoom += 0.015;
			for (hud in allUIs)
				hud.zoom += 0.05;
		}

		if (SONG.sections[curSect] != null)
			if (SONG.sections[curSect].changeBPM)
				Conductor.changeBPM(SONG.sections[curSect].bpm);

		shaderHandler.beatHit(curBeat);
		modchartHelper.call("onBeat", [curBeat]);
		uiHUD.beatHit();
		charactersDance(curBeat);
		hxsCall("onBeat", [curBeat]);
		stageBuild.onBeat(curBeat);

		if (curSong.toLowerCase() == 'bopeebo') {
			if (curBeat % 8 == 7) // hardcoded lol
				eventManager.solveTrigger({event: PlayHeyAnim(1)});

			switch (curBeat) {
				case 128, 129, 130:
					vocals.volume = 0;
			}
		}

		if (curSong.toLowerCase() == 'fresh') {
			switch (curBeat) {
				case 16 | 80:
					gfSpeed = 2;
				case 48 | 112:
					gfSpeed = 1;
			}
		}

		if (curSong.toLowerCase() == 'milf'
			&& curBeat >= 168
			&& curBeat < 200
			&& !Init.trueSettings.get('Reduced Movements')
			&& FlxG.camera.zoom < 1.35) {
			FlxG.camera.zoom += 0.015;
			for (hud in allUIs)
				hud.zoom += 0.03;
		}
	}

	// substate stuffs
	public function resetMusic() {
		// simply stated, resets the playstate's music for other states and substates
		if (songMusic != null)
			songMusic.stop();

		if (vocals != null)
			vocals.stop();
	}

	override function openSubState(SubState:FlxSubState) {
		if (paused) {
			if (songMusic != null) {
				songMusic.pause();
				vocals.pause();
			}
		}
		hxsCall("openSubState", [SubState]);
		super.openSubState(SubState);
	}

	override function closeSubState() {
		if (paused) {
			if (songMusic != null && !startingSong)
				resyncVocals(true);

			// resume all tweens and timers
			Tools.resumeEveryTween();
			Tools.resumeEveryTimer();

			paused = false;
			updateRPC(false);
		}

		Paths.clearUnusedMemory();

		hxsCall("closeSubState", []);
		super.closeSubState();
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	private var endSongEvent:Bool = false;

	function endSong():Void {
		canPause = false;
		songMusic.volume = vocals.volume = deaths = 0;
		stageBuild.songEnd();
		hxsCall("endSong", []);

		if (validScore)
			Highscore.saveScore(Tools.spaceToDash(songMeta.rawName.toLowerCase()), {
				score: songScore,
				breaks: misses,
				rating: Timings.ratingFinal,
				accuracy: Timings.trueAccuracy
			}, storyDifficulty);

		if (!isStoryMode) {
			Main.switchState((Init.trueSettings.get('End Screen') && !playerStrums.autoplay) ? new RatingState() : new FreeplayState());
		}
		else {
			// set the campaign's score higher
			campaignScore += songScore;

			// remove a song from the story playlist
			storyPlaylist.remove(storyPlaylist[0]);

			// check if there aren't any songs left
			if ((storyPlaylist.length <= 0) && (!endSongEvent)) {
				// play menu music
				Tools.resetMenuMusic();

				// set up transitions
				transIn = FlxTransitionableState.defaultTransIn;
				transOut = FlxTransitionableState.defaultTransOut;

				// change to the menu state
				Main.switchState(new StoryMenuState());

				// save the week's score if the score is valid
				if (validScore)
					Highscore.saveWeekScore(storyWeek, {
						score: campaignScore,
						breaks: null,
						accuracy: null,
						rating: null
					}, storyDifficulty);
			}
			else
				songEndSpecificActions();
		}
		//
	}

	private function songEndSpecificActions() {
		switch (songMeta.rawName.toLowerCase()) {
			case 'eggnog':
				// make the lights go out
				var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
					-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
				blackShit.scrollFactor.set();
				add(blackShit);
				camHUD.visible = false;

				// oooo spooky
				FlxG.sound.play(Paths.sound('Lights_Shut_off'));

				// call the song end
				var eggnogEndTimer:FlxTimer = new FlxTimer().start(Conductor.crochet / 1000, function(timer:FlxTimer) {
					callDefaultSongEnd();
				}, 1);

			default:
				var foundEndCutscene:Bool = false;

				for (i in scriptStack) {
					@:privateAccess
					if (i.exists("endCutscene") && i._curPath.contains('songs/${songMeta.rawName}/scripts')) {
						i.set("callDefaultSongEnd", callDefaultSongEnd);
						i.set("callSongEnd", callDefaultSongEnd);
						i.set("endSong", callDefaultSongEnd);

						i.call("endCutscene", []);
						foundEndCutscene = true;
						break;
					}
				}
				if (!foundEndCutscene)
					callDefaultSongEnd();
		}
	}

	private function callDefaultSongEnd() {
		var difficulty:String = '-' + LevelData.curDifficulties[storyDifficulty].toLowerCase();
		difficulty = difficulty.replace('-normal', '');

		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		SONG = ChartLoader.loadChart(PlayState.storyPlaylist[0].toLowerCase(), difficulty);
		Tools.killMusic([songMusic, vocals]);
		FlxG.switchState(new PlayState());
	}

	var dialogueBox:DialogueBox;

	public function songIntroCutscene() {
		switch (curSong.toLowerCase()) {
			case "winter-horrorland":
				inCutscene = true;
				var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				add(blackScreen);
				blackScreen.scrollFactor.set();
				camHUD.visible = false;

				new FlxTimer().start(0.1, function(tmr:FlxTimer) {
					remove(blackScreen);
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					camFollow.y = -2050;
					camFollow.x += 200;
					FlxG.camera.focusOn(camFollow.getPosition());
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer) {
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: stageBuild.stageData.stageCameraZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								startCountdown();
							}
						});
					});
				});
			case 'roses':
				// the same just play angery noise LOL
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));
				callTextbox();
			case 'thorns':
				inCutscene = true;
				for (hud in allUIs)
					hud.visible = false;

				var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
				red.scrollFactor.set();

				var senpaiEvil:FlxSprite = new FlxSprite();
				senpaiEvil.frames = Paths.getSparrowAtlas('cutscene/senpai/senpaiCrazy');
				senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
				senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
				senpaiEvil.scrollFactor.set();
				senpaiEvil.updateHitbox();
				senpaiEvil.screenCenter();

				add(red);
				add(senpaiEvil);
				senpaiEvil.alpha = 0;
				new FlxTimer().start(0.3, function(swagTimer:FlxTimer) {
					senpaiEvil.alpha += 0.15;
					if (senpaiEvil.alpha < 1)
						swagTimer.reset();
					else {
						senpaiEvil.animation.play('idle');
						FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function() {
							remove(senpaiEvil);
							remove(red);
							FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function() {
								for (hud in allUIs)
									hud.visible = true;
								callTextbox();
							}, true);
						});
						new FlxTimer().start(3.2, function(deadTime:FlxTimer) {
							FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
						});
					}
				});
			default:
				var foundStartCutscene:Bool = false;

				for (i in scriptStack) {
					@:privateAccess
					if (i.exists("introCutscene") && i._curPath.contains('songs/${songMeta.rawName}/scripts')) {
						i.set("callTextbox", callTextbox);
						i.set("startCountdown", startCountdown);
						i.set("startSong", startSong);

						i.call("introCutscene", []);
						foundStartCutscene = true;
						break;
					}
				}
				if (!foundStartCutscene)
					callTextbox();
		}
		//
	}

	function callTextbox() {
		var dialogPath = Paths.json(songMeta.rawName.toLowerCase() + '/dialogue');
		if (FileSystem.exists(dialogPath)) {
			startedCountdown = false;

			dialogueBox = DialogueBox.createDialogue(sys.io.File.getContent(dialogPath));
			dialogueBox.cameras = [dialogueHUD];
			dialogueBox.whenDaFinish = startCountdown;

			add(dialogueBox);
		}
		else
			startCountdown();
	}

	public static function skipCutscenes():Bool {
		// pretty messy but an if statement is messier
		if (Init.trueSettings.get('Skip Text') != null && Std.isOfType(Init.trueSettings.get('Skip Text'), String)) {
			switch (cast(Init.trueSettings.get('Skip Text'), String)) {
				case 'never':
					return false;
				case 'freeplay only':
					return !isStoryMode;
				default:
					return true;
			}
		}
		return false;
	}

	public var swagCounter:Int = 0;

	private function startCountdown():Void {
		inCutscene = false;
		Conductor.songPosition = -(Conductor.crochet * 5);

		hxsCall("startCountdown", []);
		stageBuild.countdownStart();
		camHUD.visible = true;

		if (displayCountdown)
			countingDown();
		else {
			endedCountdown = true;
			Conductor.songPosition = -(Conductor.crochet * 1);
		}
	}

	/**
	 * Function to display the countdown sprite and play countdown sounds
	 * @param starts defines where the counter starts (e.g: 1 starts at "ready"/"two")
	 * @param loops defines how many times the counter should update (usually 5)
	 */
	public function countingDown(starts:Int = 0, loops:Int = 4):Void {
		// making sure you can't overflow the offsets
		starts = Std.int(FlxMath.bound(starts, 0, 4));
		loops = Std.int(FlxMath.bound(loops, 0, 4));

		swagCounter = starts;

		var introAssets:Array<flixel.graphics.FlxGraphic> = [
			null, // three sprite, setting this as null so it goes in order correctly
			Tools.getUIAsset('ready', SkinManager.assetStyle, "images/UI"),
			Tools.getUIAsset('set', SkinManager.assetStyle, "images/UI"),
			Tools.getUIAsset('go', SkinManager.assetStyle, "images/UI"),
		];

		var introSounds:Array<openfl.media.Sound> = [
			Tools.getUIAsset('intro3', SkinManager.assetStyle, 'sounds/countdown', SOUND),
			Tools.getUIAsset('intro2', SkinManager.assetStyle, 'sounds/countdown', SOUND),
			Tools.getUIAsset('intro1', SkinManager.assetStyle, 'sounds/countdown', SOUND),
			Tools.getUIAsset('introGo', SkinManager.assetStyle, 'sounds/countdown', SOUND),
		];

		// create a countdown sprite
		var countdownSpr:FlxSprite = new FlxSprite();
		countdownSpr.camera = camHUD;
		countdownSpr.alpha = 0;
		add(countdownSpr);

		var countOG_y:Float = countdownSpr.y;
		var countdownTween:FlxTween = null;

		new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer) {
			startedCountdown = true;

			charactersDance(tmr.loopsLeft);

			stageBuild.countdownTick(swagCounter);
			hxsCall("countdownTick", [swagCounter]);

			// reload the graphic from the countdown sprite
			if (introAssets[swagCounter] != null)
				countdownSpr.loadGraphic(introAssets[swagCounter]);
			countdownSpr.alpha = introAssets[swagCounter] != null ? 1 : 0;
			countdownSpr.screenCenter();

			if (countdownTween != null)
				countdownTween.cancel();

			countdownTween = FlxTween.tween(countdownSpr, {y: countOG_y += 100, alpha: 0}, Conductor.crochet / 1000, {
				ease: FlxEase.cubeInOut,
				onComplete: function(twn:FlxTween) {
					if (tmr.loopsLeft == 0) {
						countdownSpr.destroy();
						endedCountdown = true;
					}
				}
			});

			if (introSounds[swagCounter] != null)
				FlxG.sound.play(introSounds[swagCounter], 0.6);

			if (!endedCountdown)
				Conductor.songPosition = -(Conductor.crochet * tmr.loopsLeft);
			swagCounter += 1;
		}, loops + 1);
	}

	override function add(Object:FlxBasic):FlxBasic {
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
