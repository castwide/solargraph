require 'reverse_markdown'

module Solargraph
  module Pin
    class Base
      include Conversions
      include Documenting

      attr_reader :location

      # @return [String]
      attr_reader :namespace

      attr_reader :name

      attr_reader :docstring

      def initialize location, namespace, name, docstring
        @location = location
        @namespace = namespace
        @name = name
        @docstring = docstring
      end

      # @return [String]
      def path
      end

      # @return [Integer]
      def kind
      end

      # @return [String]
      def return_type
      end

      def to_s
        name.to_s
      end

      def identifier
        @identifier ||= "#{path}|#{name}"
      end

      def variable?
        false
      end
    end
  end
end
