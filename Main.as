package
{
	import net.flashpunk.*;
	
	[SWF(width = "640", height = "480", backgroundColor="#000000")]
	public class Main extends Engine
	{
		public function Main() 
		{
			super(160, 120, 10, true);
			FP.world = new Level();
			FP.screen.color = Level.BLANK;
			scaleX = 4;
			scaleY = 4;
		}
	}
}

