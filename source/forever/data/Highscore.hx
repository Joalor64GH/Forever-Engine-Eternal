package forever.data;

typedef ScoreData = {
	var score:Int;
	var breaks:Null<Int>;
	var accuracy:Null<Float>;
	var rating:String;
}

class Highscore {
	public static var songScores:Map<String, ScoreData> = new Map<String, ScoreData>();
	static var DEFAULT_SCORE:ScoreData = {
		score: 0,
		breaks: 0,
		accuracy: 0,
		rating: "?"
	};

	public static function saveScore(song:String, score:ScoreData, ?diff:Int = 0):Void {
		var daSong:String = formatSong(song, diff);

		if (songScores.exists(daSong)) {
			if (songScores.get(daSong).score < score.score)
				setScore(daSong, score);
		}
		else
			setScore(daSong, score);
	}

	public static function saveWeekScore(week:Int = 1, score:ScoreData, ?diff:Int = 0):Void {
		var daWeek:String = formatSong('week' + week, diff);

		if (songScores.exists(daWeek)) {
			if (songScores.get(daWeek).score < score.score)
				setScore(daWeek, score);
		}
		else
			setScore(daWeek, score);
	}

	/**
	 * YOU SHOULD FORMAT SONG WITH formatSong() BEFORE TOSSING IN SONG VARIABLE
	 */
	static function setScore(song:String, score:ScoreData):Void {
		// Reminder that I don't need to format this song, it should come formatted!
		songScores.set(song, score);
		Tools.invokeTempSave(function(save) {
			save.data.songScores = songScores;
		}, "scores");
	}

	public static function formatSong(song:String, diff:Int):String {
		var daSong:String = song;
		var difficulty:String = '-' + forever.backend.LevelData.curDifficulties[diff].toLowerCase();
		difficulty = difficulty.replace('-normal', '');
		daSong += difficulty;
		return daSong;
	}

	public static function getScore(song:String, diff:Int):ScoreData {
		if (!songScores.exists(formatSong(song, diff)))
			setScore(formatSong(song, diff), DEFAULT_SCORE);

		return songScores.get(formatSong(song, diff));
	}

	public static function getWeekScore(week:Int, diff:Int):ScoreData {
		if (!songScores.exists(formatSong('week' + week, diff)))
			setScore(formatSong('week' + week, diff), DEFAULT_SCORE);

		return songScores.get(formatSong('week' + week, diff));
	}

	public static function load():Void {
		Tools.invokeTempSave(function(save) {
			if (save.data.songScores != null)
				songScores = save.data.songScores;
		}, "scores");
	}
}
