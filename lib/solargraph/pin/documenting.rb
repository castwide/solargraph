require 'rdoc'
require 'reverse_markdown'
require 'kramdown'

module Solargraph
  module Pin
    module Documenting
      class AdjustedPre < ReverseMarkdown::Converters::Pre
        def convert(node, state = {})
          orig = super
          content = orig.lines[0..2].join
          orig.lines[3..-2].each do |line|
            content += line[1..-1]
          end
          content += orig.lines.last
          content
        end
      end
      private_constant :AdjustedPre
      ReverseMarkdown::Converters.register :pre, AdjustedPre.new

      # @return [String]
      def documentation
        @documentation ||= begin
          html = Kramdown::Document.new(
            docstring.to_s.lines.map{|l| l.gsub(/^  /, "\t")}.join,
            input: 'GFM',
            entity_output: :symbolic,
            syntax_highlighter: nil
          ).to_html
          ReverseMarkdown.convert(html, github_flavored: true)
        end
      end
    end
  end
end
