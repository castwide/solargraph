module Solargraph
  module Parser
    module Rubyvm
      autoload :ClassMethods, 'solargraph/parser/rubyvm/class_methods'
      autoload :NodeChainer,  'solargraph/parser/rubyvm/node_chainer'
      autoload :NodeMethods,  'solargraph/parser/rubyvm/node_methods'
    end
  end
end

require 'solargraph/parser/rubyvm/node_processors'
