package forever.shaders;

import flixel.FlxG;
import openfl.display.Sprite;

/**
 * Fixes for shader coords when resizing the window
 * @author Sword352, original by Ne_Eo
 */
@:allow(Init)
class ShaderCoordsFix {
	static function init() {
		FlxG.signals.gameResized.add(onGameResized);
	}

	static function onGameResized(gameWidth:Int, gameHeight:Int) // we dont need to use the arguments
	{
		if (FlxG.cameras != null) {
			for (cam in FlxG.cameras.list) {
				@:privateAccess
				if (cam != null && (cam._filters != null || cam._filters != []))
					fixShaderSize(cam.flashSprite);
			}
		}

		if (FlxG.game != null)
			fixShaderSize(FlxG.game);
	}

	static function fixShaderSize(sprite:Sprite) // Code by Ne_Eo
	{
		@:privateAccess
		{
			if (sprite != null) {
				sprite.__cacheBitmap = null;
				sprite.__cacheBitmapData = null;
				sprite.__cacheBitmapData2 = null;
				sprite.__cacheBitmapData3 = null;
				sprite.__cacheBitmapColorTransform = null;
			}
		}
	}
}
