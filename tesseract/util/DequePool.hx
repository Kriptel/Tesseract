package tesseract.util;

import sys.thread.Deque;
import sys.thread.Mutex;

class DequePool
{
	private static var pool = new Deque<Deque<Dynamic>>();
	private static var mutex = new Mutex();

	private static inline var MAX_POOL_SIZE = tesseract.macro.MacroTools.getDefineValueInt('tesseract_MAX_POOL_SIZE', 50);
	private static var currentCount = 0;

	public static function get():Deque<Dynamic>
	{
		final item = pool.pop(false);

		if (item != null)
			return item;

		mutex.acquire();
		currentCount++;
		mutex.release();

		return new Deque<Dynamic>();
	}

	public static function clearAndPut(d:Deque<Dynamic>):Void
	{
		while (d.pop(false) != null) {}

		inline put(d);
	}

	public static function put(d:Deque<Dynamic>):Void
	{
		mutex.acquire();
		if (currentCount > MAX_POOL_SIZE)
		{
			currentCount--;
			mutex.release();
		}
		else
		{
			mutex.release();
			pool.add(d);
		}
	}
}
