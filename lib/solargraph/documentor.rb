# frozen_string_literal: true

require 'bundler'

module Solargraph
  class Documentor
    RDOC_GEMS = %w[
      actioncable actionmailbox actionmailer actionpack actiontext actionview
      activejob activemodel activerecord activestorage activesupport railties
    ]

    def initialize directory, rebuild: false
      @directory = directory
      @rebuild = rebuild
    end

    # @return [Boolean] True if all specs were found and documented.
    def document
      failures = 0
      Dir.chdir @directory do
        Bundler.with_clean_env do
          Bundler.reset!
          lockfile = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))
          # @param spec [Gem::Specification]
          lockfile.specs.each do |spec|
            real = spec.__materialize__
            if real.nil?
              puts "WARNING: #{spec.name} #{spec.version} not found"
              failures += 1
              next
            end
            yd = YARD::Registry.yardoc_file_for_gem(real.name, real.version)
            if !yd || @rebuild
              puts "Documenting #{real.name} #{real.version}"
              `yard gems #{real.name} #{real.version} #{@rebuild ? '--rebuild' : ''}`
            end
            if RDOC_GEMS.include?(spec.name)
              cache = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{real.name}-#{real.version}", 'yardoc')
              next if File.exist?(cache) && !@rebuild
              puts "Caching custom documentation for #{real.name} #{real.version}"
              Solargraph::YardMap::RdocToYard.run(real)
            end
          end
        end
      end
      Bundler.reset!
      if failures > 0
        puts "#{failures} spec#{failures == 1 ? '' : 's'} could not be found. You might need to run `bundle install` first."
      end
      failures == 0
    end
  end
end
