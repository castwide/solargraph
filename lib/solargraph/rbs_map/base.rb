# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Base
      def pins
        @pins ||= RbsMap::Conversions.new(loader: loader).pins
      end

      # @return [RBS::Repository]
      def repository
        @repository ||= RBS::Repository.new(no_stdlib: false)
      end

      # @return [RBS::EnvironmentLoader]
      def loader
        @loader ||= RBS::EnvironmentLoader.new(core_root: nil, repository: repository)
      end

      # @param path [String]
      # @return [Pin::Base, nil]
      def path_pin path
        pins.find { |p| p.path == path }
      end

      def self.pins(...)
        new(...).pins
      end
    end
  end
end
