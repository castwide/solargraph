module Solargraph
  module Pin
    # Use this class to track method aliases for later remapping. Common
    # examples are aliases for superclass methods or methods from included
    # modules.
    #
    class MethodAlias < Method
      def initialize location, namespace, name, scope
        # @todo Determine how to handle these parameters. Among other things,
        #   determine if the visibility is defined by the location of the
        #   alias call or the original method.
        super(location, namespace, name, '', scope, :public, [])
      end
    end
  end
end
