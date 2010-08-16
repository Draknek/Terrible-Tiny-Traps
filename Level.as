package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.events.*;
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
						add(new Target(x - 2, y));
						
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
			if (! focused) { return; }
			
			super.update();
		}
		
		public override function render (): void
		{
			super.render();
			
			if (! focused) {
				Draw.rect(0, 28, 150, 125, 0xFFFFFF, 0.8);
			}
			
			Main.clickText.visible = ! focused;
		}
		
		public var focused: Boolean = false;
		
		public override function begin (): void
		{
			FP.stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseClick);
		}
		
		public override function end (): void
		{
			FP.stage.removeEventListener(Event.ACTIVATE, focusGain);
			FP.stage.removeEventListener(Event.DEACTIVATE, focusLost);
		}
		
		private function mouseClick(e:Event):void
		{
			FP.stage.addEventListener(Event.ACTIVATE, focusGain);
			FP.stage.addEventListener(Event.DEACTIVATE, focusLost);
			FP.stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseClick);
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
