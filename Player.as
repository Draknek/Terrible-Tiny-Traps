package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Player extends Entity
	{
		[Embed(source = 'player4.png')]
		public static var playerGfx: Class;
		
		public var spritemap: Spritemap = new Spritemap(playerGfx, 3, 4);
		
		public var dx: int = 1;
		
		public var jumpCount: int = 0;
		
		public var canJump: Boolean = false;
		
		public var deathCount: int = 0;
		
		public var spawnX: int;
		public var spawnY: int;
		
		public function Player()
		{
			graphic = spritemap;
			
			setHitbox(3, 4, 0, 0);
		}
		
		public override function update (): void
		{
			if (deathCount > 0) {
				spritemap.frame = 1;
				
				visible = ((deathCount % 8) < 4);
				
				deathCount--;
				
				if (deathCount == 8) {
					x = spawnX;
					y = spawnY;
				}
				
				FP.camera.x = x - 22;
				FP.camera.y = y - 14;
				
				return;
			}
			
			spritemap.frame++;
			
			/*dx = 0;
			
			if (Input.check(Key.LEFT)) { dx -= 1; }
			if (Input.check(Key.RIGHT)) { dx += 1; }*/
			
			if (dx != 0) { spritemap.flipped = (dx > 0); }
			
			canJump = false;
			
			var e: Entity;
			
			e = collide("solid", x, y + 1);
			
			if (e) { canJump = true; }
			
			e = collide("solid", x + dx, y)
			
			if (e) {
				e = collide("solid", x + dx, y - 1);
				
				if (canJump && ! e) {
					x += dx;
					y -= 1;
				} else {
					dx *= -1;
				}
			} else {
				x += dx;
			}
			
			e = collide("solid", x, y + 1);
			
			if (e) { canJump = true; }
			
			if (canJump && Input.check(Key.Z)) {
				jumpCount = 5;
			}
			
			var dy: int = (jumpCount > 0) ? -1 : 1;
			
			e = collide("solid", x, y + dy);
			
			canJump = false;
			
			if (e) {
				if (dy > 0) {
					//canJump = true;
				}
				
				jumpCount = 0;
			} else {
				y += dy;
				jumpCount--;
			}
			
			FP.camera.x = x - 10;
			FP.camera.y = y - 6;
			
			e = collide("spike", x, y);
			
			if (e) {
				deathCount = 16;
			}
		}
		
	}
}
