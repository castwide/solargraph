# frozen_string_literal: true

module Solargraph
  module Typedef
    class Type
      attr_reader :base

      attr_reader :params

      # @param base [Path, Token]
      # @param params [Array<Path, Token, Typeset>]
      def initialize base, *params
        @base = Typedef.tokenize(base)
        @params = params.map { |par| Typedef.tokenize(par) }
      end

      def expand(named_values)
        new_base = base.expand(named_values)
        new_params = params.map { |par| par.expand(named_values) }
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

      def resolved?
        base.resolved? && params.all?(&:resolved?)
      end

      def scope
        %w[Class Module].include?(base.to_s) ? :class : :instance
      end

      def class?
        scope == :class
      end

      def instance?
        scope == :instance
      end

      def expanded?
        base.expanded? && params.all?(&:expanded?)
      end

      def generic?
        all.any?(&:generic?)        
      end

      def nullable?
        base.to_s == 'nil'
      end

      def to_s
        "#{base}#{params_to_s}"
      end

      def to_complex_type
        if params.empty?
          ComplexType.try_parse(base.to_s_for_complex_type)
        else
          ComplexType.try_parse("#{base.to_s_for_complex_type}<#{params.map(&:to_s_for_complex_type).join(', ')}>")
        end
      end

      def to_s_for_complex_type
        "#{base.to_s_for_complex_type}#{params_to_s_for_complex_type}"
      end

      def all
        [base] + params
      end

      # @param [ComplexType]
      # @return [Array<Type>]
      def self.from_complex_type complex_type
        complex_type.to_typedef_types
      end

      private

      def params_to_s
        return "" if @params.empty?
        "[#{params.join(', ')}]"
      end

      def params_to_s_for_complex_type
        return "" if @params.empty?
        "[#{params.map(&:to_s_for_complex_type).join(', ')}]"
      end

      ROOT = Type.new(Path::ROOT)
    end
  end
end
