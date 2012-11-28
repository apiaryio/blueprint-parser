fillProps = (object, props, defaults) ->
  for key of defaults
    object[key] = props[key] or defaults[key]

combineParts = (separator, builder) ->
  parts = []
  builder(parts)
  parts.join(separator)

escapeBody = (body) ->
  if /^>\s+|^<\s+|^\s*$/m.test(body)
    if /^>>>\s*$/m.test(body)
      if /^EOT$/m.test(body)
        i = 1
        while /^EOT#{i}$/m.test(body)
          i++
        "<<<EOT#{i}\n#{body}\nEOT#{i}"
      else
        "<<<EOT\n#{body}\nEOT"
    else
      "<<<\n#{body}\n>>>"
  else
    body

# Represents an Apiary blueprint.
class Blueprint
  @fromJSON: (json) ->
    new this
      location:    json.location
      name:        json.name
      description: json.description
      sections:    Section.fromJSON(s) for s in json.sections
      validations: JsonSchemaValidation.fromJSON(v) for v in json.validations

  constructor: (props = {}) ->
    fillProps this, props,
      location:    null
      name:        null
      description: null
      sections:    []
      validations: []

  resources: (opts) ->
    resources = []
    for s in @sections then for r in s.resources
      if opts?.method and opts.method isnt r.method then continue
      if opts?.url and opts.url isnt r.url then continue
      resources.push r
    return resources

  toJSON: ->
    location:    @location or ""
    name:        @name or ""
    description: @description or ""
    sections:    s.toJSON() for s in @sections
    validations: v.toJSON() for v in @validations

  toBlueprint: ->
    combineParts "\n\n", (parts) =>
      parts.push "HOST: #{@location}"        if @location
      parts.push "--- #{@name} ---"          if @name
      parts.push "---\n#{@description}\n---" if @description

      parts.push s.toBlueprint() for s in @sections

      parts.push "-- JSON Schema Validations --" if @validations.length > 0
      parts.push v.toBlueprint() for v in @validations

# Represents a section of an Apiary blueprint.
class Section
  @fromJSON: (json) ->
    new this
      name:        json.name
      description: json.description
      resources:   Resource.fromJSON(r) for r in json.resources

  constructor: (props = {}) ->
    fillProps this, props,
      name:        null
      description: null
      resources:   []

  toJSON: ->
    name:        @name or ""
    description: @description or ""
    resources:   r.toJSON() for r in @resources

  toBlueprint: ->
    combineParts "\n\n", (parts) =>
      if @name
        if @description
          parts.push "--\n#{@name}\n#{@description}\n--"
        else
          parts.push "-- #{@name} --"

      parts.push r.toBlueprint() for r in @resources

# Represents a resource of an Apiary blueprint.
class Resource
  @fromJSON: (json) ->
    new this
      description: json.description
      method:      json.method
      url:         json.url
      request:     Request.fromJSON(json.request)
      responses:   Response.fromJSON(r) for r in json.responses

  constructor: (props = {}) ->
    fillProps this, props,
      description: null
      method:      "GET"
      url:         "/"
      request:     new Request
      responses:   [new Response]

  getUrlFragment: -> "#{@method.toLowerCase()}-#{encodeURIComponent @url}"

  toJSON: ->
    description: @description or ""
    method:      @method
    url:         @url,
    request:     @request.toJSON()
    responses:   r.toJSON() for r in @responses

  toBlueprint: ->
    combineParts "\n", (parts) =>
      parts.push @description if @description
      parts.push "#{@method} #{@url}"

      requestBlueprint = @request.toBlueprint()
      parts.push requestBlueprint if requestBlueprint isnt ""

      responsesBlueprint = combineParts "\n+++++\n", (parts) =>
        parts.push r.toBlueprint() for r in @responses
      parts.push responsesBlueprint

# Represents a request of a resource.
class Request
  @fromJSON: (json) ->
    new this
      headers: json.headers
      body:    json.body

  constructor: (props = {}) ->
    fillProps this, props,
      headers: {},
      body:    null

  toJSON: ->
    headers: @headers
    body:    @body or ""

  toBlueprint: ->
    combineParts "\n", (parts) =>
      parts.push "> #{name}: #{value}" for name, value of @headers
      parts.push escapeBody(@body) if @body

# Represents a response of a resource.
class Response
  @fromJSON: (json) ->
    new this
      status:  json.status
      headers: json.headers
      body:    json.body

  constructor: (props = {}) ->
    fillProps this, props,
      status:  200,
      headers: {},
      body:    null

  toJSON: ->
    status:  @status
    headers: @headers
    body:    @body ? ""

  toBlueprint: ->
    combineParts "\n", (parts) =>
      parts.push "< #{@status}"
      parts.push "< #{name}: #{value}" for name, value of @headers
      parts.push escapeBody(@body) if @body

# Represents a JSON schema validation.
class JsonSchemaValidation
  @fromJSON: (json) ->
    new this
      method: json.method
      url:    json.url
      body:   json.body

  constructor: (props = {}) ->
    fillProps this, props,
      method: "GET",
      url:    "/",
      body:   null

  toJSON: ->
    method: @method
    url:    @url
    body:   @body or ""

  toBlueprint: ->
    combineParts "\n", (parts) =>
      parts.push "#{@method} #{@url}"
      parts.push escapeBody(@body) if @body

module.exports =
  Blueprint:            Blueprint
  Section:              Section
  Resource:             Resource
  Request:              Request
  Response:             Response
  JsonSchemaValidation: JsonSchemaValidation
