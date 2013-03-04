if window?
  url = parse: (url) ->
    l = document.createElement 'a'
    l.href = url
    return l

  # We expect amanda and has to be required from browser
  # FIXME: Of course, it would be cleaner to use require.js-style
  # but document.write is not exactly worky in zombie

verbose = false

httpMethods = 'GET|POST|PUT|DELETE|OPTIONS|PATCH|PROPPATCH|LOCK|UNLOCK|COPY|MOVE|MKCOL|HEAD' # assembled from RFC 2616, 5323, 5789
httpRequestRe = new RegExp "^(#{httpMethods})\\s+(.*?)\\s*$"
aceRules = (json,xml) -> ->
  @$rules =
  "start": [
    token: ['hostname.keyword','text','hostname.string']
    regex: '^(HOST:)(\\s*)(.*)$'
    next: 'commentStart'
  ,
    token: 'empty.separator'
    regex: '^(?!HOST:)'
    next: 'commentStart'
  ]
  "commentStart": [
    token: ['empty.separator']
    regex: "^(?=(?:#{httpMethods}))"
    next: 'resourceDeclaration'
  ,
    token: 'intro.long.start'
    regex: '^---\s*$'
    next: 'introStart'
  ,
    token: ['api.name']
    regex: '^--- .*$'
  ,
    token: ['validations.jsonschema.start']
    regex: '^(-- JSON Schema Validations --|-- JSON Validation Schemas --)$'
    next: 'validationJsonSchemaStart'
  ,
    token: 'section.long.start'
    regex: '^--\s*$'
    next: 'sectionStart'
  ,
    token: ['section.name']
    regex: '^-- .*$'
  ,
    token: ['comment']
    regex: '^.+$'
    next: 'inSideComment'
  ,
    token: 'emptyline.separator'
    regex: '^$'
  ]
  "inSideComment": [
    token: ['empty.separator']
    regex: "^(?=(?:#{httpMethods}))"
    next: 'resourceDeclaration'
  ,
    token: ['comment']
    regex: '^.*$'
  ]
  "introStart": [
    token: 'separator'
    regex: '^---\s*$'
    next: 'commentStart'
  ,
    token: 'intro.comment'
    regex: '^.*$'
  ]
  "sectionStart": [
    token: 'separator'
    regex: '^--\s*$'
    next: 'commentStart'
  ,
    token: ['section.name','section.name.long']
    regex: '^.+$'
    next: 'sectionDesc'
  ]
  "sectionDesc": [
    token: 'separator'
    regex: '^--\s*$'
    next: 'commentStart'
  ,
    token: 'section.comment'
    regex: '^.*$'
  ]
  "resourceDeclaration": [
    token: ['http.method.keyword','text','url.string']
    regex: "^(#{httpMethods})(\\s*)(\\S+)\\s*$"
    next: 'resourceHeadersIn'
  ]
  "resourceHeadersIn": [
    token: 'empty.separator'
    regex: '^(?=\\<\\s+)'
    next: 'resourceResponseStatus'
  ,
    token: ['incoming.keyword','text','incoming.variable','incoming.string']
    regex: '^(\\>)(\\s+)([^:]*:)(.*)$'
  ,
    token: 'incoming.json.data'
    regex: '^(?=\\{)'
    next: 'json-in-start'
  ,
    token: 'incoming.json.data'
    regex: '^(?=\\[)'
    next: 'json-in-start'
  ,
    token: 'incoming.xml.data'
    regex: '^(?=\\<\\S)'
    next: 'xml-in-start'
  ,
    token: 'incoming.data'
    regex: '^.+$'
  ]
  "resourceResponseStatus": [
    token: ['outgoing.keyword', 'text', 'outgoing.constant.numeric.status']
    regex: '^(\\<)(\\s+)(\\d+)\\s*$'
    next: 'resourceHeadersOut'
  ]
  "resourceHeadersOut": [
    token: 'emptyline.separator'
    regex: '^$'
    next: 'separator'
  ,
    token: ['outgoing.keyword', 'text', 'outgoing.variable', 'outgoing.string']
    regex: '^(\\<)(\\s+)([^:]*:)(.*)$'
  ,
    token: ['out.delimiter']
    regex: '^([\\+]{5})$'
    next: 'resourceResponseStatus'
  ,
    token: 'outgoing.json.data'
    regex: '^(?=\\{)'
    next: 'json-out-start'
  ,
    token: 'outgoing.json.data'
    regex: '^(?=\\[)'
    next: 'json-out-start'
  ,
    token: 'outgoing.xml.data'
    regex: '^(?=\\<\\S)'
    next: 'xml-out-start'
  ,
    token: 'outgoing.data'
    regex: '.+'
  ]
  "separator": [
    token: 'emptyline.separator'
    regex: '^$'
    next: 'commentStart'
  ,
    token: 'nonempty'
    regex: '^(?=.)'
    next: 'resourceHeadersOut'
  ]
  "validationJsonSchemaStart": [
    token: ['http.method.keyword', 'text', 'url.string.jsonschema.selector']
    regex: "^(#{httpMethods})(\\s*)(\\S+)$"
    next: 'validationJsonSchemaData'
  ,
    token: 'emptyline.separator'
    regex: '^$'
  ]
  "validationJsonSchemaData": [
    token: ['incoming.json.data', 'validation', 'jsonschema.data']
    regex: '^(?=\\{)'
    next: 'json-schema-in-start'
  ,
    token: 'emptyline.separator'
    regex: '^$'
  ]
  @embedRules json, "json-in-", [
    token: 'empty.separator'
    regex: '^(?=\\<\\s+)'
    next: 'resourceResponseStatus'
  ]
  @embedRules json, "json-schema-in-", [
    token: 'empty.separator'
    regex: '^$'
    next: 'validationJsonSchemaStart'
  ]

  @embedRules json, "json-out-", [
    token: ['out.delimiter']
    regex: '^([\\+]{5})$'
    next: 'resourceResponseStatus'
  ,
    token: 'emptyline.separator'
    regex: '^$'
    next: 'commentStart'
  ]

  @embedRules xml, "xml-in-", [
    token: 'empty.separator'
    regex: '^(?=\\<\\s+)'
    next: 'resourceResponseStatus'
  ]

  @embedRules xml, "xml-out-", [
    token: ['out.delimiter']
    regex: '^([\\+]{5})$'
    next: 'resourceResponseStatus'
  ,
    token: 'emptyline.separator'
    regex: '^$'
    next: 'commentStart'
  ]

  return undefined

# produce a lexer out of Ace-style rules
# mock embedded external grammars using embedRules
fakeContext =
  embedRules: (rules, prefix, exit)->
    console.error "Embedding #{prefix}" if verbose
    exit.push
      token: prefix+'catch-all'
      regex: '^.*$'
    @$rules[prefix+"start"] = exit

aceRules().call fakeContext, null, null
lexer = fakeContext.$rules

if window?
  window.apiaryAceRules = aceRules
