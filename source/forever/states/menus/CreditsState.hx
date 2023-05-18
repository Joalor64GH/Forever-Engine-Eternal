package forever.states.menus;

import flixel.ui.FlxSpriteButton;
import flixel.tweens.FlxEase;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import forever.ui.Alphabet;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.xml.Access;

typedef Credit =
{
    var name:String;
    var icon:String;
    var color:String;

    // for the page in the right
    var description:String;
    var expression:String;
    var socials:Array<SocialMedia>;
}

typedef SocialMedia =
{
    var graphic:String;
    var value:String;
}

class CreditsState extends forever.music.MusicBeat.MusicBeatState
{
    var creditsMap:Map<String, Array<Credit>> = [];
    var categories:Array<String> = [];
    var curSelected:Int = 0;
    var curCategory:Int = 0;
    var curCategoryString:String;

    var creditsGroup:FlxTypedGroup<CreditItem>;
    var categoryText:Alphabet;
    var bg:FlxSprite;

    override function create()
    {
        var data:Access = new Access(Xml.parse(sys.io.File.getContent(Paths.data("credits", XML))).firstElement());

        for (i in data.elements)
        {
            if (i.name == "category")
            {
                categories.push(i.att.name);

                creditsMap.set(i.att.name, [for (j in i.elements) {
                    name: j.has.name ? j.att.name : "NULL",
                    icon: j.has.icon ? j.att.icon: "sword",
                    color: j.has.color ? j.att.color : FlxColor.WHITE.toHexString(false),
                    description: j.has.description ? j.att.description : "",
                    expression: j.has.expression ? j.att.expression : "",
                    socials: [for (social in j.elements) {
                        graphic: social.has.image ? social.att.image : "menus/socials/discord",
                        value: social.has.value ? social.att.value : EternalGithubRepoURL
                    }]
                }]);
            }
        }

        super.create();

        bg = new FlxSprite(0, 0, Paths.image("menus/menuBG"));
        bg.antialiasing = true;
        add(bg);

        creditsGroup = new FlxTypedGroup<CreditItem>();
        add(creditsGroup);

        var bar = new FlxSprite().makeGraphic(FlxG.width, 100, FlxColor.BLACK);
        bar.alpha = 0.5;
        bar.screenCenter(X);
        add(bar);

        categoryText = new Alphabet(0, bar.y + (bar.height / 2), "idk", true);
        categoryText.antialiasing = true;
        add(categoryText);

        changeCategory();

        var mouseHandler = new forever.data.inputs.MouseHandler();
		mouseHandler.onWheelScroll = changeSelection;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        
        if (controls.anyJustPressed(["down", "up"]))
            changeSelection(controls.justPressed("up") ? -1 : 1);

        if (controls.anyJustPressed(["left", "right"]))
            changeCategory(controls.justPressed("left") ? -1 : 1);

        if (controls.justPressed("accept"))
        {
            var credit = creditsMap[curCategoryString][curSelected];
            openSubState(new CreditsSubState(credit.icon, credit.name, credit.description, credit.expression, credit.socials));
        }

        if (controls.justPressed("back"))
        {
            FlxG.sound.play(Paths.sound("cancelMenu"));
            Main.switchState(new MainMenuState());
        }
    }

    function changeSelection(change:Int = 0)
    {
        if (change != 0)
            FlxG.sound.play(Paths.sound("scrollMenu"));

        curSelected = FlxMath.wrap(curSelected + change, 0, creditsGroup.length - 1);

        var changement:Int = 0;
        for (item in creditsGroup)
        {
            item.text.targetY = changement - curSelected;
            item.itemAlpha = item.ID == curSelected ? 1 : 0.6;
            changement++;
        }

        FlxTween.cancelTweensOf(bg);
        FlxTween.color(bg, 0.3, bg.color, FlxColor.fromString(creditsMap[curCategoryString][curSelected].color));
    }

    function changeCategory(change:Int = 0)
    {
        if (change != 0)
            FlxG.sound.play(Paths.sound("scrollMenu"));

        curCategory = FlxMath.wrap(curCategory + change, 0, categories.length - 1);
        curCategoryString = categories[curCategory];

        categoryText.text = '< ${curCategoryString} >';
        categoryText.x = (FlxG.width - categoryText.width) / 2;
        // categoryText.screenCenter(X);

        regenerateUI();
    }

    function regenerateUI()
    {
        if (creditsGroup.length > 0)
        {
            for (item in creditsGroup)
                item.destroy();

            creditsGroup.clear();
        }

        for (i in 0...creditsMap[curCategoryString].length)
        {
            var data = creditsMap[curCategoryString][i];
            var item = new CreditItem(data.name, data.icon);
            item.ID = i;
            creditsGroup.add(item);
        }

        changeSelection();
    }
}

class CreditsSubState extends forever.music.MusicBeat.MusicBeatSubState
{
    var avatar:FlxSprite;
    var headText:FlxText;
    var descriptionText:FlxText;
    var overlay:FlxSprite;
    var bg:FlxSprite;
    
    var lastPopupText:FlxText;
    var popupsArray:Array<FlxSprite> = [];
    var buttonsArray:Array<FlxSpriteButton> = [];
    var transitioning:Bool = true;

