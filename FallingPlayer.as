package
{
	import net.flashpunk.*;
	import net.flashpunk.graphics.*;
	import net.flashpunk.masks.*;
	import net.flashpunk.utils.*;
	import net.flashpunk.tweens.misc.Alarm;
	
	public class FallingPlayer extends Entity
	{
		[Embed(source = 'fall1.png')]
		public static var playerGfx: Class;
		
		[Embed(source = 'mask.png')]
		public static var maskGfx: Class;
		
		public var spritemap: Spritemap = new Spritemap(playerGfx, 5, 5);
		
		public var dx: int = 1;
		public var dy: int = 1;
		
		public var onFloor:Boolean = false;
		
		public var noisy:Boolean = false;
		
		public function FallingPlayer(_x:int, _y:int)
		{
			x = _x;
			y = _y;
			
			graphic = spritemap;
			
			spritemap.color = Level.PLAYER;
			
			setHitbox(3, 3, -1, -1);
			
			if (Main.onWeb) {
				noisy = false;
			} else {
				noisy = true;
			}
		}
		
		public override function update (): void
		{
			spritemap.frame += dx;
			
			if (y > 110 && x == 2 && dx > 0) {
				if (! spritemap.frame) {
					world.remove(this);
					return;
				}
			} else {
				moveX(dx);
				moveY(dy);
				moveY(dy);
			}
		}
		
		public override function render ():void
		{
			super.render();
			
			if (world.collidePoint("solid", x, y+2)) FP.buffer.setPixel(x, y+2, Level.SOLID);
			if (world.collidePoint("solid", x+4, y+2)) FP.buffer.setPixel(x+4, y+2, Level.SOLID);
			if (world.collidePoint("solid", x+2, y+4)) FP.buffer.setPixel(x+2, y+4, Level.SOLID);
		}
		
		public override function removed (): void
		{
			Level(FP.world).player.visible = true;
			//Level(FP.world).started = false;
			//Level(FP.world).player.active = true;
			//Level(FP.world).fallingPlayer = null;
			
			Audio.init(FP.engine);
			
			if (Level(FP.world).started) {
				FP.world.addTween(new Alarm(3, Main(FP.engine).doMenu, Tween.ONESHOT), true);
			} else {
				Main(FP.engine).doMenu();
			}
		}
		
		public function moveX (dx: int): void
		{
			var e: Entity;
			
			e = collide("solid", x + dx, y)
			
			if (e) {
				this.dx *= -1;
				if (noisy) Audio.play("bounce");
			} else {
				x += dx;
			}
		}
		
		private var bool:Boolean = false;
		
		public function moveY (dy: int): void
		{
			var e: Entity;
			
			e = collide("solid", x, y + dy)
			
			if (e) {
				if (!onFloor) {
					onFloor = true;
					if (noisy) Audio.play("bounce");
				}
				/*if (dy == 2) {
					moveY(1);
					return;
				}
				if (! bool && collide("checkpoint", x, y)) {
					dx *= -1;
					this.dy = -1;
					bool = true;
				}*/
			} else {
				y += dy;
				//bool = false;
				onFloor = false;
			}
		}
	}
}
