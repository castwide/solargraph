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
            if node.type == :true
              @value = true
            elsif node.type == :false
              @value = false
            elsif [:int, :sym].include?(node.type)
              @value = node.children.first
            end
          end
          @type = type
          @literal_type = ComplexType.try_parse(@value.inspect)
          @complex_type = ComplexType.try_parse(type)
        end

        # @sg-ignore Fix "Not enough arguments to Module#protected"
        protected def equality_fields
          super + [@value, @type, @literal_type, @complex_type]
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
