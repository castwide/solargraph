# frozen_string_literal: true

require 'reverse_markdown'

module Solargraph
  module Pin
    # A module to add the Pin::Base#documentation method.
    #
    module Documenting
      # @return [String]
      def documentation
        @documentation ||= begin
          indented = false
          normalize_indentation(docstring.to_s).gsub(/\t/, '  ').lines.map { |l|
            next l if l.strip.empty?
            if l =~ /^  [^\s]/ || (l.start_with?(' ') && indented)
              indented = true
              "  #{l}"
            else
              indented = false
              l # (was `unhtml l`)
            end
          }.join
        end
      end

      private

      # @param text [String]
      # @return [String]
      def normalize_indentation text
        text.lines.map { |l| remove_odd_spaces(l) }.join
      end

      # @param line [String]
      # @return [String]
      def remove_odd_spaces line
        return line unless line.start_with?(' ')
        spaces = line.match(/^ +/)[0].length
        return line unless spaces.odd?
        line[1..-1]
      end

      # @todo This was tested as a simple way to convert some of the more
      #   common markup in documentation to Markdown. We should still look
      #   for a solution, but it'll have to be more robust than this.
      def unhtml text
        text.gsub(/\<\/?(code|tt)\>/, '`')
            .gsub(/\<\/?(em|i)\>/, '*')
            .gsub(/\<\/?(strong|b)\>/, '**')
      end
    end
  end
end
