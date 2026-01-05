package tesseract;

class Tools
{
	public static function castInt(i:Dynamic):Int
	{
		return if (i is String)
			Std.parseInt(i)
		else
			i;
	}

	public static function castFloat(i:Dynamic):Float
	{
		return if (i is String)
			Std.parseFloat(i)
		else
			i;
	}

	public static function castBool(i:Dynamic):Bool
	{
		return if (i is String)
			i == 'true'
		else
			i;
	}
}
