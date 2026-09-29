# frozen_string_literal: true

module Solargraph
  module RbsMap
    module Helpers
      module_function

      # @param  orig_pins [Array<Pin::Base>]
      # @param rbs_pins [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def combine orig_pins, rbs_pins
        in_orig = Set.new
        rbs_methods = method_pins_by_path(rbs_pins)
        combined =  orig_pins.map do |orig_pin|
          in_orig.add orig_pin.path
          # An ApiMap answers this too, but it indexes the core pins ahead of
          # the pins it was given, and building one per call costs far more
          # than the lookups save. Core first preserves which one it picks.
          rbs_pin = core_method_pins[orig_pin.path] || rbs_methods[orig_pin.path]
          next orig_pin unless rbs_pin && orig_pin.instance_of?(Pin::Method)

          out = combine_method_pins(rbs_pin, orig_pin)
          Solargraph.logger.debug { "GemPins.combine: Combining yard.path=#{orig_pin.path} - rbs=#{rbs_pin.inspect} with yard=#{orig_pin.inspect} into #{out}" }
          out
        end
        in_rbs_only = rbs_pins.select do |pin|
          pin.path.nil? || !in_orig.include?(pin.path)
        end
        out = combined + in_rbs_only
        Solargraph.logger.debug { "GemPins#combine: Returning #{out.length} combined pins" }
        out
      end

      # The core pins never change, so index them once for every caller.
      #
      # @return [Hash{String => Pin::Method}]
      def core_method_pins
        @core_method_pins ||= method_pins_by_path(Collection::Core.load)
      end

      # The first method pin at a path wins, matching what an ApiMap returns.
      #
      # Aliases are left out. MethodAlias subclasses Method, and combining one
      # in place of its target gives a pin whose closure is an alias rather
      # than a method. Resolving it needs an ApiMap, so the original pin is
      # kept instead.
      #
      # @param pins [Enumerable<Pin::Base>]
      # @return [Hash{String => Pin::Method}]
      def method_pins_by_path pins
        # @type [Hash{String => Pin::Method}]
        by_path = {}
        pins.each do |pin|
          next unless pin.is_a?(Pin::Method)
          next if pin.is_a?(Pin::MethodAlias)

          path = pin.path
          next if path.nil? || by_path.key?(path)

          by_path[path] = pin
        end
        by_path
      end

      # @param pins [Array<Pin::Method>]
      # @return [Pin::Method, nil]
      def combine_method_pins(*pins)
        # @type [Pin::Method, nil]
        combined_pin = nil
        # @param memo [Pin::Method, nil]
        # @param pin [Pin::Method]
        out = pins.reduce(combined_pin) do |memo, pin|
          next pin if memo.nil?
          if memo == pin && memo.source != :combined
            # @todo we should track down situations where we are handled
            #   the same pin from the same source here and eliminate them -
            #   this is an efficiency workaround for now
            next memo
          end
          memo.combine_with(pin)
        end
        Solargraph.logger.debug { "GemPins.combine_method_pins(pins.length=#{pins.length}, pins=#{pins}) => #{out.inspect}" }
        out
      end
    end
  end
end
