package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	
	public class Player extends Entity
	{
		[Embed(source = 'player.png')]
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
			
			type = "player";
			
			setHitbox(3, 4, 0, 0);
			
			Input.define("L", Key.LEFT, Key.A);
			Input.define("R", Key.RIGHT, Key.D);
			Input.define("JUMP", Key.UP, Key.W, Key.SPACE, Key.Z, Key.X, Key.C);
		}
		
		public override function update (): void
		{
			if (deathCount > 0) {
				spritemap.frame = 5;
				
				jumpCount = 0;
				
				visible = ((deathCount % 8) < 4);
				
				deathCount--;
				
				if (deathCount == 8) {
					x = spawnX;
					y = spawnY;
				}
				
				/*FP.camera.x = x - 80;
				FP.camera.y = y - 60;*/
				
				return;
			}
			
			spritemap.frame++;
			
			dx = 0;
			
			if (Input.check("L")) { dx -= 1; }
			if (Input.check("R")) { dx += 1; }
			
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
					//dx *= -1;
				}
			} else {
				x += dx;
			}
			
			e = collide("solid", x, y + 1);
			
			if (e) { canJump = true; }
			
			if (dx != 0) {
				spritemap.flipped = (dx > 0);
				
				if (spritemap.frame >= 5) {
					spritemap.frame = 0;
				}
			} else {
				/*if (canJump)*/ { spritemap.frame = 5; }
				/*else if (spritemap.frame == 0) { spritemap.frame = 6; }*/
			}
			
			if (canJump && Input.check("JUMP")) {
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
			
			/*FP.camera.x = x - 80;
			FP.camera.y = y - 60;*/
			
			e = collide("spike", x, y);
			
			if (e) {
				deathCount = 16;
			}
		}
		
	}
}
