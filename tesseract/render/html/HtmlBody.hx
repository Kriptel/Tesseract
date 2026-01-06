package tesseract.render.html;

import haxe.io.Bytes;

@:forward
@:forward.new
abstract HtmlBody(__HtmlBody) from __HtmlBody to __HtmlBody
{
	@:from static public function fromString(s:String):HtmlBody
	{
		return new HtmlBody(s);
	}

	@:from static public function fromBytes(b:Bytes):HtmlBody
	{
		return new HtmlBody(b.toString());
	}

	@:from static public function fromFile(f:File):HtmlBody
	{
		return new HtmlBody(f.get().toString());
	}
}

class __HtmlBody
{
	public var openTag:String;
	public var content:String;

	public static final regex:EReg = ~/(<body[^>]*>)([\s\S]*)<\/body>/i;

	public function new(content:String)
	{
		if (regex.match(content))
		{
			this.openTag = regex.matched(1);
			this.content = regex.matched(2);
		}
		else
		{
			this.openTag = '<body>';
			this.content = content;
		}
	}

	public function render():String
	{
		return openTag + '\n' + content + '\n</body>';
	}

	public function addTag(tagName:String, inner:String = "", attributes:String = "")
	{
		var attr = (attributes != "") ? " " + attributes : "";
		content += '\n<' + tagName + attr + '>' + inner + '</' + tagName + '>';
	}

	public function addScript(js:String)
	{
		content += '\n<script type="text/javascript">\n' + js + '\n</script>';
	}

	public function addScriptFile(url:String)
	{
		content += '\n<script type="text/javascript" src="' + url + '"></script>';
	}

	public function addCustom(customContent:String)
	{
		content += '\n' + customContent;
	}
}
