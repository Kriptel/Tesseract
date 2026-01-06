package tesseract;

enum Error
{
	ENullDatabase;
	ENotFound;
	EMissingArg(argName:String);
	#if macro
	EMacroError(e:MacroError);
	#end
}

#if macro
enum MacroError
{
	EInvalidTypeMeta;
	EInvalidFileMeta;
	EInvalidFolderMeta;
	EInvalidHtml;
}
#end
