package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.geom.*;
	
	public class Level extends World
	{
		[Embed(source = 'level.png')]
		public static var levelGfx: Class;
		
		public static const BLANK: uint = 0xFFFFFF;
		public static const SOLID: uint = 0x333333;
		public static const SPIKE: uint = 0xFF9494FF;
		public static const PLAYER: uint = 0xFFFF8B60;
		public static const SPECIAL: uint = 0x654321;
		
		public var player: Player;
		
		public var started:Boolean = false;
		
		public var time:int = 0;
		public var deaths:int = 0;
		
		public function Level()
		{
			var level: BitmapData = FP.getBitmap(levelGfx);
			
			var solid: Entity = new Entity();
			
			add(solid);
			
			solid.type = "solid";
			
			solid.graphic = new Stamp(level);
			
			var grid: Grid = new Grid(level.width, level.height, 1, 1);
			
			solid.mask = grid;
			
			player = new Player();
			
			add(player);
			
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
						
						add(new Target(x - 2, y, targetID));
						
						level.setPixel(x+1, y+1, 0xFFFFFF);
						level.setPixel(x+2, y+2, 0xFFFFFF);
						level.setPixel(x+1, y+3, 0xFFFFFF);
						level.setPixel(x+0, y+4, 0xFFFFFF);
						level.setPixel(x-1, y+3, 0xFFFFFF);
						level.setPixel(x-2, y+2, 0xFFFFFF);
						level.setPixel(x-1, y+1, 0xFFFFFF);
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
		}
		
		public override function update (): void
		{
			if (! started || ! Main.focused) { return; }
			
			if (classCount(Target) == 0) {
				var congrats:MyTextField = new MyTextField(145, 80, "Congratulations", "center", 30);
				FP.engine.addChild(congrats);
				var mins:int = time / 600;
				var secs:Number = (time % 600) / 10.0;
				//var timeString:String = mins + ":" + (secs < 10 ? "0" : "") + secs;
				var timeString:String = mins + " min " + secs + "s";
				var stats:MyTextField = new MyTextField(145, 145, "You mastered the traps\nin " + timeString + "\nwith " + deaths + " deaths", "center", 20);
				FP.engine.addChild(stats);
				//clearSave();
				started = false;
				return;
			}
			
			super.update();
			
			time++;
			
			if (time % 10 == 0) save(false);
		}
		
		public override function render (): void
		{
			super.render();
			
			if (! started || ! Main.focused) {
				Draw.rect(0, 28, 150, 125, 0xFFFFFF, 0.9);
			}
			
			Main.clickText.visible = (started && ! Main.focused);
		}
		
		public function load ():void
		{
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
			Data.load("");
			Data.save("tinytraps");
			
			Level(FP.world).started = true;
		}
		
		public function save (changeMoving:Boolean = true, minusOneTarget:Boolean = false):void
		{
			Data.writeInt("playerx", player.spawnX);
			Data.writeInt("playery", player.spawnY);
			Data.writeInt("time", time);
			Data.writeInt("deaths", deaths);
			Data.save("tinytraps");
			
			if (changeMoving) updateMoving(minusOneTarget ? 1 : 0);
		}
		
		public function updateMoving (minusTargets:int = 0):void
		{
			const types:Array = ["solid", "spike"];
			
			var a:Array = [];
			
			var targetCount: int = classCount(Target) - minusTargets;
			
			for each (var type:String in types)
			{
				if (targetCount <= 11)
				{
					collideRectInto(type, 96, 86, 51, 37, a);
				}
				
				if (targetCount <= 9)
				{
					collideRectInto(type, 10, 86, 20, 26, a);
					collideRectInto(type, 49, 76, 21, 16, a);
					collideRectInto(type, 76, 63, 13, 18, a);
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
			
			for each (var e:Entity in a) e.active = true;
		}
		
	}
}
