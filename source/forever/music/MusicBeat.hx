package forever.music;

import forever.data.Controls;
import forever.music.Conductor.BPMChangeEvent;
import forever.scripting.ScriptableState;

class MusicBeatState extends ScriptableState {
	public var curStep:Int = 0;
	public var curBeat:Int = 0;
	public var curSect:Int = 0;

	public var decStep:Float = 0.0;
	public var decBeat:Float = 0.0;
	public var decSect:Float = 0.0;

	// TODO: players
	private var controls(get, never):Controls;

	function get_controls():Controls
		return Controls.current;

	override function create() {
		// dump //// dumb??? @BeastlyGabi
		Paths.clearStoredMemory();
		if ((!Std.isOfType(this, forever.states.PlayState)))
			Paths.clearUnusedMemory();

		super.create();

		// For debugging
		#if debug
		flixel.FlxG.watch.add(Conductor, "songPosition");
		flixel.FlxG.watch.add(this, "curBeat");
		flixel.FlxG.watch.add(this, "curStep");
		flixel.FlxG.watch.add(this, "curSect");
		#end
	}

	override function update(elapsed:Float) {
		updateContents();
		super.update(elapsed);
	}

	public var lastStep:Int = 0;
	public var lastBeat:Int = 0;
	public var lastSect:Int = 0;

	public function updateContents() {
		updateSection();
		updateCurStep();
		updateBeat();

		// delta time bullshit
		var trueStep:Int = curStep;
		for (i in storedSteps)
			if (i < lastStep)
				storedSteps.remove(i);
		for (i in lastStep...trueStep) {
			if (!storedSteps.contains(i) && i > 0) {
				curStep = i;
				stepHit();
				skippedSteps.push(i);
			}
		}
		if (skippedSteps.length > 0)
			skippedSteps = [];
		curStep = trueStep;

		if (curStep > lastStep && !storedSteps.contains(curStep)) {
			lastStep = curStep;
			stepHit();
		}

		if (curBeat > lastBeat && curStep % 4 == 0) {
			lastBeat = curBeat;
			beatHit();
		}

		if (curSect > lastSect && curBeat % 4 == 0) {
			lastSect = curSect;
			sectHit();
		}
	}

	var storedSteps:Array<Int> = [];
	var skippedSteps:Array<Int> = [];

	public function updateBeat():Void {
		curBeat = Math.floor(curStep / 4);
		decBeat = curStep / 4;
	}

	public function updateSection():Void {
		curSect = Math.floor(curBeat / 4);
		decSect = curBeat / 4;
	}

	public function updateCurStep():Void {
		var lastChange:BPMChangeEvent = {stepTime: 0, songTime: 0, bpm: 0};
		for (i in 0...Conductor.bpmChangeMap.length)
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];

		var realStepCrochet:Float = (Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet;
		curStep = lastChange.stepTime + Math.floor(realStepCrochet);
		decStep = lastChange.stepTime + realStepCrochet;
	}

	public function stepHit():Void {
		if (!storedSteps.contains(curStep))
			storedSteps.push(curStep);
	}

	public function beatHit():Void {}

	public function sectHit():Void {}
}

class MusicBeatSubState extends ScriptableSubState {
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curSect:Int = 0;

	public var decStep:Float = 0.0;
	public var decBeat:Float = 0.0;
	public var decSect:Float = 0.0;

	private var controls(get, never):Controls;

	function get_controls():Controls
		return Controls.current;

	private var lastBeat:Int = 0;
	private var lastStep:Int = 0;
	private var lastSect:Int = 0;

	override function update(elapsed:Float) {
		updateCurStep();
		curBeat = Math.floor(curStep / 4);
		curSect = Math.floor(curBeat / 4);
		decBeat = curStep / 4;
		decSect = curBeat / 4;

		if (curStep > lastStep) {
			lastStep = curStep;
			stepHit();
		}

		if (curBeat > lastBeat && curStep % 4 == 0) {
			lastBeat = curBeat;
			beatHit();
		}

		if (curSect > lastSect && curBeat % 4 == 0) {
			lastSect = curSect;
			sectHit();
		}

		super.update(elapsed);
	}

	private function updateCurStep():Void {
		var lastChange:BPMChangeEvent = {stepTime: 0, songTime: 0, bpm: 0};
		for (i in 0...Conductor.bpmChangeMap.length)
			if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void {}

	public function beatHit():Void {}

	public function sectHit():Void {}
}
