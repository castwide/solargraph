module Solargraph
  module Pin
    # Use this class to track method aliases for later remapping. Common
    # examples that defer mapping are aliases for superclass methods or
    # methods from included modules.
    #
    class MethodAlias < Base
      attr_reader :scope

      attr_reader :original

      # def initialize location, namespace, name, scope, original
      def initialize scope: :instance, original: nil, **splat
        # @todo Determine how to handle these parameters. Among other things,
        #   determine if the visibility is defined by the location of the
        #   alias call or the original method.
        # super(location, namespace, name, '')
        super(splat)
        @scope = scope
        @original = original
      end

      def kind
        Pin::METHOD_ALIAS
      end

      def path
        @path ||= namespace + (scope == :instance ? '#' : '.') + name
      end
    end
  end
end
