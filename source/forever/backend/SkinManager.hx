package forever.backend;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import forever.data.utils.FNFSprite;
import forever.data.Timings;
import forever.music.Conductor;
import forever.music.Song.SwagSection;
import forever.objects.menu.*;
import forever.objects.notes.*;
import forever.objects.notes.Strumline.Receptor;
import forever.states.PlayState;
import forever.ui.*;

/**
	SkinManager is a class that manages the different asset types, basically a compilation of switch statements that are
	easy to edit for your own needs. Most of these are just static functions that return information
**/
class SkinManager {
	public static var assetStyle:String = "base";
	public static var activeSkin:String = "default";

	public static function generateCombo(number:String, allSicks:Bool, negative:Bool, createdColor:FlxColor, scoreInt:Int):FlxSprite {
		var width = 100;
		var height = 140;

		if (assetStyle == 'pixel') {
			width = 10;
			height = 12;
		}
		var newSprite:FlxSprite = new FlxSprite().loadGraphic(Tools.getUIAsset('combo', assetStyle, 'images/UI'), true, width, height);
		switch (assetStyle) {
			default:
				newSprite.alpha = 1;
				newSprite.screenCenter();
				newSprite.x += (43 * scoreInt) + 20;
				newSprite.y += 60;

				newSprite.color = FlxColor.WHITE;
				if (negative)
					newSprite.color = createdColor;
				newSprite.antialiasing = assetStyle != 'pixel';

				newSprite.animation.add('base', [
					(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!allSicks ? 0 : 11)
				], 0, false);
				newSprite.animation.play('base');
		}

		if (assetStyle == 'pixel')
			newSprite.setGraphicSize(Std.int(newSprite.width * PlayState.daPixelZoom));
		else {
			newSprite.antialiasing = true;
			newSprite.setGraphicSize(Std.int(newSprite.width * 0.5));
		}
		newSprite.updateHitbox();
		if (!Init.trueSettings.get('Simply Judgements')) {
			newSprite.acceleration.y = FlxG.random.int(200, 300);
			newSprite.velocity.y = -FlxG.random.int(140, 160);
			newSprite.velocity.x = FlxG.random.float(-5, 5);
		}

		return newSprite;
	}

	public static function generateRating(ratingName:String, perfectSick:Bool, lateHit:Bool):FlxSprite {
		var width = 500;
		var height = 163;
		if (assetStyle == 'pixel') {
			width = 72;
			height = 32;
		}
		var rating:FlxSprite = new FlxSprite().loadGraphic(Tools.getUIAsset('judgements', assetStyle, 'images/UI'), true, width, height);
		switch (assetStyle) {
			default:
				rating.alpha = 1;
				rating.screenCenter();
				rating.x = (FlxG.width * 0.55) - 40;
				rating.y -= 60;
				if (!Init.trueSettings.get('Simply Judgements')) {
					rating.acceleration.y = 550;
					rating.velocity.y = -FlxG.random.int(140, 175);
					rating.velocity.x = -FlxG.random.int(0, 10);
				}
				rating.antialiasing = assetStyle != 'pixel';
				rating.animation.add(ratingName, [
					Std.int((Timings.judgementsMap.get(ratingName)[0] * 2) + (perfectSick ? 0 : 2) + (lateHit ? 1 : 0))
				], 24, false);
				rating.animation.play(ratingName);
		}

		if (assetStyle == 'pixel')
			rating.setGraphicSize(Std.int(rating.width * PlayState.daPixelZoom * 0.7));
		else {
			rating.antialiasing = true;
			rating.setGraphicSize(Std.int(rating.width * 0.7));
		}

		return rating;
	}

	public static function generateNoteSplashes(asset:String, baseLibrary:String, direction:Int, preload:Bool = false):FNFSprite {
		var tempSplash:FNFSprite = new FNFSprite();
		switch (assetStyle) {
			case 'pixel':
				tempSplash.loadGraphic(Paths.image(Tools.returnSkinAsset('splash-pixel', assetStyle, activeSkin, baseLibrary)), true, 34, 34);
				tempSplash.animation.add('anim1', [direction, 4 + direction, 8 + direction, 12 + direction], 24, false);
				tempSplash.animation.add('anim2', [16 + direction, 20 + direction, 24 + direction, 28 + direction], 24, false);
				tempSplash.animation.play('anim1');
				tempSplash.addOffset('anim1', -120, -90);
				tempSplash.addOffset('anim2', -120, -90);
				tempSplash.setGraphicSize(Std.int(tempSplash.width * PlayState.daPixelZoom));
				tempSplash.antialiasing = false;

			default:
				tempSplash.loadGraphic(Paths.image(Tools.returnSkinAsset('noteSplashes', assetStyle, activeSkin, baseLibrary)), true, 210, 210);
				tempSplash.animation.add('anim1', [
					(direction * 2 + 1),
					8 + (direction * 2 + 1),
					16 + (direction * 2 + 1),
					24 + (direction * 2 + 1),
					32 + (direction * 2 + 1)
				], 24, false);
				tempSplash.animation.add('anim2', [
					(direction * 2),
					8 + (direction * 2),
					16 + (direction * 2),
					24 + (direction * 2),
					32 + (direction * 2)
				], 24, false);
				tempSplash.addOffset('anim1', -20, -10);
				tempSplash.addOffset('anim2', -20, -10);
		}

		tempSplash.alpha = preload ? 0.0000001 : 1;
		tempSplash.animation.play('anim1');
		tempSplash.animation.finishCallback = function(n:String) tempSplash.alpha = 0;
		return tempSplash;
	}

