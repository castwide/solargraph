module Solargraph
  module Pin
    # Use this class to track method aliases for later remapping. Common
    # examples are aliases for superclass methods or methods from included
    # modules.
    #
    class MethodAlias < Method
      attr_reader :original

      def initialize location, namespace, name, scope, original
        # @todo Determine how to handle these parameters. Among other things,
        #   determine if the visibility is defined by the location of the
        #   alias call or the original method.
        super(location, namespace, name, '', scope, :public, [])
        @original = original
      end
    end
  end
end
