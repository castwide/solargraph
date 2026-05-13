# frozen_string_literal: true

module Solargraph
  module Pin
    module Ephemeral
      class ClassMethodSend < Base # rubocop:disable Style/Documentation
        class ArgumentValue < Struct.new(:value)
          # @!attribute [r] value
          #   - literal, splat or kwargs
          #   @return [String, Integer, Float, nil, true, false, Symbol, Array, Hash]
        end

        # @return [Array<Argument>]
        attr_reader :arguments

        # @return [String]
        attr_reader :code

        # @param name [String] - name of the method called
        # @param comments [String] - name of the method called
        # @param arguments [Array<Argument>] - arguments of the method
        # @param code [String] - code of the method call
        # @param location [Solargraph::Location, nil]
        # @param kind [Integer]
        # @param closure [Solargraph::Pin::Closure, nil]
        def initialize name: '', arguments: [], code:, closure: nil, comments: '', **splat
          super(closure: closure, name: name.to_s, comments: comments, **splat)
          @arguments = arguments
          @code = code
        end

        def path
          @path ||= "#{namespace}.#{name}"
        end

        # @return [Array<String>] - normal, keyword and array arguments as a flat array of strings
        def argument_values
          @arguments.map(&:value).map { |a| Array(a) }.flatten.map(&:to_s)
        end

        # @return [Pin::Method]
        def matches?(method_pin)
          return false unless method_pin.is_a?(Method)

          method_pin.name == name
        end
      end
    end
  end
end
