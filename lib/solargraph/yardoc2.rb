# frozen_string_literal: true

require 'open3'

module Solargraph
  # Methods for caching and loading YARD documentation for gems.
  #
  module Yardoc2
    module_function

    # @param metagem [Metagem]
    # @return [String]
    def cache metagem
      path = PinCache2.yardoc_path(metagem)
      Solargraph.logger.info "Caching yardoc for #{metagem.cache_name}"
      cmd = "yardoc --db #{path} --no-output --plugin solargraph"
      Solargraph.logger.debug "Running: #{cmd}"
      output, status = Open3.capture2e(cmd, chdir: metagem.full_path)
      unless status.success?
        Solargraph.logger.warn { "YARD failed running #{cmd.inspect} in #{metagem.full_path}" }
        Solargraph.logger.info output
      end
      path
    end

    # @param metagem [Metagem]
    def cached? metagem
      yardoc = File.join(PinCache2.yardoc_path(metagem), 'complete')
      File.exist?(yardoc)
    end

    # Load a gem's yardoc cache and return its code objects.
    #
    # @note This method modifies the global YARD registry.
    #
    # @param metagem [Metagem]
    # @return [Array<YARD::CodeObjects::Base>]
    def load! metagem
      YARD::Registry.load! PinCache2.yardoc_path(metagem)
      YARD::Registry.all
    end
  end
end
