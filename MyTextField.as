package
{
	import flash.display.*;
	import flash.text.*;
	
	public class MyTextField extends TextField
	{
		[Embed(source="MODENINE.TTF", fontName='modenine', mimeType='application/x-font')]
		public static var defaultFontSrc : Class;
		
		public static var defaultFont : Font = new defaultFontSrc();
		
		public function MyTextField (_x: Number, _y: Number, _text: String, _align: String = "center", textSize: Number = 16, _fontName: String = null)
		{
			x = _x;
			y = _y;
			
			textColor = 0x0;
			
			selectable = false;
			mouseEnabled = false;
			
			if (! _fontName)
			{
				_fontName = defaultFont.fontName;
			}
			
			var _textFormat : TextFormat = new TextFormat(_fontName, textSize);
			
			_textFormat.align = _align;
			
			defaultTextFormat = _textFormat;
			
			embedFonts = true;
			
			autoSize = _align;
			
			text = _text;
			
			if (_align == TextFieldAutoSize.CENTER)
			{
				x = _x - textWidth / 2;
			}
			else if (_align == TextFieldAutoSize.RIGHT)
			{
				x = _x - textWidth;
			}
			
		}
		
	}
}

