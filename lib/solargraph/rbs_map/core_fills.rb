module Solargraph
  class RbsMap
    module CoreFills
      class Stub
        attr_reader :parameters

        attr_reader :return_type

        def initialize parameters, return_type
          @parameters = parameters
          @return_type = return_type
        end
      end

      SIGNATURE_MAP = {
        'Object#class' => [
          Stub.new(
            [],
            'Class<self>'
          )
        ]
      }

      def self.fill path
        SIGNATURE_MAP[path]
      end
    end
  end
end
