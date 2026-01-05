package tesseract;

class File
{
	public final path:String = '';

	public function new(path:String)
	{
		this.path = path;
	}

	public function get():haxe.io.Bytes
	{
		return sys.io.File.getBytes(path);
	}
}
