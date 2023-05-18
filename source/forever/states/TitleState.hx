package forever.states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import forever.music.Conductor;
import forever.music.MusicBeat.MusicBeatState;
import forever.states.menus.*;
import forever.ui.Alphabet;
import openfl.Assets;
import sys.FileSystem;
import sys.io.File;

typedef TitleScreenData = {
	var ?musicFile:String;
	var ?musicFolder:String;
	var ?musicBPM:Null<Int>;
	var sequenceBeats:Array<BeatHitData>;
}

typedef BeatHitData = {
	var call:String;
	var beat:Null<Int>;
	var ?step:Null<Int>;
	var ?text:String;
	var ?ngVisible:Bool;
}

class TitleState extends MusicBeatState {
	public static var titleData:TitleScreenData;

	var beatMap:Map<Int, BeatHitData> = [];
	var stepMap:Map<Int, BeatHitData> = [];

	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	override public function create():Void {
		curWacky = FlxG.random.getObject(getIntroTextShit());
		super.create();

		startIntro();
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro() {
		if (!initialized) {
			Discord.changePresence('TITLE SCREEN', 'In Menus');

			titleData = {
				musicFile: "freakyMenu",
				musicFolder: "music",
				musicBPM: 102,
				sequenceBeats: []
			};

			titleData.sequenceBeats = loadDefaultBeatSequence();

			if (FileSystem.exists(Paths.getPath('data/titlescreen', YAML))) {
				var parsedFile:String = File.getContent(Paths.getPath('data/titlescreen', YAML));
				var parsedData:TitleScreenData = cast yaml.Yaml.parse(parsedFile, yaml.Parser.options().useObjects());
				if (parsedData != null) {
					print('Loaded titlescreen data from file');
					if (parsedData.musicFile != null)
						titleData.musicFile = parsedData.musicFile;
					if (parsedData.musicFolder != null)
						titleData.musicFolder = parsedData.musicFolder;
					if (parsedData.musicBPM != null)
						titleData.musicBPM = parsedData.musicBPM;

					if (parsedData.sequenceBeats != null)
						titleData.sequenceBeats = parsedData.sequenceBeats;
				}
			}

			for (title in titleData.sequenceBeats) {
				var dat:BeatHitData = {
					call: title.call,
					beat: title.beat,
					step: title.step,
					text: title.text,
					ngVisible: title.ngVisible
				};
				beatMap.set(title.beat, dat);
				stepMap.set(title.step, dat);
			}

			Tools.resetMenuMusic(titleData.musicFile, titleData.musicFolder, titleData.musicBPM, true);
		}

		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		// bg.antialiasing = true;
		// bg.setGraphicSize(Std.int(bg.width * 0.6));
		// bg.updateHitbox();
		add(bg);

		logoBl = new FlxSprite(-150, -100);
		logoBl.frames = Paths.getSparrowAtlas('menus/title/logoBumpin');
		logoBl.antialiasing = true;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.animation.play('bump');
		logoBl.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('menus/title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = true;
		add(gfDance);
		add(logoBl);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('menus/title/titleEnter');
		titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = true;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		// titleText.screenCenter(X);
		add(titleText);

		// var logo:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menus/title/logo'));
		// logo.screenCenter();
		// logo.antialiasing = true;
		// add(logo);

		// FlxTween.tween(logoBl, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG});
		// FlxTween.tween(logo, {y: logoBl.y + 50}, 0.6, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.1});

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('menus/title/newgrounds_logo'));
		add(ngSpr);
		ngSpr.visible = false;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = true;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			skipIntro();
		else
			initialized = true;

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>> {
		var swagGoodArray:Array<Array<String>> = [];
		if (Assets.exists(Paths.txt('data/introText'))) {
			var fullText:String = Assets.getText(Paths.txt('data/introText'));
			var firstArray:Array<String> = fullText.split('\n');

			for (i in firstArray)
				swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float) {
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = controls.justPressed("accept");

		#if mobile
		for (touch in FlxG.touches.list)
			if (touch.justPressed)
				pressedEnter = true;
		#end

		if (pressedEnter && !transitioning && skippedIntro) {
			titleText.animation.play('press');
			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
			transitioning = true;

			new FlxTimer().start(1.3, function(tmr:FlxTimer) Main.switchState(new MainMenuState()));
		}

		// hi game, please stop crashing its kinda annoyin, thanks!
		if (pressedEnter && !skippedIntro && initialized)
			skipIntro();

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>) {
		for (i in 0...textArray.length) {
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String) {
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText() {
		while (textGroup.members.length > 0) {
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit() {
		super.beatHit();

		logoBl.animation.play('bump');
		danceLeft = !danceLeft;

		if (danceLeft)
			gfDance.animation.play('danceRight');
		else
			gfDance.animation.play('danceLeft');

		// yes siree!
		if (beatMap.get(curBeat) != null) {
			parseSequenceEvent(beatMap.get(curBeat).call);
			ngSpr.visible = beatMap.get(curBeat).ngVisible;
		}
	}

	public override function stepHit():Void {
		super.stepHit();
		if (stepMap.get(curStep) != null) {
			parseSequenceEvent(stepMap.get(curStep).call);
			ngSpr.visible = stepMap.get(curStep).ngVisible;
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void {
		if (!skippedIntro) {
			remove(ngSpr);
			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			skippedIntro = true;
		}
	}

	public function parseSequenceEvent(event:String):Void {
		var wackyText:String = '';
		if (beatMap.get(curBeat) != null && beatMap.get(curBeat).text != null)
			wackyText = beatMap.get(curBeat).text;
		else if (stepMap.get(curStep) != null)
			wackyText = stepMap.get(curStep).text;

		return switch (event) {
			case "create": createCoolText(identifySequenceText(wackyText).split(", "));
			case "add": addMoreText(identifySequenceText(wackyText));
			case "delete": deleteCoolText();
			case "skip": skipIntro();
		}
	}

	public function identifySequenceText(text:String):String {
		return switch (text) {
			case "Title_firstRandom": curWacky[0];
			case "Title_secondRandom": curWacky[1];
			default: text;
		}
	}

	public function loadDefaultBeatSequence():Array<BeatHitData> {
		return [
			{call: "create", beat: 1, text: "ninjamuffin, phantomArcade, kawaisprite, evilsker"},
			{call: "add", beat: 3, text: 'present'},
			{call: "delete", beat: 4},
			{call: "create", beat: 5, text: "In association, with"},
			{
				call: "add",
				beat: 7,
				text: "newgrounds",
				ngVisible: true
			},
			{call: "delete", beat: 8, ngVisible: false},
			{call: "create", beat: 9, text: "Title_firstRandom"},
			{call: "add", beat: 11, text: "Title_secondRandom"},
			{call: "delete", beat: 12},
			{call: "add", beat: 13, text: "Friday"},
			{call: "add", beat: 14, text: "Night"},
			{call: "add", beat: 15, text: "Funkin"},
			{call: "skip", beat: 16}
		];
	}
}
