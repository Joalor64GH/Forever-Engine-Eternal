package forever.music;

import forever.music.ChartFormat.ChartNote;
import forever.music.ChartFormat.ChartSection;
import forever.music.Song;
import forever.objects.notes.*;
import haxe.Json;
import haxe.Timer;
import sys.io.File;

typedef SongMetadata = {
	var name:String; // display name
	var rawName:String; // folder name
	var characters:Array<String>;
	var stage:String; // if unspecified, don't create any.
	var skin:String; // asset skin
}

class ChartLoader {
	public static var songMeta:SongMetadata = {
		name: "Test",
		rawName: "test",
		characters: ["bf", "bf", "bf"],
		stage: null,
		skin: "base"
	};

	public static function loadChart(songName:String, difficulty:String = "normal"):ChartFormat {
		var startTime:Float = Sys.time();

		songName = songName.toLowerCase();
		difficulty = '-${difficulty.toLowerCase()}';
		if (difficulty == "-normal")
			difficulty = '';

		print('creating chart');
		songMeta.rawName = songName;

		// create empty chart
		var newChart:ChartFormat = {speed: 1, sections: [], bpm: 100.0};
		var file:String = File.getContent(Paths.songJson(songName, songName + difficulty)).trim();
		while (!file.endsWith("}"))
			file = file.substr(0, file.length - 1);

		var fnfChart:SwagSong = cast Json.parse(file).song;
		if (fnfChart != null && fnfChart.notes != null) {
			// base game chart coolio.
			print('FNF Chart found!');
			newChart.speed = fnfChart.speed;
			newChart.bpm = fnfChart.bpm;

			for (i in 0...fnfChart.notes.length) {
				newChart.sections.push({notes: [], cameraPoints: fnfChart.notes[i].mustHitSection ? 1 : 0});

				if (fnfChart.notes[i].altAnim)
					newChart.sections[i].animation = '-alt';

				if (fnfChart.notes[i].changeBPM) {
					newChart.sections[i].changeBPM = fnfChart.notes[i].changeBPM;
					newChart.sections[i].bpm = fnfChart.notes[i].bpm;
				}

				// players
				songMeta.name = fnfChart.song;
				songMeta.characters[0] = fnfChart.player1;
				songMeta.characters[1] = fnfChart.player2;
				songMeta.characters[2] = fnfChart.gfVersion != null ? fnfChart.gfVersion : 'bf';
				songMeta.stage = fnfChart.stage != null ? fnfChart.stage : null;

				if (fnfChart.assetModifier != null && fnfChart.assetModifier.length > 0)
					songMeta.skin = fnfChart.assetModifier;

				for (note in fnfChart.notes[i].sectionNotes) {
					var noteStep:Float = note[0];
					noteStep -= Init.trueSettings['Offset']; /* - | late, + | early */

					var noteDir:Int = Std.int(note[1] % 4);
					var noteLen:Float = note[2] / Conductor.stepCrochet;
					var noteType:String = "default";

					if (note.length > 2) {
						noteType = switch (note[3]) {
							case "Hurt Note": "mine"; // just converting psych notes rq
							default: note[3];
						}
					}

					// this is stupid dude.
					var gottaHitNote:Bool = note[1] > 3 ? !fnfChart.notes[i].mustHitSection : fnfChart.notes[i].mustHitSection;
					var noteStrum:Int = gottaHitNote ? 1 : 0;

					var myNote:ChartNote = {timeStep: noteStep, direction: noteDir, length: noteLen};
					if (noteType != null)
						myNote.type = noteType;
					if (noteStrum > 0)
						myNote.strumline = noteStrum;
					newChart.sections[i].notes.push(myNote);
				}
			}
		}

		var endTime:Float = Sys.time();
		print('${songMeta.rawName.toUpperCase()} ${difficulty.toUpperCase().replace('-', '')} - Loaded in ${endTime - startTime}ms', DEBUG);
		return newChart;
	}

	public static function loadChartNotes(songData:ChartFormat):Array<Note> {
		var unspawnNotes:Array<Note> = [];
		var sections:Array<ChartSection> = songData.sections;

		// load notes
		for (section in sections) {
			for (unspawnedNote in section.notes) {
				var daStrumTime:Float = #if !neko unspawnedNote.timeStep - Init.trueSettings['Offset'] /* - | late, + | early */ #else unspawnedNote[0] #end;
				var daNoteDir:Int = Std.int(unspawnedNote.direction % 4);
				var daNoteType:String = unspawnedNote.type != null ? unspawnedNote.type : "default";

				// define the note that comes before (previous note)
				var oldNote:Note = null;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

				// create the new note
				var swagNote:Note = SkinManager.generateArrow(daStrumTime, daNoteDir, daNoteType);
				swagNote.noteSpeed = songData.speed;
				swagNote.downscroll = Init.trueSettings.get('Downscroll');
				swagNote.sustainLength = unspawnedNote.length;
				swagNote.strumline = unspawnedNote.strumline;
				unspawnNotes.push(swagNote);

				for (susNote in 0...Math.floor(swagNote.sustainLength)) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
					var sustainNote:Note = SkinManager.generateArrow(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteDir,
						daNoteType, true, oldNote);
					sustainNote.downscroll = Init.trueSettings.get('Downscroll');
					sustainNote.strumline = unspawnedNote.strumline;
					unspawnNotes.push(sustainNote);
				}
			}
		}

		return unspawnNotes;
	}
}
