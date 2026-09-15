# frozen_string_literal: true

require 'open3'
require 'fileutils'

module Solargraph
  # Methods for caching and loading YARD documentation for gems.
  #
  module Yardoc2
    extend self

    def path_for metagem
      File.join(CacheDir.yard_dir, "#{metagem.cache_name}.yardoc")
    end

    # @param metagem [Metagem]
    # @return [String]
    def cache metagem
      path = path_for(metagem)

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
    def uncache metagem
      FileUtils.rm_f path_for(metagem)
    end

    # @param metagem [Metagem]
    def cached? metagem
      yardoc = File.join(path_for(metagem), 'complete')
      File.exist?(yardoc)
    end
    alias exist? cached?

    # True if another process is currently building the yardoc cache.
    #
    # @param metagem [Metagem]
    def processing? metagem
      yardoc = File.join(path_for(metagem), 'processing')
      File.exist?(yardoc)
    end

    # Load a gem's yardoc cache and return its code objects.
    #
    # @note This method modifies the global YARD registry.
    #
    # @param metagem [Metagem]
    # @return [Array<YARD::CodeObjects::Base>]
    def load! metagem
      YARD::Registry.load! path_for(metagem)
      YARD::Registry.all
    end
  end
end
