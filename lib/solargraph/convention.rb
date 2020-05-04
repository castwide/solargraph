# frozen_string_literal: true

require 'set'

module Solargraph
  # Conventions provide a way to modify an ApiMap based on expectations about
  # one of its sources.
  #
  module Convention
    autoload :Base,    'solargraph/convention/base'
    autoload :Gemfile, 'solargraph/convention/gemfile'
    autoload :Rspec,   'solargraph/convention/rspec'
    autoload :Gemspec, 'solargraph/convention/gemspec'

    @@conventions = Set.new

    # @param convention [Class<Convention::Base>]
    # @return [Convention::Base]
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

    # @param api_map [ApiMap]
    # @return [Environ]
    def self.for_global(api_map)
      result = Environ.new
      @@conventions.each do |conv|
        result.merge conv.global(api_map)
      end
      result
    end

    register Gemfile
    register Gemspec
    register Rspec
  end
end
