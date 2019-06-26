require 'bundler'

module Solargraph
  class ApiMap
    module BundlerMethods
      module_function

      def require_from_bundle directory
        return [] unless File.file?(File.join(directory, 'Gemfile.lock'))
        result = []
        begin
          Solargraph.logger.info "Using bundler/require"
          Dir.chdir directory do
            result.concat(Bundler.with_clean_env do
              Bundler.definition.specs_for([:default]).map(&:name)
            end)
            Bundler.reset!
          end
          result
        rescue Bundler::GemfileNotFound => e
          Solargraph.logger.info "[#{e.class}] #{e.message}"
          result
        end
      end
    end
  end
end
