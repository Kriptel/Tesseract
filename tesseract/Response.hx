package tesseract;

typedef Response =
{
	var content:Dynamic;
	var type:ResponseType;
}

enum abstract ResponseType(String) from String to String
{
	var HTML = 'text/html';
	var Plain = 'text/plain';
	var CSS = 'text/css';
	var CSV = 'text/csv';

	var JSON = 'application/json';
	var XML = 'application/xml';
	var JavaScript = 'application/javascript';
	var FormData = 'multipart/form-data';

	var PNG = 'image/png';
	var JPEG = 'image/jpeg';
	var GIF = 'image/gif';
	var SVG = 'image/svg+xml';
	var WebP = 'image/webp';
	var AVIF = 'image/avif';

	var MP4 = 'video/mp4';
	var WebM = 'video/webm';
	var MPEG = 'audio/mpeg';
	var WAV = 'audio/wav';

	var OctetStream = 'application/octet-stream';
	var PDF = 'application/pdf';
	var Zip = 'application/zip';

	var WOFF2 = 'font/woff2';

	var GLTF = 'model/gltf+json';
	var EventStream = 'text/event-stream';

	public static function fromFileExt(ext:String):ResponseType
	{
		return switch (ext.toLowerCase())
		{
			case 'html', 'htm': HTML;
			case 'txt': Plain;
			case 'css': CSS;
			case 'csv': CSV;
			case 'json': JSON;
			case 'xml': XML;
			case 'js': JavaScript;
			case 'png': PNG;
			case 'jpg', 'jpeg': JPEG;
			case 'gif': GIF;
			case 'svg': SVG;
			case 'webp': WebP;
			case 'avif': AVIF;
			case 'mp4': MP4;
			case 'webm': WebM;
			case 'mp3': MPEG;
			case 'wav': WAV;
			case 'pdf': PDF;
			case 'zip': Zip;
			case 'woff2': WOFF2;
			case 'gltf': GLTF;
			default: OctetStream;
		};
	}
}
