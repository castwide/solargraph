require 'json'

module Solargraph

  class Suggestion
    CLASS = 'Class'
    KEYWORD = 'Keyword'
    MODULE = 'Module'
    METHOD = 'Method'
    VARIABLE = 'Variable'
    SNIPPET = 'Snippet'

    attr_reader :label, :kind, :insert, :detail, :documentation

    def initialize label, kind: KEYWORD, insert: nil, detail: nil, documentation: nil
      @label = label.to_s
      @kind = kind
      @insert = insert || @label
      @detail = detail
      @documentation = documentation
    end
    
    def to_s
      label
    end

    def to_json args={}
      {
        label: @label,
        kind: @kind,
        insert: @insert,
        detail: @detail,
        documentation: (@documentation.nil? ? nil : @documentation.all)
      }.to_json(args)
    end
  end

end
