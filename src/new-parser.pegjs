{
  /* Enumerates all section types. */
  var SectionType = {
    RESOURCE: 0,
    GROUP:    1,
    METHOD:   2,
    HEADERS:  3,
    PARAMS:   4,
    REQUEST:  5,
    RESPONSE: 6,
    BODY:     7,
    SCHEMA:   8,
    GENERIC:  9,
  };

  /* Enumerates all line types. */
  var LineType = {
    HEADER: 0, // e.g. "    Content-Type: application/json"
    PARAM:  1, // e.g. "+ orderId (integer) ... an order ID"
    ASSET:  2, // any asset line (part of Markdown code block)
    TEXT:   3  // any other line
  };

  /* ----- Builders ----- */

  /*
   * The following functions are extracted from actions mostly to make them more
   * DRY.
   */

  function buildResourcesFromMethods(sections) {
    // ISSUE(z): What if there are more than one "Headers" sections in resource?
    // ISSUE(z): What if there are more than one "Parameters" sections in resource?

    var headers   = extractByType(sections, SectionType.HEADERS),
        params    = extractByType(sections, SectionType.PARAMS),
        resources = extractByType(sections, SectionType.METHOD),
        i;

    for (i = 0; i < resources.length; i++) {
      mergeHeaders(headers[0], resources[i].headers);
      mergeParams(params[0], resources[i].params);
    }

    return {
      resources: resources
    };
  }

  function buildResource(header, body) {
    var url = urlPrefix !== ""
      ? "/" + urlPrefix.replace(/\/$/, "") + "/" + header.url.replace(/^\//, "")
      : header.url;

    return {
      class:       "Resource",
      description: body.description,
      method:      header.method,
      url:         url,
      headers:     body.headers,
      params:      body.params,
      requests:    body.requests,
      responses:   body.responses
    };
  }

  function buildResourceBody(description, sections) {
    // ISSUE(z): What if there are more than one "Headers" sections in resource?
    // ISSUE(z): What if there are more than one "Parameters" sections in resource?

    var headers   = extractByType(sections, SectionType.HEADERS),
        params    = extractByType(sections, SectionType.PARAMS),
        requests  = extractByType(sections, SectionType.REQUEST),
        responses = extractByType(sections, SectionType.RESPONSE);

    distributeHeaders(headers, requests, responses);

    return {
      description: description,
      headers:     headers.length > 0 ? headers[0].headers : {},
      params:      params.length  > 0 ? params[0]          : [],
      requests:    requests,
      responses:   responses
    };
  }

  function buildHeaders(header, body) {
    return {
      id:      header.id,
      status:  header.status,
      headers: body
    };
  }

  function buildRequest(header, payload) {
    if (header.type !== null) {
      mergeHeader("Content-Type", header.type, payload.headers)
    }

    return {
      class:   "Request",
      id:      header.id,
      headers: payload.headers,
      params:  payload.params,
      body:    payload.body,
      schema:  payload.schema
    };
  }

  function buildResponse(header, payload) {
    if (header.type !== null) {
      mergeHeader("Content-Type", header.type, payload.headers)
    }

    return {
      class:   "Response",
      status:  header.status,
      headers: payload.headers,
      params:  payload.params,
      body:    payload.body,
      schema:  payload.schema
    };
  }

  function buildSimplePayload(body) {
    return {
      headers: {},
      params:  [],
      body:    body,
      schema:  null
    };
  }

  function buildComplexPayload(sections) {
    // ISSUE(z): What if there are more than one "Headers" sections in payload?
    // ISSUE(z): What if there are more than one "Parameters" sections in payload?
    // ISSUE(z): What if there are more than one "Body" sections in payload?
    // ISSUE(z): What if there are more than one "Schema" sections in payload?

    var headers = extractByType(sections, SectionType.HEADERS),
        params  = extractByType(sections, SectionType.PARAMS),
        bodies  = extractByType(sections, SectionType.BODY),
        schemas = extractByType(sections, SectionType.SCHEMA);

    return {
      headers: headers.length > 0 ? headers[0] : {},
      params:  params.length  > 0 ? params[0]  : [],
      body:    bodies.length  > 0 ? bodies[0]  : "",
      schema:  schemas.length > 0 ? schemas[0] : ""
    };
  }

  /* ----- Merging ----- */

  /*
   * The following functions deal with merging of headers and parameters between
   * nodes. The general rule is that if the target already contains merged
   * header or parameter, it is not overwritten.
   */

  function mergeHeader(name, value, to) {
    var nameLowerCase = name.toLowerCase(), n;

    for (n in to) {
      if (n.toLowerCase() === nameLowerCase) {
        return;
      }
    }

    to[name] = value;
  }

  function mergeHeaders(from, to) {
    var name;

    for (name in from) {
      mergeHeader(name, from[name], to);
    }
  }

  function mergeParam(param, to) {
    var i;

    for (i = 0; i < to.length; i++) {
      if (to[i].name === param.name) {
        return;
      }
    }

    to.unshift(param);
  }

  function mergeParams(from, to) {
    var i;

    for (i = 0; i < from.length; i++) {
      mergeParam(from[i], to);
    }
  }

  /* ----- Header Distribution ----- */

  /* "Request XXX Headers" and "Response XXX Headers" handling. */

  function distributeHeaders(headers, requests, responses) {
    function getRequestById(id) {
      var i;

      for (i = 0; i < requests.length; i++) {
        if (requests[i].id === id) {
          return requests[i];
        }
      }

      return null;
    }

    function getResponseByStatus(status) {
      var i;

      for (i = 0; i < responses.length; i++) {
        if (responses[i].status === status) {
          return responses[i];
        }
      }

      return null;
    }


    var request, response, i, j;

    for (i = 0; i < headers.length; i++) {
      if (headers[i].id !== null) {
        request = getRequestById(headers[i].id);
        if (request) {
          mergeHeaders(headers[i].headers, request.headers);
        }
        for (j = i; j < headers.length - 1; j++) {
          headers[j] = headers[j + 1];
        }
        headers.length -= 1;
      } else if (headers[i].status !== null) {
        response = getResponseByStatus(headers[i].status);
        if (request) {
          mergeHeaders(headers[i].headers, response.headers);
        }
        for (j = i; j < headers.length - 1; j++) {
          headers[j] = headers[j + 1];
        }
        headers.length -= 1;
      }
    }
  }

  /* ----- Utility Functions ----- */

  /*
   * Converts name-value pairs from format like this:
   *
   *   [
   *     { name: "Content-Type",   value: "application/json" },
   *     { name: "Content-Length", value: "153"              }
   *   ]
   *
   * into format like this:
   *
   *   {
   *     "Content-Type":   "application/json",
   *     "Content-Length": "153"
   *   }
   */
  function convertNameValuePairs(pairs) {
    var result = {}, i;

    for (i = 0; i < pairs.length; i++) {
      result[pairs[i].name] = pairs[i].value;
    }

    return result;
  }

  /*
   * Filters a list of items in a format like this:
   *
   *   [
   *     { type: SectionType.HEADERS, value: ... },
   *     { type: SectionType.PARAMS,  value: ... }
   *   ]
   *
   * by given type and returns filtered items' values.
   */
  function extractByType(items, type) {
    var result = [], i;

    for (i = 0; i < items.length; i++) {
      if (items[i].type === type) {
        result.push(items[i].value);
      }
    }

    return result;
  }

  /* Converts a nested array of resources into a flat one. */
  function flattenResources(resources) {
    var result = [], i, j;

    for (i = 0; i < resources.length; i++) {
      for (j = 0; j < resources[i].length; j++) {
        result.push(resources[i][j]);
      }
    }

    return result;
  }

  /* Goes through a list of resources and sets their URL. */
  function setResourcesUrl(resources, url) {
    var i;

    for (i = 0; i < resources.length; i++) {
      resources[i].url = url;
    }
  }

  function makeDescription(s) {
    return nullIfEmpty(s.replace(/^\s*|\s*$/g, ""));
  }

  function nullIfEmpty(s) {
    return s !== "" ? s : null;
  }

  var urlPrefix = "";
}

/* ----- API ----- */

API
  = metadata:Metadata
    overview:Overview
    sections:(
        section:L1Resource { return { type: SectionType.RESOURCE, value: section }; }
      / section:Group      { return { type: SectionType.GROUP,    value: section }; }
    )*
    {
      var resources = extractByType(sections, SectionType.RESOURCE),
          groups    = extractByType(sections, SectionType.GROUP),
          location;

      if ("HOST" in metadata) {
        location = metadata["HOST"];
        delete metadata["HOST"];
      } else {
        location = null;
      }

      /* Wrap free-standing resources into an anonymnous group. */
      if (resources.length > 0) {
        groups.unshift({
          class:       "Section",
          name:        null,
          description: null,
          resources:   flattenResources(resources)
        });
      }

      return {
        location:    location,
        class:       "Blueprint",
        name:        overview.name,
        description: overview.description,
        metadata:    metadata,
        sections:    groups,
        validations: []
      };
    }

/* ----- Metadata ----- */

/* Modeled after MultiMarkdown metadata, but a bit more strict. */

Metadata
  = items:MetadataItem* EmptyLine* { return convertNameValuePairs(items); }

MetadataItem "metadata item"
  = name:MetadataName ":" S* value:MetadataValue EOLF {
      var urlWithoutProtocol, slashIndex;

      if (name === "HOST") {
        urlWithoutProtocol = value.replace(/^https?:\/\//, "")
        slashIndex = urlWithoutProtocol.indexOf("/");

        if (slashIndex > 0) {
          urlPrefix = urlWithoutProtocol.slice(slashIndex + 1);
        }
      }

      return {
        name:  name,
        value: value
      };
    }

// ISSUE(z): Is this rule for the metadata name OK?
MetadataName
  = head:[a-zA-Z0-9] tail:[a-zA-Z0-9_-]* { return head + tail.join(""); }

MetadataValue
  = Text0

/* ----- API Name & Overview ----- */

Overview
  = header:L1Header body:L1Body {
      return {
        name:        header,
        description: makeDescription(body)
      };
    }

/* ----- Group ----- */

Group
  = header:L1Header
    body:L2Body
    sections:(
        section:L2Resource { return { type: SectionType.RESOURCE, value: section }; }
      / section:L2Section  { return { type: SectionType.GENERIC }; }
    )+
    {
      var resources = extractByType(sections, SectionType.RESOURCE);

      return {
        class:       "Section",
        name:        header,
        description: makeDescription(body),
        resources:   flattenResources(resources)
      };
    }

/* ----- Resource ----- */

L1Resource = L1ResourceWithMethod / L1ResourceWithoutMethod
L2Resource = L2ResourceWithMethod / L2ResourceWithoutMethod

L1ResourceWithMethod
  = header:L1ResourceWithMethodHeader body:L1ResourceWithMethodBody {
      return [buildResource(header, body)];
    }

L2ResourceWithMethod
  = header:L2ResourceWithMethodHeader body:L2ResourceWithMethodBody {
      return [buildResource(header, body)];
    }

L1ResourceWithMethodHeader "# <resource>"
   = L1HeaderPrefix tail:ResourceWithMethodHeaderTail { return tail; }

L2ResourceWithMethodHeader "## <resource>"
   = L2HeaderPrefix tail:ResourceWithMethodHeaderTail { return tail; }

ResourceWithMethodHeaderTail
  = method:HttpMethod S+ url:URL EOLF {
      return {
        method: method,
        url:    url
      };
    }

L1ResourceWithMethodBody
  = description:L2Body
    sections:(
        section:L2HeadersX { return { type: SectionType.HEADERS,  value: section }; }
      / section:L2Params   { return { type: SectionType.PARAMS,   value: section }; }
      / section:L2Request  { return { type: SectionType.REQUEST,  value: section }; }
      / section:L2Response { return { type: SectionType.RESPONSE, value: section }; }
      / L2Section          { return { type: SectionType.GENERIC }; }
    )*
    { return buildResourceBody(makeDescription(description), sections); }

L2ResourceWithMethodBody
  = description:L3Body
    sections:(
        section:L3HeadersX { return { type: SectionType.HEADERS,  value: section }; }
      / section:L3Params   { return { type: SectionType.PARAMS,   value: section }; }
      / section:L3Request  { return { type: SectionType.REQUEST,  value: section }; }
      / section:L3Response { return { type: SectionType.RESPONSE, value: section }; }
      / L3Section          { return { type: SectionType.GENERIC }; }
    )*
    { return buildResourceBody(makeDescription(description), sections); }

L1ResourceWithoutMethod
  = header:L1ResourceWithoutMethodHeader body:L1ResourceWithoutMethodBody {
      setResourcesUrl(body.resources, header.url);

      return body.resources;
    }

L2ResourceWithoutMethod
  = header:L2ResourceWithoutMethodHeader body:L2ResourceWithoutMethodBody {
      setResourcesUrl(body.resources, header.url);

      return body.resources;
    }

L1ResourceWithoutMethodHeader "# <resource>"
  = L1HeaderPrefix tail:ResourceWithoutMethodHeaderTail { return tail; }

L2ResourceWithoutMethodHeader "## <resource>"
  = L2HeaderPrefix tail:ResourceWithoutMethodHeaderTail { return tail; }

ResourceWithoutMethodHeaderTail
  = url:URL EOLF { return { url: url }; };

L1ResourceWithoutMethodBody
  = L2Body
    sections:(
        section:L2Headers  { return { type: SectionType.HEADERS, value: section }; }
      / section:L2Params   { return { type: SectionType.PARAMS,  value: section }; }
      / section:L2Method   { return { type: SectionType.METHOD, value: section }; }
      / L2Section          { return { type: SectionType.GENERIC }; }
    )*
    { return buildResourcesFromMethods(sections); }

L2ResourceWithoutMethodBody
  = L3Body
    sections:(
        section:L3Headers  { return { type: SectionType.HEADERS, value: section }; }
      / section:L3Params   { return { type: SectionType.PARAMS,  value: section }; }
      / section:L3Method   { return { type: SectionType.METHOD, value: section }; }
      / L3Section          { return { type: SectionType.GENERIC }; }
    )*
    { return buildResourcesFromMethods(sections); }

URL
  = head:"/" tail:Text0 { return head + tail; }

/* ---- Method ----- */

L2Method = header:L2MethodHeader body:L2MethodBody { return buildResource(header, body); }
L3Method = header:L3MethodHeader body:L3MethodBody { return buildResource(header, body); }

L2MethodHeader "## <method>"
  = L2HeaderPrefix tail:MethodHeaderTail { return tail; }

L3MethodHeader "### <method>"
  = L3HeaderPrefix tail:MethodHeaderTail { return tail; }

MethodHeaderTail
  = method:HttpMethod EOLF {
      return {
        method: method,
        url:    null
      };
    }

L2MethodBody
  = description:L3Body
    sections:(
        section:L3HeadersX { return { type: SectionType.HEADERS,  value: section }; }
      / section:L3Params   { return { type: SectionType.PARAMS,   value: section }; }
      / section:L3Request  { return { type: SectionType.REQUEST,  value: section }; }
      / section:L3Response { return { type: SectionType.RESPONSE, value: section }; }
      / L3Section          { return { type: SectionType.GENERIC }; }
    )*
    { return buildResourceBody(makeDescription(description), sections); }

L3MethodBody
  = description:L4Body
    sections:(
        section:L4HeadersX { return { type: SectionType.HEADERS,  value: section }; }
      / section:L4Params   { return { type: SectionType.PARAMS,   value: section }; }
      / section:L4Request  { return { type: SectionType.REQUEST,  value: section }; }
      / section:L4Response { return { type: SectionType.RESPONSE, value: section }; }
      / L4Section          { return { type: SectionType.GENERIC }; }
    )*
    { return buildResourceBody(makeDescription(description), sections); }

/* ----- Headers ----- */

L2Headers = L2HeadersHeader body:L2HeadersBody { return body; }
L3Headers = L3HeadersHeader body:L3HeadersBody { return body; }

L2HeadersX = header:L2HeadersXHeader body:L2HeadersBody { return buildHeaders(header, body); }
L3HeadersX = header:L3HeadersXHeader body:L3HeadersBody { return buildHeaders(header, body); }
L4HeadersX = header:L4HeadersXHeader body:L4HeadersBody { return buildHeaders(header, body); }

L2HeadersHeader = L2HeaderPrefix tail:HeadersHeaderTail  { return tail; }
L3HeadersHeader = L3HeaderPrefix tail:HeadersHeaderTail  { return tail; }

L2HeadersXHeader "## Headers"
  = L2HeaderPrefix tail:RequestHeadersHeaderTail  { return tail; }
  / L2HeaderPrefix tail:ResponseHeadersHeaderTail { return tail; }
  / L2HeaderPrefix tail:HeadersHeaderTail         { return tail; }

L3HeadersXHeader "### Headers"
  = L3HeaderPrefix tail:RequestHeadersHeaderTail  { return tail; }
  / L3HeaderPrefix tail:ResponseHeadersHeaderTail { return tail; }
  / L3HeaderPrefix tail:HeadersHeaderTail         { return tail; }

L4HeadersXHeader "#### Headers"
  = L4HeaderPrefix tail:RequestHeadersHeaderTail  { return tail; }
  / L4HeaderPrefix tail:ResponseHeadersHeaderTail { return tail; }
  / L4HeaderPrefix tail:HeadersHeaderTail         { return tail; }

L2HeadersBody
  = lines:(
        line:PayloadHeadersBodyLine { return { type: LineType.HEADER, value: line }; }
      / L2BodyLine                  { return { type: LineType.TEXT }; }
    )*
    { return convertNameValuePairs(extractByType(lines, LineType.HEADER)); }

L3HeadersBody
  = lines:(
        line:PayloadHeadersBodyLine { return { type: LineType.HEADER, value: line }; }
      / L3BodyLine                  { return { type: LineType.TEXT }; }
    )*
    { return convertNameValuePairs(extractByType(lines, LineType.HEADER)); }

L4HeadersBody
  = lines:(
        line:PayloadHeadersBodyLine { return { type: LineType.HEADER, value: line }; }
      / L4BodyLine                  { return { type: LineType.TEXT }; }
    )*
    { return convertNameValuePairs(extractByType(lines, LineType.HEADER)); }

RequestHeadersHeaderTail
  = "Request" S+ id:Identifier S+ "Headers" EOLF {
      return {
        id:     id,
        status: null
      };
    }

ResponseHeadersHeaderTail
  = "Response" S+ status:HttpStatus S+ "Headers" EOLF {
      return {
        id:     null,
        status: status
      };
    }

HeadersHeaderTail
  = "Headers" EOLF {
      return {
        id:     null,
        status: null
      };
    }

/* ----- Parameters ----- */

L2Params = L2ParamsHeader body:L2ParamsBody { return body; }
L3Params = L3ParamsHeader body:L3ParamsBody { return body; }
L4Params = L4ParamsHeader body:L4ParamsBody { return body; }

L2ParamsHeader "## Parameters"   = L2HeaderPrefix "Parameters" EOLF
L3ParamsHeader "### Parameters"  = L3HeaderPrefix "Parameters" EOLF
L4ParamsHeader "#### Parameters" = L4HeaderPrefix "Parameters" EOLF

L2ParamsBody
  = lines:(
        line:ParamLine { return { type: LineType.PARAM, value: line }; }
      / L2BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.PARAM); }

L3ParamsBody
  = lines:(
        line:ParamLine { return { type: LineType.PARAM, value: line }; }
      / L3BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.PARAM); }

