Apiary Blueprint Parser
=======================

A JavaScript parser of [Apiary API blueprints](http://apiary.io/blueprint).

Installation
------------

### Node.js

    $ npm install apiary-blueprint-parser

Do not install the parser globally (using the `-g` option), otherwise you won’t be able to use the API.

### Browser

Download the latest browser version of the parser from the Downloads section on
GitHub.

Usage
-----

In Node.js, require the module:

```javascript
var ApiaryBlueprintParser = require("apiary-blueprint-parser");
```

In browser, include the browser version of the parser in your web page or
application using the `<script>` tag. The parser will be available in the
`ApiaryBlueprintParser` global object.

To parse an API blueprint, just call the `parse` method and pass the blueprint
as a parameter. The method will return an object representing the parsed
blueprint or throw an exception if the input is invalid:

```javascript
var blueprint = ApiaryBlueprintParser.parse([
  "Root resource",
  "GET /",
  "< 200"
].join("\n"));

var resource = blueprint.sections[0].resources[0];
console.log(resource.description)     // prints "Root resource"
console.log(resource.method)          // prints "GET"
console.log(resource.url)             // prints "/"
console.log(resource.response.status) // prints "200"
```

See the `src/ast.coffee` file to get an idea about returned objects and their
capabilities.

The exception thrown in case of error will contain `offset`, `line`, `column`,
`expected`, `found` and `message` properties with more details about the error.

Compatibility
-------------

The parser should run well in the following environments:

  * Node.js 0.6.18+
  * IE 9+
  * Firefox
  * Chrome
  * Safari
  * Opera

The parser should also work in IE 8, but this is not fully tested because the
test suite runs correctly only in IE 9+.
