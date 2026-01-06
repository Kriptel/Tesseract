package tesseract.servers;

import sys.thread.FixedThreadPool;
import haxe.io.Bytes;
import haxe.DynamicAccess;
import haxe.Json;
import sys.net.Socket;
import sys.net.Host;
import tesseract.interfaces.IServer;

using StringTools;

class HttpServer implements IServer
{
	var socket:Socket;
	var threadPool:FixedThreadPool;

	public var timeout:Float = 10;

	public function new(host:String, port:Int, maxConnections:Int, ?threads:Int = 10)
	{
		threadPool = new FixedThreadPool(threads);

		socket = new Socket();
		socket.bind(new Host(host), port);
		socket.listen(maxConnections);

		Log.log('HttpServer', INFO, 'Server started on $host:$port');
	}

	public function run():Void
	{
		while (true)
		{
			var client = socket.accept();

			threadPool.run(() -> try
			{
				handleClient(client);
			} catch (e) {});
		}
	}

	function handleClient(client:Socket)
	{
		try
		{
			var requestLine = client.input.readLine();
			if (requestLine == null)
			{
				client.close();
				return;
			}

			client.setTimeout(timeout);

			final firstLine = requestLine.split(" ");
			final method = firstLine[0];
			final path = firstLine[1].substring(1);
			final pathOnly = path.indexOf('?') >= 0 ? path.substring(0, path.indexOf('?')) : path;
			final queryStr = path.indexOf('?') >= 0 ? path.substring(path.indexOf('?') + 1) : '';

			final headers = HeaderAccess.acceptHeaders(client);

			var contentLength:Int = Std.parseInt(headers.getHeader('Content-Length'));

			var params:DynamicAccess<Dynamic> = {};

			if (queryStr.length > 0)
			{
				for (p in queryStr.split('&'))
				{
					if (p.length == 0)
						continue;
					var eq = p.indexOf('=');
					if (eq >= 0)
						params[p.substring(0, eq)] = p.substring(eq + 1);
					else
						params[p] = '';
				}
			}

			if (contentLength > 0)
			{
				var rawBody:Bytes = client.input.read(contentLength);

				switch (headers.getHeader('Content-Type'))
				{
					case 'application/json':
						var json:DynamicAccess<Dynamic> = Json.parse(rawBody.toString());

						for (k => v in json)
						{
							params[k] = v;
						}
				}
			}

			params['cookie'] = headers;

			final result = switch (method)
			{
				case 'GET':
					Tesseract.get(pathOnly, params);
				default: null;
			}

			var response:Bytes = result.type == JSON ? Bytes.ofString(Json.stringify(result?.content)) : result.content;

			client.output.writeString("HTTP/1.1 200 OK\r\n");
			client.output.writeString('Content-Type: ${result.type}\r\n');
			client.output.writeString("Content-Length: " + Std.string(response.length) + "\r\n");
			client.output.writeString("Connection: close\r\n");
			client.output.writeString("\r\n");
			client.output.write(response);
		} catch (e:Error)
		{
			Log.log('HttpServer', ERROR, Std.string(e));

			switch (e)
			{
				case ENotFound:
					error(client, "Resource not found", 404);
				case ENullDatabase:
					error(client, "Database connection is not initialized", 503);
				case EMissingArg(argName):
					error(client, 'Missing required argument: $argName', 400);
			}
		} catch (e)
		{
			Log.log('HttpServer', ERROR, e.details());

			error(client, 'Unknown server error');
		}
		client.close();
	}

	function error(client:Socket, message:Dynamic, code:Int = 500):Void
	{
		final response:Bytes = Bytes.ofString(Json.stringify({
			error: message
		}));

		var statusText = switch (code)
		{
			case 400: "Bad Request";
			case 401: "Unauthorized";
			case 404: "Not Found";
			case 503: "Service Unavailable";
			default: "Internal Server Error";
		};

		try
		{
			client.output.writeString('HTTP/1.1 $code $statusText\r\n');
			client.output.writeString("Content-Type: application/json\r\n");
			client.output.writeString("Content-Length: " + (response.length) + "\r\n");
			client.output.writeString("Connection: close\r\n");
			client.output.writeString("\r\n");
			client.output.write(response);
		} catch (err:Dynamic)
		{
			Log.log('HttpServer', ERROR, "Failed to send error response: " + Std.string(err));
		}
	}
}

abstract HeaderAccess(DynamicAccess<Dynamic>) to DynamicAccess<Dynamic>
{
	public function new(headers:DynamicAccess<Dynamic>)
	{
		this = headers;
	}

	inline public function hasHeader(h:String):Bool
	{
		return Reflect.hasField(abstract, h.toLowerCase());
	}

	inline public function getHeader(h:String):String
	{
		return hasHeader(h.toLowerCase()) ? Reflect.field(abstract, h.toLowerCase()) : null;
	}

	inline public function setHeader(h:String, v:Dynamic):Void
	{
		return Reflect.setField(abstract, h, v);
	}

	public static function acceptHeaders(client:Socket):HeaderAccess
	{
		final headers:DynamicAccess<Dynamic> = {};
		while (true)
		{
			var header = client.input.readLine();

			if (header == null || header.length == 0)
				break;
			var idx = header.indexOf(':');
			if (idx >= 0)
				headers[header.substring(0, idx).toLowerCase()] = StringTools.trim(header.substring(idx + 1));
		}

		return new HeaderAccess(headers);
	}
}
