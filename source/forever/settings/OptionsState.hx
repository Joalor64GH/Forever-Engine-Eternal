package forever.settings;

import forever.settings.substates.BaseOptionSubState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSprite;

enum OptionsAction
{
    GoToOptions(SubState:Class<BaseOptionSubState>);
    OpenSubState(SubState:Class<flixel.FlxSubState>);
    GoToControls;
    Exit;
}

/**
 * This is the options state, the state with the options category to choose.
 * You can mess around with it to modify its visuals and add/modify/delete categories!
 * @author Sword352
 */
class OptionsState extends forever.music.MusicBeat.MusicBeatState
{
    /**
     * This variable store all of the categories.
     * Structure of a category: `{category: "category name", action: Action}`.
     * You can use an action from the enum `OptionsAction` and even make your own if needed.
     * - Sword352
     */
    var categories:Array<{category:String, action:OptionsAction}> = [
        {category: "preferences", action: GoToOptions(forever.settings.substates.PreferencesSubState)},
        {category: "appearance", action: GoToOptions(forever.settings.substates.AppearanceSubState)},
        {category: "adjust offset", action: OpenSubState(forever.settings.substates.OffsetAdjustSubState)},
        {category: "controls", action: GoToControls},
        {category: "exit", action: Exit},
    ];

    var toPlayState:Bool;
    var curSelected:Int = 0;

    public var blackBox:FlxSprite;
    var categoriesTextGroup:FlxTypedGroup<FlxText>;
    var selector:FlxText;

    public function new(toPlayState:Bool = false)
    {
        this.toPlayState = toPlayState;
        super();
    }

    override function create()
    {
        super.create();

        Discord.changePresence('OPTIONS MENU', 'In Menus');
		Tools.resetMenuMusic(toPlayState ? 'chillFresh' : 'freakyMenu');
        
        add(flixel.util.FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0xFF5852ff, 0xFFfc019c], 1, 45));

		var bg = new FlxSprite(-85, 0, Paths.image('menus/menuDesat'));
		bg.scrollFactor.set(0, 0.18);
		bg.setGraphicSize(Std.int(bg.width * 1.1));
		bg.updateHitbox();
		bg.screenCenter();
        bg.blend = MULTIPLY;
		bg.antialiasing = true;
		add(bg);

        blackBox = new FlxSprite(0, FlxG.height + 50).makeGraphic(FlxG.width, FlxG.height - 50, 0x75000000);
        blackBox.alpha = 0.65;
        add(blackBox);
        
        categoriesTextGroup = new FlxTypedGroup<FlxText>();

        for (i in 0...categories.length)
        {
            var categoryText = new FlxText(50, 100 * (i + 1), 0, categories[i].category.toUpperCase()).setFormat(Paths.font('vcr'), 54);
            categoryText.ID = i;
            categoriesTextGroup.add(categoryText);
        }

        add(categoriesTextGroup);

        add(selector = new FlxText(10, 0, 0, '>').setFormat(Paths.font('vcr'), 54));

        persistentUpdate = true;
        changeSelection();

        var mouseHandler = new forever.data.inputs.MouseHandler();
		mouseHandler.onWheelScroll = changeSelection;
    }

    var transitioning:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.anyJustPressed(["down", "up"]) && !transitioning)
            changeSelection(controls.justPressed("down") ? 1 : -1);

        if (controls.justPressed("accept") && !transitioning)
        {
            transitioning = true;

            switch (categories[curSelected].action)
            {
                case GoToOptions(substate):
                    FlxG.sound.play(Paths.sound("confirmMenu"));
                    openOptionSubState(Type.createInstance(substate, []));
                case OpenSubState(substate):
                    FlxG.sound.play(Paths.sound("confirmMenu"));
                    openSubState(Type.createInstance(substate, []));
                case GoToControls:
                    FlxG.sound.play(Paths.sound("confirmMenu"));
                    openOptionSubState(new forever.settings.substates.ControlsSubState());
                case Exit:
                    FlxG.sound.play(Paths.sound("cancelMenu"));
                    Main.switchState(toPlayState ? new forever.states.PlayState() : new forever.states.menus.MainMenuState());
            }
        }

        selector.y = FlxMath.lerp(selector.y, categoriesTextGroup.members[curSelected].y, Tools.boundFPS(0.10) * 2);
    }

    function openOptionSubState(SubState:flixel.FlxSubState)
    {
        cancelAllTweens();

        FlxTween.tween(categoriesTextGroup.members[curSelected], {y: 10, x: (FlxG.width - categoriesTextGroup.members[curSelected].width) / 2},
            0.3, {ease: FlxEase.circOut});

        for (text in [for (text in categoriesTextGroup) if (text.ID != curSelected) text])
            FlxTween.tween(text, {alpha: 0}, 0.3);

        FlxTween.tween(blackBox, {y: 50}, 0.5, {
            ease: FlxEase.circOut,
            onComplete: function(_) openSubState(SubState)
        });

        selector.visible = false;
    }

    public function closeOptionSubState()
    {
        cancelAllTweens();

        var item = categoriesTextGroup.members[curSelected];
        FlxTween.tween(item, {y: 100 * (item.ID + 1), x: 50}, 0.3, {ease: FlxEase.circOut, onComplete: function(_) changeSelection()});

        for (text in [for (text in categoriesTextGroup) if (text.ID != curSelected) text])
            FlxTween.tween(text, {alpha: 0.6}, 0.3);

        FlxTween.tween(blackBox, {y: 1000}, 0.5, {ease: FlxEase.circIn, onComplete: function(_) {
            subState.close();
            selector.visible = true;
        }});
    }

    function cancelAllTweens()
    {
        for (text in categoriesTextGroup)
            FlxTween.cancelTweensOf(text);

        FlxTween.cancelTweensOf(selector);
        FlxTween.cancelTweensOf(blackBox);
    }

    override function openSubState(SubState:flixel.FlxSubState)
    {
        super.openSubState(SubState);
        persistentUpdate = false;
        transitioning = true;
    }

    override function closeSubState()
    {
        super.closeSubState();
        transitioning = false;
    }

    function changeSelection(change:Int = 0)
    {
        if (change != 0)
            FlxG.sound.play(Paths.sound("scrollMenu"));

        curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, categoriesTextGroup.length - 1);
        categoriesTextGroup.forEach(text -> text.alpha = text.ID == curSelected ? 1 : 0.6);
    }
}