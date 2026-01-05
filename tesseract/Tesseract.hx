package tesseract;

import tesseract.Database;
import tesseract.interfaces.IDatabase;
import tesseract.interfaces.IAPI;
import tesseract.interfaces.IServer;
import tesseract.Error;

class Tesseract
{
	private static var apiList:Array<IAPI> = [];

	public static function get(path:String, params:Dynamic):Response
	{
		for (api in apiList)
		{
			final resp = api.get(path, params);

			if (resp != null)
				return resp;
		}

		throw ENotFound;
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
