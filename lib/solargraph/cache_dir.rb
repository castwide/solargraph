# frozen_string_literal: true

require 'fileutils'

module Solargraph
  module CacheDir
    module_function

    # The base directory for cached YARD documentation and serialized pins.
    #
    # @return [String]
    def base_dir
      ENV['SOLARGRAPH_CACHE'] ||
        (ENV['XDG_CACHE_HOME'] ? File.join(ENV['XDG_CACHE_HOME'], 'solargraph') : nil) ||
        File.join(Dir.home, '.cache', 'solargraph')
            .tap { |dir| FileUtils.mkdir_p(dir) unless File.exist?(dir) }
    end

    # The working directory for the current Ruby, RBS, and Solargraph versions.
    #
    # @return [String]
    def work_dir
      File.join(base_dir, "ruby-#{RUBY_VERSION}", "rbs-#{RBS::VERSION}", "solargraph-#{Solargraph::VERSION}")
          .tap { |dir| FileUtils.mkdir_p(dir) unless File.exist?(dir) }
    end

    # The directory for the current YARD version.
    #
    # @return [String]
    def yard_dir
      File.join(base_dir, "yard-#{YARD::VERSION}", "yard-activesupport-concern-#{YARD::ActiveSupport::Concern::VERSION}")
          .tap { |dir| FileUtils.mkdir_p(dir) unless File.exist?(dir) }
    end
  end
end
