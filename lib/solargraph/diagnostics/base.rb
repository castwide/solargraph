module Solargraph
  module Diagnostics
    class Base
      # Perform a diagnosis on a Source within the context of an ApiMap.
      # The result is an array of hash objects that conform to the LSP's
      # Diagnostic specification.
      #
      # @param source [Solargraph::Source]
      # @param api_map [Solargraph::ApiMap]
      # @return [Array<Hash>]
      def diagnose source, api_map
      end
    end
  end
end
