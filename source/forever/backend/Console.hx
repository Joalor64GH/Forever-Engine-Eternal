package forever.backend;

/**
 * Temporary console, this will get removed when `ForeverConsole` is done
 * @Sword352
 */
 
#if windows
@:buildXml('
<target id="haxe">
    <lib name="dwmapi.lib" if="windows" />
    <lib name="shell32.lib" if="windows" />
    <lib name="gdi32.lib" if="windows" />
    <lib name="ole32.lib" if="windows" />
    <lib name="uxtheme.lib" if="windows" />
</target>
')
// majority is taken from microsofts doc
@:cppFileCode('
#include "mmdeviceapi.h"
#include "combaseapi.h"
#include <iostream>
#include <Windows.h>
#include <cstdio>
#include <tchar.h>
#include <dwmapi.h>
#include <winuser.h>
#include <Shlobj.h>
#include <wingdi.h>
#include <shellapi.h>
#include <uxtheme.h>
')
#end
class Console {
	#if windows
	@:functionCode('
    // https://stackoverflow.com/questions/15543571/allocconsole-not-displaying-cout

    if (!AllocConsole())
        return;

    freopen("CONIN$", "r", stdin);
    freopen("CONOUT$", "w", stdout);
    freopen("CONOUT$", "w", stderr);
    ')
	public static function allocConsole() {}

	@:functionCode('
        HANDLE console = GetStdHandle(STD_OUTPUT_HANDLE); 
        SetConsoleTextAttribute(console, color);
    ')
	public static function setConsoleColors(color:Int) {}

	@:functionCode('
        system("CLS");
        std::cout<< "" <<std::flush;
    ')
	public static function clearScreen() {}
	#end

	/**
	 * Allocates a new console. The console will automatically be opened
	 */
	public static function openConsole() {
		#if windows
		allocConsole();
		// clearScreen();
		#end
	}
}
