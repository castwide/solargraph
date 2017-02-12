module Solargraph

  class CodeData
    CLASS = 'Class',
    KEYWORD = 'Keyword',
    MODULE = 'Module',
    METHOD = 'Method',
    VARIABLE = 'Variable'
    SNIPPET = 'Snippet'

    attr_reader :label, :insert, :kind, :detail, :label, :snippet

    def initialize label, kind: KEYWORD, insert: nil, detail: nil, snippet: nil
      @label = label.to_s
      @insert = insert || @label
      @kind = kind
      @detail = detail
      @snippet = snippet
    end
    
    def to_s
      label
    end

    def to_json
      {
        text: @text,
        kind: @kind,
        detail: @detail,
        label: @label,
        snippet: @snippet
      }.to_json
    end
  end

end
