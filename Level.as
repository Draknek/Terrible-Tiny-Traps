package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.ui.Mouse;
	
	public class Level extends World
	{
		[Embed(source = 'level.png')]
		public static var levelGfx: Class;
		
		public static const BLANK: uint = 0xFFFFFF;
		public static const SOLID: uint = 0x333333;
		public static const RED: uint = 0xFFFF8B60;
		public static const BLUE: uint = 0xFF9494FF;
		public static const PLAYER: uint = Main.altColours ? BLUE : RED;
		public static const SPIKE: uint = Main.altColours ? RED : BLUE;
		//public static const TARGET: uint = 0xFF94FF94;
		
		public static const NEWRECORD: uint = RED;
		
		public static const SPECIAL: uint = 0x654321;
		
		public var player: Player;
		
		public var taunter:Taunter;
		
		public var door:Target;
		
		public var fallingPlayer:FallingPlayer;
		
		public var started:Boolean = true;
		
		public var time:int = 1;
		public var deaths:int = 0;
		
		public var trails:Array = [];
		
		public var escapeHandler:Function;
		public var actionHandler:Function;
		
		public var splash:Boolean;
		
		public function Level(_splash:Boolean = false)
		{
			splash = _splash;
			
			Input.define("MENU_ACTION", Key.SPACE, Key.Z, Key.X, Key.C, Key.ENTER);
			
			var level: BitmapData = FP.getBitmap(levelGfx).clone();
			
			var solid: Entity = new Entity();
			
			add(solid);
			
			solid.type = "solid";
			
			solid.graphic = new Stamp(level);
			
			var grid: Grid = new Grid(level.width, level.height, 1, 1);
			
			solid.mask = grid;
			
			player = new Player();
			
			player.active = ! splash;
			player.visible = ! splash;
			
			add(player);
			
			if (splash) {
				taunter = new Taunter();
				add(taunter);
			}
			
			var checkpointGrid: Grid = new Grid(level.width, level.height, 1, 1);
			
			var targetID:int = 0;
			
			for (var y: int = 0; y < level.height; y++) {
				for (var x: int = 0; x < level.width; x++) {
					var colour: uint = 0x00FFFFFF & level.getPixel(x, y);
					
					level.setPixel(x, y, BLANK);
					
					if (colour == 0xFFFFFF) {
						continue;
					} else if (colour == 0xCEE3F8) {
						level.setPixel(x, y, 0xCEE3F8);
					} else if (colour == 0x0) {
						grid.setCell(x, y, true);
						level.setPixel(x, y, SOLID);
					}
					else if (colour == 0xCCCCCC) {
						checkpointGrid.setCell(x, y, true);
					}
					else if (colour == 0x0000FF) {
						player.x = player.spawnX = x - 2;
						player.y = player.spawnY = y - 3;
					}
					else if (colour == 0xFF0000) {
						add(new Spike(x, y));
					}
					else if (colour == 0xFF00FF) {
						targetID++;
						
						var target:Target = new Target(x - 2, y, targetID);
						
						add(target);
						
						if (! door) {
							door = target;
						}
						
						level.setPixel(x+1, y+1, 0xFFFFFF);
						level.setPixel(x+2, y+2, 0xFFFFFF);
						level.setPixel(x+1, y+3, 0xFFFFFF);
						level.setPixel(x+0, y+4, 0xFFFFFF);
						level.setPixel(x-1, y+3, 0xFFFFFF);
						level.setPixel(x-2, y+2, 0xFFFFFF);
						level.setPixel(x-1, y+1, 0xFFFFFF);
					} else if (colour == 0xff1b2e) {
						if (taunter) {
							taunter.x = x - 2;
							taunter.y = y - 3;
						}
					} else {
						level.setPixel(x, y, colour | 0xFF000000);
						level.floodFill(x, y, SPECIAL | 0xFF000000);
						
						var rect: Rectangle = level.getColorBoundsRect(0xFFFFFFFF, SPECIAL | 0xFF000000);
						
						if (colour == 0xFFFF00) { // up-down spike
							add(new MovingSpike(level, rect, 0, 1));
						} else if (colour == 0x00FFFF) { // left-right spike
							add(new MovingSpike(level, rect, 1, 0));
						} else if (colour == 0x00FF00) { // lift
							add(new MovingPlatform(level, rect, 0, 1));
						} else if (colour == 0xC000FF) { // lift
							add(new MovingPlatform(level, rect, 1, 0));
						}
						
						level.floodFill(x, y, BLANK | 0xFF000000);
					}
				}
			}
			
			add(new Checkpoint(checkpointGrid));
			
			if (splash) door.door.frame = 3;
		}
		
		public override function update (): void
		{
			if (actionHandler != null && Input.pressed("MENU_ACTION")) {
				actionHandler();
				actionHandler = null;
				escapeHandler = null;
				return;
			}
			
			if (escapeHandler != null && Input.pressed(Key.ESCAPE)) {
				escapeHandler();
				escapeHandler = null;
				actionHandler = null;
				return;
			}
			
			if (! started || (! splash && ! Main.focused)) { return; }
			
			if (Input.pressed(Key.ESCAPE)) {
				Logger.endPlay("pressed escape");
				save(false);
				var bgLevel:Level = new Level;
				bgLevel.started = false;
				FP.world = bgLevel;
				Main(FP.engine).showButtons();
				FP.stage.focus = FP.stage;
				Mouse.show();
				return;
			}

            // Dunno if this is the right place to put this
            Audio.setTargetsRemaining(typeCount("target"));
			
			if (typeCount("target") == 0) {
				completed();
				
				return;
			}
			
			super.update();
			
			if (fallingPlayer) {
				if (Input.pressed(-1) && fallingPlayer.world) {
					started = false;
					remove(fallingPlayer);
				}
			} else {
				time++;
			
				if (time % 10 == 0) save(false);
				if (time % 150 == 0) Logger.update();
			}
		}
		
		public override function render (): void
		{
			super.render();
			
			if (! started || (! splash && ! Main.focused)) {
				Draw.rect(0, 28, 150, 125, 0xFFFFFF, 0.9);
			}
			
			if (started || splash) return;
			
			Main.clickText.visible = (started && ! Main.focused);
		}
		
		public function load ():void
		{
			if (fallingPlayer) remove(fallingPlayer);
			
			Data.load("tinytraps");
			player.x = player.spawnX = Data.readInt("playerx", player.x);
			player.y = player.spawnY = Data.readInt("playery", player.y);
			
			time = Data.readInt("time", 0);
			deaths = Data.readInt("deaths", 0);
			
			var a:Array = [];
			
			getClass(Target, a);
			
			var tRemoved:int = 0;
			
			for each (var t:Target in a)
			{
				if (Data.readBool("gottarget"+t.id, false))
				{
					remove(t);
					tRemoved++;
				}
			}
			
			started = true;
			
			updateMoving(tRemoved);
			
			updateLists();
		}
		
		public static function clearSave():void
		{
			Data.writeInt("playerx", 0);
			Data.writeInt("playery", 0);
			Data.writeInt("time", 0);
			Data.writeInt("deaths", 0);
			
			for (var i:int = 0; i < 13; i++) {
				Data.writeBool("gottarget"+i, false);
			}
			
			Data.save("tinytraps");
		}
		
		public function save (changeMoving:Boolean = true, minusOneTarget:Boolean = false, target:Target = null):void
		{
			if (! Main.realism) {
				Data.writeInt("playerx", player.spawnX);
				Data.writeInt("playery", player.spawnY);
				Data.writeInt("time", time);
				Data.writeInt("deaths", deaths);
				Data.save("tinytraps");
			}
			
			if (changeMoving) updateMoving(minusOneTarget ? 1 : 0, target);
		}
		
		public function updateMoving (minusTargets:int = 0, target:Target = null):void
		{
			const types:Array = ["solid", "spike"];
			
			var a:Array = [];
			
			var targetCount: int = typeCount("target") - minusTargets;
			
			for each (var type:String in types)
			{
				if (targetCount <= 11)
				{
					collideRectInto(type, 96, 86, 51, 37, a);
				}
				
				if (targetCount <= 9)
				{
					collideRectInto(type, 10, 86, 20, 100, a);
					collideRectInto(type, 49, 76, 21, 16, a);
					collideRectInto(type, 76, 57, 130, 180, a);
					collideRectInto(type, 116, 43, 31, 35, a);
				}
				
				if (targetCount <= 6)
				{
					collideRectInto(type, 0, 73, 14, 10, a);
					collideRectInto(type, 38, 44, 13, 16, a);
					collideRectInto(type, 59, 56, 15, 18, a);
					collideRectInto(type, 77, 42, 11, 15, a);
				}
				
				if (targetCount <= 3)
				{
					collideRectInto(type, 19, 52, 18, 18, a);
				}
				
				if (targetCount <= 1)
				{
					collideRectInto(type, 0, 0, 300, 250, a);
				}
			}
			
			var e:Entity;
			
			//if (! target) {
				for each (e in a) {
					e.active = true;
				}
			/* Ehh, can't be bothered
			} else {
				for each (e in a) {
					if (e.active) continue;
					
					var trailObject:Object = {};
					
					trailObject.target = e;
					trailObject.x = target.x + 2;
					trailObject.y = target.y + 2;
					
					var e2:Entity = addGraphic(new Stamp(new BitmapData(1, 1, false, Level.PLAYER)));
					
					e2.x = trailObject.x;
					e2.y = trailObject.y;
					e2.layer = -100;
					
					FP.tween(e2, {x: e.x, y:e.y}, 20, {tweener:this});
					
					e.active = true;
				}
			}*/
		}
		
		public function completed ():void
		{
			Mouse.show();
			
			Logger.endPlay("WON!");
			
			var congrats:MyTextField = new MyTextField(145*Main.magic, 70, "Congratulations", "center", 30);
			var mins:int = time / 600;
			var secs:Number = (time % 600) / 10.0;
			//var timeString:String = mins + ":" + (secs < 10 ? "0" : "") + secs;
			var timeString:String = mins + " min " + secs + "s";
			var deathString:String = "with " + deaths + " deaths";
			if (deaths == 1) { deathString = "with only one death!" }
			else if (deaths == 0) { deathString = "without dying!" }
			var stats:MyTextField = new MyTextField(145*Main.magic, 120, "You mastered the traps\nin " + timeString + "\n" + deathString, "center", 20);
			
			started = false;
			
			var backButton:Button = new Button("Back", 20);
			backButton.x = 150*Main.magic - backButton.width*0.5;
			backButton.y = 200;
			
			var bestTime:int = Data.readInt("besttime", -1);
			var bestDeaths:int = Data.readInt("bestdeaths", -1);
			
			var isNewRecord:Boolean = false;
			
			if (bestTime == -1 || bestTime > time) {
				Data.writeInt("besttime", time);
				isNewRecord = true;
			}
			
			if (bestDeaths == -1 || bestDeaths > deaths) {
				Data.writeInt("bestdeaths", deaths);
				isNewRecord = true;
			}
			
			if (Main.realism) {
				var bestRealismTime:int = Data.readInt("bestrealismtime", -1);
				if (bestRealismTime == -1 || bestRealismTime > time) {
					Data.writeInt("bestrealismtime", time);
					isNewRecord = true;
				}
			}
			
			clearSave();
			
			var b:Array = [congrats, stats];
			
			var newRecord:MyTextField;
			
			if (isNewRecord) {
				Data.save("tinytraps");
				
				newRecord = new MyTextField(150, 0, "New record!", "center", 15);
				newRecord.textColor = NEWRECORD;
			}
			
			if (deathString.substr(-1) != "!") deathString += "!";
			
			var tweetString:String = "I just mastered the Terrible Tiny Traps in " + timeString + " " + deathString + " Take the challenge: http://www.draknek.org/games/tinytraps/";
			
			var tweetButton:TweetButton = new TweetButton(tweetString);
			
			if (newRecord) {
				var s:Sprite = new Sprite;
				var w:int = newRecord.width + tweetButton.width + 6;
				var h:int = Math.max(newRecord.height, tweetButton.height);
				
				//s.height = h;
				
				newRecord.x = 150*Main.magic - int(w * 0.5);
				tweetButton.x = newRecord.x + newRecord.width + 6;
				
				s.addChild(newRecord);
				s.addChild(tweetButton);
				b.push(s);
			} else {
				tweetButton.x = 150*Main.magic - tweetButton.width*0.5;
				b.push(tweetButton);
			}
			
			escapeHandler = function ():void {
				Main.removeElements(b);
				
				var bgLevel:Level = new Level;
				bgLevel.started = false;
				FP.world = bgLevel;
				Main(FP.engine).showButtons();
				FP.stage.focus = FP.stage;
			};
			actionHandler = escapeHandler;
			
			backButton.addEventListener(MouseEvent.CLICK, escapeHandler);
		
			b.push(backButton);
			
			Main.addElements(b);
		}
		
		public function realismDeath ():void
		{

			Mouse.show();
			
			Logger.endPlay("died");
			
			var gameOver:MyTextField = new MyTextField(150*Main.magic, 70, "Failure", "center", 30);
			var mins:int = time / 600;
			var secs:Number = (time % 600) / 10.0;
			//var timeString:String = mins + ":" + (secs < 10 ? "0" : "") + secs;
			var timeString:String = mins + " min " + secs + "s";
			var targetCount:int = (12 - typeCount("target"));
			var targetString:String = targetCount + " checkpoints";
			if (targetCount == 0) targetString = "no checkpoints";
			else if (targetCount == 1) targetString = "one checkpoint";
			
			var stats:MyTextField = new MyTextField(150*Main.magic, 120, "You reached\n" + targetString + "\n" + "in " + timeString + "\n before dying", "center", 20);
			started = false;
			
			var backButton:Button = new Button("Back", 20);
			var retryButton:Button = new Button("Retry", 20);
			
			var buttons:Sprite = new Sprite;
			
			buttons.addChild(backButton);
			buttons.addChild(retryButton);
			
			backButton.x = 150*Main.magic - int(backButton.width + retryButton.width + 12) * 0.5;
			retryButton.x = backButton.x + backButton.width + 12;
			
			var b:Array = [gameOver, stats];
			
			var bestTargets:int = Data.readInt("bestrealismtargets", 0);
			
			var bestRealismTime:int = Data.readInt("bestrealismtime", -1);
			
			var isNewRecord:Boolean = false;
			
			if (bestRealismTime == -1 && targetCount > bestTargets) {
				Data.writeInt("bestrealismtargets", targetCount);
				isNewRecord = true;
			}
			
			if (isNewRecord) {
				Data.save("tinytraps");
				
				var newRecord:MyTextField = new MyTextField(150*Main.magic, 0, "New record!", "center", 15);
				newRecord.textColor = NEWRECORD;
				
				newRecord.x = 150*Main.magic - newRecord.width*0.5;
				
				b.push(newRecord);
			}
			
			escapeHandler = function ():void {
                Audio.resetMusic();
				Main.removeElements(b);
				var bgLevel:Level = new Level;
				bgLevel.started = false;
				FP.world = bgLevel;
				Main(FP.engine).showButtons();
				FP.stage.focus = FP.stage;
			};
			
			actionHandler = function ():void {
                Audio.resetMusic();
				Main.removeElements(b);
				Main.realism = true;
				var level:Level = new Level;
				FP.world = level;
				level.started = true;
				FP.stage.focus = FP.stage;
				Mouse.hide();
				Logger.startPlay("Realism mode", "retry");
			};
			
			backButton.addEventListener(MouseEvent.CLICK, escapeHandler);
			retryButton.addEventListener(MouseEvent.CLICK, escapeHandler);
			
			b.push(buttons);
			
			Main.addElements(b);
		}
		
	}
}
