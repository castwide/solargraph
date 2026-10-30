# frozen_string_literal: true

module Solargraph
  module Typedef
    class Concrete < Type
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
        Concrete.new(new_base, *new_params)
      end

      def extract_generics type
        return {} unless any_generic? && type.is_a?(Concrete)

        extracted = base.extract_generics(type.base)
        params.map.with_index { |par, idx| extracted.merge!(par.extract_generics(type.params[idx])) }
        extracted
      end

      # @param api_map [ApiMap]
      # @param gates [Array<String>]
      # @return [Concrete]
      def resolve_rooted api_map, gates
        new_base = base.resolve_rooted(api_map, gates)
        new_params = params.map { |par| par.resolve_rooted(api_map, gates) }
        Concrete.new(new_base, *new_params)
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

      # A Concrete is a single member from the any/all-of-immediate-members
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

      def undefined?
        to_s == 'undefined'
      end

      def defined?
        !undefined?
      end

      def flat_types
        [self]
      end

      # A lone type has one member, so there is one pair to make.
      #
      # @param other [Type]
      # @yieldparam mine [self]
      # @yieldparam theirs [Type]
      # @yieldreturn [Type]
      # @return [Type]
      def combine_via other
        yield self, other
      end

      # A lone type has no members to reorder.
      #
      # @return [self]
      def order_nil_last
        self
      end

      # A concrete type is its own only part, so the block decides it
      # directly.
      #
      # @yieldparam named_type [Concrete]
      # @yieldreturn [Concrete, nil]
      # @return [Concrete, nil]
      def qualify_parts
        yield self
      end

      # Every definition of +method_name+ on this type, of any visibility,
      # highest precedence first; empty when the method does not resolve.
      #
      # @param api_map [ApiMap]
      # @param method_name [String]
      # @return [Array<Pin::Method>]
      def reachable_method_stack api_map, method_name
        receiver = class_object_of || self
        api_map.get_method_stack(receiver.base.to_s, method_name,
                                 scope: receiver.equal?(self) ? :instance : :class)
      end

      # Yields this type and its definitions of +word+, and returns what
      # the block gives; undefined, without yielding, when this type does
      # not resolve +word+.
      #
      # @param word [String]
      # @param api_map [ApiMap]
      # @yieldparam receiver [Concrete]
      # @yieldparam pins [Array<Pin::Base>]
      # @yieldreturn [Type]
      # @return [Type]
      def call_type word, api_map
        # A call dispatches to the highest-precedence definition only
        pins = reachable_method_stack(api_map, word).first(1)
        return Union::UNDEFINED if pins.empty?

        yield self, pins
      end

      # Every method reachable on a value of this type, of any visibility:
      # the class methods of Foo for Class[Foo], otherwise the instance
      # methods of this type.
      #
      # @param api_map [ApiMap]
      # @return [Array<Pin::Method>]
      def reachable_methods api_map
        return [] if undefined? || to_s == 'void'

        receiver = class_object_of || self
        api_map.get_methods(receiver.base.to_s,
                            scope: receiver.equal?(self) ? :instance : :class,
                            visibility: %i[public protected private])
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

      ROOT = Concrete.new(Path::ROOT)
      UNDEFINED = Concrete.new(Typedef.tokenize('undefined'))

      private

      # The type this one is the class object of: Foo for Class[Foo] or
      # Module[Foo]. A bare Class, or one over several types, names no one
      # type.
      #
      # @return [Concrete, nil]
      def class_object_of
        return nil unless class? && params.length == 1

        param = params.first
        return Concrete.new(param) if param.is_a?(Path)
        return nil unless param.is_a?(Type)

        members = param.flat_types
        members.first if members.length == 1
      end

      def params_to_s
        return '' if params.empty?
        "#{brackets.first}#{params.join(', ')}#{brackets.last}"
      end

      def params_to_s_for_complex_type
        return '' if @params.empty?
        "<#{params.map(&:to_s_for_complex_type).join(', ')}>"
      end
    end
  end
end
