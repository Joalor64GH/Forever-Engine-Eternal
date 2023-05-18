package forever.data.utils;

import flixel.util.FlxColor;

/**
	Global FNF sprite utilities, all in one parent class!
	You'll be able to easily edit functions and such that are used by sprites
**/
class FNFSprite extends flixel.FlxSprite {
	public var animOffsets:Map<String, Array<Dynamic>>;

	public function new(x:Float = 0, y:Float = 0) {
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void {
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0) {
		animOffsets[name] = [x, y];
	}

	override public function loadGraphic(Graphic:flixel.system.FlxAssets.FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false,
			?Key:String):FNFSprite {
		return cast super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
	}

	// the rest is by Ne_Eo

	/**
	 * For performance issues, `makeSolid()` is preferable!
	 */
	override public function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FNFSprite {
        return cast super.makeGraphic(Width, Height, Color, Unique, Key);
    }

    /**
     * An optimized version of `makeGraphic()`
     */
    public function makeSolid(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FNFSprite {
        var graph:flixel.graphics.FlxGraphic = flixel.FlxG.bitmap.create(1, 1, Color, Unique, Key);
        frames = graph.imageFrame;
        scale.set(Width, Height);
        updateHitbox();
        return this;
    }

	/**
     * Set the visibility (`alpha`) of the sprite as a precentage.
	 * @param transparency The visibility percentage.
	 * @return `this` `FNFSprite`.
     */
	public function setTransparency(visibility:Float):FNFSprite {
		alpha = visibility / 100;
		return this;
	}

    public inline function hideFull() {
        alpha = 0;
    }

    public inline function hide() {
        alpha = Tools.invisibleAlpha;
    }
    public inline function show() {
        alpha = 1;
    }

	/**
	 * Executes "kill();" and "destroy();" at once
	 */
	public function free() {
		kill();
		destroy();
	}

	override public function destroy() {
		// dump cache stuffs
		if (graphic != null)
			graphic.dump();
		super.destroy();
	}
}