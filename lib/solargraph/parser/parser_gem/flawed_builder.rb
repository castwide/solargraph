# frozen_string_literal: true

require 'rubocop-ast'

module Solargraph
  module Parser
    module ParserGem
      # A custom builder for source parsers that ignores character encoding
      # issues in literal strings.
      #
      class FlawedBuilder < ::RuboCop::AST::Builder
        # @param token [::Parser::AST::Node]
        # @return [String]
        # @sg-ignore
        def string_value token
          value(token)
        end
      end
    end
  end
end