L4ParamsBody
  = lines:(
        line:ParamLine { return { type: LineType.PARAM, value: line }; }
      / L4BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.PARAM); }

/* ----- Request ----- */

L2Request = header:L2RequestHeader payload:L2Payload { return buildRequest(header, payload); }
L3Request = header:L3RequestHeader payload:L3Payload { return buildRequest(header, payload); }
L4Request = header:L4RequestHeader payload:L4Payload { return buildRequest(header, payload); }

L2RequestHeader "## Request"   = L2HeaderPrefix tail:RequestHeaderTail { return tail; }
L3RequestHeader "### Request"  = L3HeaderPrefix tail:RequestHeaderTail { return tail; }
L4RequestHeader "#### Request" = L4HeaderPrefix tail:RequestHeaderTail { return tail; }

RequestHeaderTail
  = "Request"
    id:(S+ id:Identifier { return id; })?
    type:(S+ type:MediaTypeDecl { return type; })?
    EOLF
    {
      return {
        id:   nullIfEmpty(id),
        type: nullIfEmpty(type)
      };
    }

/* ----- Response ----- */

L2Response = header:L2ResponseHeader payload:L2Payload { return buildResponse(header, payload); }
L3Response = header:L3ResponseHeader payload:L3Payload { return buildResponse(header, payload); }
L4Response = header:L4ResponseHeader payload:L4Payload { return buildResponse(header, payload); }

