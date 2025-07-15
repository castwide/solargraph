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

    # @param source_map [SourceMap]
    # @return [Environ]
    def self.for_local(source_map)
      result = Environ.new
      @@conventions.each do |conv|
        result.merge conv.local(source_map)
      end
      result
    end

    # @param doc_map [DocMap]
    # @return [Environ]
    def self.for_global(doc_map)
      result = Environ.new
      @@conventions.each do |conv|
        result.merge conv.global(doc_map)
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
    register ActiveSupportConcern
  end
end
