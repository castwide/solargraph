module Solargraph
  class Source
    class FlawedBuilder < Parser::Builders::Default
      def string_value(token)
        value(token)
      end
    end
    private_constant :FlawedBuilder
  end
end
