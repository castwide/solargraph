# frozen_string_literal: true

module Solargraph
  module Typedef
    # Reduce an array of pins and their receiver to a typeset or proxy pin.
    #
    # The Dictionary determines the selection of pins that can define the
    # return type of a given Chain. The Filter collates them into a single
    # Typeset.
    #
    class Filter
      attr_reader :api_map, :pins, :receiver

      # @param api_map [ApiMap]
      # @param pins [Array<Pin::Base>]
      # @param receiver [Pin::Closure]
      # @param infer [Boolean]
      def initialize api_map, pins, receiver, infer: true
        @api_map = api_map
        @pins = if receiver
                  pins.map { |pin| pin.proxy(Expansions::Generics.expand(api_map, pin, receiver).to_complex_type) }
                      .map { |pin| pin.proxy(expand_root(pin, receiver).to_complex_type) }
                      .map { |pin| pin.proxy(pin.typedef_typeset.expand({ 'self' => receiver.typedef_typeset }).to_complex_type) }
                else
                  pins
                end
        @receiver = receiver
        @infer = infer
      end

      def infer?
        @infer
      end

      # @return [Typeset]
      def typeset
        case pins.first
        when Pin::BaseVariable
          first_declared_or_combined
        when Pin::ProxyType
          pins.first.typedef_typeset
        else
          # @todo Handles methods. Check for other exceptions
          first_declared_or_inferred
        end
      end

      # @return [Pin::ProxyType]
      def proxy
        Pin::ProxyType.anonymous(typeset.to_complex_type, closure: receiver)
      end

      private

      # @return [Typeset]
      def first_declared_or_combined
        return first_declared if first_declared.defined? || !infer?

        inferred = pins.filter_map do |pin|
          inferred = Expansions::Inference.expand(api_map, pin, receiver)
          return inferred if inferred.undefined?
          inferred
        end

        Union.new(inferred)
      end

      # @return [Typeset]
      def first_declared_or_inferred
        return declared_types if declared_types.defined? || !infer?

        pins.each do |pin|
          inferred = Expansions::Inference.expand(api_map, pin, receiver)
          return inferred if inferred.defined?
        end

        ComplexType::UNDEFINED.to_typedef_typeset
      end

      # The types declared by the pins. A method called on a union of types is
      # resolved for each member of the union, and each member contributes its
      # own type, e.g., +nil?+ returns +true+ for +nil+ and +false+ for every
      # other type.
      #
      # @return [Typeset]
      def declared_types
        @declared_types ||= begin
          declared = union_receiver? ? pins.map(&:typedef_typeset).select(&:defined?) : []
          declared.empty? ? first_declared : Typeset.new(declared)
        end
      end

      # @return [Boolean]
      def union_receiver?
        return false if receiver.nil?

        ComplexType.new([receiver.context]).to_typedef_typeset.types.length > 1
      end

      def first_declared
        @first_declared ||= begin
          found = pins.find { |pin| pin.typedef_typeset.defined? }
          found&.typedef_typeset || ComplexType::UNDEFINED.to_typedef_typeset
        end
      end

      def expand_root pin, receiver
        pin.typedef_typeset.resolve_rooted(api_map, receiver&.closure&.gates || [''])
      end
    end
  end
end
