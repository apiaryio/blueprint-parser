if require?
  parser     = require "../lib/apiary-blueprint-parser"
  { assert } = require "chai"
else
  parser = window.ApiaryBlueprintParser
  assert = window.chai.assert

Blueprint            = parser.ast.Blueprint
Section              = parser.ast.Section
Resource             = parser.ast.Resource
Request              = parser.ast.Request
Response             = parser.ast.Response
JsonSchemaValidation = parser.ast.JsonSchemaValidation

# AST nodes

filledRequest = new Request
  headers: { "Content-Type": "application/json" }
  body:    "{ \"status\": \"ok\" }"

filledResponses = [
  new Response
    status:  200
    headers: { "Content-Type": "application/json" }
    body:    "{ \"id\": 1 }"
  new Response
    status:  200
    headers: { "Content-Type": "application/json" }
    body:    "{ \"id\": 2 }"
  new Response
    status:  200
    headers: { "Content-Type": "application/json" }
    body:    "{ \"id\": 3 }"
]

filledResources = [
  new Resource
    description: "Post resource 1"
    method:      "POST"
    url:         "/post-1"
    request:     filledRequest
    responses:   filledResponses
  new Resource
    description: "Post resource 2"
    method:      "POST"
    url:         "/post-2"
    request:     filledRequest
    responses:   filledResponses
  new Resource
    description: "Post resource 3"
    method:      "POST"
    url:         "/post-3"
    request:     filledRequest
    responses:   filledResponses
]

filledSections = [
  new Section
    name:        "Section 1"
    description: "Test section 1"
    resources:    filledResources
  new Section
    name:        "Section 2"
    description: "Test section 2"
    resources:    filledResources
  new Section
    name:        "Section 3"
    description: "Test section 3"
    resources:    filledResources
]

filledValidations = [
  new JsonSchemaValidation
    method: "POST"
    url:    "/post-1"
    body:   "{ \"type\": \"object\" }"
  new JsonSchemaValidation
    method: "POST"
    url:    "/post-2"
    body:   "{ \"type\": \"object\" }"
  new JsonSchemaValidation
    method: "POST"
    url:    "/post-3"
    body:   "{ \"type\": \"object\" }"
]

filledBlueprint = new Blueprint
  location:    "http://example.com/"
  name:        "API"
  description: "Test API"
  sections:    filledSections
  validations: filledValidations

# JSONs

filledRequestJson =
  headers: { "Content-Type": "application/json" }
  body:    "{ \"status\": \"ok\" }"

filledResponseJsons = [
  {
    status:  200
    headers: { "Content-Type": "application/json" }
    body:    "{ \"id\": 1 }"
  }
  {
    status:  200
    headers: { "Content-Type": "application/json" }
    body:    "{ \"id\": 2 }"
  }
  {
    status:  200
    headers: { "Content-Type": "application/json" }
    body:    "{ \"id\": 3 }"
  }
]

filledResourceJsons = [
  {
    description: "Post resource 1"
    method:      "POST"
    url:         "/post-1"
    request:     filledRequestJson
    responses:   filledResponseJsons
  }
  {
    description: "Post resource 2"
    method:      "POST"
    url:         "/post-2"
    request:     filledRequestJson
    responses:   filledResponseJsons
  }
  {
    description: "Post resource 3"
    method:      "POST"
    url:         "/post-3"
    request:     filledRequestJson
    responses:   filledResponseJsons
  }
]

filledSectionJsons = [
  {
    name:        "Section 1"
    description: "Test section 1"
    resources:    filledResourceJsons
  }
  {
    name:        "Section 2"
    description: "Test section 2"
    resources:    filledResourceJsons
  }
  {
    name:        "Section 3"
    description: "Test section 3"
    resources:    filledResourceJsons
  }
]

