module Solargraph
  class ApiMap
    class Cache
      def initialize
        @signature_types = {}
      end
      def get_signature_type signature, namespace, scope
        @signature_types[[signature, namespace, scope]]
      end
      def set_signature_type signature, namespace, scope, value
        @signature_types[[signature, namespace, scope]] = value
      end
    end
  end
end
