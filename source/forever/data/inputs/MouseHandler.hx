package forever.data.inputs;

import flixel.input.keyboard.FlxKey;
import forever.scripting.ScriptableState;
import flixel.FlxG;

// TODO: Hold Inputs

/**
 * A mouse handler allow you to handle the mouse wheel input to trigger a function.
 * Useful for states.
 * @author Sword352
 */
class MouseHandler
{
    /**
     * If false, the mouse wheel value will be the opposite of the direction of the wheel.
     */
    public var fixInputWheel:Null<Bool> = true;

    /**
     * The mouse wheel multiplier keys, used to multiply the mouse wheel value when one of these keys are pressed.
     */
    public var wheelMultiplierKeys:Array<FlxKey> = [SHIFT];

    /**
     * The mouse wheel input callback, called each time the wheel is moving.
     */
    public var onWheelScroll:Int->Void = null;

    /**
     * Internal, the current state of a MouseHandler object.
     */
    private var _state:ObjectState = NONE;

    /**
     * Makes a new MouseHandler.
     * @param fixInputWheel If false, the mouse wheel value will be the opposite of the direction of the wheel.
     * @param wheelMultiplierKeys The mouse wheel multiplier keys.
     * @param onWheelScroll The mouse wheel input callback, called each time the wheel is moving.
     */
    public function new(fixInputWheel:Bool = true, wheelMultiplierKeys:Array<FlxKey> = null, onWheelScroll:Int->Void = null)
    {
        this.fixInputWheel = true;
        this.onWheelScroll = onWheelScroll;

        if (wheelMultiplierKeys == null)
            wheelMultiplierKeys = [SHIFT];
        this.wheelMultiplierKeys = wheelMultiplierKeys;

        _state = ALIVE;
        ScriptableState.mouseInputs.push(this);
    }

    /**
     * Update this mouse handler to check for inputs.
     */
    public function update(elapsed:Float)
    {
        if (_state == DEAD) return;

        if (FlxG.mouse.wheel != 0)
        {
            var mouseMultiplier = FlxG.mouse.wheel;
            if (FlxG.keys.anyPressed(wheelMultiplierKeys))
                mouseMultiplier *= 10;

            if (fixInputWheel)
                mouseMultiplier = -mouseMultiplier;

            if (onWheelScroll != null)
                onWheelScroll(mouseMultiplier);
        }
    }

    /**
     * Destroy this MouseHandler.
     */
    public function destroy()
    {
        ScriptableState.mouseInputs.remove(this);
        _state = DEAD;
        fixInputWheel = null;
        wheelMultiplierKeys = null;
        onWheelScroll = null;
    }
}