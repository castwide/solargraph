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
        lockfile = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile))
        # @param spec [Gem::Specification]
        lockfile.specs.each do |spec|
          spec = spec.__materialize__
          puts "Documenting #{spec.name} #{spec.version}"
          `yard gems #{spec.name} #{spec.version} #{@rebuild ? '--rebuild' : ''}`
          if RDOC_GEMS.include?(spec.name)
            puts "  Caching custom documentation"
            Solargraph::YardMap::RdocToYard.run(spec)
          end
        end
      end
    end
  end
end
