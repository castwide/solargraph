# frozen_string_literal: true

module Solargraph
  module Parser
    module ParserGem
      # A custom builder for source parsers that ignores character encoding
      # issues in literal strings.
      #
      class FlawedBuilder < ::Parser::Builders::Default
        # @param token [::Parser::AST::Node]
        # @return [String]
        # @sg-ignore parser gem's Builders::Default#value has no return type
        def string_value token
          value(token)
        end
      end
    end
  end
end
