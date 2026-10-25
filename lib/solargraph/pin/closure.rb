# frozen_string_literal: true

module Solargraph
  module Pin
    class Closure < CompoundStatement
      # @return [::Symbol] :class or :instance
      attr_reader :scope

      # Override the pin's scope.
      #
      # Scope is normally determined by the syntax that declared the pin, but
      # YARD's `@!scope` directive can change it after the fact. Any values
      # derived from the scope, such as the pin's path and context, are
      # recalculated.
      #
      # @param scope [::Symbol] :class or :instance
      # @return [void]
      def scope= scope
        return if @scope == scope

        @scope = scope
        # remove cached values generated from scope
        reset_generated!
      end

      # @param scope [::Symbol] :class or :instance
      # @param generics [::Array<Pin::String>, nil]
      # @param generic_defaults [Hash{String => ComplexType}]
      # @param [Hash{Symbol => Object}] splat
      def initialize scope: :class, generics: nil, generic_defaults: {}, **splat
        super(**splat)
        @scope = scope
        @generics = generics
        @generic_defaults = generic_defaults
      end

      # @return [Hash{String => ComplexType}]
      def generic_defaults
        @generic_defaults ||= {}
      end

      # @param other [self]
      # @param attrs [Hash{Symbol => Object}]
      #
      # @return [self]
      def combine_with other, attrs = {}
        new_attrs = {
          scope: assert_same(other, :scope),
          generics: generics.empty? ? other.generics : generics
        }.merge(attrs)
        super(other, new_attrs)
      end

      def context
        @context ||= begin
          result = super
          if scope == :instance
            result.reduce_class_type
          else
            result
          end
        end
      end

      # Downcast vars FlowSensitiveTyping recorded in this closure for
      # repeatable call chains, by chain, e.g. [self, location] after
      # `return unless location` or [pin, location] after
      # `return unless pin.location`; see Chain::Call#narrowed_call_pin
      #
      # @return [Hash{Array<String> => Array<Pin::LocalVariable>}]
      def downcast_vars
        @downcast_vars || {}
      end

      # @param path [::Array<String>]
      # @param var [Pin::LocalVariable]
      # @return [void]
      def add_downcast_var path, var
        ((@downcast_vars ||= ChainFacts.new)[path] ||= []).push(var)
      end

      # Downcast vars come from parsing this closure, so gem pin caches leave them out
      class ChainFacts < ::Hash
        # @return [::Array]
        def marshal_dump
          []
        end

        # @param _data [::Array]
        # @return [void]
        def marshal_load _data; end
      end

      # @param api_map [Solargraph::ApiMap]
      # @return [void]
      def rebind api_map; end

      # True once #rebind found a different self for this closure
      def rebound?
        false
      end

      # @return [::Array<String>]
      def generics
        @generics ||= docstring.tags(:generic).map(&:name)
      end

      def to_rbs
        rbs_generics + return_type.to_rbs
      end

      # @return [String]
      def rbs_generics
        return '' if generics.empty?

        "[#{generics.map(&:to_s).join(', ')}] "
      end
    end
  end
end
