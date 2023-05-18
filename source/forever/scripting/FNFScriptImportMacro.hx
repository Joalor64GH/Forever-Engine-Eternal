package forever.scripting;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;

class FNFScriptImportsMacro {
	public static macro function loadImports():Void {
		Compiler.include("flixel.addons.display");
	}

	public static macro function build():Array<Field> {
		var fields:Array<Field> = Context.getBuildFields();

		// dw this is just for removing unsupported things
		for (field in fields) {
			switch (field.kind) {
				case FFun(func):
					if (field.access == null)
						field.access = [];
					// inlines can't be used on hscript
					if (field.access.contains(AInline))
						field.access.remove(AInline);
				default:
					// don't do anything
			}
		}

		return fields;
	}
}
#end
