# frozen_string_literal: true

module Solargraph
  module Typedef
    class Filter
      attr_reader :api_map, :pins, :receiver

      def initialize api_map, pins, receiver
        @api_map = api_map
        @pins = if receiver
                  pins.map { |pin| pin.proxy(Expansions::Generics.expand(api_map, pin, receiver).to_complex_type) }
                      .map { |pin| pin.proxy(expand_root(pin, receiver).to_complex_type) }
                      .map { |pin| expand_self(pin, receiver) }
                else
                  pins
                end
        @receiver = receiver
      end

      def typeset
        case pins.first
        when Pin::BaseVariable
          first_declared_or_combined
        when Pin::Method, Pin::Signature
          first_declared_or_inferred
        when Pin::ProxyType
          pins.first.typedef_typeset
        else
          # @todo Check for additional cases
          first_declared_or_inferred
        end
      end

      def proxy
        Pin::ProxyType.anonymous(typeset.to_complex_type)
      end

      private

      # @return [Typeset]
      def first_declared_or_combined
        return first_declared unless first_declared.to_s == 'undefined' # @todo Better way to identify undefined

        inferred = pins.filter_map do |pin|
          inferred = Expansions::Inference.expand(api_map, pin, receiver)
          return inferred if inferred.to_s == 'undefined' # @todo Better way to identify undefined
          inferred
        end

        Typeset.new(inferred)
      end

      # @return [Typeset]
      def first_declared_or_inferred
        return first_declared unless first_declared.to_s == 'undefined' # @todo Better way to identify undefined

        pins.each do |pin|
          inferred = Expansions::Inference.expand(api_map, pin, receiver)
          return inferred unless inferred.to_s == 'undefined' # @todo Better way to identify undefined
        end

        ComplexType::UNDEFINED.to_typedef_typeset
      end

      def first_declared
        @first_declared ||= begin
          # @todo Better way to identify undefined
          found = pins.find { |pin| pin.typedef_typeset.to_s != 'undefined' }
          found&.typedef_typeset || ComplexType::UNDEFINED.to_typedef_typeset
        end
      end

      def expand_root pin, receiver
        pin.typedef_typeset.resolve_rooted(api_map, receiver&.closure&.gates || [''])
      end

      def expand_self pin, receiver
        # @todo A Class#new exception is necessary because the current pin from
        #   RBS core has return type `undefined`. A better solution is a
        #   CoreFills override of `Class#new => self`, but it interferes with
        #   the existing chain inference.
        if pin.path == 'Class#new'
          pin.proxy(Solargraph::ComplexType.parse('::Class'))
        else
          pin.proxy(pin.typedef_typeset.expand({ 'self' => receiver.typedef_typeset }).to_complex_type)
        end
      end
    end
  end
end
