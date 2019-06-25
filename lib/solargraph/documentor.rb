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

    def document
      Dir.chdir @directory do
        Bundler.with_clean_env do
          Bundler.reset!
          lockfile = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))
          # @param spec [Gem::Specification]
          lockfile.specs.each do |spec|
            spec = spec.__materialize__
            yd = YARD::Registry.yardoc_file_for_gem(spec.name, spec.version)
            if !yd || @rebuild
              puts "Documenting #{spec.name} #{spec.version}"
              `yard gems #{spec.name} #{spec.version} #{@rebuild ? '--rebuild' : ''}`
            end
            if RDOC_GEMS.include?(spec.name)
              cache = File.join(Solargraph::YardMap::CoreDocs.cache_dir, 'gems', "#{spec.name}-#{spec.version}", 'yardoc')
              next if File.exist?(cache) && !@rebuild
              puts "Caching custom documentation for #{spec.name} #{spec.version}"
              Solargraph::YardMap::RdocToYard.run(spec)
            end
          end
        end
      end
      Bundler.reset!
    end
  end
end
