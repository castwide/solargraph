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
    autoload :StructDefinition, 'solargraph/convention/struct_definition'
    autoload :DataDefinition,   'solargraph/convention/data_definition'
    autoload :ActiveSupportConcern, 'solargraph/convention/active_support_concern'

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

    # @param root [String] the gem's root directory
    # @param require_paths [Array<String>] the gem's require paths, relative to root
    # @return [Array<String>] paths inside the gem, relative to root, to map beyond require_paths
    def self.extra_source_paths root:, require_paths:
      @@conventions.flat_map do |conv|
        conv.extra_source_paths(root: root, require_paths: require_paths)
      end.uniq
    end

    register Gemfile
    register Gemspec
    register Rakefile
    register ActiveSupportConcern
  end
end
