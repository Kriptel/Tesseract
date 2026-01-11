package tesseract.servers;

import tesseract.Request.Address;
import tesseract.util.Headers;
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

		Log.info(HttpServer, 'Server started on $host:$port');
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
			client.setTimeout(timeout);

			var requestLine = client.input.readLine();
			if (requestLine == null)
			{
				client.close();
				return;
			}

			#if debug
			Log.debug(HttpServer, requestLine);
			#end

			inline function formatAdress(rawAddress:{host:sys.net.Host, port:Int}):Address
			{
				return {
					host: rawAddress.host.host,
					port: rawAddress.port
				}
			}

			final ip:Address = formatAdress(client.peer());
			final host:Address = formatAdress(client.host());

			final firstLine:Array<String> = requestLine.split(" ");

			final method:String = firstLine[0];
			final path:String = firstLine[1].substring(1);
			final protocol:String = firstLine[2];

			final pathOnly = path.indexOf('?') >= 0 ? path.substring(0, path.indexOf('?')) : path;
			final queryStr = path.indexOf('?') >= 0 ? path.substring(path.indexOf('?') + 1) : '';

			final headers = acceptHeaders(client);

			var contentLength:Int = Std.parseInt(headers.getHeader('Content-Length'));

			var query:DynamicAccess<String> = {};

			if (queryStr.length > 0)
			{
				for (p in queryStr.split('&'))
				{
					if (p.length == 0)
						continue;

					var eq = p.indexOf('=');
					if (eq >= 0)
						query[p.substring(0, eq)] = p.substring(eq + 1);
					else
						query[p] = '';
				}
			}

			var body:Dynamic = null;

			if (method == "POST" && contentLength > 0)
			{
				var rawBody:Bytes = client.input.read(contentLength);

				switch (headers.getHeader('Content-Type'))
				{
					case 'application/json':
						body = Json.parse(rawBody.toString());
				}
			}

			final result = Tesseract.handleRequest(new Request(pathOnly, method, protocol, ip, host, query, body, headers));

			var response:Bytes = result.type == JSON ? Bytes.ofString(Json.stringify(result?.content)) : result.content;

			client.output.writeString("HTTP/1.1 200 OK\r\n");
			client.output.writeString('Content-Type: ${result.type}\r\n');
			client.output.writeString("Content-Length: " + Std.string(response.length) + "\r\n");
			client.output.writeString("Connection: close\r\n");
			client.output.writeString("\r\n");
			client.output.write(response);
		} catch (e:Error)
		{
			Log.error(HttpServer, Std.string(e));

			switch (e)
			{
				case ENotFound(_):
					error(client, "Resource not found", 404);
				case ENullDatabase:
					error(client, "Database connection is not initialized", 503);
				case EMissingArg(argName):
					error(client, 'Missing required argument: $argName', 400);
				case EInvalidMethod(method):
					error(client, 'Method "$method" is not implemented', 501);
			}
		} catch (e:haxe.io.Error)
		{
			switch (e)
			{
				case Blocked:
					Log.error(HttpServer, 'Blocked');

				default:
					Log.error(HttpServer, Std.string(e));
					error(client, 'Unknown server error');
			}
		} catch (e)
		{
			Log.error(HttpServer, e.details());
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
			case 405: "Method Not Allowed";
			case 501: "Not Implemented";
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
			Log.error(HttpServer, "Failed to send error response: " + Std.string(err));
		}
	}

	inline public static function acceptHeaders(client:Socket):Headers
	{
		final headers:Headers = new Headers();
		while (true)
		{
			var header = client.input.readLine();

			if (header == null || header.length == 0)
				break;

			var idx = header.indexOf(':');
			if (idx >= 0)
				headers.addHeader(header.substring(0, idx), StringTools.trim(header.substring(idx + 1)));
		}

		return headers;
	}
}
