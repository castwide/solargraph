module Solargraph
  module Parser
    module ParserGem
      autoload :FlawedBuilder, 'solargraph/parser/parser_gem/flawed_builder'
      autoload :ClassMethods, 'solargraph/parser/parser_gem/class_methods'
      autoload :NodeMethods, 'solargraph/parser/parser_gem/node_methods'
      autoload :NodeChainer, 'solargraph/parser/parser_gem/node_chainer'
    end
  end
end

require 'solargraph/parser/parser_gem/node_processors'
