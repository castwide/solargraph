# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Hash < Literal
        # @param type [String]
        # @param node [Parser::AST::Node]
        # @param splatted [Boolean]
        def initialize type, node, splatted = false
          super(type, node)
          @splatted = splatted
        end

        def word
          @word ||= "<#{@type}>"
        end

        def resolve api_map, name_pin, locals
          [Pin::ProxyType.anonymous(@complex_type, source: :chain)]
        end

        def splatted?
          @splatted
        end

        protected

        # @sg-ignore https://github.com/castwide/solargraph/pull/1245
        def equality_fields
          # @sg-ignore https://github.com/castwide/solargraph/pull/1223
          super + [@splatted]
        end
      end
    end
  end
end