L2ResponseHeader "## Response"   = L2HeaderPrefix tail:ResponseHeaderTail { return tail; }
L3ResponseHeader "### Response"  = L3HeaderPrefix tail:ResponseHeaderTail { return tail; }
L4ResponseHeader "#### Response" = L4HeaderPrefix tail:ResponseHeaderTail { return tail; }

ResponseHeaderTail
  = "Response"
    S+
    status:HttpStatus
    type:(S+ type:MediaTypeDecl { return type; })?
    EOLF
    {
      return {
        status: status,
        type:   nullIfEmpty(type)
      };
    }

/* ----- Common for Requests, Responses and Headers ----- */

Identifier
  = head:Word tail:(S+ Word)* { return head + tail.join(""); }

Word
  = chars:WordChar+ { return chars.join(""); }

WordChar
  = !EOLF !S ![()] !"Headers" ch:. { return ch; }

MediaTypeDecl
  = "(" type:MediaType ")" { return type; }

MediaType
  = chars:[^()]+ { return chars.join(""); }

/* ----- Payload ----- */

L2Payload
  = L3Body
    sections:(
        section:L3PayloadHeaders { return { type: SectionType.HEADERS, value: section }; }
      / section:L3PayloadParams  { return { type: SectionType.PARAMS,  value: section }; }
      / section:L3PayloadBody    { return { type: SectionType.BODY,    value: section }; }
      / section:L3PayloadSchema  { return { type: SectionType.SCHEMA,  value: section }; }
      / L3Section                { return { type: SectionType.GENERIC }; }
    )+
    { return buildComplexPayload(sections); }
  / body:L2Asset { return buildSimplePayload(body); }

