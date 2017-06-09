require 'json'

module Solargraph

  class Suggestion
    CLASS = 'Class'
    KEYWORD = 'Keyword'
    MODULE = 'Module'
    METHOD = 'Method'
    VARIABLE = 'Variable'
    PROPERTY = 'Property'
    FIELD = 'Field'
    SNIPPET = 'Snippet'

    attr_reader :label, :kind, :insert, :detail, :documentation, :code_object, :location, :arguments

    def initialize label, kind: KEYWORD, insert: nil, detail: nil, documentation: nil, code_object: nil, location: nil, arguments: []
      @label = label.to_s
      @kind = kind
      @insert = insert || @label
      @detail = detail
      @code_object = code_object
      @documentation = documentation
      @location = location
      @arguments = arguments
    end
    
    def path
      code_object.nil? ? label : code_object.path
    end

    def to_s
      label
    end

    def return_type
      if code_object.nil?
        unless documentation.nil?
          match = documentation.all.match(/@return \[([a-z0-9:_]*)/i)
          return match[1] unless match.nil?
        end
      else
        o = code_object.tag(:overload)
        if o.nil?
          r = code_object.tag(:return)
        else
          r = o.tag(:return)
        end
        return r.types[0] unless r.nil?
      end
      nil
    end

    def to_json args={}
      obj = {
        label: @label,
        kind: @kind,
        insert: @insert,
        detail: @detail,
        path: path,
        location: (@location.nil? ? nil : @location.to_s),
        arguments: @arguments,
        return_type: return_type
      }
      if @code_object.nil?
        obj[:documentation] = @documentation.to_s unless @documentation.nil?
      else
        obj[:documentation] = @code_object.docstring.to_s unless @code_object.docstring.nil?
      end
      obj.to_json(args)
    end
  end

end
