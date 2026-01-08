package tesseract;

class Log
{
	inline public static function log(source:LogSource, type:LogType = INFO, message:String)
	{
		Sys.println('[Tesseract:$source] $type: $message');
	}

	inline public static function info(source:LogSource, message:String)
	{
		log(source, INFO, message);
	}

	inline public static function debug(source:LogSource, message:String)
	{
		log(source, DEBUG, message);
	}

	inline public static function error(source:LogSource, message:String)
	{
		log(source, ERROR, message);
	}
}

enum abstract LogSource(String) from String to String
{
	var DATABASE = 'Database';
	var HTTPSERVER = 'HttpServer';
}

enum abstract LogType(String) to String
{
	var INFO;
	var DEBUG;
	var ERROR;
}
