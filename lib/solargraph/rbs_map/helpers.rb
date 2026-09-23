# frozen_string_literal: true

module Solargraph
  module RbsMap
    module Helpers
      module_function

      # @param  orig_pins [Array<Pin::Base>]
      # @param rbs_pins [Array<Pin::Base>]
      # @return [Array<Pin::Base>]
      def combine  orig_pins, rbs_pins
        in_orig = Set.new
        # @todo There's gotta be a better way!
        rbs_api_map = Solargraph::ApiMap.new(pins: rbs_pins)
        combined =  orig_pins.map do |orig_pin|
          in_orig.add orig_pin.path
          rbs_pin = rbs_api_map.get_path_pins(orig_pin.path).filter { |pin| pin.is_a? Pin::Method }.first
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
