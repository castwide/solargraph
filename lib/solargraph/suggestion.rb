require 'json'

module Solargraph

  class Suggestion
    CLASS =    'Class'
    CONSTANT = 'Constant'
    FIELD =    'Field'
    KEYWORD =  'Keyword'
    METHOD =   'Method'
    MODULE =   'Module'
    PROPERTY = 'Property'
    SNIPPET =  'Snippet'
    VARIABLE = 'Variable'

    # @return [String]
    attr_reader :label

    # @return [String]
    attr_reader :kind

    # @return [String]
    attr_reader :insert

    # @return [String]
    attr_reader :detail

    # @return [YARD::CodeObjects::Base]
    attr_reader :code_object

    # @return [String]
    attr_reader :location

    # @return [Array<String>]
    attr_reader :arguments

    def initialize label, kind: KEYWORD, insert: nil, detail: nil, docstring: nil, code_object: nil, location: nil, arguments: [], return_type: nil, path: nil
      @helper = Server::Helpers.new
      @label = label.to_s
      @kind = kind
      @insert = insert || @label
      @detail = detail
      @code_object = code_object
      @docstring = docstring
      @location = location
      @arguments = arguments
      @return_type = return_type
      @path = path
    end

    # @return [String]
    def path
      @path ||= (code_object.nil? ? label : code_object.path)
    end

    # @return [String]
    def to_s
      label
    end

    # @return [String]
    def return_type
      if @return_type.nil? and !docstring.nil?
        ol = docstring.tag(:overload)
        t = ol.nil? ? docstring.tag(:return) : ol.tag(:return)
        @return_type = t.types[0] unless t.nil? or t.types.nil?
      end
      @return_type
    end

    # @return [YARD::Docstring]
    def docstring
      @docstring ||= @code_object.nil? ? nil : @code_object.docstring
    end

    # @return [String]
    def documentation
      @documentation ||= (docstring.nil? ? '' : @helper.html_markup_rdoc(docstring))
    end

    # @return [Array<String>]
    def params
      if @params.nil?
        @params = []
        return @params if docstring.nil?
        param_tags = docstring.tags(:param)
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

    def inject_detail
    end

    def as_json args = {}
      result = {
        label: @label,
        kind: @kind,
        insert: @insert,
        detail: @detail,
        path: path,
        location: (@location.nil? ? nil : @location.to_s),
        arguments: @arguments,
        params: params,
        return_type: return_type
      }
      result[:documentation] = documentation if args[:detailed]
      result
    end

    def to_json args = {}
      as_json.to_json(args)
    end

    # @param pin [Solargraph::Pin::Base]
    def self.pull pin, return_type = nil
      Suggestion.new(pin.name, insert: pin.name.gsub(/=/, ' = '), kind: pin.kind, docstring: pin.docstring, detail: pin.namespace, arguments: pin.parameters, path: pin.path, return_type: return_type, location: pin.location)
    end
  end

end
