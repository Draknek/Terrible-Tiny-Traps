package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Spike extends Entity
	{
		public function Spike(_x: Number, _y: Number)
		{
			x = _x;
			y = _y;
			
			type = "spike";
			
			setHitbox(1, 1, 0, 0);
		}
		
		public override function update (): void
		{
			//visible = ! visible;
		}
		
		public override function render (): void
		{
			FP.buffer.setPixel(x - FP.camera.x, y - FP.camera.y, Level.SPIKE);
		}
	}
}
