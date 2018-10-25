require 'rdoc'
require 'reverse_markdown'
require 'kramdown'

module Solargraph
  module Pin
    # A module to add the Pin::Base#documentation method.
    #
    module Documenting
      # @return [String]
      def documentation
        @documentation ||= begin
          html = Kramdown::Document.new(
            normalize_indentation(docstring.to_s),
            input: 'GFM',
            entity_output: :symbolic,
            syntax_highlighter: nil
          ).to_html
          ReverseMarkdown.convert(html, github_flavored: true)
        end
      end

      private

      # @param text [String]
      # @return [String]
      def normalize_indentation text
        lines = text.lines.map do |line|
          (line =~ /^   [^\s]/ ? line[1..-1] : line).gsub(/^  /, "\t")
        end
        lines.join
      end
    end
  end
end
