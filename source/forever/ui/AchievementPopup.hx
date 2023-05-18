package forever.ui;

import forever.backend.Achievements;
import flixel.FlxSprite;

class AchievementPopup extends flixel.group.FlxSpriteGroup
{
    public function new(achievement:String)
    {
        super();

        var achievementData = Achievements.achievementsMap.get(achievement);

        var popupSprite:FlxSprite = new FlxSprite(0, 50);

        if (achievementData.skin.popup.skin != "" && achievementData.skin.popup.skin != "NONE")
        {
            popupSprite.loadGraphic(Tools.getUIAsset('achievements/${achievementData.skin.popup.skin}', SkinManager.assetStyle, "images/UI"));
            popupSprite.scale.set(achievementData.skin.popup.scale[0], achievementData.skin.popup.scale[1]);
            popupSprite.updateHitbox();
            if (achievementData.skin.popup.color != "")
                popupSprite.color = Tools.parseXMLColor(achievementData.skin.popup.color);
            popupSprite.flipX = achievementData.skin.popup.flipX;
            popupSprite.flipY = achievementData.skin.popup.flipY;
            add(popupSprite);
        }

        if (achievementData.skin.medal.skin != "" && achievementData.skin.medal.skin != "NONE")
        {
            var medal = new FlxSprite(10, 0, Tools.getUIAsset('achievements/${achievementData.skin.medal.skin}', SkinManager.assetStyle, "images/UI"));
            medal.scale.set(achievementData.skin.medal.scale[0], achievementData.skin.medal.scale[1]);
            medal.updateHitbox();
            medal.centerOverlay(popupSprite, Y);
            if (achievementData.skin.medal.color != "")
                medal.color = Tools.parseXMLColor(achievementData.skin.medal.color);
            medal.flipX = achievementData.skin.medal.flipX;
            medal.flipY = achievementData.skin.medal.flipY;
            add(medal);
        }
    }
}