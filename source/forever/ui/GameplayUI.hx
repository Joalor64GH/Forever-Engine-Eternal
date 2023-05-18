package forever.ui;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import forever.data.Timings;
import forever.music.Conductor;
import forever.states.PlayState;

class GameplayUI extends FlxTypedGroup<FlxBasic> {
	private final game = PlayState.current;

	public var scoreBar:FlxText;
	public var centerMark:FlxText; // song display name and difficulty at the center
	public var autoplayMark:FlxText; // autoplay indicator at the center
	public var autoplaySine:Float = 0;

	public var healthBarBG:FlxSprite;
	// public var timeBarBG:FlxSprite;
	public var healthBar:FlxBar;

	// public var timeBar:FlxBar;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	private var currentTime:Float = 0;
	private var centerMarkText:String;

	private var timingsMap:Map<String, FlxText> = [];

	var infoDisplay:String = Tools.dashToSpace(PlayState.current.curSong);
	var diffDisplay:String = forever.backend.LevelData.curDifficulties[PlayState.storyDifficulty];

	var downscroll:Bool = Init.trueSettings.get('Downscroll');

	public function new() {
		super();

		healthBarBG = new FlxSprite().loadGraphic(Tools.getUIAsset("healthBar", SkinManager.assetStyle, "images/UI"));
		healthBarBG.screenCenter(X).y = downscroll ? 64 : FlxG.height * 0.875;
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8));
		reloadHealthBar(false);
		add(healthBar);

		iconP1 = new HealthIcon(game.player.characterIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		add(iconP1);

		iconP2 = new HealthIcon(game.opponent.characterIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		add(iconP2);

		iconP1.boppingIcon = iconP2.boppingIcon = !Init.trueSettings.get('Reduced Movements');

		scoreBar = new FlxText(FlxG.width / 2, Math.floor(healthBarBG.y + 40), 0, '');
		scoreBar.setFormat(Paths.font('vcr'), 18, FlxColor.WHITE);
		scoreBar.setBorderStyle(OUTLINE, FlxColor.BLACK, 1.5);
		scoreBar.antialiasing = true;
		add(scoreBar);

		centerMark = new FlxText(0, (downscroll ? FlxG.height - 40 : 20), 0, centerMarkText = '- ${infoDisplay + " [" + diffDisplay}] -');
		centerMark.setFormat(Paths.font('vcr'), 24, FlxColor.WHITE);
		centerMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		centerMark.screenCenter(X);
		centerMark.antialiasing = true;
		centerMark.alpha = 0;

		/*if (Init.trueSettings.get('Song Timer'))
			{
				timeBarBG = new FlxSprite(centerMark.x - centerMark.width / 4 - 10, centerMark.y - centerMark.height / 4)
				.loadGraphic(Tools.getUIAsset("timebar", SkinManager.assetStyle, "images/UI"));
				timeBarBG.setGraphicSize(Std.int(centerMark.width * 1.5), Std.int(centerMark.height * 0.65));
				timeBarBG.updateHitbox();
				timeBarBG.alpha = 0;

				timeBar = new FlxBar(centerMark.x - centerMark.width / 4 - 10, centerMark.y - centerMark.height / 4, LEFT_TO_RIGHT,
					Std.int(centerMark.width * 1.5 + 20), Std.int(centerMark.height * 0.65 + 20));
				timeBar.createFilledBar(FlxColor.BLACK, FlxColor.LIME);
				timeBar.numDivisions = 400;
				timeBar.alpha = 0;
				add(timeBar);
				// add(timeBarBG);
		}*/

		add(centerMark);

		// counter
		if (Init.trueSettings.get('Counter') != 'None') {
			var judgeNames:Array<String> = [];
			for (i in Timings.judgementsMap.keys())
				judgeNames.insert(Timings.judgementsMap.get(i)[0], i);
			judgeNames.sort(function(a:String,
					b:String):Int return FlxSort.byValues(FlxSort.ASCENDING, Timings.judgementsMap.get(a)[0], Timings.judgementsMap.get(b)[0]));
			for (i in 0...judgeNames.length) {
				var textAsset:FlxText = new FlxText(5
					+ (!left ? (FlxG.width - 10) : 0),
					(FlxG.height / 2)
					- (counterTextSize * (judgeNames.length / 2))
					+ (i * counterTextSize), 0, '', counterTextSize);
				if (!left)
					textAsset.x -= textAsset.text.length * counterTextSize;
				textAsset.setFormat(Paths.font("vcr"), counterTextSize, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				timingsMap.set(judgeNames[i], textAsset);
				textAsset.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
				textAsset.antialiasing = true;
				add(textAsset);
			}
		}
		updateScoreText();

		autoplayMark = new FlxText(0, (downscroll ? centerMark.y - 60 : centerMark.y + 60), FlxG.width - 800, '[AUTOPLAY]\n', 32);
		autoplayMark.setFormat(Paths.font("vcr"), 32, FlxColor.WHITE, CENTER);
		autoplayMark.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		autoplayMark.screenCenter(X);
		autoplayMark.visible = game.playerStrums.autoplay;

		// repositioning for it to not be covered by the receptors
		if (Init.trueSettings.get('Centered Notefield'))
			autoplayMark.y = autoplayMark.y + (downscroll ? -125 : 125);

		add(autoplayMark);
	}

	var counterTextSize:Int = 20;

	var left = (Init.trueSettings.get('Counter') == 'Left');
	var healthLerp:Float = 0;

	override public function update(elapsed:Float) {
		super.update(elapsed);

		// pain, this is like the 7th attempt
		healthBar.percent = (game.health * 50);
		healthLerp = FlxMath.lerp(healthLerp, game.health, FlxMath.bound(elapsed * 20, 0, 1));

		if (healthLerp > 2)
			healthLerp = 2;

		var iconOffset:Int = 26;
		var percent:Float = 1 - (healthLerp / 2); // base game (0.3) smooth health (for the sake of having it)
		iconP1.x = healthBar.x + (healthBar.width * percent) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * percent) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		iconP1.updateAnim(healthBar.percent);
		iconP2.updateAnim(100 - healthBar.percent);

		if (autoplayMark.visible) {
			autoplaySine += 180 * (elapsed / 4);
			autoplayMark.alpha = 1 - Math.sin((Math.PI * autoplaySine) / 80);
		}

		if (Init.trueSettings.get('Song Timer')) {
			var realTime:Float = Conductor.songPosition - Init.trueSettings.get('Offset');
			// timeBar.percent = (realTime / game.songMusic.length) * 50;
			centerMark.text = FlxStringUtil.formatTime(Math.floor(realTime) / 1000, false)
				+ ' ${centerMarkText} '
				+ FlxStringUtil.formatTime(Math.floor(game.songMusic.length / 1000));
			centerMark.screenCenter(X);
		}
	}

	public var divider:String = " • ";

	public function updateScoreText() {
		var comboDisplay:String = (Timings.comboDisplay != null && Timings.comboDisplay != '' ? ' [${Timings.comboDisplay}]' : '');
		scoreBar.text = 'Score: ${game.songScore}';
		if (Init.trueSettings.get('Display Accuracy')) {
			if (Init.trueSettings.get('Counter') == 'None')
				scoreBar.text += divider + 'Misses: ${game.misses + comboDisplay}';
			scoreBar.text += divider + 'Accuracy: ${Math.floor(Timings.trueAccuracy * 100) / 100}%';
			scoreBar.text += divider + 'Rank: ${Timings.ratingFinal}';
		}
		scoreBar.text += '\n';
		scoreBar.screenCenter(X);

		// update counter
		if (Init.trueSettings.get('Counter') != 'None') {
			for (i in timingsMap.keys()) {
				timingsMap[i].text = '${(i.charAt(0).toUpperCase() + i.substring(1, i.length))}: ${Timings.gottenJudgements.get(i)}';
				timingsMap[i].x = (5 + (!left ? (FlxG.width - 10) : 0) - (!left ? (6 * counterTextSize) : 0));
			}
		}

		// update playstate
		game.detailsSub = scoreBar.text;
		game.updateRPC(false);
	}

	public function reloadHealthBar(changeIcons:Bool = false):Void {
		healthBar.createFilledBar(game.opponent.healthColor, game.player.healthColor);
		if (changeIcons) {
			iconP1.changeIcon(game.player.characterIcon, true);
			iconP2.changeIcon(game.opponent.characterIcon);
		}
	}

	public function beatHit() {
		if (!Init.trueSettings.get('Reduced Movements')) {
			iconP1.bop();
			iconP2.bop();
		}
	}
}
