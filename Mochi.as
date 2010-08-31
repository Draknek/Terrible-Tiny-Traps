package
{
	import flash.display.*;

	import mochi.as3.*;
	
	public class Mochi
	{
		public static var boardIDEncrypted: Array = null;
		
		public static function connect (obj: DisplayObjectContainer, gameID:String, boardID:Array = null): void
		{
			boardIDEncrypted = boardID;
			MochiServices.connect(gameID, obj);
		}
		
		public static function startPlay (): void
		{
			MochiEvents.startPlay();
		}

		public static function endPlay (): void
		{
			MochiEvents.endPlay();
		}
		
		public static function trackEvent(tag:String, value:* = null):void {
			MochiEvents.trackEvent(tag, value);
		}
		
		public static function submitScore (score: int, onClose: Function = null): void
		{
			var o:Object = { n: boardIDEncrypted, f: function (i:Number,s:String):String { if (s.length == 16) return s; return this.f(i+1,s + this.n[i].toString(16));}};
			var boardID:String = o.f(0,"");
			MochiScores.showLeaderboard({boardID: boardID, score: score, onClose: onClose});
		}
		
		public static function showScores (onClose: Function = null): void
		{
			var o:Object = { n: boardIDEncrypted, f: function (i:Number,s:String):String { if (s.length == 16) return s; return this.f(i+1,s + this.n[i].toString(16));}};
			var boardID:String = o.f(0,"");
			MochiScores.showLeaderboard({boardID: boardID, onClose: onClose});
		}
		
		public static function closeScores (): void
		{
			MochiScores.closeLeaderboard();
		}
	}
}


