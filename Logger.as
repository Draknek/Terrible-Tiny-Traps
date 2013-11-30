package
{
	import flash.display.*;
	import FGL.GameTracker.*;
	import net.flashpunk.*;
	import Playtomic.*;
	import flash.system.Security;

	public class Logger
	{
		private static var FGL:GameTracker;
		
		public static function connect (obj: DisplayObjectContainer): void
		{
			return;
			
			Mochi.connect(obj, "8a95e5563e4d35b5");
			FGL = new GameTracker();
			Log.View(1268, "ed5c0bfd7dc2", obj.stage.loaderInfo.loaderURL);
		}
		
		public static function startPlay (mode:String, message:String): void
		{
			return;
			
			FGL.beginGame(0, mode, message);
			Mochi.startPlay();
			
			FGL.alert(0, "", (mode && message) ? mode + ": " + message : mode + message);
			
			Log.Play();
			
			Log.CustomMetric((mode && message) ? mode + ": " + message : mode + message);
		}

		public static function endPlay (_message:String): void
		{
			return;
			
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
			
			/*var levelName:String = Main.realism ? "Realism mode" : "Normal mode";
			
			Log.CustomMetric(_message, levelName);
			
			Log.LevelAverageMetric("time", levelName, time);
			
			Log.LevelAverageMetric("checkpoints2", levelName, total);
			Log.LevelAverageMetric("deaths2", levelName, deaths);*/
		}
		
		public static function checkpoint(id:int, total:int):void
		{
			return;
			
			Mochi.trackEvent("gottarget", id);
			Mochi.trackEvent("targetcount", total);
			
			var deaths:int = Level(FP.world).deaths;
			var time:int = Level(FP.world).time;
			
			var realism:String = Main.realism ? "Realism mode" : "";
			
			FGL.checkpoint(total, realism, "Checkpoint " + id + ", deaths: " + deaths);
			
			if (realism) realism = ", " + realism;
			FGL.alert(total, "", "Checkpoint " + id + ", deaths: " + deaths + realism);
			
			/*var levelName:String = Main.realism ? "Realism mode" : "Normal mode";
			
			Log.LevelCounterMetric("checkpoints", levelName);
			
			Log.CustomMetric("Checkpoint " + id, levelName);*/
			
			Log.LevelCounterMetric("id_checkpoint", l(id));
			Log.LevelCounterMetric("total_checkpoint", l(total));
			Log.LevelAverageMetric("id_deaths", l(id), deaths);
			Log.LevelAverageMetric("total_deaths", l(total), deaths);
			Log.LevelAverageMetric("id_time", l(id), time);
			Log.LevelAverageMetric("total_time", l(total), time);
		}
		
		public static function died():void
		{
			return;
			
			/*var levelName:String = Main.realism ? "Realism mode" : "Normal mode";
			
			Log.LevelCounterMetric("deaths", levelName);*/
			
			var total:int = 12 - FP.world.classCount(Target);
			
			Log.LevelCounterMetric("deaths_before_total", l(total + 1));
		}
		
		public static function update():void
		{
			return;
			
			var total:int = 12 - FP.world.classCount(Target);
			var deaths:int = Level(FP.world).deaths;
			
			FGL.alert(total, "", "Deaths: " + deaths);
		}
		
		private static function l (n:int):String
		{
			var s:String = Main.realism ? "r" : "n";
			if (n < 10) s += "0";
			s += n;
			return s;
		}
	}
}


