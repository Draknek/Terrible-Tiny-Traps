package
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.SharedObject;
	import net.flashpunk.utils.Key;
	
	public class Audio
	{
		private static var jump:SfxrSynth;
		private static var death:SfxrSynth;
		private static var target:SfxrSynth;
		private static var _mute:Boolean = false;
		private static var so:SharedObject;
		
		public static function init (o:DisplayObject):void
		{
			so = SharedObject.getLocal("audio", "/");
			
			_mute = so.data.mute;
			
			if (o.stage) {
				o.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
			} else {
				o.addEventListener(Event.ADDED_TO_STAGE, stageAdd);
			}
			
			jump = new SfxrSynth();
			jump.setSettingsString("0,,0.19,,0.23,0.347,,0.252,,,,,,0.285,,,,,0.67,,,0.099,,0.15");
			jump.cacheMutations(4);
			
			death = new SfxrSynth();
			death.setSettingsString("3,,0.289,0.42,0.36,0.061,,,,,,,,,,0.491,0.222,-0.086,1,,,,,0.4");
			death.cacheMutations(4);
			
			target = new SfxrSynth();
			//target.setSettingsString("1,0.072,0.009,,0.51,0.374,0.034,0.139,,0.596,0.542,0.013,,0.047,0.015,,0.014,0.021,1,,0.025,,,0.3");
			target.setSettingsString("2,0.072,0.05,,0.51,0.55,0.034,0.08,0.179,0.596,0.542,0.013,,0.047,0.015,,0.014,0.021,0.91,,0.025,,,0.3");
			target.cacheMutations(4);
		}
		
		public static function play (sound:String):void
		{
			if (! _mute) {
				Audio[sound].playCachedMutation();
			}
		}
		
		private static function stageAdd (e:Event):void
		{
			e.target.stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
		}
		
		private static function keyListener (e:KeyboardEvent):void
		{
			if (e.keyCode == Key.M) {
				_mute = ! _mute;
				so.data.mute = _mute;
				so.flush();
			}
		}
	}
}

