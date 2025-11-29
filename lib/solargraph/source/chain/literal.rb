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
            # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
            if node.type == :true
              @value = true
            # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
            elsif node.type == :false
              @value = false
            # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
            elsif [:int, :sym].include?(node.type)
              # @sg-ignore flow sensitive typing needs to narrow down type with an if is_a? check
              @value = node.children.first
            end
          end
          @type = type
          # @sg-ignore flow sensitive typing needs to handle ivars
          @literal_type = ComplexType.try_parse(@value.inspect)
          @complex_type = ComplexType.try_parse(type)
        end

        # @sg-ignore Fix "Not enough arguments to Module#protected"
        protected def equality_fields
          # @sg-ignore literal arrays in this module turn into ::Solargraph::Source::Chain::Array
          super + [@value, @type, @literal_type, @complex_type]
        end

        def resolve api_map, name_pin, locals
          if api_map.super_and_sub?(@complex_type.name, @literal_type.name)
            [Pin::ProxyType.anonymous(@literal_type, source: :chain)]
          else
            # we don't support this value as a literal type
            [Pin::ProxyType.anonymous(@complex_type, source: :chain)]
          end
        end
      end
    end
  end
end
