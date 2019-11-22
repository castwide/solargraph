module Solargraph
  module Parser
    autoload :CommentRipper, 'solargraph/parser/comment_ripper'
    autoload :Legacy, 'solargraph/parser/legacy'
    autoload :Rubyvm, 'solargraph/parser/rubyvm'
    autoload :Region, 'solargraph/parser/region'
    autoload :NodeProcessor, 'solargraph/parser/node_processor'

    class SyntaxError < StandardError
    end

    # True if the parser can use RubyVM.
    #
    def self.rubyvm?
      # !!defined?(RubyVM::AbstractSyntaxTree)
      false
    end

    selected = rubyvm? ? Rubyvm : Legacy
    include selected
    extend selected::ClassMethods
  end
end
