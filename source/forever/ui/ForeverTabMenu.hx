package forever.ui;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

class ForeverTabMenu extends FlxGroup
{
    var tabSprite:FlxSprite;

    var tabs:Map<String, FlxGroup> = [];

    public function new(X:Float = 0, Y:Float = 0, Width:Int = 400, Height:Int = 0)
    {
        if (Height == 0)
            Height = Std.int(FlxG.height / 1.5);

        super();

        tabSprite = new FlxSprite(X, Y, Paths.image("UI/base/editors/tab"));
        resize(Width, Height);
        tabSprite.alpha = 0.5;
        tabSprite.antialiasing = false;
        add(tabSprite);
    }

    public function resize(Width:Int, Height:Int)
    {
        tabSprite.setGraphicSize(Width, Height);
        tabSprite.updateHitbox();
    }

    override function set_camera(Value:FlxCamera):FlxCamera
    {
        super.set_camera(Value);

        for (tab in [for (tab in tabs) tab])
            tab.set_camera(Value);

        return Value;
    }

    override function set_cameras(Value:Array<FlxCamera>):Array<FlxCamera>
    {
        super.set_cameras(Value);

        for (tab in tabs)
            tab.set_cameras(Value);

        return Value;
    }
}