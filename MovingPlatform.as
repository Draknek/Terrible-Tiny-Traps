package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.geom.*;
	
	public class MovingPlatform extends Entity
	{
		public var dx: int = 0;
		public var dy: int = 0;
		
		public function MovingPlatform(src: BitmapData, rect: Rectangle, _dx: int, _dy: int)
		{
			x = rect.x;
			y = rect.y;
			
			dx = _dx;
			dy = _dy;
			
			var bitmap: BitmapData = new BitmapData(rect.width, rect.height, true, 0x0);
			
			//var grid: Grid = new Grid(rect.width, rect.height, 1, 1);
			
			for (var ix: int = 0; ix < rect.width; ix++) {
				for (var iy: int = 0; iy < rect.height; iy++) {
					var pixel: uint = src.getPixel(x+ix, y+iy);
					
					if ((pixel & 0xFFFFFF) == Level.SPECIAL) {
						//grid.setCell(ix, iy, true);
						bitmap.setPixel32(ix, iy, Level.SOLID | 0xFF000000);
					}
				}
			}
			
			graphic = new Stamp(bitmap);
			mask = new Pixelmask(bitmap);
			
			type = "solid";
			
			layer = -2;
		}
		
		public override function update (): void
		{
			var e: Entity = collide("solid", x+dx, y+dy);
			
			if (e) {
				dx *= -1;
				dy *= -1;
			} else {
				x += dx;
				y += dy;
				
				var p: Player;
				var e2: Entity;
				
				if (dx == 0)
				{
					p = collide("player", x, y) as Player;
				
					if (p && p.deathCount <= 0) {
						e2 = p.collide("solid", p.x, p.y+dy);
					
						if (e2) {
							var e3: Entity = p.collide("solid", p.x-1, p.y+dy);
							var e4: Entity = p.collide("solid", p.x+1, p.y+dy);
							
							if (!e3) { p.x -= 1; p.y += dy; }
							else if (!e4) { p.x += 1; p.y += dy; }
							else { p.die(); }
						} else {
							p.y += dy;
						}
					}
					
					if (dy > 0)
					{
						p = collide("player", x, y - 2) as Player;
						
						if (p && p.deathCount <= 0) {
							e2 = p.collide("solid", p.x, p.y+dy);
							
							if (! e2) p.y += dy;
						}
					}
				}
				else
				{
					p = collide("player", x - dx, y - 1) as Player;
				
					if (p && p.deathCount <= 0) {
						x += 1000;
						
						e = p.collide("solid", p.x, p.y + 1);
						
						if (! e) p.moveX(dx);
						
						x -= 1000;
					}
					
					p = FP.world.classFirst(Player) as Player;
					var m:Mask = p.mask;
					p.mask = null;
					p.setHitbox(3,4);
					
					p = collide("player", x, y) as Player;
				
					if (p && p.deathCount <= 0) {
						p.mask = m;
						
						p.moveX(dx);
						
						if (collide("player", x, y))
						{
							p.die();
						}
					}
					
					p = FP.world.classFirst(Player) as Player;
					p.mask = m;
				}
			}
		}
	}
}

