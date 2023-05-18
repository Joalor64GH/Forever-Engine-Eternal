package forever.music;

import forever.music.ChartFormat;

typedef BPMChangeEvent = {
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

/**
 * Part of me genuinely hates this class because I have no idea why or how to rewrite it.
 * TODO: rewrite this.
 * @BeastlyGabi
 */
class Conductor {
	public static var bpm:Float = 100;

	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new() {}

	public static function mapBPMChanges(song:ChartFormat) {
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.sections.length) {
			if (song.sections[i].changeBPM && song.sections[i].bpm != curBPM) {
				curBPM = song.sections[i].bpm;
				var event:BPMChangeEvent = {stepTime: totalSteps, songTime: totalPos, bpm: curBPM};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = 16;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
	}

	public static function changeBPM(newBpm:Float, measure:Float = 4 / 4) {
		bpm = newBpm;
		crochet = ((60 / bpm) * 1000);
		stepCrochet = (crochet / 4) * measure;
	}
}
