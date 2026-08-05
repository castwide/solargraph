# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      # A method parameter represented as a link in a method call chain.
      #
      # @example
      #   some_method('literal_value')
      #                ^^^^^^^^^^^^^
      class Parameter < Link
        # @param literal [Chain::Literal] - literal argument
        # @param method_call_chain [Chain] method call that contains the argument
        def initialize literal, method_call_chain # rubocop:disable Lint/MissingSuper
          @literal = literal
          @method_call_chain = method_call_chain
        end

        def word
          @word ||= "#{method_name}(.., #{@literal.word}, ..)"
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Parameter, Pin::LocalVariable>]
        # @return [::Array<Pin::Base>]
        def resolve api_map, name_pin, locals
          # @type [Pin::Method]
          method_pin = method_call_chain.define(api_map, name_pin, locals)&.first
          return [] unless method_pin

          # Use indexed lookup for better performance
          api_map.factory_parameters_for_method(method_pin).select do |fp|
            param_index = method_pin.parameters.find_index { |param| param.name == fp.param_name }
            next if param_index.nil?

            fp.value == literal_value && current_index == param_index
          end
        end

        # @return [Boolean] true if this is a parameter of Kernel#require
        def require_parameter?
          method_call_chain.links.last.word == 'require'
        end

        private

        # @return [Chain::Literal]
        attr_reader :literal
        # @ return [Chain]
        attr_reader :method_call_chain

        # @return [String] The name of the method that this parameter belongs to
        def method_name
          @method_name ||= method_call.word
        end

        # @return [Chain::Call]
        def method_call
          @method_call_chain.links.last
        end

        # The index of the literal in the method call chain.
        # @return [Integer]
        def current_index
          @current_index ||= method_call_chain.node.children[2..].index(literal.node)
        end

        # @return [::String, ::Symbol] The literal value of the parameter
        # @sg-ignore false "return type could not be inferred"
        def literal_value
          literal.node.children.first
        end
      end
    end
  end
end