filledValidationJsons = [
  {
    method: "POST"
    url:    "/post-1"
    body:   "{ \"type\": \"object\" }"
  }
  {
    method: "POST"
    url:    "/post-2"
    body:   "{ \"type\": \"object\" }"
  }
  {
    method: "POST"
    url:    "/post-3"
    body:   "{ \"type\": \"object\" }"
  }
]

filledBlueprintJson =
  location:    "http://example.com/"
  name:        "API"
  description: "Test API"
  sections:    filledSectionJsons
  validations: filledValidationJsons

# Blueprints

filledRequestBlueprint = """
  > Content-Type: application/json
  { "status": "ok" }
"""

filledResponseBlueprints = [
  """
    < 200
    < Content-Type: application/json
    { "id": 1 }
  """
  """
    < 200
    < Content-Type: application/json
    { "id": 2 }
  """
  """
    < 200
    < Content-Type: application/json
    { "id": 3 }
  """
]

filledResourceBlueprints = [
  """
    Post resource 1
    POST /post-1
    #{filledRequestBlueprint}
    #{filledResponseBlueprints[0]}
    +++++
    #{filledResponseBlueprints[1]}
    +++++
    #{filledResponseBlueprints[2]}
  """
  """
    Post resource 2
    POST /post-2
    #{filledRequestBlueprint}
    #{filledResponseBlueprints[0]}
    +++++
    #{filledResponseBlueprints[1]}
    +++++
    #{filledResponseBlueprints[2]}
  """
  """
    Post resource 3
    POST /post-3
    #{filledRequestBlueprint}
    #{filledResponseBlueprints[0]}
    +++++
    #{filledResponseBlueprints[1]}
    +++++
    #{filledResponseBlueprints[2]}
  """
]

filledSectionBlueprints = [
  """
    --
    Section 1
    Test section 1
    --

    #{filledResourceBlueprints[0]}

    #{filledResourceBlueprints[1]}

    #{filledResourceBlueprints[2]}
  """
  """
    --
    Section 2
    Test section 2
    --

    #{filledResourceBlueprints[0]}

    #{filledResourceBlueprints[1]}

    #{filledResourceBlueprints[2]}
  """
  """
    --
    Section 3
    Test section 3
    --

    #{filledResourceBlueprints[0]}

    #{filledResourceBlueprints[1]}

    #{filledResourceBlueprints[2]}
  """
]

filledValidationBlueprints = [
  """
    POST /post-1
    { "type": "object" }
  """
  """
    POST /post-2
    { "type": "object" }
  """
  """
    POST /post-3
    { "type": "object" }
  """
]

filledBlueprintBlueprint = """
  HOST: http://example.com/

  --- API ---

  ---
  Test API
  ---

  #{filledSectionBlueprints[0]}

  #{filledSectionBlueprints[1]}

  #{filledSectionBlueprints[2]}

  -- JSON Schema Validations --

  #{filledValidationBlueprints[0]}

  #{filledValidationBlueprints[1]}

  #{filledValidationBlueprints[2]}
"""

