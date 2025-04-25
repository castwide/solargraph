module Solargraph
  module Parser
    autoload :CommentRipper, 'solargraph/parser/comment_ripper'
    autoload :ParserGem, 'solargraph/parser/parser_gem'
    autoload :Region, 'solargraph/parser/region'
    autoload :NodeProcessor, 'solargraph/parser/node_processor'
    autoload :FlowSensitiveTyping, 'solargraph/parser/flow_sensitive_typing'
    autoload :Snippet, 'solargraph/parser/snippet'

    class SyntaxError < StandardError
    end

    # @deprecated
    Legacy = ParserGem

    ClassMethods = ParserGem::ClassMethods
    # @todo should be able to just 'extend ClassMethods' here and
    #   typecheck things off it in strict mode
    extend ParserGem::ClassMethods

    NodeMethods = ParserGem::NodeMethods
  end
end
