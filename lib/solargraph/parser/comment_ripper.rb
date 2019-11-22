require 'ripper'

module Solargraph
  module Parser
    class CommentRipper < Ripper::SexpBuilder
      def on_comment *args
        result = super
        # @comments[result[2][0]] = result[1] if result[1][0..result[2][1]].strip =~ /$#?/
        if result[1][0..result[2][1]].strip =~ /$#?/
          chomped = result[1].chomp
          @comments[result[2][0]] = Snippet.new(Range.from_to(result[2][0], result[2][1], result[2][0], result[2][1] + chomped.length), chomped)
        end
        result
      end

      def on_embdoc_beg *args
        result = super
        chomped = result[1].chomp
        @comments[result[2][0]] = Snippet.new(Range.from_to(result[2][0], result[2][1], result[2][0], result[2][1] + chomped.length), chomped)
        result
      end

      def on_embdoc *args
        result = super
        chomped = result[1].chomp
        @comments[result[2][0]] = Snippet.new(Range.from_to(result[2][0], result[2][1], result[2][0], result[2][1] + chomped.length), chomped)
        result
      end

      def on_embdoc_end *args
        result = super
        chomped = result[1].chomp
        @comments[result[2][0]] = Snippet.new(Range.from_to(result[2][0], result[2][1], result[2][0], result[2][1] + chomped.length), chomped)
        result
      end

      def parse
        @comments = {}
        super
        @comments
      end
    end
  end
end
