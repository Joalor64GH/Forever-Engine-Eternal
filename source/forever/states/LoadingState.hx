package forever.states;

/*import forever.objects.StageBuilder;
import forever.objects.Character;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxBackdrop;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import openfl.media.Sound;
import sys.thread.FixedThreadPool;
import sys.thread.Mutex;

using StringTools;

class LoadingState extends forever.music.MusicBeat.MusicBeatState
{
	public static var characters:Map<String, Character> = [];
	public static var stage:StageBuilder;
	public static var songMusic:Sound;
	public static var vocals:Sound;
	public static var __THREADPOOL:FixedThreadPool;
	public static var __MUTEX:Mutex;
	var playState:PlayState;
	
	public static var time:Int = 0;
	var isTransitioning:Bool = false;
	var curLoaded:Int = 0;
	var loadingIndex:Int = 6;

	var loadingText:FlxText;
	var loadingSprite:FlxSprite;
    
	public override function new(chartingMode:Bool)
	{
		playState = new PlayState(chartingMode);
		__THREADPOOL = new FixedThreadPool(8);
		__MUTEX = new Mutex();
		super();
	}

	override function create():Void
	{
		super.create();
		time = openfl.Lib.getTimer();

		Conductor.songPosition = 0;
		Conductor.changeBPM(126);

		var curColor = FlxG.random.getObject([ // if only FlxColor.getRandomColor() would be a thing
			FlxColor.RED, FlxColor.ORANGE, FlxColor.YELLOW, FlxColor.GREEN, FlxColor.LIME,
			FlxColor.BLUE, FlxColor.CYAN, FlxColor.MAGENTA, FlxColor.PURPLE, FlxColor.PINK
		]);
		
		var backdropShit = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [curColor, FlxColor.BLACK]);
		add(backdropShit);
		
		var backdrop = new FlxBackdrop(Paths.image("menus/grid"));
		backdrop.velocity.set(-100, -100);
		backdrop.color = curColor;
		add(backdrop);

		loadingSprite = new FlxSprite().loadGraphic(CacheManager.getPersistentAsset("LOADING").data);
		loadingSprite.antialiasing = true;
		loadingSprite.angle = Math.random() * 360;
		loadingSprite.angularVelocity = 360;
		loadingSprite.setPosition(FlxG.width - 128, FlxG.height - 128);
		add(loadingSprite);

		var char = new FlxSprite(2000).loadGraphic(getRandomLoadingCharacter());
		char.antialiasing = true;
		char.screenCenter(Y);
		add(char);
		FlxTween.tween(char, {x: (FlxG.width - char.width) / 2}, 0.7, {ease: flixel.tweens.FlxEase.cubeInOut});

		var loadingBar = new FlxBar(0, 0, LEFT_TO_RIGHT, FlxG.width, 20, this, 'curLoaded', 0, loadingIndex);
		loadingBar.setPosition(FlxG.width - loadingBar.width, FlxG.height - loadingBar.height);
		loadingBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		add(loadingBar);

		loadingText = new FlxText(0, loadingBar.y - 50, 0, "Loading").setFormat(Paths.font("vcr.ttf"), 45, curColor);
		loadingText.screenCenter(X);
		add(loadingText);

		gameObjects.userInterface.notes.Note.loadNotetypes();
		for (task in [loadCharacters, loadStage, loadAudios]) // using a loop might be better than running everything seperatly
			__THREADPOOL.run(task);
		
		trace("Loading...");
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		Conductor.songPosition += elapsed * 1000;

		if (curLoaded == loadingIndex)
		{
			if (isTransitioning) return;

			trace("Done loading!");
			for (obj in [loadingText, loadingSprite])
				FlxTween.tween(obj, {alpha: 0}, 0.2);
			Conductor.songPosition = 0;
			isTransitioning = true;
			Main.switchState(playState);
		}
	}

	var curPoint:Int = 0;
	override function beatHit()
	{
		super.beatHit();
		
		curPoint++;

		if (curPoint == 4)
			curPoint = 0;

		loadingText.text = "Loading";
		for (i in 0...curPoint)
			loadingText.text += ".";

		loadingText.screenCenter(X);
	}

    function loadCharacters()
    {
		__MUTEX.acquire();
        for (char in ["boyfriend", "dadOpponent", "gf"])
        {
			trace('Loading $char...');

			switch (char)
			{
				case "dadOpponent": characters[char] = new Character().setCharacter(50, 850, PlayState.SONG.player2);
				case "boyfriend":
					characters[char] = new Boyfriend();
					characters[char].setCharacter(750, 850, PlayState.SONG.player1);
					loadGameOver();
				case "gf":
					characters[char] = new Character();
					characters[char].adjustPos = false;
					characters[char].setCharacter(300, 100, PlayState.SONG.gfVersion);
					characters[char].scrollFactor.set(0.95, 0.95);
            }

			curLoaded++;
		}
		__MUTEX.release();
    }

	function loadGameOver()
	{
		// __MUTEX.acquire();
		characters["bf-dead"] = new Boyfriend();
		characters["bf-dead"].setCharacter(0, 0, characters["boyfriend"].characterData.deathCharacter);
		GameOverSubstate.setVariables(characters["boyfriend"], characters["bf-dead"]);
		curLoaded++;
		// __MUTEX.release();
	}

	function loadStage()
	{
		// __MUTEX.acquire();
		trace('Loading Stage...');
		stage = new Stage(PlayState.SONG.stage, PlayState.current); // ok i think that should be good?
		curLoaded++;
		// __MUTEX.release();
	}

	function loadAudios()
	{
		// __MUTEX.acquire();
		songMusic = Paths.inst(PlayState.SONG.song);
		if (PlayState.SONG.needsVoices)
			vocals = Paths.voices(PlayState.SONG.song);
		curLoaded++;
		// __MUTEX.release();
	}

	function getRandomLoadingCharacter()
	{
		var loadingChars = [];
		var path = "assets/images/menus/loading";
		for (asset in sys.FileSystem.readDirectory(path))
		{
			if (!asset.contains("loading-circle.png"))
				loadingChars.push(asset);
		}

		if (loadingChars.length == 0)
			return path + "/loading-circle.png";

		return path + "/" + FlxG.random.getObject(loadingChars);
	}
}*/