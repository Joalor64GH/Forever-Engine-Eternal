package forever.data.utils;

import flixel.system.FlxAssets.FlxGraphicAsset;
import openfl.geom.ColorTransform;
import flixel.util.FlxColor;

/**
 * Makes a sprite with an outline
 * @author Ne_Eo
 */
class FNFOutlineSprite extends FNFSprite
{
    /**
     * The outline size.
     * It is not recommended to set it as a float!
     */
    public var outline:Float = 0;

    /**
     * The outline color
     */
    public var outlineColor:FlxColor = 0;

    override function draw() {
        // getting the sprite's position for later
        var oldX = x;
        var oldY = y;

        if (outline != 0) {
            // getting the original variables values
            var orig = colorTransform;
            var oldShader = shader;

            // modifying some of this sprite's properties
            shader = null;
            colorTransform = new ColorTransform();
            colorTransform.color = outlineColor;

            // drawing the outline
            x = oldX;
            y = oldY - outline;
            super.draw();
            x = oldX - outline;
            y = oldY;
            super.draw();
            x = oldX + outline;
            y = oldY;
            super.draw();
            x = oldX;
            y = oldY + outline;
            super.draw();

            // drawing the outline corners
            x = oldX + outline;
            y = oldY + outline;
            super.draw();
            x = oldX - outline;
            y = oldY - outline;
            super.draw();
            x = oldX - outline;
            y = oldY + outline;
            super.draw();
            x = oldX + outline;
            y = oldY - outline;
            super.draw();

            // and setting the original properties
            colorTransform = orig;
            shader = oldShader;
            x = oldX;
            y = oldY;
        }
        // outline done
        super.draw();
        x = oldX;
        y = oldY;
    }

    /**
     * Quickly set the required variables for the outline.
     * @param OutlineSize The size of the outline. It is not recommended to set it as a float!
     * @param OutlineColor The color of the outline.
     * @return `this` `FNFOutlineSprite`.
     */
    public function setOutline(OutlineSize:Float, OutlineColor:FlxColor):FNFOutlineSprite {
        outline = OutlineSize;
        outlineColor = OutlineColor;
        return this;
    }

    override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String):FNFOutlineSprite {
        return cast super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
    }

    override public function makeGraphic(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FNFOutlineSprite {
        return cast super.makeGraphic(Width, Height, Color, Unique, Key);
    }

    override public function makeSolid(Width:Int, Height:Int, Color:FlxColor = FlxColor.WHITE, Unique:Bool = false, ?Key:String):FNFOutlineSprite {
        return cast super.makeSolid(Width, Height, Color, Unique, Key);
    }
}
