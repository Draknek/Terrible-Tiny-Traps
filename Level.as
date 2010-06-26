package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	
	public class Level extends World
	{
		[Embed(source = 'level.png')]
		public static var levelGfx: Class;
		
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
			
			for (var y: int = 0; y < level.height; y++) {
				for (var x: int = 0; x < level.width; x++) {
					var colour: uint = 0x00FFFFFF & level.getPixel(x, y);
					
					level.setPixel(x, y, 0xFFFFFF);
					
					if (colour == 0x0) {
						grid.setCell(x, y, true);
						level.setPixel(x, y, 0x0);
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
					}
				}
			}
			
			add(player);
			
			FP.camera.x = player.x - 22;
			FP.camera.y = player.y - 14;
		}
		
	}
}
