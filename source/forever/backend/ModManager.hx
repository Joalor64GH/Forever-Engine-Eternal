package forever.backend;

import sys.FileSystem;

class ModManager {
	public static var currentMod:String = '';
	public static var keyedModFolders:Array<String> = [];
	public static var activeModFolders:Map<String, Bool> = [];

	/**
	 * NOTE: mod hierarchy is not necessarily a thing, the `currentMod` variable covers which mod is **currently** active.
	 * current active mods are going to be prioritized, meaning Freeplay Song List for example will be the same as the mod's freeplay list
	 * however most mods should be able to be displayed in things like character lists in debug menus and such.
	 */
	public static function loadMods():Void {
		keyedModFolders = [];
		activeModFolders.clear();

		if (FileSystem.exists('mods')) {
			for (i in FileSystem.readDirectory('mods')) {
				if (FileSystem.exists('mods/${i}/modConfig.ini')) {
					var modFile:String = ('mods/${i}/modConfig.ini').trim();
					var modConf:SSIni = new SSIni(modFile);

					for (j in modConf.sections.keys()) {
						var data = modConf.sections.get(j);
						if (data != null) {
							if (data.get("enabled") != null && cast(data.get("enabled"), Bool))
								activeModFolders.set(j, cast(data.get("enabled"), Bool));
						}
					}
				}
				keyedModFolders.push(i);
			}
		}
	}
}
