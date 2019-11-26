module Solargraph
  module Parser
    module Rubyvm
      autoload :ClassMethods, 'solargraph/parser/rubyvm/class_methods'
      autoload :NodeChainer,  'solargraph/parser/rubyvm/node_chainer'
    end
  end
end

require 'solargraph/parser/rubyvm/node_processors'
