package tesseract;

import sys.FileSystem;
import haxe.io.Bytes;

@:forward
@:forward.new
abstract Folder(__Folder)
{
	@:arrayAccess
	inline public function get(key:String):Bytes
	{
		return this.get(key);
	}
}

class __Folder
{
	public final path:String;
	public var files:Map<String, File>;

	public function new(folderPath:String)
	{
		path = StringTools.endsWith(folderPath, '/') ? folderPath : folderPath + '/';

		files = [];
	}

	private var loaded:Bool = false;

	function load():Void
	{
		if (loaded)
			return;

		files.clear();

		for (file in FileSystem.readDirectory(path))
		{
			if (!FileSystem.isDirectory(path + file))
				files[file] = new File(path + file);
		}
	}

	public function get(key:String):Bytes
	{
		if (!loaded)
			load();

		return files[key]?.get();
	}
}
