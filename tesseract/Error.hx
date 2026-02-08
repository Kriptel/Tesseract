package tesseract;

enum Error
{
	ENullDatabase;
	ENotFound(path:String);
	EInvalidMethod(method:String);
	EMissingArg(argName:String);
	EInvalidPathParam(param:String);
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
	EInvalidKind(kind:tesseract.macro.APIBuilder.APIKind);
	EDuplicateKindDefinition;
	EInvalidKindMeta(meta:haxe.macro.Expr.MetadataEntry);
	EPostMethodOnField;
}
#end
