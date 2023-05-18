package forever.ui;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

enum ForeverButtonStatus
{
    Pressed;
    Hovered;
    None;
}

/**
 * The ForeverButton class is just a button with many customizations.
 * (yes ik FlxButton is a thing but shhhh)
 * @author Sword352
 */
class ForeverButton extends flixel.group.FlxSpriteGroup
{
    /**
     * Callback trigerred when the mouse press this `ForeverButton`.
     */
    public var onPressedCallback:Void->Void = null;

    /**
     * Callback trigerred when the mouse releases this `ForeverButton`.
     */
    public var onReleaseCallback:Void->Void = null;

    /**
     * Callback trigerred when the mouse hover this `ForeverButton`.
     */
    public var onHoverCallback:Void->Void = null;

    /**
     * Callback trigerred when the mouse goes out of the hitbox of this `ForeverButton`.
     */
    public var onOutCallback:Void->Void = null;

    /**
     * The current status of this `ForeverButton`.
     */
    public var currentStatus:ForeverButtonStatus = None;

    /**
     * The colors that will applied to the `changingColorTarget` when the status changes.
     * You can safely clear this map or set `changingColorTarget` to null if you don't wanna use that feature.
     */
    public var labelColors:Map<ForeverButtonStatus, FlxColor> = [
        Pressed => FlxColor.GREEN,
        Hovered => FlxColor.YELLOW,
        None => FlxColor.WHITE
    ];

    /**
     * The object that will change color when the status changes.
     * You can safely set this to null or clear the `labelColors` map if you don't wanna use that feature.
     */
    public var changingColorTarget:FlxSprite;

    /**
     * The button graphic used to display the box of this `ForeverButton`.
     */
    public var button:FlxSprite;

    /**
     * The text shown in this `ForeverButton`.
     */
    public var text:FlxText;

    /**
     * Makes a new `ForeverButton`.
     * @param X The X Position of the button.
     * @param Y The Y Position of the button.
     * @param Width The width of the button.
     * @param Height The height of the button.
     * @param Text The text that will show in the button.
     */
    public function new(X:Float = 0, Y:Float = 0, Width:Int = 200, Height:Int = 50, Text:String = "")
    {
        super();

        button = new FlxSprite(X, Y, Paths.image("UI/base/editors/graphic"));
        button.setGraphicSize(Width, Height);
        button.updateHitbox();
        button.alpha = 0.7;
        add(button);

        text = new FlxText(0, 0, 0, Text).setFormat(Paths.font('vcr'), 22);
        add(text);

        changingColorTarget = button;
    }

    // Helper boolean to check if the button is hovered
    var isHovered:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        text.x = button.x + 15;
        text.centerOverlay(button, Y);

        if (changingColorTarget != null && labelColors.get(currentStatus) != null)
            changingColorTarget.color = labelColors.get(currentStatus);

        if (button.isOverlaped())
        {
            if (currentStatus == Pressed)
            {
                if (FlxG.mouse.pressed)
                    return;

                if (FlxG.mouse.justReleased && onReleaseCallback != null)
                    onReleaseCallback();

                currentStatus = Hovered;
            }

            if (!isHovered)
            {
                currentStatus = Hovered;

                if (onHoverCallback != null)
                    onHoverCallback();

                isHovered = true;
            }

            if (FlxG.mouse.justPressed)
            {
                currentStatus = Pressed;

                if (onPressedCallback != null)
                    onPressedCallback();
            }
        }
        else if (isHovered)
        {
            currentStatus = None;
            isHovered = false;

            if (onOutCallback != null)
                onOutCallback();
        }
    }
}