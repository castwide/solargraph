# frozen_string_literal: true

require 'rdoc'
require 'reverse_markdown'
require 'maruku'

module Solargraph
  module Pin
    # A module to add the Pin::Base#documentation method.
    #
    module Documenting
      # @return [String]
      def documentation
        @documentation ||= begin
          html = Maruku.new(normalize_indentation(docstring.to_s)).to_html
          ReverseMarkdown.convert(html, github_flavored: true).lines.map(&:rstrip).join("\n")
        end
      end

      private

      # @param text [String]
      # @return [String]
      def normalize_indentation text
        text.lines.map { |l| remove_odd_spaces(l).gsub(/^  /, "\t") }.join
      end

      # @param line [String]
      # @return [String]
      def remove_odd_spaces line
        return line unless line.start_with?(' ')
        spaces = line.match(/^ +/)[0].length
        return line unless spaces.odd?
        line[1..-1]
      end
    end
  end
end