L3Payload
  = L4Body
    sections:(
        section:L4PayloadHeaders { return { type: SectionType.HEADERS, value: section }; }
      / section:L4PayloadParams  { return { type: SectionType.PARAMS,  value: section }; }
      / section:L4PayloadBody    { return { type: SectionType.BODY,    value: section }; }
      / section:L4PayloadSchema  { return { type: SectionType.SCHEMA,  value: section }; }
      / L4Section                { return { type: SectionType.GENERIC }; }
    )+
    { return buildComplexPayload(sections); }
  / body:L3Asset { return buildSimplePayload(body); }

L4Payload
  = L5Body
    sections:(
        section:L5PayloadHeaders { return { type: SectionType.HEADERS, value: section }; }
      / section:L5PayloadParams  { return { type: SectionType.PARAMS,  value: section }; }
      / section:L5PayloadBody    { return { type: SectionType.BODY,    value: section }; }
      / section:L5PayloadSchema  { return { type: SectionType.SCHEMA,  value: section }; }
      / L5Section                { return { type: SectionType.GENERIC }; }
    )+
    { return buildComplexPayload(sections); }
  / body:L4Asset { return buildSimplePayload(body); }


/* ----- Payload Headers ----- */

L3PayloadHeaders = L3PayloadHeadersHeader body:L3PayloadHeadersBody { return body; }
L4PayloadHeaders = L4PayloadHeadersHeader body:L4PayloadHeadersBody { return body; }
L5PayloadHeaders = L5PayloadHeadersHeader body:L5PayloadHeadersBody { return body; }

