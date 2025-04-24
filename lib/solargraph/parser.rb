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

    ClassMethods = ParserGem::ClassMethods

    # @deprecated
    Legacy = ParserGem

    extend ParserGem::ClassMethods

    NodeMethods = ParserGem::NodeMethods
  end
end
