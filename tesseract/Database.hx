package tesseract;

import tesseract.interfaces.IDatabase;

class Database
{
	private static var db:IDatabase;

	@:allow(tesseract.Tesseract)
	private static function init(db:IDatabase)
	{
		Database.db = db;
	}

	public static function load(file:String):Void
	{
		db.load(file);
	}

	public static function save(file:String):Void
	{
		db.save(file);
	}

	public static function get<T>(path:String):T
	{
		return db.get(path);
	}

	public static function set(path:String, v:Dynamic):Void
	{
		db.set(path, v);
	}
}
