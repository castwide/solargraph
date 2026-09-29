# frozen_string_literal: true

module Solargraph
  module RbsMap
    module Helpers
      module_function

      # Pin types whose YARD and RBS pins should merge via #combine_with
      # rather than one side simply winning. A namespace carries generic
      # parameters that only RBS states, so picking one side loses them.
      #
      # @return [Array<Class>]
      def combinable_pin_types
        [Pin::Method, Pin::Namespace]
      end

      # @param  orig_pins [Array<Pin::Base>]
      # @param rbs_pins [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def combine orig_pins, rbs_pins
        in_orig = Set.new
        # @todo There's gotta be a better way!
        rbs_api_map = Solargraph::ApiMap.new(pins: rbs_pins)
        combined = orig_pins.map do |orig_pin|
          in_orig.add orig_pin.path
          next orig_pin unless combinable_pin_types.any? { |type| orig_pin.instance_of?(type) }

          # Match the same pin type: a namespace must not be combined with
          # a method that happens to share its path.
          rbs_pin = rbs_api_map.get_path_pins(orig_pin.path).find { |pin| pin.instance_of?(orig_pin.class) }
          unless rbs_pin
            Solargraph.logger.debug { "Helpers.combine: No rbs pin for #{orig_pin.path} - using #{orig_pin.inspect}" }
            next orig_pin
          end

          out = combine_pins(rbs_pin, orig_pin)
          Solargraph.logger.debug { "Helpers.combine: Combining path=#{orig_pin.path} - rbs=#{rbs_pin.inspect} with orig=#{orig_pin.inspect} into #{out}" }
          out
        end
        in_rbs_only = rbs_pins.select do |pin|
          pin.path.nil? || !in_orig.include?(pin.path)
        end
        out = combined + in_rbs_only
        Solargraph.logger.debug { "Helpers#combine: Returning #{out.length} combined pins" }
        out
      end

      # @param pins [Array<Pin::Base>]
      # @return [Pin::Base, nil]
      def combine_pins(*pins)
        # @type [Pin::Base, nil]
        combined_pin = nil
        # @param memo [Pin::Base, nil]
        # @param pin [Pin::Base]
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
        Solargraph.logger.debug { "Helpers.combine_pins(pins.length=#{pins.length}, pins=#{pins}) => #{out.inspect}" }
        out
      end
    end
  end
end
