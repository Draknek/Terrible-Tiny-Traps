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
			
			if (counter == 5) {
				fallingPlayer.active = true;
			}
			
			if (counter == 20) {
				Main(FP.engine).speechBubble.visible = true;
				Main(FP.engine).speech1.visible = true;
			}
			
			if (counter == 40) {
				Main(FP.engine).speech1.visible = false;
				Main(FP.engine).speech2.visible = true;
			}
			
			if (counter == 60) {
				Main(FP.engine).speech2.visible = false;
				Main.title.y = (4 + 54)*Main.magic;
				FP.engine.addChild(Main.title);
			}
		}
	}
}