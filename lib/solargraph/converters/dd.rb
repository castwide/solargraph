module ReverseMarkdown
  module Converters
    class Dd < Base
      # @return [String]
      # @param node [Nokogiri::XML::Element]
      # @param state [Hash]
      def convert node, state = {}
        content = treat_children(node, state)
        ": #{content.strip}\n"
      end
    end
  end
end

ReverseMarkdown::Converters.register :dd, ReverseMarkdown::Converters::Dd.new
