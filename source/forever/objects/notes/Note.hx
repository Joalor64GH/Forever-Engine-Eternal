package forever.objects.notes;

import forever.data.*;
import forever.data.utils.FNFSprite;
import forever.music.Conductor;
import forever.objects.notes.Strumline.Receptor;
import forever.states.PlayState;

class Note extends FNFSprite {
	public var prevNote:Note;

	public var timeStep:Float = 0;
	public var direction:Int = 0;
	public var type:String = "default";

	public var strumline:Int = 0;
	public var mustPress(get, never):Bool;

	function get_mustPress():Bool
		return strumline == 1;

	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;

	public var isSustain:Bool = false;
	public var sustainLength:Float = 0;
	public var downscroll:Bool = false;

	// not set initially
	public var noteQuant:Int = -1;
	public var noteVisualOffset:Float = 0;
	public var noteSpeed:Float = 0;
	public var noteDirection:Float = 0;
	public var noteAngle:Float = 0;

	public var parentNote:Note;
	public var childrenNotes:Array<Note> = [];

	public static var swagWidth:Float = 160 * 0.7;

	// it has come to this.
	public var endHoldOffset:Float = Math.NEGATIVE_INFINITY;

	public function new(timeStep:Float, direction:Int, type:String = "default", ?prevNote:Note, ?isSustain:Bool = false) {
		super(x, y);

		if (prevNote == null)
			prevNote = this;

		this.prevNote = prevNote;
		this.isSustain = isSustain;
		this.type = type;

		// oh okay I know why this exists now
		y -= 2000;

		this.timeStep = timeStep;
		this.direction = direction;

		// determine parent note
		if (isSustain && prevNote != null) {
			parentNote = prevNote;
			while (parentNote.parentNote != null)
				parentNote = parentNote.parentNote;
			parentNote.childrenNotes.push(this);
		}
		else if (!isSustain)
			parentNote = null;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (mustPress) {
			if (timeStep > Conductor.songPosition - (Timings.msThreshold) && timeStep < Conductor.songPosition + (Timings.msThreshold))
				canBeHit = true;
			else
				canBeHit = false;
		}
		else // make sure the note can't be hit if it's the dad's I guess
			canBeHit = false;

		if (tooLate || (parentNote != null && parentNote.tooLate))
			alpha = 0.3;
	}

	/**
		Note creation scripts

		these are for all your custom note needs
	**/
	public static function returnDefaultNote(assetStyle:String, timeStep:Float, direction:Int, noteType:String, ?isSustain:Bool = false,
			?prevNote:Note = null):Note {
		var newNote:Note = new Note(timeStep, direction, prevNote, isSustain);

		// frames originally go here
		switch (assetStyle) {
			case 'pixel': // pixel arrows default
				if (isSustain) {
					newNote.loadGraphic(Paths.image(Tools.returnSkinAsset('arrowEnds', assetStyle, Init.trueSettings.get("Note Skin"), 'noteskins/notes')),
						true, 7, 6);
					newNote.animation.add('purpleholdend', [4]);
					newNote.animation.add('greenholdend', [6]);
					newNote.animation.add('redholdend', [7]);
					newNote.animation.add('blueholdend', [5]);
					newNote.animation.add('purplehold', [0]);
					newNote.animation.add('greenhold', [2]);
					newNote.animation.add('redhold', [3]);
					newNote.animation.add('bluehold', [1]);
				}
				else {
					newNote.loadGraphic(Paths.image(Tools.returnSkinAsset('arrows-pixels', assetStyle, Init.trueSettings.get("Note Skin"),
						'noteskins/notes')), true, 17, 17);
					newNote.animation.add('greenScroll', [6]);
					newNote.animation.add('redScroll', [7]);
					newNote.animation.add('blueScroll', [5]);
					newNote.animation.add('purpleScroll', [4]);
				}
				newNote.antialiasing = false;
				newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
				newNote.updateHitbox();
			default: // base game arrows for no reason whatsoever
				newNote.frames = Paths.getSparrowAtlas(Tools.returnSkinAsset('NOTE_assets', assetStyle, Init.trueSettings.get("Note Skin"),
					'noteskins/notes'));
				newNote.animation.addByPrefix('purpleholdend', 'pruple end hold');
				newNote.animation.addByPrefix('greenScroll', 'green0');
				newNote.animation.addByPrefix('redScroll', 'red0');
				newNote.animation.addByPrefix('blueScroll', 'blue0');
				newNote.animation.addByPrefix('purpleScroll', 'purple0');
				newNote.animation.addByPrefix('purpleholdend', 'pruple end hold');
				newNote.animation.addByPrefix('greenholdend', 'green hold end');
				newNote.animation.addByPrefix('redholdend', 'red hold end');
				newNote.animation.addByPrefix('blueholdend', 'blue hold end');
				newNote.animation.addByPrefix('purplehold', 'purple hold piece');
				newNote.animation.addByPrefix('greenhold', 'green hold piece');
				newNote.animation.addByPrefix('redhold', 'red hold piece');
				newNote.animation.addByPrefix('bluehold', 'blue hold piece');
				newNote.setGraphicSize(Std.int(newNote.width * 0.7));
				newNote.updateHitbox();
				newNote.antialiasing = true;
		}
		//
		if (!isSustain)
			newNote.animation.play(Receptor.cols[direction] + 'Scroll');
		if (isSustain && prevNote != null) {
			newNote.noteSpeed = prevNote.noteSpeed;
			newNote.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
			newNote.animation.play(Receptor.cols[direction] + 'holdend');
			newNote.updateHitbox();
			if (prevNote.isSustain) {
				prevNote.animation.play(Receptor.cols[prevNote.direction] + 'hold');
				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * prevNote.noteSpeed;
				prevNote.updateHitbox();
			}
		}
		return newNote;
	}

