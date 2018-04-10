module Solargraph
  module Pin
    class Reference
      attr_reader :pin
      attr_reader :name

      def initialize pin, name
        @pin = pin
        @name = name
        @resolved = false
      end

      def resolve api_map
        unless @resolved
          @resolved = true
          @name = api_map.find_fully_qualified_namespace(@name, pin.namespace)
        end
      end
    end
  end
end