L3PayloadHeadersHeader "### Headers"   = L3HeaderPrefix "Headers" EOLF
L4PayloadHeadersHeader "#### Headers"  = L4HeaderPrefix "Headers" EOLF
L5PayloadHeadersHeader "##### Headers" = L5HeaderPrefix "Headers" EOLF

L3PayloadHeadersBody
  = lines:(
        line:PayloadHeadersBodyLine { return { type: LineType.HEADER, value: line }; }
      / L3BodyLine                  { return { type: LineType.TEXT }; }
    )*
    { return convertNameValuePairs(extractByType(lines, LineType.HEADER)); }

L4PayloadHeadersBody
  = lines:(
        line:PayloadHeadersBodyLine { return { type: LineType.HEADER, value: line }; }
      / L4BodyLine                  { return { type: LineType.TEXT }; }
    )*
    { return convertNameValuePairs(extractByType(lines, LineType.HEADER)); }

L5PayloadHeadersBody
  = lines:(
        line:PayloadHeadersBodyLine { return { type: LineType.HEADER, value: line }; }
      / L5BodyLine                  { return { type: LineType.TEXT }; }
    )*
    { return convertNameValuePairs(extractByType(lines, LineType.HEADER)); }


PayloadHeadersBodyLine "HTTP header"
  = CodeBlockPrefix header:HttpHeader { return header; }

