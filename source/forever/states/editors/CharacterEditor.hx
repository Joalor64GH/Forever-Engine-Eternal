package forever.states.editors;

import forever.ui.ColorPicker;
import flixel.addons.ui.FlxUICheckBox;
import sys.thread.Thread;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.input.mouse.FlxMouseEvent;
import forever.ui.HealthIcon;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUIInputText;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import sys.thread.FixedThreadPool;
import flixel.text.FlxText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUITabMenu;
import flixel.math.FlxMath;
import flixel.FlxObject;
import flixel.FlxCamera;
import forever.objects.Character;
import flixel.FlxG;

class CharacterEditor extends forever.music.MusicBeat.MusicBeatState
{
    var mainCamera:FlxCamera;
    var uiCamera:FlxCamera;

    var mainCameraFollow:FlxObject;

    var character:Character;
    var ghostCharacter:Character;
    var characterData:CharacterData;
    var characterName:String;

    var ui:FlxUITabMenu;

    var threads:FixedThreadPool = new FixedThreadPool(3);

    var animationsList:Array<SpriteAnimation> = [];

    var blockInputsWhileTyping:Array<FlxUIInputText> = [];

    override function create()
    {
        super.create();
        Tools.killMusic([FlxG.sound.music]);

        mainCamera = new FlxCamera();
        mainCamera.bgColor.alpha = 0;

        uiCamera = new FlxCamera();
        uiCamera.bgColor.alpha = 0;

        FlxG.cameras.reset(mainCamera);
        FlxG.cameras.add(uiCamera, false);

        mainCameraFollow = new FlxObject(mainCamera.x, mainCamera.y, 1, 1);
        mainCamera.follow(mainCameraFollow, LOCKON);

        pendingCameraX = mainCameraFollow.x;
        pendingCameraY = mainCameraFollow.y;

        var grayBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.GRAY);
        grayBG.scrollFactor.set();
        add(grayBG);

        character = new Character().loadBoyfriend();
        character.adjustPos = false;
        character.debugMode = character.allowDanceOnDebug = true;
        add(character);

        characterData = cast yaml.Yaml.parse(sys.io.File.getContent(Paths.getPath("characters/bf/bf", YAML)), yaml.Parser.options().useObjects());
        characterData.healthColor = [0, 0, 0];

        ghostCharacter = new Character().loadBoyfriend();
        ghostCharacter.adjustPos = false;
        ghostCharacter.alpha = 0.5;
        ghostCharacter.visible = false;
        ghostCharacter.debugMode = ghostCharacter.allowDanceOnDebug = true;
        add(ghostCharacter);

