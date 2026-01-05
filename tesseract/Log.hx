package tesseract;

class Log
{
	public static function log(source:String, type:LogType = INFO, message:String)
	{
		Sys.println('[Tesseract:$source] $type: $message');
	}
}

enum abstract LogType(String) to String
{
	var INFO;
	var ERROR;
}
