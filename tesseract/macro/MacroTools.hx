package tesseract.macro;

import haxe.macro.Expr;

class MacroTools
{
	public static function FFun(f:Expr):FieldType
	{
		return FieldType.FFun(toFunction(f));
	}

	public static function toFunction(f:Expr):Function
	{
		return switch (f.expr)
		{
			case EFunction(_, f): f;
			default: null;
		}
	}

	public static function isResponseType(e:Expr):Bool
	{
		return switch (e.expr)
		{
			case EConst(CIdent(s)), EConst(CString(s)):
				true;
			default:
				false;
		}
	}

	public static function createField(name:String, access:Array<Access>, kind:FieldType, pos:Position):Field
	{
		return {
			name: name,
			access: access,
			kind: kind,
			pos: pos
		}
	}

	public static function getFirstMetaNamed(meta:Metadata, name:String):Null<MetadataEntry>
	{
		for (m in meta)
		{
			if (m.name == name)
				return m;
		}

		return null;
	}

	public static function getMetaNamed(meta:Metadata, name:String):Array<MetadataEntry>
	{
		return [
			for (m in meta)
			{
				if (m.name == name)
					m;
			}
		];
	}

	public static function metaExists(meta:Metadata, name:String):Bool
	{
		for (m in meta)
		{
			if (m.name == name)
				return true;
		}

		return false;
	}
}
