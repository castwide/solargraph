require 'bundler'
require 'shellwords'

module Solargraph
  class ApiMap
    module BundlerMethods
      module_function

      def require_from_bundle directory
        @require_from_bundle ||= begin
          Solargraph.logger.info "Loading gems for bundler/require"
          Bundler.with_clean_env do
            specs = `cd #{Shellwords.escape(directory)} && bundle exec ruby -e "require 'bundler'; puts Bundler.definition.specs_for([:default]).map(&:name)"`
            if specs
              specs.lines.map(&:strip).reject(&:nil?)
            else
              []
            end
          end
        end
      end

      def reset_require_from_bundle
        @require_from_bundle = nil
      end
    end
  end
end
