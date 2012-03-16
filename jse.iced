class JSEValue
        constructor: (@optional,@title) ->

        setvalue: (value) ->
                if @validate(value)
                        @value = value

        validate: (value) ->
                if !(@optional or value?)
                        throw "JSE: Required mandatory value"
                return value? and value != 'undefined'

        getvalue: -> @value

class JSEString extends JSEValue
        constructor: (optional,title) ->
                super optional,title

        render: (jselector) ->
                jselector.append("<input type='text' class='input-xlarge' id='input01' placeholder='Enter something'>")
                @el = jselector.find("input:last")
                if @value?
                        @el.val( @value )

        validate: (obj) ->
                if super(obj)
                        unless (typeof(obj) == "string")
                                throw "JSE: Expected String value"
                        else
                                return true
                return false

        getvalue: ->
                if @el
                        if @el.val() != ""
                                @el.val()
                        else
                                null
                else
                        @value

class JSEText extends JSEString

        render: (jselector) ->
                jselector.append("<textarea class='input-xlarge' rows='3' placeholder='Enter something'>")
                @el = jselector.find("textarea:last")
                if @value?
                        @el.val( @value )

class JSEDate extends JSEString

        render: (jselector) ->
                jselector.append("<input data-date-format='dd/mm/yyyy' value='01/01/2012' type='text' class='input-xlarge'>")
                @el = jselector.find("input:last")
                @el.datepicker({})
                if @value?
                        @el.val( @value )

class JSESelect extends JSEString

        constructor: (optional,title,@options) ->
                super optional,title

        render: (jselector) ->
                jselector.append("<select></select>")
                @el = jselector.find("select:last")
                for option in @options
                        [ val, display ] = option
                        @el.append("<option value='#{val}'>#{display}</option>")
                if @value?
                        @el.select( @value )

class JSENumber extends JSEValue
        constructor: (optional,title) ->
                super optional,title

        render: (jselector) ->
                jselector.append("<input type='text' class='input-xlarge' id='input01' placeholder='Enter something'>")
                @el = jselector.find("input:last")
                if @value?
                        @el.val( @value )

        validate: (obj) ->
                if super(obj)
                        unless (typeof(obj) == "number")
                                throw "JSE: Expected Number value"
                        else
                                return true
                return false

        getvalue: ->
                if @el
                        if @el.val() != ""
                                parseInt( @el.val(), 10 )
                        else
                                null
                else
                        @value


