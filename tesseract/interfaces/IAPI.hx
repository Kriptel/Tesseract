package tesseract.interfaces;

@:autoBuild(tesseract.macro.APIBuilder.build())
interface IAPI
{
	function get(path:String, params:Dynamic):Response;
}
