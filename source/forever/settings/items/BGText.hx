package forever.settings.items;

import flixel.FlxG;

/**
 * Class to display a text with a background.
 * Used to support opacity.
 * @author Cherri + Sword352
 */
class BGText extends flixel.text.FlxText
{
    /**
     * The background.
     */
    public var backgroundGraphic:flixel.FlxSprite;

    /**
     * Makes a new BGText.
     * @param   X              The x position of the text.
	 * @param   Y              The y position of the text.
	 * @param   FieldWidth     The `width` of the text object. Enables `autoSize` if `<= 0`.
	 *                         (`height` is determined automatically).
	 * @param   Text           The actual text you would like to display initially.
	 * @param   Size           The font size for this text object.
	 * @param   graphicColor   The color of the background.
     */
    public function new(X:Float = 0, Y:Float = 0, FieldWidth:Float = 0, ?Text:String, Size = 8, graphicColor:flixel.util.FlxColor = 0xFF000000)
    {
        super(X, Y, FieldWidth, Text, Size, true);
        backgroundGraphic = new flixel.FlxSprite().makeGraphic(Std.int(width), Std.int(height), graphicColor);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        backgroundGraphic.setGraphicSize(Std.int(width), Std.int(height));
        backgroundGraphic.x = x + (width / 2) - 5;
        backgroundGraphic.y = (FlxG.height - backgroundGraphic.height) - (height / 4);
    }

    override public function draw()
    {
        backgroundGraphic.draw();
        super.draw();
    }
}