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
		
		public static var focused: Boolean = false;
		
		public static var realism:Boolean = false;
		
		public function Main()
		{
			super(150, 125, 10, true);
			
			Audio.init(this);
			
			FP.world = new Level();
			FP.screen.color = Level.BLANK;
			FP.screen.scale = 2;
		}
		
		public override function setStageProperties():void
		{
			super.setStageProperties();
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
		}
		
		public var newGameButton:Button;
		public var continueButton:Button;
		public var noDeathButton:Button;
		public var stats:MyTextField;
		public var continueStats:MyTextField;
		
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
			
			newGameButton = new Button("New Game", 20);
			newGameButton.x = 150 - newGameButton.width*0.5;
			
			continueButton = new Button("Continue", 20);
			continueButton.x = 150 - continueButton.width*0.5;
			
			noDeathButton = new Button("Realism Mode", 20);
			noDeathButton.x = 150 - noDeathButton.width*0.5;
			
			stats = new MyTextField(150, 50, "", "center", 15);
			continueStats = new MyTextField(150, 50, "", "left", 10);
			continueStats.x = continueButton.x + continueButton.width + 5;
			
			continueButton.addEventListener(MouseEvent.CLICK, function ():void {
				Main.realism = false;
				removeChild(continueButton);
				removeChild(newGameButton);
				if (continueStats.parent) removeChild(continueStats);
				if (stats.parent) removeChild(stats);
				if (noDeathButton.parent) removeChild(noDeathButton);
				Level(FP.world).load();
				FP.stage.focus = FP.stage;
				Mouse.hide();
			});
			
			newGameButton.addEventListener(MouseEvent.CLICK, function ():void {
				Main.realism = false;
				if (continueButton.parent) removeChild(continueButton);
				if (continueStats.parent) removeChild(continueStats);
				if (stats.parent) removeChild(stats);
				if (noDeathButton.parent) removeChild(noDeathButton);
				removeChild(newGameButton);
				Level.clearSave();
				Level(FP.world).started = true;
				FP.stage.focus = FP.stage;
				Mouse.hide();
			});
			
			noDeathButton.addEventListener(MouseEvent.CLICK, function ():void {
				Main.realism = true;
				if (continueButton.parent) removeChild(continueButton);
				if (continueStats.parent) removeChild(continueStats);
				if (stats.parent) removeChild(stats);
				if (noDeathButton.parent) removeChild(noDeathButton);
				removeChild(newGameButton);
				Level(FP.world).started = true;
				FP.stage.focus = FP.stage;
				Mouse.hide();
			});
			
			showButtons();
		}
		
		public function showButtons ():void
		{
			var b:Array = [];
			
			if (Data.readInt("time", 0)) {
				b.push(continueButton);
				
				var targetCount:int = 0;
				for (var i:int = 0; i <= 12; i++) {
					if (Data.readBool("gottarget"+i)) targetCount++;
				}
				
				var time:int = Data.readInt("time", 0);
				var mins:int = time / 600;
				var secs:Number = (time % 600) / 10.0;
				
				var deaths:int = Data.readInt("deaths", 0);
				var deathText:String = deaths + " deaths";
				if (deaths == 1) deathText = "1 death";
				
				continueStats.text = targetCount + "/12\n" + mins + ":" + (secs < 10 ? "0" : "") + secs + "\n" + deathText;
				
				addChild(continueStats);
			}
			
			b.push(newGameButton);
			
			var bestTime:int = Data.readInt("besttime", -1);
			var bestDeaths:int = Data.readInt("bestdeaths", -1);
			
			if (bestTime >= 0) {
				b.push(noDeathButton);
				
				mins = bestTime / 600;
				secs = (bestTime % 600) / 10.0;
				
				stats.text = "Best time: " + mins + ":" + (secs < 10 ? "0" : "") + secs + "\nLeast deaths: " + bestDeaths;
				var bestRealismTime:int = Data.readInt("bestrealismtime", -1);
				var bestRealismTargets:int = Data.readInt("bestrealismtargets", 0);
				
				if (bestRealismTime > 0) {
					mins = bestRealismTime / 600;
					secs = (bestRealismTime % 600) / 10.0;
				
					stats.text += "\nRealism mode: " + mins + ":" + (secs < 10 ? "0" : "") + secs;
				} else if (bestRealismTargets > 0) {
					stats.text += "\nRealism mode: " + bestRealismTargets + "/12";
				}
			
				b.push(stats);
			}
			
			addElements(b);
			
			if (continueStats.parent) {
				continueStats.y = continueButton.y + (continueButton.height - continueStats.height)*0.5;
			}
		}
		
		public static function addElements(b:Array):void
		{
			var h:Number = 0;
			
			for each (var o:DisplayObject in b) {
				h += o.height;
			}
			
			var s:Number = 200 - h;
			s /= b.length + 1;
			
			var y:Number = 54 + s;
			
			for each (o in b) {
				o.y = int(y);
				FP.engine.addChild(o);
				y += s + o.height;
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
		
		private static var mochiConnected:Boolean = false;
		
		private function mouseClick(e:Event):void
		{
			if (! mochiConnected) {
				Mochi.connect(this, "8a95e5563e4d35b5");
				mochiConnected = true;
			}
			
			focusGain();
		}
		
		private function focusGain(e:Event = null):void
		{
			focused = true;
			if (FP.world is Level && Level(FP.world).started) {
				Mouse.hide();
			}
		}
		
		private function focusLost(e:Event = null):void
		{
			focused = false;
			Mouse.show();
		}
		
	}
}