	public static function generateUIArrows(x:Float, y:Float, ?receptorType:Int = 0):Receptor {
		var newReceptor:Receptor = new Receptor(x, y, receptorType);
		switch (assetStyle) {
			case 'pixel':
				// look man you know me I fucking hate repeating code
				// not even just a cleanliness thing it's just so annoying to tweak if something goes wrong like
				// genuinely more programmers should make their code more modular
				var framesArgument:String = "arrows-pixels";
				newReceptor.loadGraphic(Paths.image(Tools.returnSkinAsset('${framesArgument}', assetStyle, Init.trueSettings.get("Note Skin"),
					'noteskins/notes')), true, 17, 17);
				newReceptor.animation.add('static', [receptorType]);
				newReceptor.animation.add('pressed', [4 + receptorType, 8 + receptorType], 12, false);
				newReceptor.animation.add('confirm', [12 + receptorType, 16 + receptorType], 24, false);

				newReceptor.setGraphicSize(Std.int(newReceptor.width * PlayState.daPixelZoom));
				newReceptor.updateHitbox();
				newReceptor.antialiasing = false;

				newReceptor.addOffset('static', -67, -50);
				newReceptor.addOffset('pressed', -67, -50);
				newReceptor.addOffset('confirm', -67, -50);

			case 'chart editor':
				newReceptor.loadGraphic(Paths.image('UI/forever/base/chart editor/note_array'), true, 157, 156);
				newReceptor.animation.add('static', [receptorType]);
				newReceptor.animation.add('pressed', [16 + receptorType], 12, false);
				newReceptor.animation.add('confirm', [4 + receptorType, 8 + receptorType, 16 + receptorType], 24, false);

				newReceptor.addOffset('static');
				newReceptor.addOffset('pressed');
				newReceptor.addOffset('confirm');

			default:
				// probably gonna revise this and make it possible to add other arrow types but for now it's just pixel and normal
				var stringSect:String = Receptor.dirs[receptorType];
				var framesArgument:String = "NOTE_assets";

				newReceptor.frames = Paths.getSparrowAtlas(Tools.returnSkinAsset('${framesArgument}', assetStyle, Init.trueSettings.get("Note Skin"),
					'noteskins/notes'));

				newReceptor.animation.addByPrefix('static', 'arrow' + stringSect.toUpperCase());
				newReceptor.animation.addByPrefix('pressed', stringSect + ' press', 24, false);
				newReceptor.animation.addByPrefix('confirm', stringSect + ' confirm', 24, false);

				newReceptor.antialiasing = true;
				newReceptor.setGraphicSize(Std.int(newReceptor.width * 0.7));

				// set little offsets per note!
				// so these had a little problem honestly and they make me wanna off(set) myself so the middle notes basically
				// have slightly different offsets than the side notes (which have the same offset)

				var offsetMiddleX = 0;
				var offsetMiddleY = 0;
				if (receptorType > 0 && receptorType < 3) {
					offsetMiddleX = 2;
					offsetMiddleY = 2;
					if (receptorType == 1) {
						offsetMiddleX -= 1;
						offsetMiddleY += 2;
					}
				}
				newReceptor.addOffset('static');

				newReceptor.addOffset('pressed', -2, -2);
				newReceptor.addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
		}

		return newReceptor;
	}

	/**
		Notes!
	**/
	public static function generateArrow(timeStep:Float, direction:Int, type:String, ?isSustain:Bool = false, ?prevNote:Note = null):Note {
		var newNote:Note;
		var activeSkin:String = Init.trueSettings.get("Note Skin");
		// gonna improve the system eventually
		if (activeSkin.startsWith('quant'))
			newNote = Note.returnQuantNote(assetStyle, timeStep, direction, type, isSustain, prevNote);
		else
			newNote = Note.returnDefaultNote(assetStyle, timeStep, direction, type, isSustain, prevNote);

		// hold note shit
		if (isSustain && prevNote != null) {
			// set note offset
			if (prevNote.isSustain)
				newNote.noteVisualOffset = prevNote.noteVisualOffset;
			else // calculate a new visual offset based on that note's width and newnote's width
				newNote.noteVisualOffset = ((prevNote.width / 2) - (newNote.width / 2));
		}

		return newNote;
	}

	/**
		Checkmarks!
	**/
	public static function generateCheckmark(x:Float, y:Float, asset:String) {
		var newCheckmark:Checkmark = new Checkmark(x, y);
		switch (assetStyle) {
			default:
				newCheckmark.frames = Paths.getSparrowAtlas('UI/base/${asset}');
				newCheckmark.antialiasing = true;

				newCheckmark.animation.addByPrefix('false finished', 'uncheckFinished');
				newCheckmark.animation.addByPrefix('false', 'uncheck', 12, false);
				newCheckmark.animation.addByPrefix('true finished', 'checkFinished');
				newCheckmark.animation.addByPrefix('true', 'check', 12, false);

				// for week 7 assets when they decide to exist
				// animation.addByPrefix('false', 'Check Box unselected', 24, true);
				// animation.addByPrefix('false finished', 'Check Box unselected', 24, true);
				// animation.addByPrefix('true finished', 'Check Box Selected Static', 24, true);
				// animation.addByPrefix('true', 'Check Box selecting animation', 24, false);
				newCheckmark.setGraphicSize(Std.int(newCheckmark.width * 0.7));
				newCheckmark.updateHitbox();

				///*
				var offsetByX = 45;
				var offsetByY = 5;
				newCheckmark.addOffset('false', offsetByX, offsetByY);
				newCheckmark.addOffset('true', offsetByX, offsetByY);
				newCheckmark.addOffset('true finished', offsetByX, offsetByY);
				newCheckmark.addOffset('false finished', offsetByX, offsetByY);
				// */

				// addOffset('true finished', 17, 37);
				// addOffset('true', 25, 57);
				// addOffset('false', 2, -30);
		}
		return newCheckmark;
	}
}
