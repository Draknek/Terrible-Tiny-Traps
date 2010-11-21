package
{
	import flash.display.*;
	import FGL.GameTracker.*;
	import net.flashpunk.*;
	import SWFStats.*;
	import flash.system.Security;

	public class Logger
	{
		private static var FGL:GameTracker;
		
		public static function connect (obj: DisplayObjectContainer): void
		{
			Mochi.connect(obj, "8a95e5563e4d35b5");
			FGL = new GameTracker();
			Log.View(1268, "ed5c0bfd7dc2", obj.stage.loaderInfo.loaderURL);
		}
		
		public static function startPlay (mode:String, message:String): void
		{
			FGL.beginGame(0, mode, message);
			Mochi.startPlay();
			
			FGL.alert(0, "", (mode && message) ? mode + ": " + message : mode + message);
			
			Log.Play();
			
			Log.CustomMetric((mode && message) ? mode + ": " + message : mode + message);
		}

		public static function endPlay (_message:String): void
		{
			var total:int = 12 - FP.world.classCount(Target);
			var deaths:int = Level(FP.world).deaths;
			var time:int = Level(FP.world).time;
			
			var realism:String = Main.realism ? "Realism mode" : "";
			
			var message:String = "Deaths: " + deaths;
			if (_message) message += ", " + _message;
			FGL.endGame(total, realism, message);
			Mochi.endPlay();
			
			if (realism) realism = ", " + realism;
			FGL.alert(total, "", message + realism);
			
			var levelName:String = Main.realism ? "Realism mode" : "Normal mode";
			
			Log.CustomMetric(_message, levelName);
			
			Log.LevelAverageMetric("time", levelName, time);
			
			Log.LevelAverageMetric("checkpoints2", levelName, total);
			Log.LevelAverageMetric("deaths2", levelName, deaths);
		}
		
		public static function checkpoint(id:int, total:int):void
		{
			Mochi.trackEvent("gottarget", id);
			Mochi.trackEvent("targetcount", total);
			
			var deaths:int = Level(FP.world).deaths;
			
			var realism:String = Main.realism ? "Realism mode" : "";
			
			FGL.checkpoint(total, realism, "Checkpoint " + id + ", deaths: " + deaths);
			
			if (realism) realism = ", " + realism;
			FGL.alert(total, "", "Checkpoint " + id + ", deaths: " + deaths + realism);
			
			var levelName:String = Main.realism ? "Realism mode" : "Normal mode";
			
			Log.LevelCounterMetric("checkpoints", levelName);
			
			Log.CustomMetric("Checkpoint " + id, levelName);
		}
		
		public static function died():void
		{
			var levelName:String = Main.realism ? "Realism mode" : "Normal mode";
			
			Log.LevelCounterMetric("deaths", levelName);
		}
		
	}
}


