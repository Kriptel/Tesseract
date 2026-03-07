package octacube.interfaces;

@:autoBuild(octacube.macro.APIBuilder.build())
interface IAPI
{
	function get(request:Request):Response;
	function post(request:Request):Response;
}