bodyTestcases = [
  { body: "> ",           blueprint: "<<<\n> \n>>>"                }
  { body: ">   ",         blueprint: "<<<\n>   \n>>>"              }
  { body: "line\n> ",     blueprint: "<<<\nline\n> \n>>>"          }
  { body: "> \nline",     blueprint: "<<<\n> \nline\n>>>"          }
  { body: "a> ",          blueprint: "a> "                         }

  { body: "< ",           blueprint: "<<<\n< \n>>>"                }
  { body: "<   ",         blueprint: "<<<\n<   \n>>>"              }
  { body: "line\n< ",     blueprint: "<<<\nline\n< \n>>>"          }
  { body: "< \nline",     blueprint: "<<<\n< \nline\n>>>"          }
  { body: "a< ",          blueprint: "a< "                         }

  { body: " ",            blueprint: "<<<\n \n>>>"                 }
  { body: "   ",          blueprint: "<<<\n   \n>>>"               }
  { body: "line\n",       blueprint: "<<<\nline\n\n>>>"            }
  { body: "\nline",       blueprint: "<<<\n\nline\n>>>"            }
  { body: "a ",           blueprint: "a "                          }
  { body: " a",           blueprint: " a"                          }

  { body: "\n>>>",        blueprint: "<<<EOT\n\n>>>\nEOT"          }
  { body: "\n>>> ",       blueprint: "<<<EOT\n\n>>> \nEOT"         }
  { body: "\n>>>   ",     blueprint: "<<<EOT\n\n>>>   \nEOT"       }
  { body: "\n\n>>>",      blueprint: "<<<EOT\n\n\n>>>\nEOT"        }
  { body: "\n>>>\n",      blueprint: "<<<EOT\n\n>>>\n\nEOT"        }
  { body: "\na>>>",       blueprint: "<<<\n\na>>>\n>>>"            }
  { body: "\n>>>a",       blueprint: "<<<\n\n>>>a\n>>>"            }

  { body: "\n>>>\nEOT",   blueprint: "<<<EOT1\n\n>>>\nEOT\nEOT1"   }
  { body: "\n>>>\n\nEOT", blueprint: "<<<EOT1\n\n>>>\n\nEOT\nEOT1" }
  { body: "\n>>>\nEOT\n", blueprint: "<<<EOT1\n\n>>>\nEOT\n\nEOT1" }
  { body: "\n>>>\naEOT",  blueprint: "<<<EOT\n\n>>>\naEOT\nEOT"    }
  { body: "\n>>>\nEOTa",  blueprint: "<<<EOT\n\n>>>\nEOTa\nEOT"    }
]

describe "Blueprint", ->
  emptyBlueprint = new Blueprint

  describe "#constructor", ->
    describe "when passed property values", ->
      it "initializes properties correctly", ->
        blueprint = filledBlueprint

        assert.deepEqual blueprint.location,    "http://example.com/"
        assert.deepEqual blueprint.name,        "API"
        assert.deepEqual blueprint.description, "Test API"
        assert.deepEqual blueprint.sections,    filledSections
        assert.deepEqual blueprint.validations, filledValidations

    describe "when not passed property values", ->
      it "uses correct defaults", ->
        assert.deepEqual emptyBlueprint.location,    null
        assert.deepEqual emptyBlueprint.name,        null
        assert.deepEqual emptyBlueprint.description, null
        assert.deepEqual emptyBlueprint.sections,    []
        assert.deepEqual emptyBlueprint.validations, []

  describe "#toJSON", ->
    describe "on a filled-in blueprint", ->
      it "returns a correct JSON-serializable object", ->
        assert.deepEqual filledBlueprint.toJSON(), filledBlueprintJson

    describe "on a blueprint with no location", ->
      it "uses \"\" as the location value", ->
        blueprint = new Blueprint location: null

        assert.deepEqual blueprint.toJSON().location, ""

    describe "on a blueprint with no name", ->
      it "uses \"\" as the name value", ->
        blueprint = new Blueprint name: null

        assert.deepEqual blueprint.toJSON().name, ""

    describe "on a blueprint with no description", ->
      it "uses \"\" as the description value", ->
        blueprint = new Blueprint description: null

        assert.deepEqual blueprint.toJSON().description, ""

  describe "#toBlueprint", ->
    describe "on an empty blueprint", ->
      it "returns a correct blueprint", ->
        assert.deepEqual emptyBlueprint.toBlueprint(), ""

    describe "on a filled-in blueprint", ->
      it "returns a correct blueprint", ->
        assert.deepEqual filledBlueprint.toBlueprint(), filledBlueprintBlueprint

