# frozen_string_literal: true

module Solargraph
  module Yardoc
    module_function

    # Build and cache a gem yardoc.
    #
    # @param gemspec [Gem::Specification]
    # @return [void]
    def build(gemspec)
      Solargraph.logger.info "Caching yardoc for #{gemspec.name} #{gemspec.version}"
      Dir.chdir gemspec.gem_dir do
        `yardoc --db #{path_for(gemspec)} --no-output --plugin solargraph`
      end
      # rbs_map = RbsMap.new(gemspec.name)
      # methods = rbs_map.pins.select { |pin| pin.is_a?(Pin::Method) }
      # puts methods.map(&:path)
      # puts "RBS has #{rbs_map.pins.length} pins"
    end

    # @param gemspec [Gem::Specification]
    def cached?(gemspec)
      yardoc = File.join(path_for(gemspec), 'complete')
      File.exist?(yardoc)
    end

    # Get the absolute path for a cached gem yardoc.
    #
    # @param gemspec [Gem::Specification]
    # @return [String]
    def path_for(gemspec)
      File.join(Solargraph::Cache.work_dir, 'gems', "#{gemspec.name}-#{gemspec.version}.yardoc")
    end

    def load!(gemspec)
      YARD::Registry.load! path_for(gemspec)
    end
  end
end
