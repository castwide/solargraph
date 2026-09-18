# frozen_string_literal: true

module Solargraph
  # @todo This class might need a way to track changes to the repo, e.g.,
  #   bundle or dependency updates
  #
  class External
    autoload :Core,   'solargraph/external/core'
    autoload :Gem,    'solargraph/external/gem'
    autoload :Stdlib, 'solargraph/external/stdlib'

    # @param directory [String]
    # @param requires [Array<String>]
    def initialize directory, requires
      @repo = Repo.new(directory)
      @directory = directory
      update requires
    end

    def requires
      @requires ||= []
    end

    def unresolved_requires
      @unresolved_requires ||= []
    end

    def unresolved_dependencies
      @unresolved_dependencies ||= []
    end

    def loaded_gems
      @loaded_gems ||= []
    end

    def unloaded_gems
      @unloaded_gems ||= []
    end

    def pins
      @pins ||= []
    end

    # @param new_requires [Array<String>]
    # @return [Boolean]
    def update new_requires
      return false if requires == new_requires

      requires.replace new_requires
      load_requires
      true
    end

    private

    def load_requires
      pins.clear
      unresolved_requires.clear
      unresolved_dependencies.clear
      loaded_gems.clear
      unloaded_gems.clear

      bundler_require = true
      requires.each do |path|
        if path == 'bundler/require'
          bundler_require = true
        end
        if RbsMap::Stdlib.has?(path)
          Stdlib.pins(path)
        else
          metagem = @repo.find_by_path(path)
          next unresolved_requires.push(path) unless metagem
          process_gem metagem
        end
      end

      if bundler_require
        @repo.bundled.each do |metagem|
          next if loaded_gems.include?(metagem) || unloaded_gems.include?(metagem)
          process_gem metagem
        end
      end
    end

    def process_gem metagem
      if metagem.cacheable?
        if Gem.cached?(metagem)
          pins.concat Gem.pins(metagem)
          loaded_gems.push metagem
        else
          unloaded_gems.push metagem
        end
      else
        pins.concat Gem.pins(metagem)
        loaded_gems.push metagem
      end
      load_dependencies metagem
    end

    # @param metagem [Metagem]
    # @return [void]
    # def process_cached_gem(metagem)
    #   if GemCache.exist?(metagem)
    #     pins.concat GemCache.load(metagem)
    #     loaded_gems.push metagem
    #   else
    #     unloaded_gems.push metagem
    #   end
    # end

    # @param metagem [Metagem]
    # @return [void]
    # def process_uncached_gem(metagem)
    #   files = metagem.require_paths.flat_map { |path| Dir.glob(File.join(metagem.full_path, path, '**', '*.rb')) }
    #   source_maps = files.map { |file| Solargraph::SourceMap.load(file) }
    #   source_pins = source_maps.flat_map(&:pins)
    #   rbs_pins = RbsMap::Gem.pins(metagem)
    #   combined = GemPins.combine(source_pins, rbs_pins)
    #   pins.concat combined
    #   loaded_gems.push metagem
    # end

    def load_dependencies parent
      parent.dependencies.each do |name|
        next if loaded_gems.map(&:name).include?(name) || unloaded_gems.map(&:name).include?(name)
        metagem = @repo.find_by_name(name)
        next unresolved_dependencies.push(name) unless metagem
        process_gem metagem
      end
    end
  end
end
