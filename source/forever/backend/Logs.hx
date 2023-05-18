package forever.backend;

import flixel.util.FlxColor;
import Sys;

/**
 * Simple logs class to support custom traces.
 */
class Logs {
	/**
	 * Simple map that contains useful ascii color strings
	 * that can be used when printing to console for nice colors.
	 * @author martinwells (https://gist.github.com/martinwells/5980517)
	 */
	public static var logColors:Map<String, String> = [
		'black' => '\033[0;30m',
		'red' => '\033[31m',
		'green' => '\033[32m',
		'yellow' => '\033[33m',
		'blue' => '\033[1;34m',
		'magenta' => '\033[1;35m',
		'cyan' => '\033[0;36m',
		'grey' => '\033[0;37m',
		'white' => '\033[1;37m',
		'default' => '\033[0;37m' // grey apparently
	];

	public static function init() {
		haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos) {
			print(v, LOG, infos);
		};
	}

	public static function print(v:Dynamic, type:PrintType = LOG, ?infos:haxe.PosInfos) {
		switch (type) {
			case DEFAULT: trace(v, infos);
			case LOG:
				if (infos.fileName.contains('flixel'))
					Sys.println('${logColors['cyan']}[ FLIXEL - ${infos.fileName}:${infos.lineNumber} - ${infos.methodName}() ] $v');
				else
					Sys.println('${logColors['white']}[ LOG - ${infos.fileName}:${infos.lineNumber} - ${infos.methodName}() ] $v');
			case DEBUG: Sys.println('${logColors['cyan']}[ DEBUG - ${infos.fileName}:${infos.lineNumber} - ${infos.methodName}() ] $v');
			case WARNING: Sys.println('${logColors['yellow']}[ WARNING - ${infos.fileName}:${infos.lineNumber} - ${infos.methodName}() ] $v');
			case ERROR: Sys.println('${logColors['red']}[ ERROR - ${infos.fileName}:${infos.lineNumber} - ${infos.methodName}() ] $v');
			case SCRIPT: Sys.println('${logColors['green']}[ SCRIPT - ${infos.fileName}:${infos.lineNumber} - ${infos.methodName}() ] $v');
			case FROM_SCRIPT: Sys.println('${logColors['green']}[ SCRIPT LOG ] $v');
			case SCRIPT_ERROR: Sys.println('${logColors['red']}[ SCRIPT ] $v');
		}

		ForeverConsole.print(v, type.returnColor());
	}
}

enum abstract PrintType(String) to String
{
	var DEFAULT:PrintType = "default";
	var LOG:PrintType = "log";
	var DEBUG:PrintType = "debug";
	var WARNING:PrintType = "warning";
	var ERROR:PrintType = "error";
	var SCRIPT:PrintType = "script";
	var FROM_SCRIPT:PrintType = "from_script";
	var SCRIPT_ERROR:PrintType = "script_error";

	public function returnColor():FlxColor
	{
		return switch (this) {
			case DEFAULT: FlxColor.GRAY;
			case LOG: FlxColor.WHITE;
			case DEBUG: FlxColor.BLUE;
			case WARNING: FlxColor.YELLOW;
			case ERROR | SCRIPT_ERROR: FlxColor.RED;
			case SCRIPT | FROM_SCRIPT : FlxColor.LIME;
			default: FlxColor.WHITE;
		}
	}
}
