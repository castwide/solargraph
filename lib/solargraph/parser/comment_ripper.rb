# frozen_string_literal: true

require 'ripper'

module Solargraph
  module Parser
    class CommentRipper < Ripper::SexpBuilderPP
      # @!override Ripper::SexpBuilder#on_embdoc_beg
      #   @return [Array(Symbol, String, Array)]
      # @!override Ripper::SexpBuilder#on_embdoc
      #   @return [Array(Symbol, String, Array)]
      # @!override Ripper::SexpBuilder#on_embdoc_end
      #   @return [Array(Symbol, String, Array)]
      # @!override Ripper::SexpBuilder#on_comment
      #   @return [Array(Symbol, String, Array(Integer, Integer))]

      # @param src [String]
      # @param filename [String]
      # @param lineno [Integer]
      def initialize src, filename = '(ripper)', lineno = 0
        super
        @buffer = src
        @buffer_lines = @buffer.lines
      end

      def on_comment *args
        # @sg-ignore https://github.com/castwide/solargraph/pull/1364
        # @type [Array(Symbol, String, Array(Integer, Integer))]
        result = super
        # @sg-ignore Need to add nil check here
        if @buffer_lines[result[2][0]][0..result[2][1]].strip =~ /^#/
          # @sg-ignore Literal index into a tuple returns every element type plus nil
          chomped = result[1].chomp
          # @sg-ignore Literal index into a tuple returns every element type plus nil
          if result[2][0].zero? && chomped.encode('UTF-8', 'binary', invalid: :replace, undef: :replace,
                                                                     replace: '').match(/^#\s*frozen_string_literal:/)
            chomped = '#'
          end
          # @sg-ignore Literal index into a tuple returns every element type plus nil
          @comments[result[2][0]] =
            # @sg-ignore Literal index into a tuple returns every element type plus nil
            Snippet.new(Range.from_to(result[2][0], result[2][1], result[2][0], result[2][1] + chomped.length), chomped)
        end
        result
      end

      # @param result [Array(Symbol, String, Array([Integer, nil], [Integer, nil]))]
      # @return [void]
      def create_snippet result
        # @sg-ignore Literal index into a tuple returns every element type plus nil
        chomped = result[1].chomp
        # @sg-ignore Literal index into a tuple returns every element type plus nil
        @comments[result[2][0]] =
          Snippet.new(
            # @sg-ignore Literal index into a tuple returns every element type plus nil
            Range.from_to(result[2][0] || 0, result[2][1] || 0, result[2][0] || 0,
                          # @sg-ignore Literal index into a tuple returns every element type plus nil
                          (result[2][1] || 0) + chomped.length), chomped
          )
      end

      # @sg-ignore https://github.com/castwide/solargraph/pull/1104
      def on_embdoc_beg *args
        result = super
        # @sg-ignore https://github.com/castwide/solargraph/pull/1364
        create_snippet(result)
        result
      end

      # @sg-ignore https://github.com/castwide/solargraph/pull/1104
      def on_embdoc *args
        result = super
        # @sg-ignore https://github.com/castwide/solargraph/pull/1364
        create_snippet(result)
        result
      end

      # @sg-ignore https://github.com/castwide/solargraph/pull/1104
      def on_embdoc_end *args
        result = super
        # @sg-ignore https://github.com/castwide/solargraph/pull/1364
        create_snippet(result)
        result
      end

      # @return [Hash{Integer => Solargraph::Parser::Snippet}]
      def parse
        @comments = {}
        super
        @comments
      end
    end
  end
end
