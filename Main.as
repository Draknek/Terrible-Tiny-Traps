package
{
	import net.flashpunk.*;
	import net.flashpunk.utils.*;
	
	import flash.ui.*;
	import flash.text.*;
	import flash.events.*;
	import flash.display.*;

	
	//[SWF(width = "300", height = "250", backgroundColor="#FFFFFF")]
	[SWF(width = "450", height = "294", backgroundColor="#FFFFFF")]
	public class Main extends Engine
	{
		public static var clickText: TextField;
		
		public static var focused: Boolean = false;
		
		public static var realism:Boolean = false;

		
		// Magic versioning constants
		public static const magic:Number = 1.5; // 1.0 or 1.5
		public static const header:Boolean = false;
		public static const showReddit:Boolean = false;
		public static const showMoreGames:Boolean = false;
		public static const altColours:Boolean = true;

        private static var prevMuteState:Boolean = false;
		
		public function Main()
		{
			super(150, 125, 10, true);
			
			Audio.init(this);
			
			FP.world = new Level();
			FP.screen.color = Level.BLANK;
			FP.screen.scale = magic * 2;
			
			this.y = header ? 0 : -54*magic;
		}
		
		public override function setStageProperties():void
		{
			super.setStageProperties();
			stage.align = StageAlign.TOP;
			stage.scaleMode = StageScaleMode.SHOW_ALL;
		}
		
		public static var title: MyTextField;
		public static var credits: MyTextField;
		public static var newGameButton:Button;
		public static var continueButton:Button;
		public static var noDeathButton:Button;
		public static var moreGamesButton:Button;
		public static var stats:MyTextField;
		public static var continueStats:MyTextField;

		public override function init (): void
		{
			sitelock(["draknek.org", "reddit.com", "redditmedia.com", "redditads.s3.amazonaws.com", "flashgamelicense.com"]);
			
			FP.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseClick);
			FP.stage.addEventListener(Event.ACTIVATE, focusGain);
			FP.stage.addEventListener(Event.DEACTIVATE, focusLost);
			
			FP.screen.refresh();
			
			super.init();
			
			var ss:StyleSheet = new StyleSheet();
			ss.parseCSS("a:hover { text-decoration: none; } a { text-decoration: underline; }");

			title = new MyTextField(header ? 2*magic : 150*magic, 6*magic, "Terrible Tiny Traps", header ? "left" : "center", 20*magic);

			credits = new MyTextField(header ? 2*magic : 150*magic, 32*magic, "", header ? "left" : "center", 10);
			//credits.multiline = true;
			credits.htmlText = 'Created by <a href="http://www.draknek.org/?ref=ttt" target="_blank">Alan Hazelden</a>';
			
			if (showReddit) {
				credits.htmlText += ' for <a href="http://www.reddit.com/r/RedditGameJam/" target="_blank">Reddit Game Jam 03</a>';
			}
			
			credits.htmlText += '    Music by <a href="http://runtime-audio.co.uk/" target="_blank">Paul Forey</a>';
			
			credits.mouseEnabled = true;
			credits.styleSheet = ss;
			
			clickText = new MyTextField(150*magic, (125+14-14*int(header))*magic, "Click to continue", "center", 20);
			clickText.visible = false;
			
			if (header) {
				addChild(title);
				addChild(credits);
			}
			
			addChild(clickText);
			
			Data.load("tinytraps");
			
			newGameButton = new Button("New Game", 20);
			newGameButton.x = 150*magic - newGameButton.width*0.5;
			
			continueButton = new Button("Continue", 20);
			continueButton.x = 150*magic - continueButton.width*0.5;
			
			noDeathButton = new Button("Realism Mode", 20);
			noDeathButton.x = 150*magic - noDeathButton.width*0.5;
			
			moreGamesButton = new Button("More Games", 20);
			moreGamesButton.x = 150*magic - moreGamesButton.width*0.5;
			
			stats = new MyTextField(150*magic, 50, "", "center", 15);
			continueStats = new MyTextField(150*magic, 50, "", "left", 10);
			continueStats.x = continueButton.x + continueButton.width + 5;
			
			continueButton.addEventListener(MouseEvent.CLICK, function ():void {
				Main.realism = false;
				removeElements();
				Level(FP.world).load();
				FP.stage.focus = FP.stage;
                Audio.enabled = true;
				Mouse.hide();
				Logger.startPlay("", "Continue");
			});
			
			newGameButton.addEventListener(MouseEvent.CLICK, function ():void {
				Main.realism = false;
				removeElements();
				Level.clearSave();
				Level(FP.world).started = true;
				FP.stage.focus = FP.stage;
                Audio.enabled = true;
				Mouse.hide();
				Logger.startPlay("", "New game");
			});
			
			noDeathButton.addEventListener(MouseEvent.CLICK, function ():void {
				Main.realism = true;
				removeElements();
				Level(FP.world).started = true;
				FP.stage.focus = FP.stage;
                Audio.enabled = true;
				Mouse.hide();
				Logger.startPlay("Realism mode", "");
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
				
			}
			
			if (showMoreGames) {
				b.push(moreGamesButton);
			}
			
			if (bestTime >= 0) {
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

            Audio.enabled = false;
		}
		
		public static function addElements(b:Array):void
		{
			if (! header) {
				Main.title.y = (4 + 54)*magic;
				Main.credits.y = Main.title.height + Main.title.y;
				FP.engine.addChild(Main.credits);
				FP.engine.addChild(Main.title);
			}
			
			var h:Number = 0;
			
			for each (var o:DisplayObject in b) {
				h += o.height;
			}
			
			var start:Number = header ? 54*magic : Main.credits.y + Main.credits.height;
			
			var s:Number = 250*magic - h - start;
			s /= b.length + 1;
			
			var y:Number = start + s;
			
			for each (o in b) {
				o.y = int(y);
				FP.engine.addChild(o);
				y += s + o.height;
			}
		}
		
		public static function removeElements(b:Array = null):void
		{
			if (! header) {
				FP.engine.removeChild(Main.credits);
				FP.engine.removeChild(Main.title);
			}
			
			if (Main.continueButton.parent) FP.engine.removeChild(Main.continueButton);
			if (Main.continueStats.parent) FP.engine.removeChild(Main.continueStats);
			if (Main.stats.parent) FP.engine.removeChild(Main.stats);
			if (Main.noDeathButton.parent) FP.engine.removeChild(Main.noDeathButton);
			if (Main.moreGamesButton.parent) FP.engine.removeChild(Main.moreGamesButton);
			if (Main.newGameButton.parent) FP.engine.removeChild(Main.newGameButton);
			
			if (b) {
				for each (var o:DisplayObject in b) {
					if (o.parent) FP.engine.removeChild(o);
				}
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
				mochiConnected = true;
				Logger.connect(this);
				trace("Yo");
			}
			
			focusGain();
		}
		
		private function focusGain(e:Event = null):void
		{
			focused = true;
			if (FP.world is Level && Level(FP.world).started) {
				Mouse.hide();
				//Logger.startPlay(Main.realism ? "Realism mode" : "", "gained focus");
			}

            Audio.enabled = true;
		}
		
		private function focusLost(e:Event = null):void
		{
			focused = false;
			Mouse.show();
			
			if (FP.world is Level && Level(FP.world).started) {
				//Logger.endPlay("lost focus");
			}

            Audio.enabled = false;
		}
		
	}
}

