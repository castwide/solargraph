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
        # @sg-ignore https://github.com/ruby/gem_rbs_collection/pull/1104
        def string_value token
          value(token)
        end
      end
    end
  end
end
