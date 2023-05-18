package forever.music;

import flixel.tweens.FlxEase.EaseFunction;

/**
 * for Reference:
 *
 *	Event Types:
 *		- "Timed Event" [event triggered by a step hit]
 *		- "Camera Event" [basically replaces "Must Hit Section"]
 *		- "BPM Change" [event triggered if a section has a BPM Change flag]
 */
typedef ChartFormat = {
	var speed:Float; // initial speed
	var sections:Array<ChartSection>;
	var bpm:Float; // initial bpm
}

typedef ChartSection = {
	var notes:Array<ChartNote>;
	var cameraPoints:Int;
	var ?animation:String; // -alt, -gfSing, etc...
	var ?changeBPM:Bool; // needed for bpm changes
	var ?bpm:Float;
}

typedef ChartNote = {
	var timeStep:Float;
	var direction:Int;
	var ?strumline:Int; // default is 0
	var ?length:Float;
	var ?type:String;
}

typedef ChartEvent<EventList> = {
	var event:EventList;
	var ?step:Int; // some events don't rely on this, so there's no need to make it obligatory
}

enum DefaultEventList {
	CustomEvent(name:String, script:String, args:Array<Dynamic>);
	ChangeChar(whose:Int, newCharacter:String);
	PlayHeyAnim(whose:Int);
	MoveCamToChar(whose:Int);
}

enum ModchartEventsList {
	ChangeScrollSpeed(strum:Int, newSpeed:Float, easing:EaseFunction);
	TweenStrum(strum:Int, property:String, value:Float, duration:Float, ease:EaseFunction);
}

enum ShaderEventsList {
	AddShader(index:String, script:String, objects:Array<String>, ?parameters:Array<Dynamic>, ?allowRecycling:Bool);
	SetShaderUniform(index:String, uniform:String, value:Dynamic);
	RemoveShader(index:String);
	ClearAllShaders;
}

typedef GameplayEvent = ChartEvent<DefaultEventList>;
typedef ModchartEvent = ChartEvent<ModchartEventsList>;
typedef ShaderEvent = ChartEvent<ShaderEventsList>;
