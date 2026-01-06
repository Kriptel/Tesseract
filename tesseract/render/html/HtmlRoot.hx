package tesseract.render.html;

import haxe.io.Bytes;

@:forward.new
@:forward
abstract HtmlRoot(__HtmlRoot) from __HtmlRoot to __HtmlRoot
{
	@:from static public function fromString(s:String):HtmlRoot
	{
		return new HtmlRoot(s);
	}

	@:from static public function fromBytes(b:Bytes):HtmlRoot
	{
		return new HtmlRoot(b.toString());
	}

	@:from static public function fromFile(f:File):HtmlRoot
	{
		return new HtmlRoot(f.get().toString());
	}
}

class __HtmlRoot
{
	public var start:String;
	public var end:String;

	public static final openTagRegex:EReg = ~/<html[^>]*>/i;
	public static final closeTagRegex:EReg = ~/<\/html>/i;

	public function new(content:String = '<!DOCTYPE html><html></html>')
	{
		if (openTagRegex.match(content) && closeTagRegex.match(content))
		{
			var openMatch = openTagRegex.matchedPos();
			var openTagEnd = openMatch.pos + openMatch.len;
			this.start = content.substring(0, openTagEnd);

			var lastClosePos = -1;
			var searchPos = openTagEnd;
			while (closeTagRegex.matchSub(content, searchPos))
			{
				var m = closeTagRegex.matchedPos();
				lastClosePos = m.pos;
				searchPos = m.pos + m.len;
			}

			if (lastClosePos != -1)
				end = content.substring(lastClosePos);
			else
				end = '</html>';
		}
		else
		{
			start = '<!DOCTYPE html>\n<html>\n';
			end = '\n</html>';
		}
	}

	public function renderStart():String
	{
		return start;
	}

	public function renderEnd():String
	{
		return end;
	}
}
