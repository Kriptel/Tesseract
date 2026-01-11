package tesseract.macro;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.Context.currentPos as curPos;
import haxe.macro.Expr;
import haxe.macro.Context;
import tesseract.macro.MacroTools.createField;
import tesseract.Error;
import tesseract.Response.ResponseType.fromFileExt;

using tesseract.macro.MacroTools;
#end

class APIBuilder
{
	private static final kindMetas:Array<String> = ["file", "folder", "html", "get", "post"];

	macro public static function build():Array<Field>
	{
		final localType = Context.getLocalClass().get();

		localType.isFinal = true;

		var path:String = ExprTools.getValue(localType.meta.extract('path')[0]?.params[0] ?? macro '');

		var fields:Array<Field> = Context.getBuildFields();

		final getCases:Array<Case> = [];
		final postCases:Array<Case> = [];

		final extraFields:Array<Field> = [];

		for (field in fields)
		{
			var type:Expr = if (field.meta.metaExists('type'))
			{
				field.meta.getFirstMetaNamed('type')?.params[0];
			}
			else
				null;

			var path:Array<Expr> = field.meta.getFirstMetaNamed('path')?.params;

			var guard:Expr = null;
			var contentExpr:Expr = macro $i{field.name};
			var meta:Metadata = [];

			final kindMeta:MetadataEntry =
				{
					final metas:Metadata = field.meta.filter(m -> kindMetas.contains(m.name));
					if (metas.length > 1)
						error(EDuplicateKindDefinition);
					metas[0];
				}

			final kind:APIKind = switch (kindMeta)
			{
				case null: KNone;
				case {name: 'file', params: params}:
					switch (params)
					{
						case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}]:
							KFile(k, fp, macro $v{fromFileExt(haxe.io.Path.extension(fp))});
						case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}, t]:
							KFile(k, fp, t);
						default:
							error(EInvalidFileMeta);
					}
				case {name: 'folder', params: params}:
					switch (params)
					{
						case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}]:
							KFolder(k, fp, null);
						case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}, t]:
							KFolder(k, fp, t);
						default:
							error(EInvalidFolderMeta);
					}
				case {name: 'html', params: params}:
					switch (params)
					{
						case [{expr: EConst(CString(p))}, root, head, body]:
							KHtml(p, root, head, body);
						default: error(EInvalidHtml);
					}
				case {name: 'get', params: null | []}:
					KGet;
				case {name: 'post', params: null | []}:
					KPost;
				default:
					error(EInvalidKindMeta(kindMeta));
			}

			switch (kind)
			{
				case KFile(key, filepath, t):
					type ??= t;
					path ??= [macro $v{key}];

					field.kind = FVar(macro :tesseract.File, macro new tesseract.File($v{filepath}));
					contentExpr = macro $i{field.name}.get();
				case KFolder(key, folderPath, t):
					type ??= (t ?? macro OctetStream);
					path = [macro folder];

					guard = macro StringTools.startsWith(folder, $v{key + "/"});

					field.kind = FVar(macro :tesseract.Folder, macro new tesseract.Folder($v{folderPath}));
					contentExpr = macro $i{field.name}.get(folder.substr($v{folderPath.length + 1}));
				case KHtml(p, root, head, body):
					contentExpr = macro $i{field.name}.render();
					path = [macro $v{p}];
					type ??= macro HTML;
					meta.push({name: ":isVar", params: null, pos: curPos()});
					field.kind = FProp("get", "default", macro :tesseract.render.Html);
					extraFields.push(createField("get_" + field.name, [AInline, AStatic, APrivate], FFun({
						args: [],
						ret: macro :tesseract.render.Html,
						expr: macro
						{
							if ($i{field.name} == null)
								$i{field.name} = new tesseract.render.Html($e{root}, $e{head}, $e{body});
							return $i{field.name};
						}
					}), field.pos));
				case KGet:
				case KPost:
				case KNone:
			}

			field.meta = meta;

			type ??= macro JSON;

			if (!MacroTools.isResponseType(type))
			{
				error(EInvalidTypeMeta);
			}

			if (path == null)
			{
				path = [macro $v{field.name}];
			}

			switch (field.kind)
			{
				case _ if (kind == KNone):
				case FVar(t, e), FProp(_, _, t, e):
					if (kind == KPost)
						error(EPostMethodOnField);

					getCases.push({
						values: path,
						guard: guard,
						expr: macro {
							content: $e{contentExpr},
							type: $e{type}
						}
					});
				case FFun({args: args}):
					(kind != KPost ? getCases : postCases).push({
						values: path,
						guard: guard,
						expr: macro {
							content: $i{field.name}($a
								{
									args.map(arg ->
									{
										var argName:String = arg.name;
										var type:CType = arg.type;

										var check:Expr = macro request.query;
										var access:Expr = castType(macro request.query.$argName, type);

										if (kind == KPost && !arg.meta.metaExists('query'))
										{
											check = macro request.body;
											access = macro request.body.$argName;
										}

										if (arg.meta.metaExists('request'))
										{
											arg.type = macro :tesseract.Request;
											macro request;
										}
										else if (arg.opt)
											macro $e{access};
										else
											macro
											{
												if (Reflect.hasField($e{check}, $v{argName}))
													$e{access};
												else
													throw tesseract.Error.EMissingArg($v{argName});
											};
									})
								}),
							type: $e{type}
						}
					});
			}
			if (!field.access.contains(AStatic))
				field.access.push(AStatic);
		}

		fields = fields.concat([
			createField('new', [APublic], MacroTools.FFun(macro function() {}), curPos()),

			createField('get', [APublic], MacroTools.FFun(macro function(request:tesseract.Request):tesseract.Response
			{
				return if (StringTools.startsWith(request.path, $v{path}))
				{
					$e{buildMethodSwitch(path, getCases)}
				}
				else
					null;
			}), curPos()),

			createField('post', [APublic], MacroTools.FFun(macro function(request:tesseract.Request):tesseract.Response
			{
				return if (StringTools.startsWith(request.path, $v{path}))
				{
					$e{buildMethodSwitch(path, postCases)}
				}
				else
					null;
			}), curPos())
		]);
		fields = fields.concat(extraFields);
		return fields;
	}

	#if macro
	public static function buildMethodSwitch(path:String, cases:Array<Case>):Expr
	{
		return {
			expr: ESwitch(macro request.path.substr($v{path}.length), cases, macro null),
			pos: curPos()
		}
	}

	public static function castType(e:Expr, type:CType)
	{
		return switch (type)
		{
			case INT:
				macro Std.parseInt(${e});
			case FLOAT:
				macro Std.parseFloat(${e});
			case BOOL:
				macro tesseract.Tools.parseBool(${e});
			default:
				e;
		}
	}

	public static function error(e:MacroError):Dynamic
	{
		throw EMacroError(e);
	}
	#end
}

#if macro
private enum abstract CType(Int)
{
	var INT;
	var FLOAT;
	var BOOL;
	var ANY;

	@:from
	public static function fromType(t:ComplexType)
	{
		return switch (t)
		{
			case null: ANY;
			case macro :Int: INT;
			case macro :Float: FLOAT;
			case macro :Bool: BOOL;
			default: ANY;
		}
	}
}

enum APIKind
{
	KFile(key:String, path:String, type:Expr);
	KFolder(key:String, path:String, type:Null<Expr>);
	KHtml(path:String, root:Expr, head:Expr, body:Expr);
	KGet;
	KPost;
	KNone;
}
#end
