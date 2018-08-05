module Solargraph
  module Pin
    class DuckMethod < Pin::Method
      attr_reader :scope
      attr_reader :visibility
      attr_reader :parameters

      def initialize location, name
        super(location, 'Object', name, nil, :instance, :public, [])
      end
    end
  end
end
