package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Checkpoint extends Entity
	{
		public function Checkpoint(grid: Grid)
		{
			type = "checkpoint";
			
			mask = grid;
			
			visible = false;
			//collidable = false;
		}
		
		public override function update (): void
		{
			var p: Player = collide("player", 0, 0) as Player;
			
			if (p) {
				p.spawnX = p.x;
				p.spawnY = p.y;
			}
		}
	}
}
