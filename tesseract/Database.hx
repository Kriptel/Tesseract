package tesseract;

import tesseract.util.DequePool;
import tesseract.interfaces.IDatabase;
import sys.thread.Thread;
import sys.thread.Deque;

enum DatabaseMessage
{
	Get(id:String, queue:Deque<Dynamic>);
	Set(id:String, value:Dynamic, queue:Deque<Dynamic>);
	Load(file:String);
	Save(file:String);
}

class Database
{
	private static var db:IDatabase;
	private static var queue:Deque<DatabaseMessage>;

	@:allow(tesseract.Tesseract)
	private static function init(db:IDatabase)
	{
		Database.db = db;

		queue = new Deque<DatabaseMessage>();

		Thread.create(() ->
		{
			while (true)
			{
				var msg = queue.pop(true);

				switch (msg)
				{
					case Get(id, queue):
						try
						{
							queue.add(db.get(id));
						} catch (e)
						{
							queue.add(null);
							Log.error(Database, e.toString());
						}
					case Set(id, value, queue):
						try
						{
							queue.add(db.set(id, value));
						} catch (e)
						{
							queue.add(false);
							Log.error(Database, e.toString());
						}
					case Load(file):
						db.load(file);
					case Save(file):
						db.save(file);
				}
			}
		});
	}

	public static function send(msg:DatabaseMessage)
	{
		queue.add(msg);
	}

	public static function load(file:String):Void
	{
		send(Load(file));
	}

	public static function save(file:String):Void
	{
		send(Save(file));
	}

	public static function get<T>(path:String):Null<T>
	{
		final queue:Deque<Dynamic> = DequePool.get();

		Database.send(Get(path, queue));

		final result = queue.pop(true);

		DequePool.put(queue);

		if (result == null)
			return null;

		return cast result;
	}

	public static function set(path:String, value:Dynamic):Bool
	{
		final queue:Deque<Dynamic> = DequePool.get();

		Database.send(Set(path, value, queue));

		final result = queue.pop(true);

		DequePool.put(queue);

		return result;
	}
}
