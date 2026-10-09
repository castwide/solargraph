# frozen_string_literal: true

module Solargraph
  module Convention
    # Rails engines keep code under app/, which Zeitwerk loads instead of
    # require. Map the roots Rails::Engine::Configuration#paths autoloads.
    #
    class RailsEngine < Base
      ENGINE_SUPERCLASS = /<\s*(?:::)?Rails::Engine\b/

      # app/* and app/*/concerns, as the "app" path's glob.
      APP_ROOTS = '{*,*/concerns}'

      # Excluded from the "app" path's eager loading.
      NON_RUBY_APP_DIRS = %w[assets javascript].freeze

      MAILER_PREVIEWS = 'test/mailers/previews'

      # @param metagem [Metagem]
      # @return [Array<String>]
      def gem_directories metagem
        app = File.join(metagem.full_path, 'app')
        return [] unless File.directory?(app) && engine?(metagem)

        roots = Dir.glob(File.join(app, APP_ROOTS)).select { |dir| File.directory?(dir) }
        roots = roots.map { |dir| dir.delete_prefix("#{app}/") } - NON_RUBY_APP_DIRS
        roots = roots.sort.map { |dir| File.join('app', dir) }
        roots.push(MAILER_PREVIEWS) if File.directory?(File.join(metagem.full_path, MAILER_PREVIEWS))
        roots
      end

      private

      # Whether the gem's required code subclasses Rails::Engine.
      #
      # @param metagem [Metagem]
      # @return [Boolean]
      def engine? metagem
        metagem.require_paths.any? do |path|
          Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')).any? do |file|
            File.read(file).match?(ENGINE_SUPERCLASS)
          end
        end
      end
    end
  end
end
