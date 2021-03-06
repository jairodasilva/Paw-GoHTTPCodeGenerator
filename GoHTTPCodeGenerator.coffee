# in API v0.2.0 and below (Paw 2.2.2 and below), require had no return value
((root) ->
  if root.bundle?.minApiVersion('0.2.0')
    root.URI = require("./URI")
    root.Mustache = require("./mustache")
  else
    require("URI.min.js")
    require("mustache.js")
)(this)

addslashes = (str) ->
    ("#{str}").replace(/[\\"]/g, '\\$&')

addBackSlashes = (str) ->
    ("#{str}").replace(/[\\`]/g, '\\$&')

slugify = (str) ->
    re = /([a-zA-Z0-9])([a-zA-Z0-9]*)/g
    l = []
    while (m = re.exec(str))
        if (m)
            l.push(m[1].toUpperCase() + m[2].toLowerCase())
    return l.join('')

GoHTTPCodeGenerator = ->

    @url = (request) ->
        url_params_object = (() ->
            _uri = URI request.url
            _uri.search true
        )()
        url_params = ({
            "name": addslashes name
            "value": addslashes value
        } for name, value of url_params_object)

        return {
            "fullpath": request.url
            "base": addslashes (() ->
                _uri = URI request.url
                _uri.search("")
                _uri
            )()
            "params": url_params
            "has_params": url_params.length > 0
        }

    @headers = (request) ->
        headers = request.headers
        return {
            "has_headers": Object.keys(headers).length > 0
            "header_list": ({
                "header_name": addslashes header_name
                "header_value": addslashes header_value
            } for header_name, header_value of headers)
        }

    @body = (request) ->
        json_body = request.jsonBody
        if json_body
            return {
                "has_json_body":true
                "json_body_object": @json_body_object json_body
            }

        url_encoded_body = request.urlEncodedBody
        if url_encoded_body
            return {
                "has_url_encoded_body":true
                "url_encoded_body": ({
                    "name": addslashes name
                    "value": addslashes value
                } for name, value of url_encoded_body)
            }

        multipart_body = request.multipartBody
        if multipart_body
            return {
                "has_multipart_body":true
                "multipart_body": ({
                    "name": addslashes name
                    "value": addslashes value
                } for name, value of multipart_body)
            }

        raw_body = request.body
        if raw_body
            if raw_body.length < 5000
                return {
                    "has_raw_body":true
                    "raw_body": addBackSlashes raw_body
                }
            else
                return {
                    "has_long_body":true
                }

    @json_body_object = (object) ->
        if object == null
            s = "null"
        else if typeof(object) == 'string'
            s = "\"#{addslashes object}\""
        else if typeof(object) == 'number'
            s = "#{object}"
        else if typeof(object) == 'boolean'
            s = "#{if object then "true" else "false"}"
        else if typeof(object) == 'object'
            if object.length?
                s = '[' + ("#{@json_body_object(value)}" for value in object).join(',') + ']'
            else
                s = '{' + ("\"#{addslashes key}\": #{@json_body_object(value)}" for key, value of object).join(',') + '}'
        return s

    @generate = (context) ->
        request = context.getCurrentRequest()

        view =
            "request": context.getCurrentRequest()
            "method": request.method[0].toUpperCase() + request.method[1..-1].toLowerCase()
            "url": @url request
            "headers": @headers request
            "body": @body request
            "codeSlug": slugify request.name

        template = readFile "go.mustache"
        Mustache.render template, view

    return


GoHTTPCodeGenerator.identifier =
    "com.luckymarmot.PawExtensions.GoHTTPCodeGenerator"
GoHTTPCodeGenerator.title =
    "Go (HTTP)"
GoHTTPCodeGenerator.fileExtension = "go"
GoHTTPCodeGenerator.languageHighlighter = "go"

registerCodeGenerator GoHTTPCodeGenerator
