# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Base
      # @return [Array<Pin::Base>]
      def pins
        @pins ||= RbsMap::Conversions.new(loader: loader).pins
      end

      # @return [RBS::Repository]
      def repository
        @repository ||= RBS::Repository.new(no_stdlib: true)
      end

      # @return [RBS::EnvironmentLoader]
      def loader
        @loader ||= RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
      end

      # @param path [String]
      # @return [Array<Pin::Base>]
      def path_pins path
        pins.select { |p| p.path == path }
      end

      # @return [Array<Pin::Base>]
      # @sg-ignore https://github.com/castwide/solargraph/issues/1108
      def self.pins(...)
        # @sg-ignore https://github.com/castwide/solargraph/issues/1108
        new(...).pins
      end
    end
  end
end
