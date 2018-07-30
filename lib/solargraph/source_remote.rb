module Solargraph
  class SourceRemote < Solargraph::Source
    class << self
      # In the parent class this method does a blocking laod and returns
      # the file contents which is not possible with the async network
      # loading done by this sub-class. The only way to create a new
      # SourceRemote instance is to pass in the file content with load_string.
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
