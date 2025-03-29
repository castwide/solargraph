# frozen_string_literal: true

require 'kramdown'
require 'kramdown-parser-gfm'
require 'yard'
require 'reverse_markdown'
require 'solargraph/converters/dl'
require 'solargraph/converters/dt'
require 'solargraph/converters/dd'
require 'solargraph/converters/misc'

module Solargraph
  module Pin
    # A module to add the Pin::Base#documentation method.
    #
    module Documenting
      # A documentation formatter that either performs Markdown conversion for
      # text, or applies backticks for code blocks.
      #
      class DocSection
        # @return [String]
        attr_reader :plaintext

        # @param code [Boolean] True if this section is a code block
        def initialize code
          @plaintext = String.new('')
          @code = code
        end

        def code?
          @code
        end

        # @param text [String]
        # @return [String]
        def concat text
          @plaintext.concat text
        end

        def to_s
          return to_code if code?
          to_markdown
        end

        private

        # @return [String]
        def to_code
          "\n```ruby\n#{Documenting.normalize_indentation(@plaintext)}#{@plaintext.end_with?("\n") ? '' : "\n"}```\n\n"
        end

        # @return [String]
        def to_markdown
          ReverseMarkdown.convert Kramdown::Document.new(@plaintext, input: 'GFM').to_html
        end
      end

      # @return [String]
      def documentation
        @documentation ||= begin
          # Using DocSections allows for code blocks that start with an empty
          # line and at least two spaces of indentation. This is a common
          # convention in Ruby core documentation, e.g., String#split.
          sections = [DocSection.new(false)]
          Documenting.normalize_indentation(Documenting.strip_html_comments(docstring.to_s.gsub("\t", '  '))).lines.each do |l|
            if l.start_with?('  ')
              # Code block
              sections.push DocSection.new(true) unless sections.last.code?
            elsif sections.last.code?
              # Regular documentation
              sections.push DocSection.new(false)
            end
            sections.last.concat l
          end
          sections.map(&:to_s).join.strip
        end
      end

      def self.strip_html_comments text
        text.gsub(/<!--([\s\S]*?)-->/, '').strip
      end

      # @param text [String]
      # @return [String]
      def self.normalize_indentation text
        left = text.lines.map do |line|
          match = line.match(/^ +/)
          next 0 unless match
          match[0].length
        end.min
        return text if left.nil? || left.zero?
        text.lines.map { |line| line[left..] }.join
      end
    end
  end
end
