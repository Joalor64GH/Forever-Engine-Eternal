package forever.objects.notes;

import flixel.tweens.FlxEase;
import flixel.FlxCamera;
import flixel.tweens.FlxTween;
import forever.data.utils.FNFSprite;
import forever.objects.notes.Strumline.Receptor;
import forever.scripting.FNFScript;
import forever.states.PlayState;
import sys.FileSystem;

class ModchartHelper {
	public var game:PlayState = PlayState.current;
	public var curTweens:Map<FNFSprite, FlxTween> = [];
	public var tweenManager:FlxTweenManager;
	public var strumlines:Array<Strumline>;
	public var receptors:Array<Receptor>;
	public var script:FNFScript;

	public function new(song:String, strumlines:Array<Strumline>, ?receptors:Array<Receptor>):Void {
		this.strumlines = strumlines;

		if (receptors != null)
			this.receptors = receptors;
		else {
			this.receptors = [];
			for (strumline in this.strumlines)
				for (receptor in strumline.receptors)
					this.receptors.push(receptor);
		}

		tweenManager = new FlxTweenManager();

		var scriptPath = Paths.songScript(Tools.spaceToDash(song.toLowerCase()), "modchart");
		if (FileSystem.exists(scriptPath)) {
			script = new FNFScript(scriptPath);
			script.set("FlxEase", FlxEase);
			script.set("game", game);
			script.set("tweenManager", tweenManager);
			script.set("shaderHandler", game.shaderHandler);
			script.set("getReceptorString", function(id:Int) return Receptor.dirs[id]);
			script.set("getNoteString", function(note:Note) return Receptor.dirs[note.direction]);
			script.set("strumLines", this.strumlines);
			script.set("receptors", this.receptors);
			script.set("strumHUDs", game.strumHUD);
			script.set("noteHUDs", game.notesHUD);
			script.set("sustainHUDs", game.sustainsHUD);
			script.set("strumHUD", game.strumHUD);
			script.set("notesHUD", game.notesHUD);
			script.set("sustainsHUD", game.sustainsHUD);
			script.set("OPPONENT_CAM_INDEX", 0);
			script.set("PLAYER_CAM_INDEX", 1);

			for (i in 0...this.strumlines.length)
				script.set('strumLine${i}', this.strumlines[i]);

			for (i in 0...this.receptors.length)
				script.set('receptor${i}', this.receptors[i]);

			for (i in 0...game.strumHUD.length)
				script.set('strumHUD${i}', game.strumHUD[i]);

			for (i in 0...game.notesHUD.length)
				script.set('noteHUD${i}', game.notesHUD[i]);

			for (i in 0...game.sustainsHUD.length)
				script.set('sustainHUD${i}', game.sustainsHUD[i]);

			script.set("tweenReceptor", tweenReceptor);
			script.set("tweenReceptorByID", tweenReceptorByID);

			script.set("addShader", function(index:String, shaderScript:String, ?parameters:Array<Dynamic>) {
				var allCameras:Array<FlxCamera> = [for (hud in game.notesHUD) hud];
				for (hud in game.sustainsHUD)
					allCameras.push(hud);
				for (hud in game.strumHUD)
					allCameras.push(hud);
				game.shaderHandler.addShader(index, shaderScript, cast allCameras, parameters);
			});

			script.set("addShaderToReceptors", function(index:String, shaderScript:String, ?parameters:Array<Dynamic>, recycle:Bool = false) {
				game.shaderHandler.addShader(index, shaderScript, cast game.strumHUD, parameters, recycle);
			});

			script.set("addShaderToNotes", function(index:String, shaderScript:String, ?parameters:Array<Dynamic>, recycle:Bool = false) {
				game.shaderHandler.addShader(index, shaderScript, cast game.notesHUD, parameters, recycle);
			});

			script.set("addShaderToSustains", function(index:String, shaderScript:String, ?parameters:Array<Dynamic>, recycle:Bool = false) {
				game.shaderHandler.addShader(index, shaderScript, cast game.sustainsHUD, parameters, recycle);
			});

			script.set("addShaderToSpecifiedReceptors", function(receptorsIndex:Int, index:String, shaderScript:String, ?parameters:Array<Dynamic>, recycle:Bool = false) {
				game.shaderHandler.addShader(index, shaderScript, [game.strumHUD[receptorsIndex]], parameters, recycle);
			});

			script.set("addShaderToSpecificNotes", function(notesIndex:Int, index:String, shaderScript:String, ?parameters:Array<Dynamic>, recycle:Bool = false) {
				game.shaderHandler.addShader(index, shaderScript, [game.notesHUD[notesIndex]], parameters, recycle);
			});

			script.set("addShaderToSpecificSustains", function(sustainsIndex:Int, index:String, shaderScript:String, ?parameters:Array<Dynamic>, recycle:Bool = false) {
				game.shaderHandler.addShader(index, shaderScript, [game.sustainsHUD[sustainsIndex]], parameters, recycle);
			});

			script.call('init');
		}
	}

	public function update(delta:Float):Void {
		tweenManager.update(delta);
		call('update', [delta]);

		for (strumline in strumlines)
			for (note in strumline.allNotes)
				if (curTweens.exists(note))
					call('onNoteTween', [note, curTweens.get(note)]);

		for (receptor in receptors)
			if (curTweens.exists(receptor))
				call('onReceptorTween', [receptor, curTweens.get(receptor)]);
	}

	public function tweenReceptorByID(id:Int, Values:Dynamic, Duration:Float = 1, ?TweenOptions:TweenOptions, ?onComplete:FlxTween->Void)
		return tweenReceptor(receptors[id], Values, Duration, TweenOptions, onComplete);

	public function tweenReceptor(receptor:Receptor, Values:Dynamic, Duration:Float = 1, ?TweenOptions:TweenOptions, ?onComplete:FlxTween->Void) {
		if (receptor != null) {
			if (TweenOptions == null)
				TweenOptions = {};

			TweenOptions.onComplete = function(tween) {
				curTweens.remove(receptor);
				call('onReceptorTweenEnd', [receptor, tween]);
				if (onComplete != null)
					onComplete(tween);
			};

			curTweens.set(receptor, tweenManager.tween(receptor, Values, Duration, TweenOptions));
			call('onReceptorTweenStart', [receptor, curTweens.get(receptor)]);
		}
	}

	public function call(func:String, ?args:Null<Array<Dynamic>>):Void {
		if (script != null)
			script.call(func, args);
	}
}