    public function new(avatarGraphic:String, name:String, description:String, expression:String, socials:Array<SocialMedia>)
    {
        super();
        FlxG.mouse.visible = true;

        bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.GRAY);
        bg.alpha = 0;
        add(bg);

        overlay = new FlxSprite(FlxG.width).makeGraphic(600, FlxG.height, FlxColor.BLACK);
        overlay.alpha = 0.75;
        add(overlay);

        avatar = new FlxSprite(0, overlay.y + 25, Paths.image('menus/credits/avatars/${avatarGraphic}'));
        avatar.scale.set(0.5, 0.5);
        avatar.updateHitbox();
        add(avatar);

        add(headText = new FlxText(0, avatar.y, 0, name).setFormat(Paths.font('vcr'), 35));

        descriptionText = new FlxText(0, headText.y + headText.height + 10).setFormat(Paths.font('vcr'), 22);
        descriptionText.text = '${description}\n${expression}';
        add(descriptionText);

        for (i in 0...socials.length)
        {
            var button = new FlxSpriteButton();
            button.loadGraphic(Paths.image('menus/credits/socials/${socials[i].graphic}'));
            button.scale.set(0.5, 0.5);
            button.updateHitbox();
            button.onDown.callback = function() {
                if (!transitioning) {
                    if (socials[i].value.startsWith("http"))
                        Tools.openURL(socials[i].value);
                    else
                        makePopup(socials[i].value);
                }
            };
            button.onOver.callback = function() {
                if (!transitioning) {
                    button.scale.add(0.05, 0.05);
                    FlxG.sound.play(Paths.sound("scrollMenu"));
                }
            };
            button.onOut.callback = function() if (!transitioning) button.scale.set(button.scale.x - 0.05, button.scale.y - 0.05);
            add(button);
            buttonsArray.push(button);
        }

        FlxTween.tween(overlay, {x: FlxG.width - overlay.width}, 0.7, {ease: FlxEase.circInOut, onComplete: function(_) transitioning = false});
        FlxTween.tween(bg, {alpha: 0.6}, 0.7);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        avatar.x = overlay.x + 25;
        headText.x = descriptionText.x = avatar.x + avatar.width + 5;

        var xPos = overlay.x + 25;
        var yPos = avatar.y + avatar.height + 25;
        for (button in buttonsArray)
        {
            if (xPos >= FlxG.width - buttonsArray[buttonsArray.length - 1].width)
            {
                xPos = overlay.x + 25;
                yPos += button.height;
            }

            button.setPosition(xPos, yPos);
            xPos += button.width;
        }

        if (controls.justPressed("back") && !transitioning)
        {
            transitioning = true;
            FlxG.mouse.visible = false;

            for (button in buttonsArray)
                button.scale.set(0.5, 0.5);

            lastPopupText = null;
            destroyPopups();

            FlxTween.cancelTweensOf(bg);
            FlxTween.cancelTweensOf(overlay);

            FlxTween.tween(bg, {alpha: 0}, 0.7);
            FlxTween.tween(overlay, {x: FlxG.width}, 0.7, {ease: FlxEase.circInOut, onComplete: function(_) close()});
        }

        if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C && lastPopupText != null && !transitioning)
        {
            openfl.desktop.Clipboard.generalClipboard.setData(TEXT_FORMAT, lastPopupText.text, false);
            lastPopupText.text = "Copied to clipboard!";
            lastPopupText.screenCenter(X);
            lastPopupText = null;
        }
    }

    private function makePopup(text:String)
    {
        destroyPopups();

        var popupText = new FlxText(0, 25).setFormat(Paths.font('vcr.ttf'), 34);
        popupText.text = text;
        popupText.screenCenter(X);

        var popupRectangle = new FlxSprite(0, 50).makeGraphic(Std.int(popupText.width * 1.2), 10, FlxColor.BLACK);
        popupRectangle.screenCenter(X);
        add(popupRectangle);
        add(popupText);

        lastPopupText = popupText;

        for (obj in [popupText, popupRectangle])
        {
            popupsArray.push(obj);
            FlxTween.tween(obj, {alpha: 0}, 4, {startDelay: 4, onComplete: function(_) {
                popupsArray.remove(obj);
                if (lastPopupText == popupText)
                    lastPopupText = null;
                obj.destroy();
            }});
        }
    }

    private function destroyPopups()
    {
        for (popupObj in popupsArray)
            popupObj.destroy();   
    }
}

class CreditItem extends flixel.group.FlxGroup
{
    public var itemAlpha(default, set):Float = 1;
    public var text:Alphabet;
    var icon:FlxSprite;

    public function new(name:String, iconGraphic:String)
    {
        super();

        text = new Alphabet(0, 0, name, true);
        text.isMenuItem = text.disableX = true;
        text.xTo = 200;
        add(text);
        add(icon = new FlxSprite(0, 0, Paths.image('menus/credits/icons/${iconGraphic}')));

        text.antialiasing = icon.antialiasing = true;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
        icon.setPosition(text.x - 150, text.y - 35);
    }

	function set_itemAlpha(value:Float):Float
    {
		itemAlpha = text.alpha = icon.alpha = value;
        return value;
	}
}