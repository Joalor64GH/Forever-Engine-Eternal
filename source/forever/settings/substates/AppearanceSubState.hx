package forever.settings.substates;

class AppearanceSubState extends BaseOptionSubState
{
    override function create()
    {
        // Interface category
        addOption(new OptionItem('Interface'));
        addOption(new OptionItem(''));
        
        addOption(new OptionItem('Note Skin'));
        addOption(new OptionItem('Song Timer'));
        addOption(new OptionItem('End Screen'));
        addOption(new OptionItem('Counter'));

        // Gameplay category
        addOption(new OptionItem(''));
        addOption(new OptionItem('Gameplay'));
        addOption(new OptionItem(''));

        addOption(new OptionItem('Fixed Judgements'));
        addOption(new OptionItem('Simply Judgements'));
        addOption(new OptionItem('Disable Note Splashes'));
        addOption(new OptionItem('Opaque Arrows'));
        addOption(new OptionItem('Opaque Holds'));

        super.create();
    }
}