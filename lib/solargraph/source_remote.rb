module Solargraph
  class SourceRemote < Solargraph::Source
    class << self
      # @param filename [String]
      # @return [Solargraph::Source]
      def load filename
      	raise NoMethodError.new "load not supported when using remote files"
      end

      # @param code [String]
      # @param filename [String]
      # @return [Solargraph::Source]
      def load_string code, filename = nil
        SourceRemote.new code, filename
      end
    end
  end
end