/* ----- Payload Parameters ----- */

L3PayloadParams = L3PayloadParamsHeader body:L3PayloadParamsBody { return body; }
L4PayloadParams = L4PayloadParamsHeader body:L4PayloadParamsBody { return body; }
L5PayloadParams = L5PayloadParamsHeader body:L5PayloadParamsBody { return body; }

L3PayloadParamsHeader "### Parameters"   = L3HeaderPrefix "Parameters" EOLF
L4PayloadParamsHeader "#### Parameters"  = L4HeaderPrefix "Parameters" EOLF
L5PayloadParamsHeader "##### Parameters" = L5HeaderPrefix "Parameters" EOLF

L3PayloadParamsBody
  = lines:(
        line:ParamLine { return { type: LineType.PARAM, value: line }; }
      / L3BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.PARAM); }

L4PayloadParamsBody
  = lines:(
        line:ParamLine { return { type: LineType.PARAM, value: line }; }
      / L4BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.PARAM); }

L5PayloadParamsBody
  = lines:(
        line:ParamLine { return { type: LineType.PARAM, value: line }; }
      / L5BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.PARAM); }


/* ----- Payload Body ----- */

L3PayloadBody = L3PayloadBodyHeader body:L3Asset { return body; }
L4PayloadBody = L4PayloadBodyHeader body:L4Asset { return body; }
L5PayloadBody = L5PayloadBodyHeader body:L5Asset { return body; }

