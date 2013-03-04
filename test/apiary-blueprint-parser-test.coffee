if require?
  parser = require "../lib/apiary-blueprint-parser"
  chai   = require "chai"
else
  parser = window.ApiaryBlueprintParser
  chai   = window.chai

chai.use (chai, util) ->
  chai.assert.parse = (input, result) ->
    assertion = new chai.Assertion(input)

    assertion.assert(
      util.eql(parser.parse(input), result)
      "expected \#{act} to parse as \#{exp}"
      "expected \#{act} not to parse as \#{exp}"
      result
      input
    )

  chai.assert.notParse = (input) ->
    assertion = new chai.Assertion(input)

    try
      parser.parse(input)
      parsed = true
    catch e
      parsed = false

    assertion.assert(
      not parsed
      "expected \#{act} not to parse"
      "expected \#{act} to parse"
      null
      input
    )

assert = chai.assert

Blueprint            = parser.ast.Blueprint
Section              = parser.ast.Section
Resource             = parser.ast.Resource
Request              = parser.ast.Request
Response             = parser.ast.Response
JsonSchemaValidation = parser.ast.JsonSchemaValidation

sectionBlueprint = (props = {}) ->
  new Blueprint
    name:     "API"
    sections: [new Section(props)]

resourceBlueprint = (props = {}) ->
  sectionBlueprint resources: [new Resource(props)]

requestBlueprint = (props = {}) ->
  resourceBlueprint request: new Request(props)

responseBlueprint = (props = {}) ->
  resourceBlueprint responses: [new Response(props)]

