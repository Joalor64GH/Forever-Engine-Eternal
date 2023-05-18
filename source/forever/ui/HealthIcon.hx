package forever.ui;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import sys.FileSystem;

class HealthIcon extends FlxSprite {
	// rewrite using da new icon system as ninjamuffin would say it
	public var sprTracker:FlxSprite;
	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;
	public var boppingIcon:Bool = false;
	public var lerp:Float = 0.85;

	public function new(char:String = 'bf', isPlayer:Bool = false) {
		super();
		changeIcon(char, isPlayer);
	}

	public function changeIcon(char:String = 'bf', isPlayer:Bool = false) {
		var trimmedCharacter:String = char;
		if (trimmedCharacter.contains('-'))
			trimmedCharacter = trimmedCharacter.substring(0, trimmedCharacter.indexOf('-'));

		var iconPath:String = char;
		if (!FileSystem.exists(Paths.getPath('images/icons/${iconPath}.png', IMAGE))) {
			if (iconPath != trimmedCharacter && FileSystem.exists(Paths.getPath('images/icons/${trimmedCharacter}.png', IMAGE)))
				iconPath = trimmedCharacter;
			else
				iconPath = 'face';
		}

		antialiasing = true;
		var iconGraphic:FlxGraphic = Paths.image('icons/${iconPath}');
		loadGraphic(iconGraphic, true, Std.int(iconGraphic.width / 2), iconGraphic.height);

		initialWidth = width;
		initialHeight = height;

		animation.add('icon', [0, 1], 0, false, isPlayer);
		animation.play('icon');
		scrollFactor.set();
	}

	public dynamic function updateAnim(health:Float) {
		if (health < 20)
			animation.curAnim.curFrame = 1;
		else
			animation.curAnim.curFrame = 0;
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);

		if (boppingIcon) {
			setGraphicSize(Std.int(flixel.math.FlxMath.lerp(initialWidth, width, lerp)));
			updateHitbox();
		}
	}

	public function bop() {
		if (boppingIcon) {
			setGraphicSize(Std.int(width + 30));
			updateHitbox();
		}
	}
}
