<p align="center">
  <img src="./logo.png" width="60%"/>
</p>

#

Tesseract is a library for quickly and easily creating APIs. It provides tools for creating a bundle of HTTP servers, APIs, and databases (currently WIP).

> [!WARNING] 
> This library is in early development, so use it with caution; it is not recommended for production use.

# Example

```haxe
import tesseract.servers.HttpServer;
import tesseract.Tesseract;
import tesseract.interfaces.IAPI;

class Main {
    static public function main() {
        // Initialize Tesseract with Server, APIs, and Database
        Tesseract.init(
            new HttpServer('localhost', 60000, 10), 
            [new MyAPI()], 
            null
        );
    }
}

@path("api/")
class MyAPI implements IAPI {
    @get final version:String = '0.0.1';

    // Serve a static HTML file
    @file('', 'pages/index.html') final index_html;

    @folder('pages', 'pages', HTML) final pages;

    @folder('styles', 'styles', CSS) final styles;

    // Path, root, head and body
    @html('main', "<!DOCTYPE html><html></html>", pages["template.html"], pages["main.html"]) final main;

    // A GET endpoint with parameters
    @get function addition(a:Int, b:Int, ?c:Float) {
        return a + b + c;
    }

    // Defines a POST endpoint at 'api/foo' where 'a' is parsed from the body and 'b' from the URL query string
    @path("foo") @post function helloWorld(a:Float, @query b:Bool) {
        return b ? a + 100 : a;
    }
}
```

## Install

1. Installing the library: 
	- `haxelib git Tesseract https://github.com/Kriptel/Tesseract.git`