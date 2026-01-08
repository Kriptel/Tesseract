package tesseract.interfaces;

interface IDatabase
{
	function load(file:String):Void;
	function save(file:String):Void;
	function get<T>(path:String):T;
	function set(path:String, v:Dynamic):Bool;
}
