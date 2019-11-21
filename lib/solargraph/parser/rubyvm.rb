module Solargraph
  module Parser
    module Rubyvm
      autoload :ClassMethods, 'solargraph/parser/rubyvm/class_methods'
    end
  end
end

require 'solargraph/parser/rubyvm/node_processors'
