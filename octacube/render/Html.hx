package octacube.render;

import haxe.io.Bytes;
import octacube.render.html.HtmlRoot;
import octacube.render.html.HtmlHead;
import octacube.render.html.HtmlBody;

class Html
{
	var root:HtmlRoot;
	var head:HtmlHead;
	var body:HtmlBody;

	public function new(root:HtmlRoot, head:HtmlHead, body:HtmlBody)
	{
		this.root = root;
		this.head = head;
		this.body = body;
	}

	public var cacheRender:Bool = true;

	public var _cachedRender:Null<Bytes>;

	public function render():Bytes
	{
		if (cacheRender && _cachedRender != null)
			return _cachedRender;

		final render:Bytes = Bytes.ofString(root.renderStart() + head.render() + body.render() + root.renderEnd());

		if (cacheRender)
			_cachedRender = render;

		return render;
	}

	inline public function clearCache():Void
	{
		_cachedRender = null;
	}
}
