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
		
		[Embed(source = 'mask.png')]
		public static var maskGfx: Class;
		
		public var spritemap: Spritemap = new Spritemap(playerGfx, 5, 4);
		
		public var dx: int = 1;
		
		public var jumpCount: int = 0;
		
		public var canJump: Boolean = false;
		
		public var deathCount: int = 0;
		
		public var spawnX: int;
		public var spawnY: int;

        // Remove
        //private var musicDebugPressed:Boolean = false;
		
		public function Player()
		{
			graphic = spritemap;
			
			spritemap.color = Level.PLAYER;
			
			spritemap.frame = 5;
			spritemap.x = -1;
			
			type = "player";

			
			//setHitbox(3, 4, 0, 0);
			
			mask = new Pixelmask(maskGfx); // TODO: consider effects this has on moving platforms
			
			Input.define("L", Key.LEFT, Key.A);
			Input.define("R", Key.RIGHT, Key.D);
			Input.define("JUMP", Key.UP, Key.W, Key.SPACE, Key.Z, Key.X, Key.C);
            //Remove
            //Input.define("MUSICDEBUG", Key.N)
		}
		
		public override function update (): void
		{
			if (deathCount > 0) {
				spritemap.frame = 5;
				
				jumpCount = 0;
				
				//visible = ((deathCount % 8) < 4);
				
				deathCount--;
				
				if (deathCount == 8) {
					if (Main.realism) {
						Level(FP.world).realismDeath();
					} else {
						x = spawnX;
						y = spawnY;
                        Audio.muteLead = false;
					}
				}
				
				/*FP.camera.x = x - 80;
				FP.camera.y = y - 60;*/
				
				return;
			}
			
			spritemap.frame++;
			
			dx = 0;
			
			if (Input.check("L") || Input.pressed("L")) { dx -= 1; }
			if (Input.check("R") || Input.pressed("R")) { dx += 1; }

            // Remove
            //if(musicDebugPressed && !Input.check("MUSICDEBUG"))
            //    musicDebugPressed = false;

            // Remove
            //if (!musicDebugPressed && Input.check("MUSICDEBUG"))
            //{
            //    musicDebugPressed = true;
            //    Audio.incrementMusicTensionLevel();
            //}

			
			canJump = false;
			
			var e: Entity;
			
			e = collide("solid", x, y + 1);
			
			if (e) { canJump = true; }
			
			moveX(dx);
			
			e = collide("solid", x, y + 1);
			
			if (e) 
            { 
                canJump = true; 
                Audio.portamento = false;
            }
			
			if (dx != 0) {
				spritemap.flipped = (dx > 0);
				
				if (spritemap.frame >= 5) {
					spritemap.frame = 0;
				}
			} else {
				/*if (canJump)*/ { spritemap.frame = 5; }
				/*else if (spritemap.frame == 0) { spritemap.frame = 6; }*/
			}
			
			if (canJump && (Input.check("JUMP") || Input.pressed("JUMP"))) {
				jumpCount = 5;
				Audio.play("jump");
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
                Audio.portamento = true;
			}
			
			/*FP.camera.x = x - 80;
			FP.camera.y = y - 60;*/
			
			e = collide("spike", x, y);
			
			if (e) {
				die();
			}
		}
		
		public function moveX (dx: int): void
		{
			var e: Entity;
			
			e = collide("solid", x + dx, y)
			
			if (e) {
				e = collide("solid", x + dx, y - 1);
				
				if (/*canJump &&*/ ! e) {
					x += dx;
					y -= 1;
					
					jumpCount = 0;
				} else {
					//dx *= -1;
				}
			} else {
				x += dx;
			}
		}
		
		public override function render (): void
		{
			if (deathCount > 0) {
				var s: int = 15 - deathCount;
				
				if (deathCount <= 8) s = deathCount;
				
				Draw.linePlus(x + 1 - s, y + 2, x + 1 + s, y + 2, Level.PLAYER, 1.0 - s/8.0);
				Draw.linePlus(x + 1, y + 2 - s, x + 1, y + 2 + s, Level.PLAYER, 1.0 - s/8.0);
				
				return;
			}
			
			/*if (deathCount > 0 && (deathCount % 4) < 2) {
				return;
			}*/
			
			super.render();
		}
		
		public function die () : void
		{
			Logger.died();
			Audio.play("death");
            Audio.muteLead = true;
			deathCount = 15;
			Level(FP.world).deaths++;
			Level(FP.world).save(false);
		}
	}
}
