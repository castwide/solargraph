module ReverseMarkdown
  module Converters
    class Dd < Base
      def convert node, state = {}
        content = treat_children(node, state)
        if state[:first_definition]
          " #{content.strip} |\n"
        else
          state.merge!(first_definition: false)
          "|   | #{content.strip} |\n"
        end
      end
    end
  end
end

ReverseMarkdown::Converters.register :dd, ReverseMarkdown::Converters::Dd.new
