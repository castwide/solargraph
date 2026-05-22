# frozen_string_literal: true

module Solargraph
  module Typedef
    class Type
      attr_reader :base

      attr_reader :params

      # @param base [String, Path, Token]
      # @param params [Array<String, Path, Token>]
      def initialize base, *params
        @base = Typedef.tokenize(base)
        @params = params.map { |par| Typedef.tokenize(par) }
      end

      def resolve_named_tokens(named_values)
        new_base = base.resolve_named_tokens(named_values)
        new_params = params.map { |par| base.resolve_named_tokens(named_values) }
        Type.new(new_base, *new_params)
      end

      # @param api_map [ApiMap]
      # @param api_map [Array<Path>]
      # @return [Type]
      def resolve_rooted(api_map, gates)
        new_base = base.resolve_rooted(api_map, gates)
        new_params = params.map { |par| par.resolve_rooted(api_map, gates) }
        Type.new(new_base, *new_params)
      end

      def resolve(api_map, gates)
        new_base = base.resolve_rooted(api_map, gates)
        return self unless new_base.resolved?

        path_pins = api_map.get_path_pins(new_base.name)
        tokens = path_pins.flat_map(&:generics)
                          .map { |name| "generics[#{name}]" }
        new_generic_values = tokens.zip(params).to_h
        new_params = params.map { |par| par.resolve_named_tokens(new_generic_values).resolve_rooted(api_map, gates) }
        return self unless new_params.all?(&:resolved?)

        Type.new(new_base, *new_params)
      end

      def resolved?
        base.resolved? && params.all?(&:resolved?)
      end

      def to_s
        "#{base}#{params_to_s}"
      end

      # @param [Array<ComplexType>]
      # @retunrn [Array<Type>]
      def self.from_complex_type complex_type
        complex_type.to_typedef_types
      end

      private

      def params_to_s
        return "" if @params.empty?
        "[#{params.join(', ')}]"
      end

      ROOT = Type.new(Path::ROOT)
    end
  end
end
