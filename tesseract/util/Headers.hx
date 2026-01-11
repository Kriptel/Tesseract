package tesseract.util;

import haxe.ds.StringMap;

@:allow(tesseract)
abstract Headers(StringMap<Array<String>>) from StringMap<Array<String>>
{
	public function new()
	{
		this = new StringMap();
	}

	inline public function hasHeader(header:String):Bool
	{
		return hasHeaderUnsafe(header.toLowerCase());
	}

	inline public function getHeader(header:String):Null<String>
	{
		return getHeaderUnsafe(header.toLowerCase());
	}

	inline public function getHeaders(header:String):Null<Array<String>>
	{
		return getHeadersUnsafe(header.toLowerCase());
	}

	inline public function iterator()
	{
		return this.iterator();
	}

	inline public function keyValueIterator()
	{
		return this.keyValueIterator();
	}

	// Internal API

	inline private function addHeader(header:String, value:String):Void
	{
		addHeaderUnsafe(header.toLowerCase(), value);
	}

	inline private function addHeaders(header:String, values:Array<String>):Void
	{
		addHeadersUnsafe(header.toLowerCase(), values);
	}

	inline private function setHeaders(header:String, values:Array<String>):Void
	{
		setHeadersUnsafe(header.toLowerCase(), values);
	}

	inline private function removeHeader(header:String):Bool
	{
		return removeHeaderUnsafe(header.toLowerCase());
	}

	// Unsafe API

	inline private function hasHeaderUnsafe(header:String):Bool
	{
		return this.exists(header);
	}

	inline private function getHeaderUnsafe(header:String):Null<String>
	{
		final headers:Array<String> = this.get(header);

		return if (headers != null)
			headers[0];
		else
			null;
	}

	inline private function getHeadersUnsafe(header:String):Null<Array<String>>
	{
		return if (hasHeaderUnsafe(header))
			this.get(header);
		else
			null;
	}

	inline private function addHeaderUnsafe(header:String, value:String):Void
	{
		if (hasHeaderUnsafe(header))
			getHeadersUnsafe(header).push(value);
		else
			setHeadersUnsafe(header, [value]);
	}

	inline private function addHeadersUnsafe(header:String, values:Array<String>):Void
	{
		if (hasHeaderUnsafe(header))
		{
			final headers:Array<String> = getHeadersUnsafe(header);

			for (value in values)
				headers.push(value);
		}
		else
			setHeadersUnsafe(header, values);
	}

	inline private function setHeadersUnsafe(header:String, values:Array<String>):Void
	{
		this.set(header, values);
	}

	inline private function removeHeaderUnsafe(header:String):Bool
	{
		return this.remove(header);
	}
}