        FlxG.mouse.visible = true;
        setupUI();
    }

    var icon:HealthIcon;
    var healthBar:FlxSprite;

    private function setupUI():Void
    {
        var tabs = [
            {name: 'Character', label: 'Character'},
            {name: 'Animations', label: 'Animations'},
            {name: 'Help', label: 'Help'}
        ];

        ui = new FlxUITabMenu(null, tabs);
        ui.cameras = [uiCamera];
        ui.resize(300, FlxG.height);
        ui.x = FlxG.width - ui.width;
        add(ui);

        var character_tab = new FlxUI(null, ui);
		character_tab.name = "Character";

        var characterNameInput = new FlxUIInputText(25, 50, 125, "bf");
        character_tab.add(characterNameInput);
        character_tab.add(new FlxText(characterNameInput.x, characterNameInput.y - 18, 0, 'Character Name:'));
        blockInputsWhileTyping.push(characterNameInput);

        var characterInput = new FlxUIInputText(25, 150, 125, "BOYFRIEND");
        characterInput.name = "character_input";
        character_tab.add(characterInput);
        characterInput.updateFramePixels();
        characterInput.updateHitbox();
        character_tab.add(new FlxText(characterInput.x, characterInput.y - 18, 0, 'Character Frames Path:'));
        blockInputsWhileTyping.push(characterInput);

        var reloadCharacterButton = new FlxUIButton(characterInput.x + characterInput.width + 5, 45, "Reload Character");
        character_tab.add(reloadCharacterButton);

        healthBar = new FlxSprite(15, 550).loadGraphic(Tools.getUIAsset("healthBar", SkinManager.assetStyle, "images/UI"));
        healthBar.scale.set(0.25, 0.5);
        healthBar.updateHitbox();
        character_tab.add(healthBar);

        icon = new HealthIcon();
        icon.scale.set(0.5, 0.5);
        icon.updateHitbox();
        icon.setPosition(15, 512);
        FlxMouseEvent.globalManager.add(icon, _ -> icon.animation.curAnim.curFrame = icon.animation.curAnim.curFrame == 1 ? 0 : 1);
        character_tab.add(icon);

        reloadCharacterButton.onDown.callback = function () {
            characterName = characterNameInput.text;
            if (characterInput.text != "") {
                threads.run(function() reloadCharacter(characterInput.text));
            }
        };

        var colorsStepersArray:Array<String> = ["red_healthbar_stepper", "green_healthbar_stepper", "blue_healthbar_stepper"];
        for (i in 0...colorsStepersArray.length)
        {
            var colorStepper = new FlxUINumericStepper(20 + (100 * i), 600, 1, 100, 0, 255);
            colorStepper.name = colorsStepersArray[i];
            character_tab.add(colorStepper);
            character_tab.add(new FlxText(colorStepper.x, colorStepper.y - 15, 0, '${colorsStepersArray[i].split("_")[0].toUpperCase()}:'));

            getEvent(FlxUINumericStepper.CHANGE_EVENT, colorStepper, null);
        }

        var picker = new ColorPicker(25, 300, 200, 200);
        picker.onChange = function() healthBar.color = picker.getColor();
        character_tab.add(picker);

        var animations_tab = new FlxUI(null, ui);
        animations_tab.name = "Animations";

        var animationNameInput = new FlxUIInputText(25, 50, 150, "");
        var prefixInput = new FlxUIInputText(25, 100, 150, "");
        var indicesInput = new FlxUIInputText(25, 150, 150, "");
        var loopCheckBox = new FlxUICheckBox(250, 50, null, null, "Loop?");
        var fpsStepper = new FlxUINumericStepper(25, 200, 1, 24, 1, 360);

        for (i in [animationNameInput, prefixInput, indicesInput, loopCheckBox, fpsStepper])
        {
            if (i is FlxUIInputText)
                blockInputsWhileTyping.push(cast i);

            animations_tab.add(i);
        }

        animations_tab.add(new FlxText(animationNameInput.x, animationNameInput.y - 15, 0, "Animation Name:"));
        animations_tab.add(new FlxText(prefixInput.x, prefixInput.y - 15, 0, "Prefix in the XML/TXT:"));
        animations_tab.add(new FlxText(indicesInput.x, indicesInput.y - 15, 0, "ADVANCED - Indices:"));
        animations_tab.add(new FlxText(fpsStepper.x, fpsStepper.y - 15, 0, "Framerate:"));

        var addAnimationsButton = new FlxUIButton(25, 250, "Add animation");
        addAnimationsButton.onDown.callback = function() {
            var newAnim:SpriteAnimation = {
                name: animationNameInput.text,
                prefix: prefixInput.text,
                indices: [for (i in indicesInput.text.split(", ")) Std.int(Std.parseFloat(i))],
                loop: loopCheckBox.checked,
                fps: Std.int(fpsStepper.value)
            };
            animationsList.push(newAnim);

            try {
                if (character.animation.exists(newAnim.name))
                    character.animation.remove(newAnim.name);

                if (newAnim.indices.length > 0)
                    character.animation.addByIndices(newAnim.name, newAnim.prefix, newAnim.indices, '', newAnim.fps, newAnim.loop);
                else
                    character.animation.addByPrefix(newAnim.name, newAnim.prefix, newAnim.fps, newAnim.loop);

                character.playAnim(newAnim.name);

                if (!character.active)
                    character.active = true;
            } catch(e) print(e, ERROR);
        };

        animations_tab.add(addAnimationsButton);

        var help_tab = new FlxUI(null, ui);
        help_tab.name = "Help";
        help_tab.add(new FlxText(10, 10, 0, "j"));
        
        ui.addGroup(character_tab);
        ui.addGroup(animations_tab);
        ui.addGroup(help_tab);
    }

    var pendingCameraX:Float = 0;
    var pendingCameraY:Float = 0;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (controls.justPressed("back"))
            Main.switchState(new forever.states.menus.MainMenuState());

        var canInteract:Bool = true;

        for (i in blockInputsWhileTyping) {
            if (i.hasFocus) {
                canInteract = false;
                break;
            }
        }

        if (FlxG.keys.anyPressed([I, J, K, L]) && canInteract)
        {
            pendingCameraX += FlxG.keys.pressed.J ? -5 : (FlxG.keys.pressed.L ? 5 : 0);
            pendingCameraY += FlxG.keys.pressed.I ? -5 : (FlxG.keys.pressed.K ? 5 : 0);
        }

        if (FlxG.keys.anyJustPressed([LEFT, DOWN, UP, RIGHT])&& canInteract)
        {
            var multiplier = FlxG.keys.pressed.SHIFT && FlxG.keys.pressed.CONTROL ? 5 : (FlxG.keys.pressed.SHIFT ? 2 : 1);
            character.x += (FlxG.keys.justPressed.LEFT ? -5 : (FlxG.keys.justPressed.RIGHT ? 5 : 0)) * multiplier;
            character.y += (FlxG.keys.justPressed.UP ? -5 : (FlxG.keys.justPressed.DOWN ? 5 : 0)) * multiplier;
            character.dance(true);
        }

        if (FlxG.keys.justPressed.SPACE && canInteract)
        {
            ghostCharacter.visible = !ghostCharacter.visible;
            character.alpha = ghostCharacter.visible ? 0.8 : 1;

            if (ghostCharacter.visible)
            {
                ghostCharacter.setPosition(character.x, character.y);

                if (ghostCharacter.curCharacter != character.curCharacter || ghostCharacter.curVariant != character.curVariant)
                    updateGhost();
            }
        }

        if (FlxG.mouse.wheel != 0)
            mainCamera.zoom -= FlxG.mouse.wheel;

        var cameraLerp:Float = Tools.boundFPS(0.05) * 2;
        mainCameraFollow.setPosition(FlxMath.lerp(mainCameraFollow.x, pendingCameraX, cameraLerp), FlxMath.lerp(mainCameraFollow.y, pendingCameraY, cameraLerp));
    }

    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
    {
        if (id == FlxUINumericStepper.CHANGE_EVENT && sender is FlxUINumericStepper)
        {
            var stepper = cast(sender, FlxUINumericStepper);

            if (stepper.name.endsWith("_healthbar_stepper"))
            {
                switch (stepper.name)
                {
                    case "red_healthbar_stepper": characterData.healthColor[0] = Std.int(stepper.value);
                    case "green_healthbar_stepper": characterData.healthColor[1] = Std.int(stepper.value);
                    case "blue_healthbar_stepper": characterData.healthColor[2] = Std.int(stepper.value);
                }

                healthBar.color = FlxColor.fromRGB(characterData.healthColor[0], characterData.healthColor[1], characterData.healthColor[2]);
            }
        }
    }

    function reloadCharacter(newCharacter:String)
    {
        character.frames = generateCharacterSparrow(newCharacter);

        for (anim in character.animation.getNameList())
            character.animation.remove(anim);

        animationsList = [];
    }

    function generateCharacterSparrow(char:String)
    {
        var basePath = 'characters/${characterName}/${char}';
        return FlxAtlasFrames.fromSparrow(Paths.getPath(basePath, IMAGE), Paths.getPath(basePath, XML));
    }

    function updateGhost()
    {
        threads.run(function() {
            ghostCharacter.active = false;

            if (ghostCharacter.curVariant != character.curVariant)
                ghostCharacter.curVariant = character.curVariant;
    
            if (ghostCharacter.curCharacter != character.curCharacter)
                ghostCharacter.setCharacter(0, 0, character.curCharacter);
    
            ghostCharacter.setPosition(character.x, character.y);

            ghostCharacter.active = true;
        });
    }
}