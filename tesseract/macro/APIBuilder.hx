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
using Lambda;
#end

class APIBuilder
{
	private static final kindMetas:Array<String> = ["file", "folder", "html", "get", "post"];
	private static final pathParamsReg:EReg = ~/\$\{([a-zA-Z_][a-zA-Z0-9_]*)\}/g;

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

			var path:Array<Expr> = field.meta.metaExists('path') ? [
				for (meta in field.meta.getMetaNamed('path'))
				{
					if (meta.params != null && meta.params[0] != null)
						meta.params[0];
				}
			] : null;

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

			var specialUrlPaths:Array<
				{
					path:Array<Expr>,
					guard:Expr,
					pathParams:Array<String>
				}> = [];

			if (kind == KGet || kind == KPost)
			{
				for (p in path.copy())
				{
					switch (p)
					{
						case {expr: EConst(CString(s, _))} if (pathParamsReg.match(s)):
							final parts:Array<{s:String, v:Bool}> = s.split('/').map(part ->
							{
								if (pathParamsReg.match(part))
								{
									{s: pathParamsReg.matched(1), v: true}
								}
								else {s: part, v: false}
							});

							final pathParams = [];
							final staticParts = [];
							for (id => part in parts)
							{
								if (part.v)
									pathParams[id] = part.s;
								else
									staticParts.push(macro request.pathParts[$v{id}] == $v{part.s});
							}

							var staticPartsExpr = staticParts.fold((i, r) -> macro $e{r} && $e{i}, staticParts.shift());

							var g = macro request.pathParts.length == $v{parts.length} && $e{staticPartsExpr};

							specialUrlPaths.push({path: [macro _], guard: g, pathParams: pathParams});

							path.remove(p);
						default:
					}
				}
			}

			if (path.length > 0 && field.kind.match(FFun(_)))
			{
				specialUrlPaths.push({
					path: path,
					guard: guard,
					pathParams: null
				});
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
					final cases = (kind != KPost ? getCases : postCases);

					for (p in specialUrlPaths)
						cases.push({
							values: p.path,
							guard: p.guard,
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

											if (p.pathParams != null && p.pathParams.contains(arg.name))
											{
												var index = p.pathParams.indexOf(arg.name);

												macro
												{
													final v = $e{castType(macro request.pathParts[$v{index}], type)};

													if (v != null)
														v
													else
														throw tesseract.Error.EInvalidPathParam(request.pathParts[$v{index}]);
												}
											}
											else if (arg.meta.metaExists('request'))
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
				macro tesseract.Tools.parseFloat(${e});
			case BOOL:
				macro tesseract.Tools.parseBool(${e});
			default:
				e;
		}
	}

	public static function error(e:MacroError):Dynamic
	{
		Context.error(Std.string(EMacroError(e)), curPos());

		return null;
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
		try
		{
			return switch (Context.followWithAbstracts(Context.resolveType(t, curPos())))
			{
				case TAbstract(_.get() => {name: "Int"}, _): INT;
				case TAbstract(_.get() => {name: "Float"}, _): FLOAT;
				case TAbstract(_.get() => {name: "Bool"}, _): BOOL;
				default: ANY;
			}
		} catch (e)
		{
			return ANY;
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
