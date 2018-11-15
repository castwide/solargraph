module Solargraph
  class SourceMap
    class Region
      # @return [String]
      attr_reader :filename

      # @return [String]
      attr_reader :namespace

      # @return [Symbol]
      attr_reader :scope

      # @return [Symbol]
      attr_reader :visibility

      attr_reader :stack

      attr_reader :comments

      # @param filename [String, nil]
      # @param namespace [String]
      # @param scope [Symbol]
      # @param visibility [Symbol]
      # @param comments [Array]
      def initialize filename: nil, namespace: '', scope: :instance, visibility: :public, comments: []
        @filename = filename
        @namespace = namespace
        @scope = scope
        @visibility = visibility
        @comments = comments
      end

      # Generate a new Region with the provided attribute changes.
      #
      def update filename: nil, namespace: nil, scope: nil, visibility: nil, comments: nil
        Region.new(
          filename: filename || self.filename,
          namespace: namespace || self.namespace,
          scope: scope || self.scope,
          visibility: visibility || self.visibility,
          comments: comments || self.comments
        )
      end
    end
  end
end