describe "Section", ->
  emptySection = new Section

  describe "#constructor", ->
    describe "when passed property values", ->
      it "initializes properties correctly", ->
        section = filledSections[0]

        assert.deepEqual section.name,        "Section 1"
        assert.deepEqual section.description, "Test section 1"
        assert.deepEqual section.resources,   filledResources

    describe "when not passed property values", ->
      it "uses correct defaults", ->
        assert.deepEqual emptySection.name,        null
        assert.deepEqual emptySection.description, null
        assert.deepEqual emptySection.resources,   []

  describe "#toJSON", ->
    describe "on a filled-in section", ->
      it "returns a correct JSON-serializable object", ->
        assert.deepEqual filledSections[0].toJSON(), filledSectionJsons[0]

    describe "on a section with no name", ->
      it "uses \"\" as the name value", ->
        section = new Section name: null

        assert.deepEqual section.toJSON().name, ""

    describe "on a section with no description", ->
      it "uses \"\" as the description value", ->
        section = new Section description: null

        assert.deepEqual section.toJSON().description, ""

  describe "#toBlueprint", ->
    describe "on an empty section", ->
      it "returns a correct blueprint", ->
        assert.deepEqual emptySection.toBlueprint(), ""

    describe "on a section with a name but with no description", ->
      it "returns a correct blueprint", ->
        section = new Section name: "Section 1"

        assert.deepEqual section.toBlueprint(), "-- Section 1 --"

    describe "on a section with no name but with a description", ->
      it "returns a correct blueprint", ->
        section = new Section description: "Test section 1"

        assert.deepEqual section.toBlueprint(), ""

    describe "on a filled-in section", ->
      it "returns a correct blueprint", ->
        assert.deepEqual filledSections[0].toBlueprint(), filledSectionBlueprints[0]

describe "Resource", ->
  emptyResource = new Resource

  describe "#constructor", ->
    describe "when passed property values", ->
      it "initializes properties correctly", ->
        resource = filledResources[0]

        assert.deepEqual resource.description, "Post resource 1"
        assert.deepEqual resource.method,      "POST"
        assert.deepEqual resource.url,         "/post-1"
        assert.deepEqual resource.request,     filledRequest
        assert.deepEqual resource.responses,   filledResponses

    describe "when not passed property values", ->
      it "uses correct defaults", ->
        assert.deepEqual emptyResource.description, null
        assert.deepEqual emptyResource.method,      "GET"
        assert.deepEqual emptyResource.url,         "/"
        assert.deepEqual emptyResource.request,     new Request
        assert.deepEqual emptyResource.responses,   [new Response]

  describe "#toJSON", ->
    describe "on a filled-in resource", ->
      it "returns a correct JSON-serializable object", ->
        assert.deepEqual filledResources[0].toJSON(), filledResourceJsons[0]

    describe "on a resource with no description", ->
      it "uses \"\" as the description value", ->
        resource = new Resource description: null

        assert.deepEqual resource.toJSON().description, ""

  describe "#toBlueprint", ->
    describe "on an empty resource", ->
      it "returns a correct blueprint", ->
        assert.deepEqual emptyResource.toBlueprint(), "GET /\n< 200"

    describe "on a filled-in resource", ->
      it "returns a correct blueprint", ->
        assert.deepEqual filledResources[0].toBlueprint(), filledResourceBlueprints[0]

describe "Request", ->
  emptyRequest = new Request

  describe "#constructor", ->
    describe "when passed property values", ->
      it "initializes properties correctly", ->
        assert.deepEqual filledRequest.headers, { "Content-Type": "application/json" }
        assert.deepEqual filledRequest.body,    "{ \"status\": \"ok\" }"

    describe "when not passed property values", ->
      it "uses correct defaults", ->
        assert.deepEqual emptyRequest.headers, {}
        assert.deepEqual emptyRequest.body,    null

  describe "#toJSON", ->
    describe "on a filled-in request", ->
      it "returns a correct JSON-serializable object", ->
        assert.deepEqual filledRequest.toJSON(), filledRequestJson

    describe "on a request with no body", ->
      it "uses \"\" as the body value", ->
        request = new Request body: null

        assert.deepEqual request.toJSON().body, ""

  describe "#toBlueprint", ->
    describe "on an empty request", ->
      it "returns a correct blueprint", ->
        assert.deepEqual emptyRequest.toBlueprint(), ""

    describe "on a filled-in request", ->
      it "returns a correct blueprint", ->
        assert.deepEqual filledRequest.toBlueprint(), filledRequestBlueprint

    describe "on requests with weird bodies", ->
      it "uses suitable body syntax", ->
        for testcase in bodyTestcases
          request = new Request body: testcase.body

          assert.deepEqual request.toBlueprint(), testcase.blueprint

