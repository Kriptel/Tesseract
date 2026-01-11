package tesseract;

import tesseract.Database;
import tesseract.interfaces.IDatabase;
import tesseract.interfaces.IAPI;
import tesseract.interfaces.IServer;
import tesseract.Error;

class Tesseract
{
	private static var apiList:Array<IAPI> = [];

	public static function handleRequest(request:Request):Response
	{
		return switch (request.method)
		{
			case 'GET': get(request);
			case 'POST': post(request);
			default:
				throw ENotFound(request.path);
		}
	}

	static function get(request:Request):Response
	{
		for (api in apiList)
		{
			final resp = api.get(request);

			if (resp != null)
				return resp;
		}

		throw ENotFound(request.path);
	}

	static function post(request:Request):Response
	{
		for (api in apiList)
		{
			final resp = api.post(request);

			if (resp != null)
				return resp;
		}

		throw ENotFound(request.path);
	}

	public static function init(server:IServer, apiList:Array<IAPI>, database:IDatabase)
	{
		Database.init(database);

		for (api in apiList)
		{
			if (!Tesseract.apiList.contains(api))
				Tesseract.apiList.push(api);
		}

		server.run();
	}
}
