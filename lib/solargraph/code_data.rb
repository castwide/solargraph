module Solargraph

  class CodeData
    CLASS = 'Class',
    KEYWORD = 'Keyword',
    MODULE = 'Module',
    METHOD = 'Method',
    VARIABLE = 'Variable'
    SNIPPET = 'Snippet'

    attr_reader :label, :kind, :insert, :detail

    def initialize label, kind: KEYWORD, insert: nil, detail: nil
      @label = label.to_s
      @kind = kind
      @insert = insert || @label
      @detail = detail
    end
    
    def to_s
      label
    end

    def to_json
      {
        label: @label,
        kind: @kind,
        insert: @insert,
        detail: @detail,
      }.to_json
    end
  end

end
