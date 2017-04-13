require 'json'

module Solargraph

  class Suggestion
    CLASS = 'Class'
    KEYWORD = 'Keyword'
    MODULE = 'Module'
    METHOD = 'Method'
    VARIABLE = 'Variable'
    SNIPPET = 'Snippet'

    attr_reader :label, :kind, :insert, :detail, :documentation, :code_object, :location

    def initialize label, kind: KEYWORD, insert: nil, detail: nil, documentation: nil, code_object: nil, location: nil
      @label = label.to_s
      @kind = kind
      @insert = insert || @label
      @detail = detail
      @code_object = code_object
      @documentation = documentation
      @location = location
    end
    
    def path
      code_object.nil? ? label : code_object.path
    end

    def to_s
      label
    end

    def to_json args={}
      obj = {
        label: @label,
        kind: @kind,
        insert: @insert,
        detail: @detail,
        path: path,
        location: (@location.nil? ? nil : @location.to_s)
      }
      if @code_object.nil?
        obj[:documentation] = @documentation.all unless @documentation.nil?
      else
        obj[:documentation] = @code_object.docstring.all unless @code_object.docstring.nil?
      end
      obj.to_json(args)
    end
  end

end
