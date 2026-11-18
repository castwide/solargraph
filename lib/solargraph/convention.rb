# frozen_string_literal: true

module Solargraph
  # Conventions provide a way to modify an ApiMap based on expectations about
  # one of its sources.
  #
  module Convention
    autoload :Base,    'solargraph/convention/base'
    autoload :Gemfile, 'solargraph/convention/gemfile'
    autoload :Gemspec, 'solargraph/convention/gemspec'
    autoload :Rakefile, 'solargraph/convention/rakefile'

    # @type [Set<Convention::Base>]
    @@conventions = Set.new

    # @param convention [Class<Convention::Base>]
    # @return [void]
    def self.register convention
      @@conventions.add convention.new
    end

    # @param convention [Class<Convention::Base>]
    # @return [void]
    def self.unregister convention
      @@conventions.delete_if { |c| c.is_a?(convention) }
    end

    # The gems other than Solargraph that define the registered conventions,
    # keyed like {Workspace#plugin_versions}. A Workspace with no directory
    # has no config naming its plugins, so it uses these to pick its gem
    # cache directory. A convention's gem is the loaded gem whose directory
    # holds the file that defines the convention's class.
    #
    # @return [Hash{String => String}] gem name => version
    def self.plugin_versions
      @@conventions.to_a.filter_map do |conv|
        name = conv.class.name
        next if name.nil?
        file = Object.const_source_location(name)&.first
        next if file.nil?
        spec = Gem.loaded_specs.values.find { |s| file.start_with?(File.join(s.full_gem_path, '')) }
        next if spec.nil? || spec.name == 'solargraph'
        [spec.name, spec.version.to_s]
      end.to_h
    end

    # @param source_map [SourceMap]
    # @return [Environ]
    def self.for_local source_map
      result = Environ.new
      @@conventions.each do |conv|
        result.merge conv.local(source_map)
      end
      result
    end

    # @todo Determine what argument needs to be passed here
    #
    # @param object [Object]
    # @return [Environ]
    def self.for_global object
      result = Environ.new
      @@conventions.each do |conv|
        result.merge conv.global(object)
      end
      result
    end

    # Provides any additional method pins based on the described object.
    #
    # @param api_map [ApiMap]
    # @param rooted_tag [String] A fully qualified namespace, with
    #   generic parameter values if applicable
    # @param scope [Symbol] :class or :instance
    # @param visibility [Array<Symbol>] :public, :protected, and/or :private
    # @param deep [Boolean]
    # @param skip [Set<String>]
    # @param no_core [Boolean] Skip core classes if true
    #
    # @return [Environ]
    def self.for_object api_map, rooted_tag, scope, visibility,
                        deep, skip, no_core
      result = Environ.new
      @@conventions.each do |conv|
        result.merge conv.object(api_map, rooted_tag, scope, visibility,
                                 deep, skip, no_core)
      end
      result
    end

    register Gemfile
    register Gemspec
    register Rakefile
  end
end