	public static function returnQuantNote(assetStyle:String, timeStep:Float, direction:Int, type:String = "default", ?isSustain:Bool = false,
			?prevNote:Note = null):Note {
		var newNote:Note = new Note(timeStep, direction, type, prevNote, isSustain);

		// actually determine the quant of the note
		if (newNote.noteQuant == -1) {
			/*
				I have to credit like 3 different people for these LOL they were a hassle
				but its gede pixl and scarlett, thank you SO MUCH for baring with me
			 */
			final quantArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 192]; // different quants

			var curBPM:Float = Conductor.bpm;
			var newTime = timeStep;
			for (i in 0...Conductor.bpmChangeMap.length) {
				if (timeStep > Conductor.bpmChangeMap[i].songTime) {
					curBPM = Conductor.bpmChangeMap[i].bpm;
					newTime = timeStep - Conductor.bpmChangeMap[i].songTime;
				}
			}

			final beatTimeSeconds:Float = (60 / curBPM); // beat in seconds
			final beatTime:Float = beatTimeSeconds * 1000; // beat in milliseconds
			// assumed 4 beats per measure?
			final measureTime:Float = beatTime * 4;

			final smallestDeviation:Float = measureTime / quantArray[quantArray.length - 1];

			for (quant in 0...quantArray.length) {
				// please generate this ahead of time and put into array :)
				// I dont think I will im scared of those
				final quantTime = (measureTime / quantArray[quant]);
				if ((newTime #if !neko + Init.trueSettings['Offset'] #end + smallestDeviation) % quantTime < smallestDeviation * 2) {
					// here it is, the quant, finally!
					newNote.noteQuant = quant;
					break;
				}
			}
		}

		// note quants
		switch (assetStyle) {
			default:
				// inherit last quant if hold note
				if (isSustain && prevNote != null)
					newNote.noteQuant = prevNote.noteQuant;
				// base quant notes
				if (!isSustain) {
					// in case you're unfamiliar with these, they're ternary operators, I just dont wanna check for pixel notes using a separate statement
					var newNoteSize:Int = (assetStyle == 'pixel') ? 17 : 157;
					newNote.loadGraphic(Paths.image(Tools.returnSkinAsset('NOTE_quants', assetStyle, Init.trueSettings.get("Note Skin"), 'noteskins/notes',
						'quant')), true,
						newNoteSize, newNoteSize);

					newNote.animation.add('leftScroll', [0 + (newNote.noteQuant * 4)]);
					// LOL downscroll thats so funny to me
					newNote.animation.add('downScroll', [1 + (newNote.noteQuant * 4)]);
					newNote.animation.add('upScroll', [2 + (newNote.noteQuant * 4)]);
					newNote.animation.add('rightScroll', [3 + (newNote.noteQuant * 4)]);
				}
				else {
					// quant holds
					newNote.loadGraphic(Paths.image(Tools.returnSkinAsset('HOLD_quants', assetStyle, Init.trueSettings.get("Note Skin"), 'noteskins/notes',
						'quant')), true,
						(assetStyle == 'pixel') ? 17 : 109, (assetStyle == 'pixel') ? 6 : 52);
					newNote.animation.add('hold', [0 + (newNote.noteQuant * 4)]);
					newNote.animation.add('holdend', [1 + (newNote.noteQuant * 4)]);
					newNote.animation.add('rollhold', [2 + (newNote.noteQuant * 4)]);
					newNote.animation.add('rollend', [3 + (newNote.noteQuant * 4)]);
				}
				if (assetStyle == 'pixel') {
					newNote.antialiasing = false;
					newNote.setGraphicSize(Std.int(newNote.width * PlayState.daPixelZoom));
					newNote.updateHitbox();
				}
				else {
					newNote.setGraphicSize(Std.int(newNote.width * 0.7));
					newNote.updateHitbox();
					newNote.antialiasing = true;
				}
		}

		//
		if (!isSustain)
			newNote.animation.play(Receptor.dirs[direction] + 'Scroll');

		if (isSustain && prevNote != null) {
			newNote.noteSpeed = prevNote.noteSpeed;
			newNote.alpha = (Init.trueSettings.get('Opaque Holds')) ? 1 : 0.6;
			newNote.animation.play('holdend');
			newNote.updateHitbox();

			if (prevNote.isSustain) {
				prevNote.animation.play('hold');
				prevNote.scale.y *= Conductor.stepCrochet / 100 * (43 / 52) * 1.5 * prevNote.noteSpeed;
				prevNote.updateHitbox();
			}
		}

		return newNote;
	}
}
