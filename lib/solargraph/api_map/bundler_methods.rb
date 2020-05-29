require 'bundler'
require 'shellwords'

module Solargraph
  class ApiMap
    module BundlerMethods
      module_function

      # @param directory [String]
      # @return [Hash]
      def require_from_bundle directory
        @require_from_bundle ||= begin
          Solargraph.logger.info "Loading gems for bundler/require"
          Documentor.specs_from_bundle(directory)
        rescue BundleNotFoundError => e
          Solargraph.logger.warn e.message
          {}
        end
      end

      # @return [void]
      def reset_require_from_bundle
        @require_from_bundle = nil
      end
    end
  end
end
