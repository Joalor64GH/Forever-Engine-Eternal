package forever.objects.notes;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxSort;
import forever.data.utils.FNFSprite;
import forever.music.Conductor;

class Receptor extends FNFSprite {
	public static final dirs:Array<String> = ['left', 'down', 'up', 'right'];
	public static final cols:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var receptorDirection:Int = 0;
	public var canFinishAnimation:Bool = true;

	public var initialX:Int;
	public var initialY:Int;

	public var xTo:Float;
	public var yTo:Float;
	public var angleTo:Float;

	public var setAlpha:Float = (Init.trueSettings.get('Opaque Arrows')) ? 1 : 0.8;

	public function new(x:Float, y:Float, ?receptorDirection:Int = 0) {
		// this extension is just going to rely a lot on preexisting code as I wanna try to write an extension before I do options and stuff
		super(x, y);

		this.receptorDirection = receptorDirection;

		updateHitbox();
		scrollFactor.set();
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		alpha = AnimName == 'confirm' ? 1 : setAlpha;
		super.playAnim(AnimName, Force, Reversed, Frame);
		centerOrigin();
	}
}

class Strumline extends FlxTypedGroup<FlxBasic> {
	public var receptors:FlxTypedGroup<Receptor>;
	public var splashNotes:FlxTypedGroup<FNFSprite>;
	public var notesGroup:FlxTypedGroup<Note>;
	public var holdsGroup:FlxTypedGroup<Note>;
	public var allNotes:FlxTypedGroup<Note>;

	public var autoplay:Bool = true;
	public var displayJudgements:Bool = false;
	public var character:Character;

	public function new(x:Float = 0, y:Float = 0, ?character:Character, ?displayJudgements:Bool = true, ?autoplay:Bool = true, ?keyAmount:Int = 4,
			?parent:Strumline) {
		super();

		receptors = new FlxTypedGroup<Receptor>();
		if (!Init.trueSettings.get('Disable Note Splashes'))
			splashNotes = new FlxTypedGroup<FNFSprite>();
		notesGroup = new FlxTypedGroup<Note>();
		holdsGroup = new FlxTypedGroup<Note>();
		allNotes = new FlxTypedGroup<Note>();

		this.autoplay = autoplay;
		this.character = character;
		this.displayJudgements = displayJudgements;

		for (i in 0...keyAmount) {
			var receptor:Receptor = SkinManager.generateUIArrows(x, y, i);
			receptor.ID = i;

			receptor.x -= ((keyAmount / 2) * Note.swagWidth);
			receptor.x += (Note.swagWidth * i);
			receptors.add(receptor);

			receptor.initialX = Math.floor(receptor.x);
			receptor.initialY = Math.floor(receptor.y);
			receptor.angleTo = 0;
			receptor.y -= 10;
			receptor.playAnim('static');

			receptor.alpha = 0;
			FlxTween.tween(receptor, {y: receptor.initialY, alpha: receptor.setAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			if (splashNotes != null)
				popSplash(i, true);
		}

		add(holdsGroup);
		add(receptors);
		add(notesGroup);
		if (splashNotes != null)
			add(splashNotes);
	}

	public function popSplash(id:Int, preload:Bool = false) {
		var noteSplash:FNFSprite = splashNotes.recycle(FNFSprite, function() return SkinManager.generateNoteSplashes('noteSplashes', 'noteskins/notes', id, preload));
		noteSplash.x = receptors.members[id].x - 55;
		noteSplash.y = receptors.members[id].y + (Note.swagWidth / 6) - 40;
		noteSplash.playAnim('anim' + FlxG.random.int(1, 2), true);
		splashNotes.add(noteSplash);
	}

	public function push(newNote:Note) {
		var chosenGroup = (newNote.isSustain ? holdsGroup : notesGroup);
		chosenGroup.add(newNote);
		allNotes.add(newNote);
		chosenGroup.sort(FlxSort.byY, (!newNote.downscroll) ? FlxSort.DESCENDING : FlxSort.ASCENDING);
	}

	public override function update(elapsed:Float):Void {
		allNotes.forEachAlive(function(daNote:Note) {
			if (daNote == null) {
				if (daNote.exists)
					destroyNote(daNote);
				return;
			}

			// set the notes x and y
			var downscrollMultiplier = daNote.downscroll ? -1 : 1;
			var roundedSpeed = FlxMath.roundDecimal(daNote.noteSpeed, 2);
			var receptorPosY:Float = receptors.members[daNote.direction].y + Note.swagWidth / 6;
			var psuedoY:Float = (downscrollMultiplier * -((Conductor.songPosition - daNote.timeStep) * (0.45 * roundedSpeed)));
			var psuedoX = 25 + daNote.noteVisualOffset;

			daNote.y = receptorPosY
				+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY)
				+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX);
			daNote.centerOverlay(receptors.members[daNote.direction], X);

			// also set note rotation
			daNote.angle = -daNote.noteDirection;

			// shitty note hack I hate it so much
			var center:Float = receptorPosY + Note.swagWidth / 2;
			if (daNote.isSustain) {
				daNote.y -= ((daNote.height / 2) * downscrollMultiplier);
				if ((daNote.animation.curAnim.name.endsWith('holdend')) && (daNote.prevNote != null)) {
					daNote.y -= ((daNote.prevNote.height / 2) * downscrollMultiplier);
					if (daNote.downscroll) {
						daNote.y += (daNote.height * 2);
						if (daNote.endHoldOffset == Math.NEGATIVE_INFINITY)
							daNote.endHoldOffset = (daNote.prevNote.y - (daNote.y + daNote.height));
						else
							daNote.y += daNote.endHoldOffset;
					}
					else // this system is funny like that
						daNote.y += ((daNote.height / 2) * downscrollMultiplier);
				}

				if (daNote.downscroll) {
					daNote.flipY = true;
					if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
						&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
						&& (autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))) {
						var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
						swagRect.height = (center - daNote.y) / daNote.scale.y;
						swagRect.y = daNote.frameHeight - swagRect.height;
						daNote.clipRect = swagRect;
					}
				}
				else {
					if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
						&& daNote.y + daNote.offset.y * daNote.scale.y <= center
						&& (autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit)))) {
						var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						swagRect.y = (center - daNote.y) / daNote.scale.y;
						swagRect.height -= swagRect.y;
						daNote.clipRect = swagRect;
					}
				}
			}

			// check where the note is and make sure it is either active or inactive
			daNote.active = daNote.y < FlxG.height;
			daNote.visible = daNote.y < FlxG.height;

			// if the note is off screen (above)
			if ((((!daNote.downscroll) && (daNote.y < -daNote.height))
				|| ((daNote.downscroll) && (daNote.y > (FlxG.height + daNote.height))))
				&& (daNote.tooLate || daNote.wasGoodHit))
				destroyNote(daNote);
		});

		super.update(elapsed);
	}

	public function destroyNote(daNote:Note) {
		daNote.active = false;
		daNote.exists = false;

		var chosenGroup = (daNote.isSustain ? holdsGroup : notesGroup);
		// note damage here I guess
		daNote.kill();
		if (allNotes.members.contains(daNote))
			allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}
}
