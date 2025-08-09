# frozen_string_literal: true

module Solargraph
  module Pin
    class FactoryParameter < Base
      # @return [String]
      attr_reader :method_name
      # @return [String]
      attr_reader :method_namespace
      # @return [Symbol] :class or :instance
      attr_reader :method_scope
      # @return [String, nil]
      attr_reader :param_name
      # @return [::String, ::Symbol] The literal value
      attr_reader :value
      # @return decl [::Symbol] :arg, :optarg, :kwarg, :kwoptarg, :restarg, :kwrestarg, :block, :blockarg
      attr_reader :decl
      # @return [Location, nil]
      attr_reader :location

      # @param method_name [String] The name of the method that this parameter belongs to
      # @param method_namespace [String] The class of the method that this parameter belongs to
      # @param method_scope [Symbol] The scope of the method, either :class or :instance
      # @param param_name [String, nil] The name of the parameter
      # @param value [String, Symbol] The value of the parameter
      # @param decl [::Symbol] :arg, :kwarg
      # @param location [Location, nil] The location of the parameter in the source code
      def initialize(
        method_name:,
        method_namespace:,
        method_scope:,
        param_name:,
        value:,
        return_type:,
        decl: :arg,
        location: nil
      )
        super(location: location)
        @method_name = method_name
        @method_namespace = method_namespace
        @method_scope = method_scope
        @param_name = param_name
        @value = value
        @decl = decl
        @return_type = return_type
      end

      def name
        param_name
      end

      def text_documentation
        "#{method_path}(#{param_name}) = #{value.inspect}"
      end

      # @return [String]
      def method_path
        @method_path ||= "#{method_namespace}#{(method_scope == :instance ? '#' : '.')}#{method_name}"
      end

      private

      def inner_desc
        "method_path=#{method_path}, value=#{value.inspect}, decl=#{decl.inspect}, return_type=#{return_type&.to_s || 'nil'}"
      end
    end
  end
end
