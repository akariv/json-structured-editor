class JSEValue
        constructor: (@optional,@title,@fixed) ->

        setvalue: (value) ->
                if @validate(value)
                        @value = value

        validate: (value) ->
                if !(@optional or value?)
                        throw "JSE: #{@title} Required mandatory value"
                return value? and value != 'undefined'

        getvalue: -> @value

class JSEString extends JSEValue
        constructor: (optional,title,fixed) ->
                super optional,title,fixed

        render: (jselector) ->
                jselector.append("<input type='text' class='input-xlarge' id='input01' placeholder='Enter something'>")
                @el = jselector.find("input:last")
                if @value?
                        @el.val( @value )
                if @fixed
                        @el.addClass("disabled")
                        @el.attr("disabled","")

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
                if @fixed
                        @el.addClass("disabled")

class JSEDate extends JSEString

        render: (jselector) ->
                jselector.append("<input data-date-format='dd/mm/yyyy' value='01/01/2012' type='text' class='input-xlarge'>")
                @el = jselector.find("input:last")
                @el.datepicker({})
                if @value?
                        @el.val( @value )
                if @fixed
                        @el.addClass("disabled")

class JSESelect extends JSEString

        constructor: (optional,title,@options) ->
                super optional,title,false

        render: (jselector) ->
                jselector.append("<select></select>")
                @el = jselector.find("select:last")
                for option in @options
                        [ val, display ] = option
                        @el.append("<option value='#{val}'>#{display}</option>")
                if @value?
                        @el.select( @value )

class JSENumber extends JSEValue
        constructor: (optional,title,fixed) ->
                super optional,title,fixed

        render: (jselector) ->
                jselector.append("<input type='text' class='input-xlarge' id='input01' placeholder='Enter something'>")
                @el = jselector.find("input:last")
                if @value?
                        @el.val( @value )
                if @fixed
                        @el.addClass("disabled")

        validate: (obj) ->
                if super(obj)
                        unless (typeof(obj) == "number")
                                throw "JSE: #{@title} Expected Number value"
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


class JSEBoolean extends JSEValue
        constructor: (optional,title,fixed) ->
                super false,title,fixed

        render: (jselector) ->
                jselector.append("<input type='checkbox' class='input-xlarge' id='input01'>")
                @el = jselector.find("input:last")
                if @value?
                        @el.val( @value )
                if @fixed
                        @el.addClass("disabled")

        validate: (obj) ->
                if super(obj)
                        unless (typeof(obj) == "boolean")
                                throw "JSE: #{@title} Expected Boolean value"
                        else
                                return true
                return false

        getvalue: ->
                if @el
                        @el.val()


class JSEObject extends JSEValue
        constructor: (fields,optional,title) ->
                console.log("new object")
                super optional,title,false
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
                super optional,title,false
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
        fixed = fielddesc["fixed"]
        console.log("type: #{type}")
        switch type
                when "obj" then new JSEObject(children,optional,title)
                when "num" then new JSENumber(optional,title,fixed)
                when "bool" then new JSEBoolean(optional,title,fixed)
                when "str" then new JSEString(optional,title,fixed)
                when "select" then new JSESelect(optional,title,options)
                when "text" then new JSEText(optional,title,fixed)
                when "date" then new JSEDate(optional,title,fixed)
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

