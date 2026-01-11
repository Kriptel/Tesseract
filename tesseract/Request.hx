package tesseract;

import tesseract.util.Headers;

typedef Address =
{
	var host:String;
	var port:Int;
}

enum abstract Method(String) to String
{
	var GET = "GET";
	var POST = "POST";
	var PUT = "PUT";
	var DELETE = "DELETE";
	var PATCH = "PATCH";
	var HEAD = "HEAD";
	var OPTIONS = "OPTIONS";

	@:from
	public static function fromString(method:String):Null<Method>
	{
		if (method == null)
			return null;

		return switch (method.toUpperCase())
		{
			case GET: GET;
			case POST: POST;
			case PUT: PUT;
			case DELETE: DELETE;
			case PATCH: PATCH;
			case HEAD: HEAD;
			case OPTIONS: OPTIONS;
			case _: throw Error.EInvalidMethod(method);
		}
	}

	public inline function supportsBody():Bool
	{
		return switch (abstract)
		{
			case POST | PUT | PATCH: true;
			case _: false;
		}
	}
}

class Request
{
	public var path(default, null):String;
	public var pathParts(get, null):Array<String>;
	public var method(default, null):String;
	public var protocol(default, null):String;
	public var ip(default, null):Address;
	public var host(default, null):Address;

	public var query(default, null):Dynamic<String>;
	public var body(default, null):Dynamic;

	public var headers(default, null):Headers;
	public var cookie(default, null):Array<String>;

	public function new(path:String, method:String, protocol:String, ip:Address, host:Address, query:Dynamic<String>, body:Dynamic, headers:Headers)
	{
		this.path = path;
		this.method = method;
		this.protocol = protocol;
		this.ip = ip;
		this.host = host;
		this.query = query;
		this.body = body;
		this.headers = headers;

		cookie = headers.getHeadersUnsafe('cookie');
	}

	inline function get_pathParts():Array<String>
	{
		if (pathParts == null)
			pathParts = path.split('/');

		return pathParts;
	}
}
