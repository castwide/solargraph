# frozen_string_literal: true

require 'parser'

module Solargraph
  class Source
    class Chain
      class Literal < Link
        def word
          @word ||= "<#{@type}>"
        end

        attr_reader :value

        # @param type [String]
        # @param node [Parser::AST::Node, Object]
        def initialize type, node
          if node.is_a?(::Parser::AST::Node)
            @value = node.children.first
          else
            @value = node
          end
          @type = type
          @literal_type = ComplexType.try_parse(@value.inspect)
          @complex_type = ComplexType.try_parse(type)
        end

        def resolve api_map, name_pin, locals
          if api_map.super_and_sub?(@complex_type.name, @literal_type.name)
            [Pin::ProxyType.anonymous(@literal_type)]
          else
            # we don't support this value as a literal type
            [Pin::ProxyType.anonymous(@complex_type)]
          end
        end
      end
    end
  end
end
