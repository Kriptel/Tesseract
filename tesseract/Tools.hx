package tesseract;

class Tools
{
	inline public static function parseFloat(f:String):Null<Float>
	{
		return Std.parseFloat(f);
	}

	inline public static function parseBool(i:String):Null<Bool>
	{
		return i == 'true';
	}
}
