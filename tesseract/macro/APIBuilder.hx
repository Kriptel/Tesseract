package tesseract.macro;

#if macro
import haxe.macro.ExprTools;
import haxe.macro.Context.currentPos as curPos;
import haxe.macro.Expr;
import haxe.macro.Context;
import tesseract.macro.MacroTools.createField;
import tesseract.Error;

using tesseract.macro.MacroTools;
#end

class APIBuilder
{
	macro public static function build():Array<Field>
	{
		final localType = Context.getLocalClass().get();

		localType.isFinal = true;

		var path:String = ExprTools.getValue(localType.meta.extract('path')[0]?.params[0] ?? macro '');

		var fields:Array<Field> = Context.getBuildFields();

		final getCases = [];

		final extraFields:Array<Field> = [];
		for (field in fields)
		{
			var type:Expr = null;
			if (field.meta.metaExists('type'))
			{
				type = field.meta.getFirstMetaNamed('type')?.params[0];
			}

			var path:Array<Expr> = field.meta.getFirstMetaNamed('path')?.params;

			var guard:Expr = null;
			var contentExpr:Expr = macro $i{field.name};
			var meta:Metadata = [];

			if (field.meta.metaExists('file'))
			{
				field.access.remove(AFinal);

				var key:String = null;
				var filepath:String = null;

				switch (field.meta.getFirstMetaNamed('file')?.params)
				{
					case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}]:
						key = k;
						filepath = fp;
						type ??= macro $v{tesseract.Response.ResponseType.fromFileExt(haxe.io.Path.extension(filepath))};

					case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}, t]:
						key = k;
						filepath = fp;
						type = t;

					default:
						error(EInvalidFileMeta);
				}

				path ??= [macro $v{key}];

				field.kind = FVar(macro :tesseract.File, macro new tesseract.File($v{filepath}));

				contentExpr = macro $i{field.name}.get();
			}
			else if (field.meta.metaExists('folder'))
			{
				var key:String = "";
				var folderPath:String = "";

				switch (field.meta.getFirstMetaNamed('folder')?.params)
				{
					case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}]:
						key = k;
						folderPath = fp;
					case [{expr: EConst(CString(k))}, {expr: EConst(CString(fp))}, t]:
						key = k;
						folderPath = fp;
						type = t;
					default:
						error(EInvalidFolderMeta);
				}

				path = [macro folder];
				guard = macro StringTools.startsWith(folder, $v{key + "/"});

				type ??= macro OctetStream;

				field.kind = FVar(macro :tesseract.Folder, macro new tesseract.Folder($v{folderPath}));

				contentExpr = macro $i{field.name}.get(folder.substr($v{folderPath.length + 1}));
			}
			else if (field.meta.metaExists('html'))
			{
				switch (field.meta.getFirstMetaNamed('html')?.params)
				{
					case [{expr: EConst(CString(p))}, root, head, body]:
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

					default:
						error(EInvalidHtml);
				}
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
				case FVar(t, e), FProp(_, _, t, e):
					getCases.push({
						values: path,
						guard: guard,
						expr: macro {
							content: $e{contentExpr},
							type: $e{type}
						}
					});
				case FFun({args: args}):
					getCases.push({
						values: path,
						guard: guard,
						expr: macro {
							content: $i{field.name}($a
								{
									args.map(arg ->
									{
										var argName = arg.name;
										var type:CType = switch (arg.type)
										{
											case macro :Int:
												INT;
											case macro :Float:
												FLOAT;
											case macro :Bool:
												BOOL;
											default:
												ANY;
										}

										if (arg.opt)
											castType(macro params.$argName, type);
										else
											macro
											{
												if (Reflect.hasField(params, $v{argName}))
													$e{castType(macro params.$argName, type)};
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
			createField('get', [APublic], MacroTools.FFun(macro function(name:String, params:Dynamic):tesseract.Response
			{
				return if (StringTools.startsWith(name, $v{path}))
					$
					{
						{
							expr: ESwitch(macro name.substr($v{path}.length), getCases, macro null),
							pos: curPos()
						}
					};
				else
					null;
			}), curPos()),
			createField('post', [APublic], MacroTools.FFun(macro function(name:String, params:Dynamic):Dynamic
			{
				return null;
			}), curPos())
		]);

		fields = fields.concat(extraFields);

		return fields;
	}

	#if macro
	public static function castType(e:Expr, type:CType)
	{
		return switch (type)
		{
			case INT:
				macro tesseract.Tools.castInt(${e});
			case FLOAT:
				macro tesseract.Tools.castFloat(${e});
			case BOOL:
				macro tesseract.Tools.castBool(${e});
			default:
				e;
		}
	}

	public static function error(e:MacroError)
	{
		throw EMacroError(e);
	}
	#end
}

#if macro
private enum CType
{
	INT;
	FLOAT;
	BOOL;
	ANY;
}
#end