describe "Apiary blueprint parser", ->
  # ===== Rule Tests =====

  # There is no canonical API.
  it "parses API", ->
    # Tests here do not mimic the grammar as tests of other rules do. This is
    # because almost all such tests would use incomplete blueprints already
    # exercised in other tests, only introducing duplication.
    blueprint = new Blueprint
      location:    "http://example.com/"
      name:        "API"
      description: "Test API"
      sections:    [
        new Section resources: [
          new Resource url: "/one"
          new Resource url: "/two"
          new Resource url: "/three"
        ]
        new Section name: "Section 1"
        new Section name: "Section 2"
        new Section name: "Section 3"
      ]

    assert.parse """
      HOST: http://example.com/
      --- API ---
      ---
      Test API
      ---
      GET /one
      < 200

      GET /two
      < 200

      GET /three
      < 200

      -- Section 1 --
      -- Section 2 --
      -- Section 3 --
      -- JSON Schema Validations --
    """, blueprint

    assert.parse """

      HOST: http://example.com/

      --- API ---

      ---
      Test API
      ---

      GET /one
      < 200

      GET /two
      < 200

      GET /three
      < 200

      -- Section 1 --
      -- Section 2 --
      -- Section 3 --

      -- JSON Schema Validations --

    """, blueprint

    assert.parse """



      HOST: http://example.com/



      --- API ---



      ---
      Test API
      ---



      GET /one
      < 200

      GET /two
      < 200

      GET /three
      < 200



      -- Section 1 --
      -- Section 2 --
      -- Section 3 --



      -- JSON Schema Validations --



    """, blueprint

  # Canonical Location is "HOST: http://example.com/".
  it "parses Location", ->
    assert.parse """
      HOST:abcd

      --- API ---
    """, new Blueprint location: "abcd", name: "API"

    assert.parse """
      HOST: abcd

      --- API ---
    """, new Blueprint location: "abcd", name: "API"

    assert.parse """
      HOST:   abcd

      --- API ---
    """, new Blueprint location: "abcd", name: "API"

  # Canonical APIName is "--- API ---".
  it "parses APIName", ->
    assert.parse "--- abcd",       new Blueprint name: "abcd"
    assert.parse "---   abcd",     new Blueprint name: "abcd"
    assert.parse "--- abcd ---",   new Blueprint name: "abcd"
    assert.parse "--- abcd   ---", new Blueprint name: "abcd"

  # Canonical APIDescription is:
  #
  #   ---
  #   Test API
  #   ---
  #
  it "parses APIDescription", ->
    assert.parse """
      --- API ---

      ---
      ---
    """, new Blueprint name: "API", description: null

    assert.parse """
      --- API ---

      --- 
      ---
    """, new Blueprint name: "API", description: null

    assert.parse """
      --- API ---

      ---  
      ---
    """, new Blueprint name: "API", description: null

    assert.parse """
      --- API ---

      ---
      abcd
      ---
    """, new Blueprint name: "API", description: "abcd"

    assert.parse """
      --- API ---

      ---
      abcd
      efgh
      ijkl
      ---
    """, new Blueprint name: "API", description: "abcd\nefgh\nijkl"

    assert.parse """
      --- API ---

      ---
      --- 
    """, new Blueprint name: "API", description: null

    assert.parse """
      --- API ---

      ---
      ---   
    """, new Blueprint name: "API", description: null

  # Canonical APIDescriptionLine is "abcd".
  it "parses APIDescriptionLine", ->
    assert.parse """
      --- API ---

      ---
      abcd
      ---
    """, new Blueprint name: "API", description: "abcd"

    assert.notParse """
      --- API ---

      ---
      ---
      ---
    """

  # Canonical Sections is:
  #
  #   -- Section 1 --
  #   -- Section 2 --
  #   -- Section 3 --
  #
  it "parses Sections", ->
    blueprint0 = new Blueprint
      name: "API"
      sections: []

    blueprint1 = new Blueprint
      name:     "API"
      sections: [new Section name: "Section 1"]

    blueprint3 = new Blueprint
      name:     "API"
      sections: [
        new Section name: "Section 1"
        new Section name: "Section 2"
        new Section name: "Section 3"
      ]

    assert.parse """
      --- API ---

    """, blueprint0

    assert.parse """
      --- API ---

      -- Section 1 --
    """, blueprint1

    assert.parse """
      --- API ---

      -- Section 1 --
      -- Section 2 --
      -- Section 3 --
    """, blueprint3

    assert.parse """
      --- API ---

      -- Section 1 --

      -- Section 2 --

      -- Section 3 --
    """, blueprint3

    assert.parse """
      --- API ---

      -- Section 1 --



      -- Section 2 --



      -- Section 3 --
    """, blueprint3

  # Canonical Section is "-- Section --".
  it "parses Section", ->
    blueprint = sectionBlueprint
      name:      "Section"
      resources: [
        new Resource url: "/one"
        new Resource url: "/two"
        new Resource url: "/three"
      ]

    assert.parse """
      --- API ---

      -- Section --
      GET /one
      < 200

      GET /two
      < 200

      GET /three
      < 200
    """, blueprint

    assert.parse """
      --- API ---

      -- Section --

      GET /one
      < 200

      GET /two
      < 200

      GET /three
      < 200
    """, blueprint

    assert.parse """
      --- API ---

      -- Section --



      GET /one
      < 200

      GET /two
      < 200

      GET /three
      < 200
    """, blueprint

  # Canonical SectionHeader is "-- Section --".
  it "parses SectionHeader", ->
    assert.parse """
      --- API ---

      -- Section --
    """, sectionBlueprint name: "Section"

    assert.parse """
      --- API ---

      --\nSection\n--
    """, sectionBlueprint name: "Section"

  # Canonical SectionHeaderShort is "-- Section --".
  it "parses SectionHeaderShort", ->
    assert.parse """
      --- API ---

      -- abcd
    """, sectionBlueprint name: "abcd"

    assert.parse """
      --- API ---

      --   abcd
    """, sectionBlueprint name: "abcd"

    assert.parse """
      --- API ---

      -- abcd --
    """, sectionBlueprint name: "abcd"

    assert.parse """
      --- API ---

      -- abcd   --
    """, sectionBlueprint name: "abcd"

  # Canonical SectionHeaderLong is:
  #
  #   ---
  #   Test API
  #   ---
  #
  it "parses SectionHeaderLong", ->
    assert.parse """
      --- API ---

      --
      --
    """, sectionBlueprint name: null, description: null

    assert.parse """
      --- API ---

      -- 
      --
    """, sectionBlueprint name: null, description: null

    assert.parse """
      --- API ---

      --   
      --
    """, sectionBlueprint name: null, description: null

    assert.parse """
      --- API ---

      --
      abcd
      --
    """, sectionBlueprint name: "abcd", description: null

    assert.parse """
      --- API ---

      --
      abcd
      efgh
      ijkl
      --
    """, sectionBlueprint name: "abcd", description: "efgh\nijkl"

    assert.parse """
      --- API ---

      --
      -- 
    """, sectionBlueprint name: null, description: null

    assert.parse """
      --- API ---

      --
      --   
    """, sectionBlueprint name: null, description: null

  # Canonical SectionHeaderLongLine is "abcd".
  it "parses SectionHeaderLongLine", ->
    assert.parse """
      --- API ---

      --
      abcd
      --
    """, sectionBlueprint name: "abcd"

    assert.notParse """
      --- API ---

      --
      --
      --
    """

  # Canonical Resources is:
  #
  #   GET /one
  #
  #   GET /two
  #
  #   GET /three
  #
  it "parses Resources", ->
    blueprint0 = new Blueprint
      name: "API"

    blueprint1 = sectionBlueprint
      resources: [new Resource url: "/one"]

    blueprint3 = sectionBlueprint
      resources: [
        new Resource url: "/one"
        new Resource url: "/two"
        new Resource url: "/three"
      ]

    assert.parse """
      --- API ---

    """, blueprint0

    assert.parse """
      --- API ---

      GET /one
      < 200
    """, blueprint1

    assert.parse """
      --- API ---

      GET /one
      < 200

      GET /two
      < 200

      GET /three
      < 200
    """, blueprint3

    assert.parse """
      --- API ---

      GET /one
      < 200



      GET /two
      < 200



      GET /three
      < 200
    """, blueprint3

  # Canonical Resource is:
  #
  #   GET /
  #   < 200
  #
  it "parses Resource", ->
    request = new Request
      headers: { "Content-Type": "application/json" }
      body:    "{ \"status\": \"ok\" }"

    responses = [
      new Response
        headers: { "Content-Type": "application/json" }
        body:    "{ \"id\": 1 }"
      new Response
        headers: { "Content-Type": "application/json" }
        body:    "{ \"id\": 2 }"
      new Response
        headers: { "Content-Type": "application/json" }
        body:    "{ \"id\": 3 }"
    ]

    assert.parse """
      --- API ---

      GET /
      > Content-Type: application/json
      { "status": "ok" }
      < 200
      < Content-Type: application/json
      { "id": 1 }
      +++++
      < 200
      < Content-Type: application/json
      { "id": 2 }
      +++++
      < 200
      < Content-Type: application/json
      { "id": 3 }
    """, resourceBlueprint request: request, responses: responses

    assert.parse """
      --- API ---

      Root resource
      GET /
      > Content-Type: application/json
      { "status": "ok" }
      < 200
      < Content-Type: application/json
      { "id": 1 }
      +++++
      < 200
      < Content-Type: application/json
      { "id": 2 }
      +++++
      < 200
      < Content-Type: application/json
      { "id": 3 }
    """, resourceBlueprint
      description: "Root resource",
      request:     request,
      responses:   responses

    assert.parse """
      HOST: http://example.com

      --- API ---

      GET url
      < 200

      GET /
      < 200

      GET /url
      < 200
    """, new Blueprint
      location:    "http://example.com"
      name:        "API"
      sections:    [
        new Section resources: [
          new Resource url: "url"
          new Resource url: "/"
          new Resource url: "/url"
        ]
      ]

    assert.parse """
      HOST: http://example.com/

      --- API ---

      GET url
      < 200

      GET /
      < 200

      GET /url
      < 200
    """, new Blueprint
      location:    "http://example.com/"
      name:        "API"
      sections:    [
        new Section resources: [
          new Resource url: "url"
          new Resource url: "/"
          new Resource url: "/url"
        ]
      ]

    assert.parse """
      HOST: http://example.com/path

      --- API ---

      GET url
      < 200

      GET /
      < 200

      GET /url
      < 200
    """, new Blueprint
      location:    "http://example.com/path"
      name:        "API"
      sections:    [
        new Section resources: [
          new Resource url: "/path/url"
          new Resource url: "/path/"
          new Resource url: "/path/url"
        ]
      ]

    assert.parse """
      HOST: http://example.com/path/

      --- API ---

      GET url
      < 200

      GET /
      < 200

      GET /url
      < 200
    """, new Blueprint
      location:    "http://example.com/path/"
      name:        "API"
      sections:    [
        new Section resources: [
          new Resource url: "/path/url"
          new Resource url: "/path/"
          new Resource url: "/path/url"
        ]
      ]

  # Canonical ResourceDescription is "Root resource".
  it "parses ResourceDescription", ->
    assert.parse """
      --- API ---

      abcd
      GET /
      < 200
    """, resourceBlueprint description: "abcd"

    assert.parse """
      --- API ---

      abcd
      efgh
      ijkl
      GET /
      < 200
    """, resourceBlueprint description: "abcd\nefgh\nijkl"

  # Canonical ResourceDescriptionLine is "abcd".
  it "parses ResourceDescriptionLine", ->
    assert.parse """
      --- API ---

      abcd
      GET /
      < 200
    """, resourceBlueprint description: "abcd"

    assert.notParse """
      --- API ---

      GET
      GET /
      < 200
    """

  # Canonical HTTPMethod is "GET".
  it "parses HTTPMethod", ->
    assert.parse """
      --- API ---

      GET /
      < 200
    """, resourceBlueprint method: "GET"

    assert.parse """
      --- API ---

      POST /
      < 200
    """, resourceBlueprint method: "POST"

    assert.parse """
      --- API ---

      PUT /
      < 200
    """, resourceBlueprint method: "PUT"

    assert.parse """
      --- API ---

      DELETE /
      < 200
    """, resourceBlueprint method: "DELETE"

    assert.parse """
      --- API ---

      OPTIONS /
      < 200
    """, resourceBlueprint method: "OPTIONS"

    assert.parse """
      --- API ---

      PATCH /
      < 200
    """, resourceBlueprint method: "PATCH"

    assert.parse """
      --- API ---

      PROPPATCH /
      < 200
    """, resourceBlueprint method: "PROPPATCH"
    assert.parse """
      --- API ---

      LOCK /
      < 200
    """, resourceBlueprint method: "LOCK"

    assert.parse """
      --- API ---

      UNLOCK /
      < 200
    """, resourceBlueprint method: "UNLOCK"

    assert.parse """
      --- API ---

      COPY /
      < 200
    """, resourceBlueprint method: "COPY"

    assert.parse """
      --- API ---

      MOVE /
      < 200
    """, resourceBlueprint method: "MOVE"

    assert.parse """
      --- API ---

      MKCOL /
      < 200
    """, resourceBlueprint method: "MKCOL"

    assert.parse """
      --- API ---

      HEAD /
      < 200
    """, resourceBlueprint method: "HEAD"

    assert.notParse """
      --- API ---

      HEAD /
      < 200
      Hello World
    """

  # Canonical Request is:
  #
  #   > Content-Type: application/json
  #   { "status": "ok" }
  #
  it "parses Request", ->
    assert.parse """
      --- API ---

      GET /
      > Content-Type: application/json
      < 200
    """, resourceBlueprint
      request: new Request
        headers: { "Content-Type": "application/json" }
        body:    null

    assert.parse """
      --- API ---

      GET /
      > Content-Type: application/json
      { "status": "ok" }
      < 200
    """, resourceBlueprint
      request: new Request
        headers: { "Content-Type": "application/json" }
        body:    "{ \"status\": \"ok\" }"

  # Canonical RequestHeaders is " Content-Type: application/json".
  it "parses RequestHeaders", ->
    assert.parse """
      --- API ---

      GET /
      < 200
    """, requestBlueprint()

    assert.parse """
      --- API ---

      GET /
      > Content-Type: application/json
      < 200
    """, requestBlueprint headers: { "Content-Type": "application/json" }

    assert.parse """
      --- API ---

      GET /
      > Content-Type: application/json
      > Content-Length: 153
      > Cache-Control: no-cache
      < 200
    """, requestBlueprint
      headers:
        "Content-Type":   "application/json"
        "Content-Length": "153"
        "Cache-Control":  "no-cache"

  # Canonical RequestHeader is "< Content-Type: application/json".
  it "parses RequestHeader", ->
    assert.parse """
      --- API ---

      GET /
      > Content-Type: application/json
      < 200
    """, requestBlueprint headers: { "Content-Type": "application/json" }

  # Canonical Responses is:
  #
  #   < 200
  #   < Content-Type: application/json
  #   { "id": 1 }
  #   +++++
  #   < 200
  #   < Content-Type: application/json
  #   { "id": 1 }
  #   +++++
  #   < 200
  #   < Content-Type: application/json
  #   { "id": 1 }
  #
  it "parses Responses", ->
    responses = [
      new Response
        headers: { "Content-Type": "application/json" }
        body:    "{ \"id\": 1 }"
      new Response
        headers: { "Content-Type": "application/json" }
        body:    "{ \"id\": 2 }"
      new Response
        headers: { "Content-Type": "application/json" }
        body:    "{ \"id\": 3 }"
    ]

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
      { "id": 1 }
    """, resourceBlueprint responses: responses[0..0]

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
      { "id": 1 }
      +++++
      < 200
      < Content-Type: application/json
      { "id": 2 }
    """, resourceBlueprint responses: responses[0..1]

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
      { "id": 1 }
      +++++
      < 200
      < Content-Type: application/json
      { "id": 2 }
      +++++
      < 200
      < Content-Type: application/json
      { "id": 3 }
    """, resourceBlueprint responses: responses[0..2]

  # Canonical Response is:
  #
  #   < 200
  #   < Content-Type: application/json
  #   { "status": "ok" }
  #
  it "parses Response", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
    """, resourceBlueprint
      responses: [
        new Response
          status:  200
          headers: { "Content-Type": "application/json" }
          body:    null
      ]

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
      { "status": "ok" }
    """, resourceBlueprint
      responses: [
        new Response
          status:  200
          headers: { "Content-Type": "application/json" }
          body:    "{ \"status\": \"ok\" }"
      ]

  # Canonical ResponseStatus is "> 200".
  it "parses ResponseStatus", ->
    assert.parse """
      --- API ---

      GET /
      < 200
    """, resourceBlueprint()

    assert.parse """
      --- API ---

      GET /
      < 200 
    """,   resourceBlueprint()

    assert.parse """
      --- API ---

      GET /
      < 200   
    """, resourceBlueprint()

  # Canonical ResponseHeaders is " Content-Type: application/json".
  it "parses ResponseHeaders", ->
    assert.parse """
      --- API ---

      GET /
      < 200
    """, responseBlueprint()

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
    """, responseBlueprint headers: { "Content-Type": "application/json" }

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
      < Content-Length: 153
      < Cache-Control: no-cache
    """, responseBlueprint
      headers:
        "Content-Type": "application/json"
        "Content-Length": "153"
        "Cache-Control": "no-cache"

  # Canonical ResponseHeader is "< Content-Type: application/json".
  it "parses ResponseHeader", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
    """, responseBlueprint headers: { "Content-Type": "application/json" }

  # Canonical ResponseSeparator is "+++++".
  it "parses ResponseSeparator", ->
    blueprint = resourceBlueprint responses: [new Response, new Response]

    assert.parse """
      --- API ---

      GET /
      < 200
      +++++
      < 200
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      < 200
      +++++ 
      < 200
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      < 200
      +++++   
      < 200
    """, blueprint

  # Canonical HttpStatus is "200".
  it "parses HttpStatus", ->
    assert.parse """
      --- API ---

      GET /
      < 0
    """, responseBlueprint status: 0

    assert.parse """
      --- API ---

      GET /
      < 9
    """, responseBlueprint status: 9

    assert.parse """
      --- API ---
      GET /
      < 123
    """, responseBlueprint status: 123

  # Canonical HttpHeader is "Content-Type: application/json".
  it "parses HttpHeader", ->
    blueprint = responseBlueprint
      headers: { "Content-Type": "application/json" }

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type:application/json
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type:   application/json
    """, blueprint

  # Canonical HttpHeaderName is "Content-Type".
  it "parses HttpHeaderName", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      < !: application/json
    """, responseBlueprint headers: { "!": "application/json" }

    assert.parse """
      --- API ---

      GET /
      < 200
      < 9: application/json
    """, responseBlueprint headers: { "9": "application/json" }

    assert.parse """
      --- API ---

      GET /
      < 200
      < ;: application/json
    """, responseBlueprint headers: { ";": "application/json" }

    assert.parse """
      --- API ---

      GET /
      < 200
      < ~: application/json
    """, responseBlueprint headers: { "~": "application/json" }

    assert.parse """
      --- API ---

      GET /
      < 200
      < abc: application/json
    """, responseBlueprint headers: { "abc": "application/json" }

  # Canonical HttpHeaderValue is "application/json".
  it "parses HttpHeaderValue", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: abcd
    """, responseBlueprint headers: { "Content-Type": "abcd" }

  # Canonical JsonSchemaValidations is "-- JSON Schema Validations --"
  it "parses JSONSchemaValidations", ->
    blueprint0 = new Blueprint
      name: "API"

    blueprint1 = new Blueprint
      name:        "API"
      validations: [
        new JsonSchemaValidation url: "/one", body: "{ \"type\": \"object\" }"
      ]

    blueprint3 = new Blueprint
      name:        "API"
      validations: [
        new JsonSchemaValidation url: "/one",   body: "{ \"type\": \"object\" }"
        new JsonSchemaValidation url: "/two",   body: "{ \"type\": \"object\" }"
        new JsonSchemaValidation url: "/three", body: "{ \"type\": \"object\" }"
      ]

    assert.parse """
      --- API ---

      -- JSON Schema Validations --

    """, blueprint0

    assert.parse """
      --- API ---

      -- JSON Schema Validations --
      GET /one
      { "type": "object" }
    """, blueprint1

    assert.parse """
      --- API ---

      -- JSON Schema Validations --
      GET /one
      { "type": "object" }

      GET /two
      { "type": "object" }

      GET /three
      { "type": "object" }
    """, blueprint3

    assert.parse """
      --- API ---

      -- JSON Schema Validations --
      GET /one
      { "type": "object" }



      GET /two
      { "type": "object" }



      GET /three
      { "type": "object" }
    """, blueprint3

  # Canonical JsonSchemaValidation is:
  #
  #   GET /
  #   { "type": "object" }
  #
  it "parses JSONSchemaValidation", ->
    assert.parse """
      --- API ---

      -- JSON Schema Validations --
      GET /
      { "type": "object" }
    """, new Blueprint
      name:        "API"
      validations: [new JsonSchemaValidation body: "{ \"type\": \"object\" }"]

  # Canonical Signature is "GET /".
  it "parses Signature", ->
    assert.parse """
      --- API ---

      GET abcd
      < 200
    """, resourceBlueprint url: "abcd"

    assert.parse """
      --- API ---

      GET   abcd
      < 200
    """, resourceBlueprint url: "abcd"

  # Canonical Body is "{ \"status\": \"ok\" }".
  it "parses Body", ->
    blueprint = responseBlueprint body: "{ \"status\": \"ok\" }"

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<
      { \"status\": \"ok\" }
      >>>
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<EOT
      { \"status\": \"ok\" }
      EOT
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      < 200
      { \"status\": \"ok\" }
    """, blueprint

  # Canonical DelimitedBodyFixed is:
  #
  #   <<<
  #   { \"status\": \"ok\" }
  #   >>>
  #
  it "parses DelimitedBodyFixed", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      <<<
      >>>
    """, responseBlueprint body: null

    assert.parse """
      --- API ---

      GET /
      < 200
      <<< 
      >>>
    """, responseBlueprint body: null

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<   
      >>>
    """, responseBlueprint body: null

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<
      abcd
      >>>
    """, responseBlueprint body: "abcd"

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<
      abcd
      efgh
      ijkl
      >>>
    """, responseBlueprint body: "abcd\nefgh\nijkl"

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<
      >>> 
    """, responseBlueprint body: null

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<
      >>>   
    """, responseBlueprint body: null

  # Canonical DelimitedBodyFixedLine is "abcd".
  it "parses DelimitedBodyFixedLine", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      <<<
      abcd
      >>>
    """, responseBlueprint body: "abcd"

  # Canonical DelimitedBodyVariable is:
  #
  #   <<<EOT
  #   { \"status\": \"ok\" }
  #   EOT
  #
  it "parses DelimitedBodyVariable", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      <<<EOT
      EOT
    """, responseBlueprint body: null

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<EOT
      abcd
      EOT
    """, responseBlueprint body: "abcd"

    assert.parse """
      --- API ---

      GET /
      < 200
      <<<EOT
      abcd
      efgh
      ijkl
      EOT
    """, responseBlueprint body: "abcd\nefgh\nijkl"

  # Canonical DelimitedBodyVariableLine is "abcd".
  it "parses DelimitedBodyVariableLine", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      <<<EOT
      abcd
      EOT
    """, responseBlueprint body: "abcd"

  # Canonical DelimitedBodyVariableTerminator is "EOT".
  it "parses DelimitedBodyVariableTerminator", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      <<<abcd
      abcd
    """, responseBlueprint()

  # Canonical SimpleBody is "{ \"status\": \"ok\" }".
  it "parses SimpleBody", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      abcd
      efgh
      ijkl
    """, responseBlueprint body: "abcd\nefgh\nijkl"

    assert.parse """
      --- API ---

      GET /
      < 200
      abcd
    """, responseBlueprint body: "abcd"

    assert.notParse """
      --- API ---

      GET /
      < 200
      <<<
    """

  # Canonical SimpleBodyLine is "abcd".
  it "parses SimpleBodyLine", ->
    assert.parse """
      --- API ---

      GET /
      < 200
      abcd
    """, responseBlueprint body: "abcd"

    assert.notParse "GET /\n> "
    assert.notParse "GET /\n< "
    assert.notParse "GET /\n+++++"
    assert.notParse "GET /\n"

  # Canonical In is "> ".
  it "parses In", ->
    blueprint = requestBlueprint
      headers: { "Content-Type": "application/json" }

    assert.parse """
      --- API ---

      GET /
      > Content-Type: application/json
      < 200
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      >   Content-Type: application/json
      < 200
    """, blueprint

  # Canonical Out is "< ".
  it "parses Out", ->
    blueprint = responseBlueprint
      headers: { "Content-Type": "application/json" }

    assert.parse """
      --- API ---

      GET /
      < 200
      < Content-Type: application/json
    """, blueprint

    assert.parse """
      --- API ---

      GET /
      < 200
      <   Content-Type: application/json
    """, blueprint

  # Canonical Text0 is "abcd".
  it "parses Text0", ->
    assert.parse """
      --- API ---

      ---

      ---
    """, new Blueprint
      name:       "API"
      description: null

    assert.parse """
      --- API ---

      ---
      a
      ---
    """, new Blueprint
      name:        "API"
      description: "a"

    assert.parse """
      --- API ---

      ---
      abc
      ---
    """, new Blueprint
      name:        "API"
      description: "abc"

  # Canonical Text1 is "abcd".
  it "parses Text1", ->
    assert.parse "--- a",   new Blueprint name: "a"
    assert.parse "--- abc", new Blueprint name: "abc"

  # Canonical EmptyLine is "\n".
  it "parses EmptyLine", ->
    assert.parse "\n--- abcd",    new Blueprint name: "abcd"
    assert.parse " \n--- abcd",   new Blueprint name: "abcd"
    assert.parse "   \n--- abcd", new Blueprint name: "abcd"

  # Canonical EOLF is ""  end of input.
  it "parses EOLF", ->
    assert.parse "--- abcd\n", new Blueprint name: "abcd"
    assert.parse "--- abcd",   new Blueprint name: "abcd"

  # Canonical EOL is "\n".
  it "parses EOL", ->
    assert.parse "--- abcd\n", new Blueprint name: "abcd"

  # Canonical EOF is ""  end of input.
  it "parses EOF", ->
    assert.parse "--- abcd", new Blueprint name: "abcd"

  # Canonical S is " ".
  it "parses S", ->
    assert.parse "---\tabcd",     new Blueprint name: "abcd"
    assert.parse "---\vabcd",     new Blueprint name: "abcd"
    assert.parse "---\fabcd",     new Blueprint name: "abcd"
    assert.parse "--- abcd",      new Blueprint name: "abcd"
    assert.parse "---\u00A0abcd", new Blueprint name: "abcd"
    assert.parse "---\u1680abcd", new Blueprint name: "abcd"
    assert.parse "---\u180Eabcd", new Blueprint name: "abcd"
    assert.parse "---\u2000abcd", new Blueprint name: "abcd"
    assert.parse "---\u2001abcd", new Blueprint name: "abcd"
    assert.parse "---\u2002abcd", new Blueprint name: "abcd"
    assert.parse "---\u2003abcd", new Blueprint name: "abcd"
    assert.parse "---\u2004abcd", new Blueprint name: "abcd"
    assert.parse "---\u2005abcd", new Blueprint name: "abcd"
    assert.parse "---\u2006abcd", new Blueprint name: "abcd"
    assert.parse "---\u2007abcd", new Blueprint name: "abcd"
    assert.parse "---\u2008abcd", new Blueprint name: "abcd"
    assert.parse "---\u2009abcd", new Blueprint name: "abcd"
    assert.parse "---\u200Aabcd", new Blueprint name: "abcd"
    assert.parse "---\u202Fabcd", new Blueprint name: "abcd"
    assert.parse "---\u205Fabcd", new Blueprint name: "abcd"
    assert.parse "---\u3000abcd", new Blueprint name: "abcd"
    assert.parse "---\uFEFFabcd", new Blueprint name: "abcd"

  # ===== Complex Examples =====

  it "parses demo blueprint", ->
    assert.parse """
      HOST: http://www.google.com/

      --- Sample API v2 ---
      ---
      Welcome to the our sample API documentation. All comments can be written in (support [Markdown](http://daringfireball.net/projects/markdown/syntax) syntax)
      ---

      --
      Shopping Cart Resources
      The following is a section of resources related to the shopping cart
      --
      List products added into your shopping-cart. (comment block again in Markdown)
      GET /shopping-cart
      < 200
      < Content-Type: application/json
      { "items": [
        { "url": "/shopping-cart/1", "product":"2ZY48XPZ", "quantity": 1, "name": "New socks", "price": 1.25 }
      ] }

      Save new products in your shopping cart
      POST /shopping-cart
      > Content-Type: application/json
      { "product":"1AB23ORM", "quantity": 2 }
      < 201
      < Content-Type: application/json
      { "status": "created", "url": "/shopping-cart/2" }


      -- Payment Resources --
      This resource allows you to submit payment information to process your *shopping cart* items
      POST /payment
      { "cc": "12345678900", "cvc": "123", "expiry": "0112" }
      < 200
      { "receipt": "/payment/receipt/1" }
    """, new Blueprint
      location:    "http://www.google.com/"
      name:        "Sample API v2"
      description: "Welcome to the our sample API documentation. All comments can be written in (support [Markdown](http://daringfireball.net/projects/markdown/syntax) syntax)"
      sections:    [
        new Section
          name:        "Shopping Cart Resources"
          description: "The following is a section of resources related to the shopping cart"
          resources:   [
            new Resource
              description: "List products added into your shopping-cart. (comment block again in Markdown)"
              method:      "GET"
              url:         "/shopping-cart"
              request:     new Request
              responses:   [
                new Response
                  status: 200
                  headers: { "Content-Type": "application/json" }
                  body: """
                    { "items": [
                      { "url": "/shopping-cart/1", "product":"2ZY48XPZ", "quantity": 1, "name": "New socks", "price": 1.25 }
                    ] }
                  """
              ]
            new Resource
              description: "Save new products in your shopping cart"
              method:      "POST"
              url:         "/shopping-cart"
              request: new Request
                headers: { "Content-Type": "application/json" }
                body:    "{ \"product\":\"1AB23ORM\", \"quantity\": 2 }"
              responses: [
                new Response
                  status:  201
                  headers: { "Content-Type": "application/json" }
                  body:    "{ \"status\": \"created\", \"url\": \"/shopping-cart/2\" }"
              ]
          ]
        new Section
          name:      "Payment Resources"
          resources: [
             new Resource {
               description: "This resource allows you to submit payment information to process your *shopping cart* items"
               method:      "POST"
               url:         "/payment"
               request:     new Request
                 body: "{ \"cc\": \"12345678900\", \"cvc\": \"123\", \"expiry\": \"0112\" }"
               responses:   [
                 new Response
                   status: 200
                   body:   "{ \"receipt\": \"/payment/receipt/1\" }"
               ]
             }
          ]
      ]
      validations: []
