# frozen_string_literal: true

module Solargraph
  module Typedef
    class Unique < Type
      attr_reader :base, :params

      # @param base [Path, Token]
      # @param params [Array<Path, Token, Type>]
      def initialize base, *params
        super()
        @base = Typedef.tokenize(base)
        @params = params.map { |par| Typedef.tokenize(par) }
      end

      def expand named_values
        new_base = base.expand(named_values)
        new_params = params.map { |par| par.expand(named_values) }
        Unique.new(new_base, *new_params)
      end

      def extract_generics type
        return {} unless any_generic? && type.is_a?(Unique)

        extracted = base.extract_generics(type.base)
        params.map.with_index { |par, idx| extracted.merge!(par.extract_generics(type.params[idx])) }
        extracted
      end

      # @param api_map [ApiMap]
      # @param gates [Array<String>]
      # @return [Unique]
      def resolve_rooted api_map, gates
        new_base = base.resolve_rooted(api_map, gates)
        new_params = params.map { |par| par.resolve_rooted(api_map, gates) }
        Unique.new(new_base, *new_params)
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

      # @return [Boolean] true if base or any param contains a generic
      #   placeholder anywhere in its own structure
      def any_generic?
        all.any?(&:any_generic?)
      end

      # A Unique is a single member from the any/all-of-immediate-members
      # question (see Type), so the two coincide for it.
      # @return [Boolean]
      def all_generic?
        any_generic?
      end

      def nullable?
        base.to_s == 'nil'
      end

      def rooted?
        all.all?(&:rooted?)
      end

      def flat_types
        [self]
      end

      def to_s
        "#{base}#{params_to_s}"
      end

      def to_complex_type
        if params.empty?
          ComplexType.try_parse(base.to_s_for_complex_type)
        elsif base.to_s == 'Hash'
          ComplexType.try_parse("#{base.to_s_for_complex_type}{#{params.first.to_s_for_complex_type} => #{params.last.to_s_for_complex_type}}")
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

      # @return [Array<String>]
      def brackets
        ['[', ']']
      end

      private

      def params_to_s
        return '' if params.empty?
        "#{brackets.first}#{params.join(', ')}#{brackets.last}"
      end

      def params_to_s_for_complex_type
        return '' if @params.empty?
        "<#{params.map(&:to_s_for_complex_type).join(', ')}>"
      end

      ROOT = Unique.new(Path::ROOT)
      UNDEFINED = Unique.new(Typedef.tokenize('undefined'))
    end
  end
end
