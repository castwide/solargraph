module Solargraph
  class Source
    # A custom builder for source parsers that ignores character encoding
    # issues in literal strings.
    #
    class FlawedBuilder < Parser::Builders::Default
      def string_value(token)
        value(token)
      end
    end
    private_constant :FlawedBuilder
  end
end
