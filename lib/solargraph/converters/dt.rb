module ReverseMarkdown
  module Converters
    class Dt < Base
      def convert node, state = {}
        state.merge!(first_definition: true)
        content = treat_children(node, state)
        "| #{content.strip} |"
      end
    end
  end
end

ReverseMarkdown::Converters.register :dt, ReverseMarkdown::Converters::Dt.new
