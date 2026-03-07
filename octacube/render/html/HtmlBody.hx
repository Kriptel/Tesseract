package octacube.render.html;

import haxe.io.Bytes;

@:forward
abstract HtmlBody(__HtmlBody) from __HtmlBody to __HtmlBody
{
	inline extern overload public function new(content:String, ?templates:Map<String, HtmlBody>)
	{
		this = new __HtmlBody(content, templates);
	}

	inline extern overload public function new(bytes:Bytes, ?templates:Map<String, HtmlBody>)
	{
		this = new __HtmlBody(bytes.toString(), templates);
	}

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

	@:op(a | b) public function combine(b:HtmlBody)
	{
		return new HtmlBody(this.openTag + '\n' + this.content + '\n' + b.content + '\n</body>');
	}
}

class __HtmlBody
{
	public var openTag:String;
	public var content:String;

	public static final regex:EReg = ~/(<body[^>]*>)([\s\S]*)<\/body>/i;
	private static final templateRegex = ~/::(.+?)::/g;

	public function new(content:String, ?templates:Map<String, HtmlBody>)
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

		if (templates != null)
		{
			replaceTemplates(templates);
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

	public function replaceTemplate(id:String, html:HtmlBody):HtmlBody
	{
		content = StringTools.replace(content, '::$id::', html.render());

		return this;
	}

	public function replaceTemplates(templates:Map<String, HtmlBody>):HtmlBody
	{
		content = templateRegex.map(content, e ->
		{
			final id:String = e.matched(1);

			return if (templates.exists(id))
				templates.get(id).render();
			else
				e.matched(0);
		});

		return this;
	}
}
