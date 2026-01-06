package tesseract.render;

import haxe.io.Bytes;
import tesseract.render.html.HtmlRoot;
import tesseract.render.html.HtmlHead;
import tesseract.render.html.HtmlBody;

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

	public function render():Bytes
	{
		return Bytes.ofString(root.renderStart() + head.render() + body.render() + root.renderEnd());
	}
}
