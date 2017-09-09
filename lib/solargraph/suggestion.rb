require 'json'

module Solargraph

  class Suggestion
    CLASS = 'Class'
    CONSTANT = 'Constant'
    KEYWORD = 'Keyword'
    MODULE = 'Module'
    METHOD = 'Method'
    VARIABLE = 'Variable'
    PROPERTY = 'Property'
    FIELD = 'Field'
    SNIPPET = 'Snippet'

    attr_reader :label, :kind, :insert, :detail, :documentation, :code_object, :location, :arguments

    def initialize label, kind: KEYWORD, insert: nil, detail: nil, documentation: nil, code_object: nil, location: nil, arguments: [], return_type: nil
      @helper = Server::Helpers.new
      @label = label.to_s
      @kind = kind
      @insert = insert || @label
      @detail = detail
      @code_object = code_object
      @documentation = documentation
      @location = location
      @arguments = arguments
      @return_type = return_type
    end
    
    def path
      code_object.nil? ? label : code_object.path
    end

    def to_s
      label
    end

    def return_type
      if @return_type.nil?
        if code_object.nil?
          if documentation.kind_of?(YARD::Docstring)
            t = documentation.tag(:return)
            @return_type = t.types[0] unless t.nil? or t.types.nil?
          end
        else
          o = code_object.tag(:overload)
          if o.nil?
            r = code_object.tag(:return)
          else
            r = o.tag(:return)
          end
          @return_type = r.types[0] unless r.nil? or r.types.nil?
        end
      end
      @return_type
    end

    def documentation
      if @documentation.nil?
        unless @code_object.nil?
          @documentation = @code_object.docstring unless @code_object.docstring.nil?
        end
      end
      @documentation
    end

    def params
      if @params.nil?
        @params = []
        return @params if documentation.nil?
        param_tags = documentation.tags(:param)
        unless param_tags.empty?
          param_tags.each do |t|
            txt = t.name.to_s
            txt += " [#{t.types.join(',')}]" unless t.types.nil? or t.types.empty?
            txt += " #{t.text}" unless t.text.nil? or t.text.empty?
            @params.push txt
          end
        end
      end
      @params
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
        params: params,
        return_type: return_type,
        documentation: @helper.html_markup_rdoc(documentation.to_s)
      }
      obj.to_json(args)
    end
  end

end
