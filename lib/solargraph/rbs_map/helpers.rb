# frozen_string_literal: true

module Solargraph
  module RbsMap
    module Helpers
      module_function

      # @param yard_pins [Array<Pin::Base>]
      # @param rbs_pins [Array<Pin::Base>]
      #
      # @return [Array<Pin::Base>]
      def combine yard_pins, rbs_pins
        in_yard = Set.new
        # @todo There's gotta be a better way!
        rbs_api_map = Solargraph::ApiMap.new(pins: rbs_pins)
        combined = yard_pins.map do |yard_pin|
          in_yard.add yard_pin.path
          rbs_pin = rbs_api_map.get_path_pins(yard_pin.path).filter { |pin| pin.is_a? Pin::Method }.first
          next yard_pin unless rbs_pin && yard_pin.instance_of?(Pin::Method)

          unless rbs_pin
            # @sg-ignore https://github.com/castwide/solargraph/pull/1114
            Solargraph.logger.debug { "GemPins.combine: No rbs pin for #{yard_pin.path} - using YARD's '#{yard_pin.inspect} (return_type=#{yard_pin.return_type}; signatures=#{yard_pin.signatures})" }
            next yard_pin
          end

          out = combine_method_pins(rbs_pin, yard_pin)
          Solargraph.logger.debug { "GemPins.combine: Combining yard.path=#{yard_pin.path} - rbs=#{rbs_pin.inspect} with yard=#{yard_pin.inspect} into #{out}" }
          out
        end
        in_rbs_only = rbs_pins.select do |pin|
          pin.path.nil? || !in_yard.include?(pin.path)
        end
        out = combined + in_rbs_only
        Solargraph.logger.debug { "GemPins#combine: Returning #{out.length} combined pins" }
        out
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
