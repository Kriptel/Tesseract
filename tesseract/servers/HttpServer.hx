package tesseract.servers;

import haxe.io.Bytes;
import haxe.DynamicAccess;
import haxe.Json;
import sys.net.Socket;
import sys.net.Host;
import tesseract.interfaces.IServer;
import sys.thread.Thread;

using StringTools;

class HttpServer implements IServer
{
	var socket:Socket;

	public function new(host:String, port:Int, maxConnections:Int)
	{
		socket = new Socket();
		socket.bind(new Host(host), port);
		socket.listen(100);
		Log.log('HttpServer', INFO, 'Server started on $host:$port');
	}

	public function run():Void
	{
		while (true)
		{
			var client = socket.accept();
			Thread.create(handleClient.bind(client));
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
				var rawBody:String = '';

				rawBody = client.input.readString(contentLength);

				var contentType = headers.getHeader('Content-Type');

				switch (contentType)
				{
					case 'application/json':
						var json:DynamicAccess<Dynamic> = Json.parse(rawBody);

						for (k => v in json)
						{
							params[k] = v;
						}
				}
			}

			params['cookie'] = headers;

			final result = Tesseract.get(pathOnly, params);

			var response:Bytes = result.type == JSON ? Bytes.ofString(Json.stringify(result?.content)) : result.content;

			client.output.writeString("HTTP/1.1 200 OK\r\n");
			client.output.writeString('Content-Type: ${result.type}\r\n');
			client.output.writeString("Content-Length: " + Std.string(response.length) + "\r\n");
			client.output.writeString("Connection: close\r\n");
			client.output.writeString("\r\n");
			client.output.write(response);
		} catch (e)
		{
			try
			{
				Log.log('HttpServer', ERROR, e.details());

				error(client, 'Unknown server error');
			} catch (_) {}
		}
		client.close();
	}

	function error(client:Socket, e:Dynamic):Void
	{
		var response = Json.stringify({error: e});

		client.output.writeString("HTTP/1.1 500 Internal Server Error\r\n");
		client.output.writeString("Content-Type: application/json\r\n");
		client.output.writeString("Content-Length: " + response.length + "\r\n");
		client.output.writeString("Connection: close\r\n");
		client.output.writeString("\r\n");
		client.output.writeString(response);
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
