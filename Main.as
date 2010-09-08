package
{
	import net.flashpunk.*;
	import net.flashpunk.utils.*;
	
	import flash.ui.*;
	import flash.text.*;
	import flash.events.*;
	import flash.display.*;
	
	[SWF(width = "300", height = "250", backgroundColor="#FFFFFF")]
	public class Main extends Engine
	{
		public static var clickText: TextField;
		
		public static var jump:SfxrSynth;
		public static var death:SfxrSynth;
		public static var target:SfxrSynth;
		
		public static var focused: Boolean = false;
		
		public function Main() 
		{
			super(150, 125, 10, true);
			
			Mochi.connect(this, "8a95e5563e4d35b5");
			
			FP.world = new Level();
			FP.screen.color = Level.BLANK;
			FP.screen.scale = 2;
			
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
		
		public override function setStageProperties():void
		{
			super.setStageProperties();
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
		}
		
		public override function init (): void
		{
			//sitelock("draknek.org");
			
			FP.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseClick);
			FP.stage.addEventListener(Event.ACTIVATE, focusGain);
			FP.stage.addEventListener(Event.DEACTIVATE, focusLost);
			
			FP.screen.refresh();
			
			super.init();
			
			var ss:StyleSheet = new StyleSheet();
			ss.parseCSS("a:hover { text-decoration: underline; } a { text-decoration: none; color: #FF8B60; }");

			var title: MyTextField = new MyTextField(2, 6, "Terrible Tiny Traps", "left", 20);

			var credits: MyTextField = new MyTextField(2, 32, "", "left", 10);
			credits.htmlText = 'Created by <a href="http://www.draknek.org/?ref=ttt" target="_blank">Alan Hazelden</a> for <a href="http://www.reddit.com/r/RedditGameJam/" target="_blank">Reddit Game Jam 03</a>';
			credits.mouseEnabled = true;
			credits.styleSheet = ss;
			
			clickText = new MyTextField(150, 125, "Click to continue", "center", 20);
			clickText.visible = false;
			
			addChild(title);
			addChild(credits);
			addChild(clickText);
			
			Data.load("tinytraps");
			
			var newGameButton:Button = new Button("New Game", 20);
			newGameButton.x = 150 - newGameButton.width*0.5;
			newGameButton.y = 50 + 100 - newGameButton.height*0.5;
			
			addChild(newGameButton);
			
			var level:Level = FP.world as Level;
			
			if (Data.readInt("time", 0))
			{
				var continueButton:Button = new Button("Continue", 20);
				continueButton.x = 150 - continueButton.width*0.5;
				
				var s:Number = 200 - continueButton.height - newGameButton.height;
				s /= 3.0;
				
				continueButton.y = 50 + s;
				newGameButton.y = continueButton.y + continueButton.height + s;
			
				addChild(continueButton);
				
				continueButton.addEventListener(MouseEvent.CLICK, function ():void {
					removeChild(continueButton);
					removeChild(newGameButton);
					level.load();
					FP.stage.focus = FP.stage;
				});
				
				newGameButton.addEventListener(MouseEvent.CLICK, function ():void {
					removeChild(continueButton);
					removeChild(newGameButton);
					Level.clearSave();
					FP.stage.focus = FP.stage;
				});
			} else {
				newGameButton.addEventListener(MouseEvent.CLICK, function ():void {
					removeChild(newGameButton);
					Level.clearSave();
					FP.stage.focus = FP.stage;
				});
			}
		}
		
		public function sitelock (allowed:*):Boolean
		{
			var url:String = FP.stage.loaderInfo.url;
			var startCheck:int = url.indexOf('://' ) + 3;
			
			if (url.substr(0, startCheck) == 'file://') return true;
			
			var domainLen:int = url.indexOf('/', startCheck) - startCheck;
			var host:String = url.substr(startCheck, domainLen);
			
			if (allowed is String) allowed = [allowed];
			for each (var d:String in allowed)
			{
				if (host.substr(-d.length, d.length) == d) return true;
			}
			
			parent.removeChild(this);
			throw new Error("Error: this game is sitelocked");
			
			return false;
		}
		
		private function mouseClick(e:Event):void
		{
			focusGain();
		}
		
		private function focusGain(e:Event = null):void
		{
			focused = true;
		}
		
		private function focusLost(e:Event = null):void
		{
			focused = false;
		}
		
	}
}

