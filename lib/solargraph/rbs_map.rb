# frozen_string_literal: true

require 'rbs'

module Solargraph
  class RbsMap
    autoload :Conversions, 'solargraph/rbs_map/conversions'
    autoload :CoreMap,     'solargraph/rbs_map/core_map'
    autoload :CoreFills,   'solargraph/rbs_map/core_fills'
    autoload :CoreSigns,   'solargraph/rbs_map/core_signs'
    autoload :StdlibMap,   'solargraph/rbs_map/stdlib_map'

    include Conversions

    # @type [Hash{String => RbsMap}]
    @@rbs_maps_hash = {}

    attr_reader :library

    # @param library [String]
    def initialize library, version = nil
      @library = library
      @version = version
      @collection = nil
      loader = RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
      add_library loader, library, version
      return unless resolved?
      load_environment_to_pins(loader)
    end

    # @generic T
    # @param path [String]
    # @param klass [Class<generic<T>>]
    # @return [generic<T>, nil]
    def path_pin path, klass = Pin::Base
      pin = pins.find { |p| p.path == path }
      pin if pin&.is_a?(klass)
    end

    # @param path [String]
    # @return [Array<Pin::Base>]
    def path_pins path
      pins.select { |p| p.path == path }
    end

    def resolved?
      @resolved
    end

    def repository
      @repository ||= RBS::Repository.new(no_stdlib: false)
    end

    # @param library [String]
    # @return [RbsMap]
    def self.load library
      @@rbs_maps_hash[library] ||= RbsMap.new(library)
    end

    def self.from_gemspec(gemspec)
      RbsMap.new(gemspec.name, gemspec.version)
    end

    private

    # @param loader [RBS::EnvironmentLoader]
    # @param library [String]
    # @return [Boolean] true if adding the library succeeded
    def add_library loader, library, version
      @resolved = if loader.has_library?(library: library, version: version)
        loader.add library: library, version: version
        Solargraph.logger.info "#{short_name} successfully loaded library #{library}"
        true
      else
        Solargraph.logger.debug "#{short_name} failed to load library #{library}"
        false
      end
    end

    # @return [String]
    def short_name
      self.class.name.split('::').last
    end
  end
end
