package forever.settings.substates;

import forever.settings.items.OptionItem;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.FlxG;

/**
 * This is the base option sub state, where you can add your options in.
 * Extend this sub state to make the options, by making `new OptionItem`s.
 * You can then add the sub state to the category action in the category array of `OptionsState`!
 * @see forever.settings.OptionsState
 * @author Sword352
 */
class BaseOptionSubState extends forever.music.MusicBeat.MusicBeatSubState
{
    var optionsItemGroup:FlxTypedGroup<OptionItem>;
    var descriptionText:BGText;
    var descriptionTimer:FlxTimer;

    var curSelected:Int = 0;
    var onSubState:Bool = true;

    public function new()
    {
        super();
        optionsItemGroup = new FlxTypedGroup<OptionItem>();
    }

    override function create()
    {
        super.create();

        for (i in 0...optionsItemGroup.length)
        {
            var item = optionsItemGroup.members[i];
            item.targetY = i;
            item.ID = i;
        }
        add(optionsItemGroup);

        descriptionText = new BGText(5, FlxG.height - 24, 0, "", 8, 0x80000000);
        descriptionText.setFormat(Paths.font("vcr"), 20, FlxColor.WHITE, CENTER);
        descriptionText.backgroundGraphic.alpha = 0.6;
		add(descriptionText);

        changeSelection();
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        var menu = cast(FlxG.state, OptionsState);

        if (controls.anyJustPressed(["up", "down"]) && onSubState)
            changeSelection(controls.justPressed("up") ? -1 : 1);

        if (controls.justPressed("back") && onSubState)
        {
            onSubState = false;

            for (item in optionsItemGroup)
                item.destroy();
            optionsItemGroup.destroy();

            descriptionText.destroy();

            if (descriptionTimer != null)
            {
                descriptionTimer.cancel();
                descriptionTimer.destroy();
            }

            FlxG.sound.play(Paths.sound("cancelMenu"));
            menu.closeOptionSubState();
        }

        if (onSubState && optionsItemGroup != null)
            for (item in optionsItemGroup)
                item.visible = item.y >= menu.blackBox.y - 12;
    }

    function changeSelection(change:Int = 0):Void
    {
        if (!onSubState || optionsItemGroup == null)
            return;

        curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, optionsItemGroup.length - 1);

        if (optionsItemGroup.members[curSelected].text == "")
            return changeSelection(change);

        if (change != 0)
            FlxG.sound.play(Paths.sound("scrollMenu"));

        var changement:Int = 0;
        for (item in optionsItemGroup)
        {
            item.targetY = changement - curSelected;
            item.alpha = item.ID == curSelected ? 1 : 0.6;
            item.isSelected = item.ID == curSelected;

            changement++;  
        }

        if (optionsItemGroup.members[curSelected].description != "")
            updateDescription(optionsItemGroup.members[curSelected].description);
        else
            descriptionText.visible = false;
    }

    function updateDescription(description:String)
    {
        var textSplit:Array<String> = description.split("");
        var loopTimes:Int = 0;

        if (descriptionTimer != null)
            descriptionTimer.cancel();

        descriptionText.visible = true;
        descriptionText.text = "";
        
        descriptionTimer = new FlxTimer().start(0.025, function(tmr:FlxTimer)
        {
            descriptionText.text += textSplit[loopTimes];
            descriptionText.screenCenter(X);

            if (textSplit[loopTimes] == "\n")
                descriptionText.y -= descriptionText.height;

            loopTimes++;
        }, textSplit.length);
    }

    function addOption(option:OptionItem)
    {
        optionsItemGroup.add(option);
    }
}