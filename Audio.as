package
{
	import flash.display.*;
	import flash.events.*;
	import flash.net.SharedObject;
	import flash.ui.ContextMenu;
	import flash.ui.ContextMenuItem;
	import net.flashpunk.utils.Key;
	
	public class Audio
	{
		private static var jump:SfxrSynth;
		private static var death:SfxrSynth;
		private static var target:SfxrSynth;
		private static var bounce:SfxrSynth;
		
		private static var _mute:Boolean = false;
		private static var so:SharedObject;
		private static var menuItem:ContextMenuItem;
		
		public static function init (o:InteractiveObject):void
		{
			// Setup
			
			so = SharedObject.getLocal("audio", "/");
			
			_mute = so.data.mute;
			
			addContextMenu(o);
			
			if (o.stage) {
				addKeyListener(o.stage);
			} else {
				o.addEventListener(Event.ADDED_TO_STAGE, stageAdd);
			}
			
			// Create sounds
			
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
			
			bounce = new SfxrSynth();
			bounce.setSettingsString("0,,0.031,,0.23,0.26,,-0.35,,,,,,0.493,,,,,0.77,,,0.49,,0.26");
			bounce.cacheMutations(4);
		}
		
		public static function play (sound:String):void
		{
			if (! _mute) {
				Audio[sound].playCachedMutation();
			}
		}
		
		// Getter and setter for mute property
		
		public static function get mute (): Boolean { return _mute; }
		
		public static function set mute (newValue:Boolean): void
		{
			if (_mute == newValue) return;
			
			_mute = newValue;
			
			menuItem.caption = _mute ? "Unmute" : "Mute";
			
			so.data.mute = _mute;
			so.flush();
		}
		
		// Implementation details
		
		private static function stageAdd (e:Event):void
		{
			addKeyListener(e.target.stage);
		}
		
		private static function addContextMenu (o:InteractiveObject):void
		{
			var menu:ContextMenu = o.contextMenu || new ContextMenu;
			
			menu.hideBuiltInItems();
			
			menuItem = new ContextMenuItem(_mute ? "Unmute" : "Mute");
			
			menuItem.addEventListener(ContextMenuEvent.MENU_ITEM_SELECT, menuListener);
			
			menu.customItems.push(menuItem);
			
			o.contextMenu = menu;
		}
		
		private static function addKeyListener (stage:Stage):void
		{
			stage.addEventListener(KeyboardEvent.KEY_DOWN, keyListener);
		}
		
		private static function keyListener (e:KeyboardEvent):void
		{
			if (e.keyCode == Key.M) {
				mute = ! mute;
			}
		}
		
		private static function menuListener (e:ContextMenuEvent):void
		{
			mute = ! mute;
		}
	}
}