describe "Response", ->
  emptyResponse = new Response

  describe "#constructor", ->
    describe "when passed property values", ->
      it "initializes properties correctly", ->
        response = filledResponses[0]

        assert.deepEqual response.status,  200
        assert.deepEqual response.headers, { "Content-Type": "application/json" }
        assert.deepEqual response.body,    "{ \"id\": 1 }"

    describe "when not passed property values", ->
      it "uses correct defaults", ->
        assert.deepEqual emptyResponse.status,  200
        assert.deepEqual emptyResponse.headers, {}
        assert.deepEqual emptyResponse.body,    null

  describe "#toJSON", ->
    describe "on a filled-in response", ->
      it "returns a correct JSON-serializable object", ->
        assert.deepEqual filledResponses[0].toJSON(), filledResponseJsons[0]

    describe "on a response with no body", ->
      it "uses \"\" as the body value", ->
        response = new Response body: null

        assert.deepEqual response.toJSON().body, ""

  describe "#toBlueprint", ->
    describe "on an empty response", ->
      it "returns a correct blueprint", ->
        assert.deepEqual emptyResponse.toBlueprint(), "< 200"

    describe "on a filled-in response", ->
      it "returns a correct blueprint", ->
        assert.deepEqual filledResponses[0].toBlueprint(), filledResponseBlueprints[0]

    describe "on responses with weird bodies", ->
      it "uses suitable body syntax", ->
        for testcase in bodyTestcases
          response = new Response body: testcase.body

          assert.deepEqual response.toBlueprint(), "< 200\n#{testcase.blueprint}"

describe "JsonSchemaValidation", ->
  emptyValidation = new JsonSchemaValidation

  describe "#constructor", ->
    describe "when passed property values", ->
      it "initializes properties correctly", ->
        validation = filledValidations[0]

        assert.deepEqual validation.method, "POST"
        assert.deepEqual validation.url,    "/post-1"
        assert.deepEqual validation.body,   "{ \"type\": \"object\" }"

    describe "when not passed property values", ->
      it "uses correct defaults", ->
        assert.deepEqual emptyValidation.method, "GET"
        assert.deepEqual emptyValidation.url,    "/"
        assert.deepEqual emptyValidation.body,   null

  describe "#toJSON", ->
    describe "on a filled-in validation", ->
      it "returns a correct JSON-serializable object", ->
        assert.deepEqual filledValidations[0].toJSON(), filledValidationJsons[0]

    describe "on a validation with no body", ->
      it "uses \"\" as the body value", ->
        validation = new JsonSchemaValidation body: null

        assert.deepEqual validation.toJSON().body, ""

  describe "#toBlueprint", ->
    describe "on an empty validation", ->
      it "returns a correct blueprint", ->
        assert.deepEqual emptyValidation.toBlueprint(), "GET /"

    describe "on a filled-in validation", ->
      it "returns a correct blueprint", ->
        assert.deepEqual filledValidations[0].toBlueprint(), filledValidationBlueprints[0]

    describe "on validations with weird bodies", ->
      it "uses suitable body syntax", ->
        for testcase in bodyTestcases
          validation = new JsonSchemaValidation body: testcase.body

          assert.deepEqual validation.toBlueprint(), """
            GET /
            #{testcase.blueprint}
          """
