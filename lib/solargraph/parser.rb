module Solargraph
  module Parser
    autoload :Legacy, 'solargraph/parser/legacy'
    autoload :Rubyvm, 'solargraph/parser/rubyvm'
    autoload :Region, 'solargraph/parser/region'

    class SyntaxError < StandardError
    end

    def self.rubyvm?
      # !!defined?(RubyVM::AbstractSyntaxTree)
      false
    end

    if rubyvm?
      include Rubyvm
      extend Rubyvm::ClassMethods
    else
      include Legacy
      extend Legacy::ClassMethods
    end
  end
end
