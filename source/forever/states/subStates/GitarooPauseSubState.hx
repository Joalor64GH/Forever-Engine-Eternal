package forever.states.subStates;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import forever.music.Conductor;

/**
 * Gitaroo Man easter egg with a chance of 1 / 1000 to unlock it lol!
 * @author Sword352
 */
class GitarooPauseSubState extends forever.music.MusicBeat.MusicBeatSubState
{
    var optionsList:Array<String> = ["Resume", "Restart Song", "Go To Options", "Exit To Menu"];
    var buttonsArray:Array<FlxSprite> = [];
    var lastSongPos:Float = 0;
    var curSelected:Int = 0;

    var character:FlxSprite;
    var bg:FlxSprite;

    public function new()
    {
        super();

        Conductor.songPosition = 0;
        Conductor.changeBPM(110);
        FlxG.sound.playMusic(Paths.music("secretPause"), 0.6);

        bg = new FlxSprite().loadGraphic(Paths.image("pauseUI/pauseBG"));
        bg.screenCenter();
        bg.alpha = 0;
        add(bg);

        character = new FlxSprite(0, 30).loadGraphic(Paths.image("pauseUI/bfLol"));
        character.alpha = 0;
        character.screenCenter(X);

        cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        bg.antialiasing = character.antialiasing = true;

        var buttonsColorArray = [FlxColor.YELLOW, FlxColor.CYAN, FlxColor.GREEN, FlxColor.RED];
        var circleGraphic = Paths.image("pauseUI/circlBase");
        var xPos = 250;

        for (i in 0...optionsList.length)
        {
            var button = FlxSpriteUtil.drawCircle(new FlxSprite(xPos, FlxG.height * 0.7).loadGraphic(circleGraphic));
            button.color = buttonsColorArray[i];
            button.ID = i;
            add(button);
            buttonsArray.push(button);

            var text = new FlxText().setFormat(Paths.font('vcr'), 32, FlxColor.PURPLE, CENTER);
            text.text = formatText(optionsList[i]);
            text.centerOverlay(button);
            add(text);

            button.antialiasing = text.antialiasing = true;
            button.alpha = text.alpha = 0;

            FlxTween.tween(text, {alpha: 1}, 1);
            FlxTween.tween(button, {alpha: 1}, 1);

            xPos += 200;
        }

        add(character);

        FlxTween.tween(bg, {alpha: 1}, 1);
        FlxTween.tween(character, {alpha: 1}, 1);
    }

    var beatDropped:Bool = false;
    var switching:Bool = false;
    var lerpChar:Bool = true;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        var lerpRatio = Tools.boundFPS(0.10);

        bg.scale.set(FlxMath.lerp(bg.scale.x, 1, lerpRatio), FlxMath.lerp(bg.scale.y, 1, lerpRatio));

        if (lerpChar)
            character.scale.set(FlxMath.lerp(character.scale.x, 1, lerpRatio), FlxMath.lerp(character.scale.y, 1, lerpRatio));

        for (button in buttonsArray)
            button.scale.x = button.scale.y = FlxMath.lerp(button.scale.x, button.ID == curSelected ? 1.15 : 1, lerpRatio);

        if (!switching)
        {
            Conductor.songPosition = FlxG.sound.music.time;
            if (Conductor.songPosition == lastSongPos)
                Conductor.songPosition += elapsed * 1000;

            lastSongPos = Conductor.songPosition;
        }

        if (FlxG.sound.music.time >= 8719 && !beatDropped && !switching)
            beatDropped = true;

        if (controls.justPressed("accept") && !switching)
        {
            switching = true;

            switch (optionsList[curSelected].toLowerCase())
            {
                case "resume":
                    Tools.killMusic([FlxG.sound.music]);
                    Conductor.songPosition = PlayState.current.lastSongPosition;
                    Conductor.changeBPM(PlayState.current.lastBPM);
                    close();
                case "restart song": doDaGoofy(function() FlxG.switchState(new PlayState()));
                case "go to options": doDaGoofy(function() FlxG.switchState(new forever.settings.OptionsState(true)));
                case "exit to menu":
                    PlayState.current.resetMusic();
					PlayState.deaths = 0;
					doDaGoofy(function() FlxG.switchState(PlayState.isStoryMode ? new forever.states.menus.StoryMenuState() : new forever.states.menus.FreeplayState()));
            }
        }

        if (controls.anyJustPressed(["left", "right"]) && !switching)
            curSelected = FlxMath.wrap(curSelected + (controls.justPressed("left") ? -1 : 1), 0, optionsList.length - 1);
    }

    override function beatHit()
    {
        super.beatHit();

        character.angle = character.angle == 0 ? 40 : 0;
        if (beatDropped && !Init.trueSettings.get('Reduced Movements'))
        {
            bg.scale.add(0.05, 0.05);
            curBeat % 2 == 0 ? character.scale.x = 1.5 : character.scale.y = 1.5;
        }
    }

    private function doDaGoofy(func:Void->Void)
    {
        lerpChar = false;

        var snore = FlxG.sound.play(Paths.sound("snore"));
        snore.pitch = 2;

        FlxTween.tween(character.scale, {x: 12, y: 6}, 0.3, {ease:flixel.tweens.FlxEase.circInOut, onComplete: function(_) {
            Tools.killMusic([FlxG.sound.music, snore]);
            func();
        }});
    }

    private function formatText(text:String):String
    {
        var textToFormat:Array<String> = text.split(" ");
        var finalText:String = "";

        for (i in 0...textToFormat.length)
        {
            var addSpace:Bool = true;

            if (FlxMath.isEven(i) && i != 0)
            {
                finalText += "\n";
                addSpace = false;
            }

            finalText += (i == 0 || !addSpace ? textToFormat[i] : ' ${textToFormat[i]}');
        }

        // lil workaround lol!!!1!1!1
        if (text == optionsList[1])
            finalText = finalText.replace(" ", "\n");

        return finalText.toUpperCase();
    }
}