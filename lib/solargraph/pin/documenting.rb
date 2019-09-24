# frozen_string_literal: true

require 'redcarpet'
require 'reverse_markdown'

module Solargraph
  module Pin
    # A module to add the Pin::Base#documentation method.
    #
    module Documenting
      # A documentation formatter that either performs Markdown conversion for
      # text, or applies backticks for code blocks.
      #
      class DocSection
        @@markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, lax_spacing: true)

        # @param code [Boolean] True if this section is a code block
        def initialize code
          @text = String.new('')
          @code = code
        end

        def code?
          @code
        end

        def concat text
          @text.concat text
        end

        def to_s
          return "\n```ruby\n#{@text}#{@text.end_with?("\n") ? '' : "\n"}```\n\n" if code?
          ReverseMarkdown.convert @@markdown.render(@text)
        end
      end

      # @return [String]
      def documentation
        @documentation ||= begin
          # Using DocSections allows for code blocks that start with an empty
          # line and at least two spaces of indentation. This is a common
          # convention in Ruby core documentation, e.g., String#split.
          sections = [DocSection.new(false)]
          normalize_indentation(docstring.to_s).gsub(/\t/, '  ').lines.each do |l|
            if l.strip.empty?
              sections.last.concat l
            else
              if (l =~ /^  [^\s]/ && sections.last.to_s =~ /(\r?\n[ \t]*?){2,}$/) || (l.start_with?('  ') && sections.last.code?)
                # Code block
                sections.push DocSection.new(true) unless sections.last.code?
                sections.last.concat l[2..-1]
              else
                # Regular documentation
                sections.push DocSection.new(false) if sections.last.code?
                sections.last.concat l
              end
            end
          end
          sections.map(&:to_s).join
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
