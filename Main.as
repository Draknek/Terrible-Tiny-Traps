package
{
	import net.flashpunk.*;
	
	import flash.ui.*;
	import flash.text.*;
	
	[SWF(width = "300", height = "250", backgroundColor="#000000")]
	public class Main extends Engine
	{
		public static var clickText: TextField;
		
		public function Main() 
		{
			super(150, 125, 10, true);
			FP.world = new Level();
			FP.screen.color = Level.BLANK;
			FP.screen.scale = 2;
		}
		
		public override function init (): void
		{
			super.init();
			
			var ss:StyleSheet = new StyleSheet();
			ss.parseCSS("a:hover { text-decoration: underline; } a { text-decoration: none; color: #FF8B60; }");

			var title: MyTextField = new MyTextField(0, 2, "Terrible Tiny Traps", "left", 10);

			var credits: MyTextField = new MyTextField(0, 15, "", "left", 5);
			credits.htmlText = 'Created by <a href="http://www.draknek.org/?ref=ttt" target="_blank">Alan Hazelden</a> for <a href="http://www.reddit.com/r/RedditGameJam/" target="_blank">Reddit Game Jam 03</a>';
			credits.mouseEnabled = true;
			credits.styleSheet = ss;
			
			clickText = new MyTextField(150*0.5, 125*0.5, "Click to play", "center", 10);

			addChild(title);
			addChild(credits);
			addChild(clickText);
		}
	}
}

