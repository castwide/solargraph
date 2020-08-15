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
    # @return [void]
    def self.register convention
      @@conventions.add convention.new
    end

    # @param source [Source]
    # @return [Environ]
    def self.for(source)
      result = Environ.new
      return result if source.filename.nil? || source.filename.empty?
      @@conventions.each do |conv|
        result.merge conv.environ if conv.match?(source)
      end
      result
    end

    register Gemfile
    register Gemspec
    register Rspec
  end
end
