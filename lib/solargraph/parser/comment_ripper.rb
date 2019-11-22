require 'ripper'

module Solargraph
  module Parser
    class CommentRipper < Ripper::SexpBuilder
      def on_comment *args
        result = super
        @comments[result[2][0]] = result[1] if result[1][0..result[2][1]].strip =~ /$#?/
        result
      end

      def on_embdoc_beg *args
        result = super
        @comments[result[2][0]] = ''
        result
      end

      def on_embdoc *args
        result = super
        @comments[result[2][0]] = result[1]
        result
      end

      def on_embdoc_end *args
        result = super
        @comments[result[2][0]] = ''
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
