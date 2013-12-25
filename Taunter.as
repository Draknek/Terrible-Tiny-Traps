package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Taunter extends Entity
	{
		[Embed(source = 'player.png')]
		public static var playerGfx: Class;
		
		public var spritemap: Spritemap = new Spritemap(playerGfx, 5, 4);
		
		public var fallingPlayer:FallingPlayer
		
		public function Taunter ()
		{
			spritemap.frame = 5;
			spritemap.color = Level.SPIKE;
			graphic = spritemap;
		}
		
		public override function added ():void
		{
			fallingPlayer = new FallingPlayer(x+3, y - 1);
			Level(world).fallingPlayer = fallingPlayer;
			fallingPlayer.active = false;
			world.add(fallingPlayer);
		}
		
		public var counter:int = 0;
		
		public override function update ():void
		{
			counter++;
			
			if (counter == 10) {
				fallingPlayer.active = true;
			}
		}
	}
}