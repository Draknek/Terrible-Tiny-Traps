package
{
	import net.flashpunk.*;
	
	[SWF(width = "192", height = "128", backgroundColor="#000000")]
	public class Main extends Engine
	{
		public function Main() 
		{
			super(48, 32, 10, true);
			FP.world = new Level();
			FP.screen.color = 0xFFFFFF;
			scaleX = 4;
			scaleY = 4;
		}
	}
}

