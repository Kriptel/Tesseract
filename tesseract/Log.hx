package tesseract;

class Log
{
	inline public static function log(source:LogSource, type:LogType = INFO, message:String, ?color:LogColor = null)
	{
		if (color != null)
			Sys.println('[Tesseract:$source] $color$type: $message$RESET');
		else
			Sys.println('[Tesseract:$source] $type: $message');
	}

	inline public static function info(source:LogSource, message:String)
	{
		log(source, INFO, message, GREEN);
	}

	inline public static function warn(source:LogSource, message:String)
	{
		log(source, WARN, message, YELLOW);
	}

	inline public static function debug(source:LogSource, message:String)
	{
		log(source, DEBUG, message, CYAN);
	}

	inline public static function error(source:LogSource, message:String)
	{
		log(source, ERROR, message, RED);
	}
}

enum abstract LogSource(String) from String to String
{
	var Database;
	var HttpServer;
}

enum abstract LogType(String) to String
{
	var INFO;
	var WARN;
	var DEBUG;
	var ERROR;
}

enum abstract LogColor(String) to String
{
	var RESET = "\x1b[0m";
	var RED = "\x1b[31m";
	var GREEN = "\x1b[92m";
	var YELLOW = "\x1b[93m";
	var CYAN = "\x1b[36m";
}
