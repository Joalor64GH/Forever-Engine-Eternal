package forever.settings.substates;

class PreferencesSubState extends BaseOptionSubState
{
    override function create()
    {
        // Gameplay Category
        addOption(new OptionItem('Gameplay'));
        addOption(new OptionItem(''));

        addOption(new OptionItem('Downscroll'));
        addOption(new OptionItem('Centered Notefield'));
        addOption(new OptionItem('Ghost Tapping'));

        // Text and Display category
        addOption(new OptionItem(''));
        addOption(new OptionItem('Text and Display'));
        addOption(new OptionItem(''));

        addOption(new OptionItem('Skip Text'));
        addOption(new OptionItem('Stage Opacity'));
        addOption(new OptionItem('Display Accuracy'));
        addOption(new OptionItem('Filter'));

        // Accessibility category
        addOption(new OptionItem(''));
        addOption(new OptionItem('Accessibility'));
        addOption(new OptionItem(''));

        addOption(new OptionItem('Disable Antialiasing'));
        addOption(new OptionItem('Disable Camera Panning'));
        addOption(new OptionItem('Disable Flashing Lights'));
        addOption(new OptionItem('Disable Reset Button'));
        addOption(new OptionItem('Reduced Movements'));
        addOption(new OptionItem('GPU Rendering'));

        // Metadata category
        addOption(new OptionItem(''));
        addOption(new OptionItem('Metadata'));
        addOption(new OptionItem(''));

        addOption(new OptionItem('Auto Pause'));
        #if cpp addOption(new OptionItem('Framerate Cap')); #end
        addOption(new OptionItem('FPS Counter'));
        addOption(new OptionItem('Memory Counter'));
        addOption(new OptionItem('Accurate Fps'));
        #if cpp addOption(new OptionItem('Accurate Memory')); #end

        super.create();
    }
}