L3PayloadBodyHeader "### Body"   = L3HeaderPrefix "Body" EOLF
L4PayloadBodyHeader "#### Body"  = L4HeaderPrefix "Body" EOLF
L5PayloadBodyHeader "##### Body" = L5HeaderPrefix "Body" EOLF

/* ----- Payload Schema ----- */

L3PayloadSchema = L3PayloadSchemaHeader body:L3Asset { return body; }
L4PayloadSchema = L4PayloadSchemaHeader body:L4Asset { return body; }
L5PayloadSchema = L5PayloadSchemaHeader body:L4Asset { return body; }

L3PayloadSchemaHeader "### Schema"   = L3HeaderPrefix "Schema" EOLF
L4PayloadSchemaHeader "#### Schema"  = L4HeaderPrefix "Schema" EOLF
L5PayloadSchemaHeader "##### Schema" = L5HeaderPrefix "Schema" EOLF

/* ----- Parameters ----- */

ParamLine "parameter definition"
  = "+" S+
    name:ParamName S+
    default_:("=" S+ default_:ParamDefault S+ { return default_; })?
    type:("(" type:ParamType ")" S+ { return type; })?
    "..." S+ description:Text0 EOLF
    {
      return {
        name:        name,
        description: description,
        type:        nullIfEmpty(type),
        default:     nullIfEmpty(default_)
      };
    }

ParamName
  = chars:[a-zA-Z0-9_\-.]* { return chars.join(""); }

ParamDefault
  = chars:ParamDefaultChar+ { return chars.join(""); }

ParamDefaultChar
  = !(S+ "(") !(S+ "...") ch:. { return ch; }

ParamType
  = chars:ParamTypeChar+ { return chars.join(""); }

ParamTypeChar
  = !")" ch:. { return ch; }

/* ----- Assets ----- */

L2Asset
  = lines:(
        line:AssetLine { return { type: LineType.ASSET, value: line }; }
      / L2BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.ASSET).join("\n"); }

L3Asset
  = lines:(
        line:AssetLine { return { type: LineType.ASSET, value: line }; }
      / L3BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.ASSET).join("\n"); }

L4Asset
  = lines:(
        line:AssetLine { return { type: LineType.ASSET, value: line }; }
      / L4BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.ASSET).join("\n"); }

L5Asset
  = lines:(
        line:AssetLine { return { type: LineType.ASSET, value: line }; }
      / L5BodyLine     { return { type: LineType.TEXT }; }
    )*
    { return extractByType(lines, LineType.ASSET).join("\n"); }

AssetLine "asset"
  = CodeBlockPrefix text:Text0 EOLF { return text; }