class JSEObject extends JSEValue
        constructor: (fields,optional,title) ->
                console.log("new object")
                super optional,title
                @children = {}
                @fieldnames = (tuple.name for tuple in fields)
                @children[ tuple.name ] = generateJSEItem( tuple.props ) for tuple in fields

        render: (jselector) ->
                jselector.append( "<form class='well form-horizontal'></form>" )
                jselector = jselector.find("form:last")
                for fieldname in @fieldnames
                        title = @children[fieldname].title
                        jselector.append("<div class='control-group'>
                                               <label class='control-label'>#{title}</label>
                                               <div class='controls'>
                                               </div>
                                          </div>")
                        @children[fieldname].render( jselector.find(".control-group:last > .controls") )

        validate: (obj) ->
                if super(obj)
                        unless (typeof(obj) == "object")
                                throw "JSE: Expected Object value"
                        else
                                return true
                return false

        setvalue: (obj) ->
                if @validate( obj )
                        for fieldname in @fieldnames
                                value = obj[fieldname]
                                @children[ fieldname ].setvalue(value)

        getvalue: ->
                r = {}
                for fieldname in @fieldnames
                        if @children[ fieldname ].getvalue()?
                                r[fieldname] = @children[ fieldname ].getvalue()
                return r


class JSEArray extends JSEValue
        constructor: (@fielddesc,optional,title) ->
                console.log("new array")
                super optional,title
                @children = []

        render: (jselector) ->
                jselector.append("<div></div>
                                  <a class='additem btn btn-mini'><i class='icon-plus'></i>New item</a>")
                @el = jselector.find("div:last")
                for child in @children
                        child.render( @el )
                jselector.find(".additem:last").click () =>
                        child = generateJSEItem(@fielddesc)
                        @children.push child
                        child.render( @el )

        validate: (obj) ->
                if super(obj)
                        unless (typeof(obj) == "object")
                                throw "JSE: Expected Array value"
                        else
                                return true
                return false

        setvalue: (obj) ->
                if @validate( obj )
                        @children = []
                        for value in obj
                                child = generateJSEItem(@fielddesc)
                                child.setvalue(value)
                                @children.push(child)

        getvalue: ->
                el.getvalue() for el in @children when el.getvalue()?


generateJSEItem = ( fielddesc ) ->
        type = fielddesc["type"]
        optional = fielddesc["optional"] == true
        children = fielddesc["children"]
        eltype = fielddesc["eltype"]
        title = fielddesc["title"]
        options = fielddesc["options"]
        console.log("type: #{type}")
        switch type
                when "obj" then new JSEObject(children,optional,title)
                when "num" then new JSENumber(optional,title)
                when "str" then new JSEString(optional,title)
                when "select" then new JSESelect(optional,title,options)
                when "text" then new JSEText(optional,title)
                when "date" then new JSEDate(optional,title)
                when "arr" then new JSEArray(eltype,optional,title)
                else throw "JSE: unknown type #{type}"

class JSE

      constructor: (@selector,@scheme) ->
                           @jse = generateJSEItem( @scheme )
                           @jse.render(@selector)

      setvalue: (value) -> @jse.setvalue(value)
      getvalue: () -> @jse.getvalue()
      render:   () -> @jse.render(@selector)

window.JSE = JSE

issue_scheme = {"type": "obj", "children": [{"name": "slug", "props": {"type": "str", "title": "\u05de\u05d6\u05d4\u05d4"}}, {"name": "book", "props": {"type": "str", "title": "\u05d3\u05d5\"\u05d7"}}, {"name": "chapter", "props": {"type": "str", "title": "\u05e4\u05e8\u05e7"}}, {"name": "subchapter", "props": {"optional": true, "type": "str", "title": "\u05e1\u05e2\u05d9\u05e3"}}, {"name": "subject", "props": {"type": "str", "title": "\u05db\u05d5\u05ea\u05e8\u05ea"}}, {"name": "recommendation", "props": {"type": "text", "title": "\u05e4\u05d9\u05e8\u05d5\u05d8"}}, {"name": "result_metric", "props": {"type": "text", "title": "\u05de\u05d8\u05e8\u05d4"}}, {"name": "budget", "props": {"type": "obj", "children": [{"name": "description", "props": {"optional": true, "type": "text", "title": "\u05ea\u05d9\u05d0\u05d5\u05e8"}}, {"name": "millions", "props": {"type": "num", "title": "\u05e1\u05db\u05d5\u05dd \u05d1\u05de\u05d9\u05dc\u05d9\u05d5\u05e0\u05d9\u05dd"}}, {"name": "year_span", "props": {"type": "num", "title": "\u05e2\u05dc \u05e4\u05e0\u05d9 \u05db\u05de\u05d4 \u05e9\u05e0\u05d9\u05dd"}}], "title": "\u05e2\u05dc\u05d5\u05ea \u05db\u05e1\u05e4\u05d9\u05ea"}}, {"name": "responsible_authority", "props": {"type": "str", "title": "\u05d2\u05d5\u05e8\u05dd \u05d0\u05d7\u05e8\u05d0\u05d9"}}, {"name": "tags", "props": {"type": "arr", "eltype": {"type": "str"}, "title": "\u05ea\u05d2\u05d9\u05d5\u05ea"}}, {"name": "description", "props": {"type": "text", "optional": true, "title": "\u05d3\u05d1\u05e8\u05d9 \u05d4\u05e1\u05d1\u05e8"}}, {"name": "implementation_status", "props": {"type": "select", "options": [["NEW", "\u05d8\u05e8\u05dd \u05d4\u05ea\u05d7\u05d9\u05dc"], ["STUCK", "\u05ea\u05e7\u05d5\u05e2"], ["IN_PROGRESS", "\u05d1\u05ea\u05d4\u05dc\u05d9\u05da"], ["FIXED", "\u05d9\u05d5\u05e9\u05dd \u05d1\u05de\u05dc\u05d5\u05d0\u05d5"], ["WORKAROUND", "\u05d9\u05d5\u05e9\u05dd \u05d7\u05dc\u05e7\u05d9\u05ea"], ["IRRELEVANT", "\u05db\u05d1\u05e8 \u05dc\u05d0 \u05e8\u05dc\u05d5\u05d5\u05e0\u05d8\u05d9"]], "title": "\u05e1\u05d8\u05d8\u05d5\u05e1 \u05d9\u05d9\u05e9\u05d5\u05dd"}}, {"name": "implementation_status_text", "props": {"type": "text", "optional": true, "title": "\u05d4\u05e1\u05d1\u05e8 \u05dc\u05e1\u05d8\u05d8\u05d5\u05e1 \u05d4\u05d9\u05d9\u05e9\u05d5\u05dd"}}, {"name": "timeline", "props": {"type": "arr", "eltype": {"type": "obj", "children": [{"name": "milestone_name", "props": {"type": "str", "title": "\u05e9\u05dd \u05d0\u05d1\u05df \u05d4\u05d3\u05e8\u05da"}}, {"name": "description", "props": {"optional": true, "type": "text", "title": "\u05ea\u05d9\u05d0\u05d5\u05e8 \u05de\u05e4\u05d5\u05e8\u05d8"}}, {"name": "due_date", "props": {"optional": true, "type": "date", "title": "\u05ea\u05d0\u05e8\u05d9\u05da \u05d9\u05e2\u05d3 \u05de\u05ea\u05d5\u05db\u05e0\u05df"}}, {"name": "action_date", "props": {"optional": true, "type": "date", "title": "\u05ea\u05d0\u05e8\u05d9\u05da \u05d1\u05d9\u05e6\u05d5\u05e2 \u05d1\u05e4\u05d5\u05e2\u05dc"}}, {"name": "links", "props": {"type": "arr", "eltype": {"type": "obj", "children": [{"name": "url", "props": {"type": "str", "title": "URL"}}, {"name": "description", "props": {"type": "str", "title": "\u05ea\u05d9\u05d0\u05d5\u05e8"}}]}, "title": "\u05e7\u05d9\u05e9\u05d5\u05e8\u05d9\u05dd"}}], "title": "\u05d0\u05d1\u05df \u05d3\u05e8\u05da"}, "title": "\u05dc\u05d5\u05d7 \u05d6\u05de\u05e0\u05d9\u05dd"}}]}

$( () ->
        J = new JSE($("#body"), issue_scheme)

        $("#results-button").click () ->
                newval = J.getvalue()
                try
                        J.setvalue(newval)
                        #$("#results").html( "<pre>#{ JSON.stringify(newval) }</pre>" )
                        $("#errors").html("&nbsp;")
                        $("#saver input").val(JSON.stringify(newval))
                        $("#saver").submit()
                catch e
                        $("#errors").html(e)
                $("#body").html("")
                J.render()

        window.onhashchange = (e) ->
                hash = window.location.hash
                hash = hash[1..hash.length]
                $("#saver").attr("action","/api/#{hash}")
                await $.getJSON("http://127.0.0.1:5000/api/#{hash}",(defer data))
                J.setvalue(data)
                $("#body").html("")
                J.render()

        window.onhashchange()
)