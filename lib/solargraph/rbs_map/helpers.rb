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
        # Index these pins rather than looking them up through an ApiMap,
        # which also loads Ruby core: for a method a gem adds to a core
        # class, core's pin would be found instead of the gem's, and the
        # gem's signature dropped.
        rbs_methods_by_path = rbs_pins.select { |pin| pin.is_a?(Pin::Method) }.group_by(&:path)
        combined = orig_pins.map do |orig_pin|
          in_orig.add orig_pin.path
          rbs_pin = rbs_methods_by_path[orig_pin.path]&.first
          next orig_pin unless rbs_pin && orig_pin.instance_of?(Pin::Method)

          unless rbs_pin
            # @sg-ignore https://github.com/castwide/solargraph/pull/1114
            Solargraph.logger.debug { "GemPins.combine: No rbs pin for #{orig_pin.path} - using YARD's '#{orig_pin.inspect} (return_type=#{orig_pin.return_type}; signatures=#{orig_pin.signatures})" }
            next orig_pin
          end

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

      # Combine method pins sharing a path. Core and a gem that reopens a
      # core class are cached separately, so a method described by both
      # only meets here.
      #
      # @param pins [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def combine_method_pins_by_path pins
        method_pins, other_pins = pins.partition { |pin| pin.instance_of?(Pin::Method) }
        by_path = method_pins.group_by(&:path)
        by_path.transform_values! { |same_path| combine_method_pins(*same_path) }
        by_path.values + other_pins
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
          if memo == pin && memo.to_rbs == pin.to_rbs && memo.source != :combined
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
