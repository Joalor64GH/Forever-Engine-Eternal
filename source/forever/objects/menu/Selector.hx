package forever.objects.menu;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import forever.data.utils.FNFSprite;
import forever.ui.Alphabet;

class Selector extends FlxTypedSpriteGroup<FlxSprite> {
	//
	var leftSelector:FNFSprite;
	var rightSelector:FNFSprite;

	public var optionChosen:Alphabet;
	public var chosenOptionString:String = '';
	public var options:Array<String>;

	public var fpsCap:Bool = false;
	public var darkBG:Bool = false;

	public function new(x:Float = 0, y:Float = 0, word:String, options:Array<String>, fpsCap:Bool = false, darkBG:Bool = false) {
		// call back the function
		super(x, y);

		this.options = options;

		// oops magic numbers
		var shiftX = 48;
		var shiftY = 35;
		// generate multiple pieces

		this.fpsCap = fpsCap;
		this.darkBG = darkBG;

		leftSelector = createSelector(shiftX, shiftY, word, 'left');
		rightSelector = createSelector(shiftX + ((word.length) * 50) + (shiftX / 4) + ((fpsCap) ? 20 : 0), shiftY, word, 'right');

		add(leftSelector);
		add(rightSelector);

		chosenOptionString = Init.trueSettings.get(word);
		if (fpsCap || darkBG) {
			chosenOptionString = Std.string(Init.trueSettings.get(word));
			optionChosen = new Alphabet(FlxG.width / 2 + 200, shiftY + 20, chosenOptionString, false, false);
		}
		else
			optionChosen = new Alphabet(FlxG.width / 2, shiftY + 20, chosenOptionString, true, false);

		add(optionChosen);
	}

	public function createSelector(objectX:Float = 0, objectY:Float = 0, word:String, dir:String):FNFSprite {
		var returnSelector = new FNFSprite(objectX, objectY);
		returnSelector.frames = Paths.getSparrowAtlas('menus/storymenu/campaign_menu_UI_assets');

		returnSelector.animation.addByPrefix('idle', 'arrow ${dir}', 24, false);
		returnSelector.animation.addByPrefix('press', 'arrow push ${dir}', 24, false);
		returnSelector.addOffset('press', 0, -10);
		returnSelector.playAnim('idle');

		return returnSelector;
	}

	override public function update(elapsed:Float) {
		super.update(elapsed);
		for (object in 0...objectArray.length)
			objectArray[object].setPosition(x + positionLog[object][0], y + positionLog[object][1]);
	}

	public function selectorPlay(whichSelector:String, animPlayed:String = 'idle') {
		switch (whichSelector) {
			case 'left':
				leftSelector.playAnim(animPlayed);
			case 'right':
				rightSelector.playAnim(animPlayed);
		}
	}

	var objectArray:Array<FlxSprite> = [];
	var positionLog:Array<Array<Float>> = [];

	override public function add(object:FlxSprite):FlxSprite {
		objectArray.push(object);
		positionLog.push([object.x, object.y]);
		return super.add(object);
	}
}
