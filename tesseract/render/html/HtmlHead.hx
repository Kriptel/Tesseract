package tesseract.render.html;

import haxe.io.Bytes;

@:forward
@:forward.new
abstract HtmlHead(__HtmlHead) from __HtmlHead to __HtmlHead
{
	@:from static public function fromString(s:String):HtmlHead
	{
		return new HtmlHead(s);
	}

	@:from static public function fromBytes(b:Bytes):HtmlHead
	{
		return new HtmlHead(b.toString());
	}

	@:from static public function fromFile(f:File):HtmlHead
	{
		return new HtmlHead(f.get().toString());
	}
}

class __HtmlHead
{
	public var openTag:String;
	public var content:String;

	public static final regex:EReg = ~/(<head[^>]*>)([\s\S]*)<\/head>/i;

	public function new(content:String)
	{
		if (regex.match(content))
		{
			this.openTag = regex.matched(1);
			this.content = regex.matched(2);
		}
		else
		{
			this.openTag = '<head>';
			this.content = content;
		}
	}

	public function render():String
	{
		return openTag + '\n' + content + '\n</head>';
	}

	public function addStyle(css:String)
	{
		content += '\n<style>\n' + css + '\n</style>';
	}

	public function addStyleFile(url:String)
	{
		content += '\n<link rel="stylesheet" type="text/css" href="' + url + '">';
	}

	public function addTag(tag:String)
	{
		content += '\n' + tag;
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