/* ----- Generic Sections ----- */

L2Section = header:L2Header body:L2Body
L3Section = header:L3Header body:L3Body
L4Section = header:L4Header body:L4Body
L5Section = header:L5Header body:L5Body

L1HeaderPrefix = "#" S+
L2HeaderPrefix = "##" S+
L3HeaderPrefix = "###" S+
L4HeaderPrefix = "####" S+
L5HeaderPrefix = "#####" S+

L1Header "#-header"     = L1HeaderPrefix text:Text0 EOLF { return text; }
L2Header "##-header"    = L2HeaderPrefix text:Text0 EOLF { return text; }
L3Header "###-header"   = L3HeaderPrefix text:Text0 EOLF { return text; }
L4Header "####-header"  = L4HeaderPrefix text:Text0 EOLF { return text; }
L5Header "#####-header" = L5HeaderPrefix text:Text0 EOLF { return text; }

L1Body = lines:L1BodyLine* { return lines.join("\n"); }
L2Body = lines:L2BodyLine* { return lines.join("\n"); }
L3Body = lines:L3BodyLine* { return lines.join("\n"); }
L4Body = lines:L4BodyLine* { return lines.join("\n"); }
L5Body = lines:L5BodyLine* { return lines.join("\n"); }

L1BodyLine "any text except #-header"
  = !L1HeaderPrefix
    line:Line { return line; }

L2BodyLine "any text except ##-header (or higher level header)"
  = !L1HeaderPrefix !L2HeaderPrefix
    line:Line { return line; }

L3BodyLine "any text except ###-header (or higher level header)"
  = !L1HeaderPrefix !L2HeaderPrefix !L3HeaderPrefix
    line:Line { return line; }

L4BodyLine "any text except ####-header (or higher level header)"
  = !L1HeaderPrefix !L2HeaderPrefix !L3HeaderPrefix !L4HeaderPrefix
    line:Line { return line; }

L5BodyLine "any text except #####-header (or higher level header)"
  = !L1HeaderPrefix !L2HeaderPrefix !L3HeaderPrefix !L4HeaderPrefix !L5HeaderPrefix
    line:Line { return line; }

/* ----- HTTP ----- */

HttpStatus
  = digits:[0-9]+ { return parseInt(digits.join(""), 10); }

/* Assembled from RFC 2616, 5323, 5789. */
HttpMethod
  = "GET"
  / "POST"
  / "PUT"
  / "DELETE"
  / "OPTIONS"
  / "PATCH"
  / "PROPPATCH"
  / "LOCK"
  / "UNLOCK"
  / "COPY"
  / "MOVE"
  / "MKCOL"
  / "HEAD"

HttpHeader
  = name:HttpHeaderName ":" S* value:HttpHeaderValue EOLF {
      return {
        name:  name,
        value: value
      };
    }

/*
 * See RFC 822, 3.1.2: "The field-name must be composed of printable ASCII
 * characters (i.e., characters that have values between 33. and 126., decimal,
 * except colon)."
 */
HttpHeaderName
  = chars:[\x21-\x39\x3B-\x7E]+ { return chars.join(""); }

HttpHeaderValue
  = Text0

/* ----- Markdown ----- */

CodeBlockPrefix "Markdown code block"
  = "    "
  / "\t"

/* ----- Helpers Rules ----- */

Text0 "zero or more characters"
  = chars:[^\n\r]* { return chars.join(""); }

Text1 "one or more characters"
  = chars:[^\n\r]+ { return chars.join(""); }

Line "line"
  = text:Text0 EOL { return text; }
  / text:Text1 EOF { return text; }

EmptyLine "empty line"
  = S* EOL
  / S+ EOF

EOLF "end of line or file"
  = EOL / EOF

EOL "end of line"
  = "\n"
  / "\r\n"
  / "\r"

EOF "end of file"
  = !. { return ""; }

/*
 * What "\s" matches in JavaScript regexps, sans "\r", "\n", "\u2028" and
 * "\u2029". See ECMA-262, 5.1 ed., 15.10.2.12.
 */
S "whitespace"
  = [\t\v\f \u00A0\u1680\u180E\u2000\u2001\u2002\u2003\u2004\u2005\u2006\u2007\u2008\u2009\u200A\u202F\u205F\u3000\uFEFF]
