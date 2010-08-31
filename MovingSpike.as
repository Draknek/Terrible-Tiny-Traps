package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	import flash.display.*;
	import flash.geom.*;
	
	public class MovingSpike extends Entity
	{
		public var dx: int = 0;
		public var dy: int = 0;
		
		public function MovingSpike(src: BitmapData, rect: Rectangle, _dx: int, _dy: int)
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
						bitmap.setPixel32(ix, iy, Level.SPIKE);
					}
				}
			}
			
			graphic = new Stamp(bitmap);
			mask = new Pixelmask(bitmap);
			
			type = "spike";
			
			active = false;
		}
		
		public override function update (): void
		{
			var e: Entity = collide("solid", x+dx, y+dy);
			
			if (e) {
				dx *= -1;
				dy *= -1;
				if (y < 40) update();
			} else {
				x += dx;
				y += dy;
			}
		}
	}
}
