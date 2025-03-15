# frozen_string_literal: true

require 'rbs'

module Solargraph
  module GemPins
    module_function

    # @param gemspec [Gem::Specification]
    # @return [Array<Pin::Base>]
    def build(gemspec)
      Yardoc.cache(gemspec) unless Yardoc.cached?(gemspec)
      yardoc = Yardoc.load!(gemspec)
      yard_pins = YardMap::Mapper.new(yardoc, gemspec).map
      rbs_map = RbsMap.from_gemspec(gemspec)
      in_yard = Set.new
      combined = yard_pins.map do |yard|
        in_yard.add yard.path
        next yard unless yard.is_a?(Pin::Method)
        rbs = rbs_map.path_pin(yard.path)
        next yard unless rbs
        # @todo Could not include: attribute and anon_splat
        # @sg-ignore
        yard.class.new(
          location: yard.location,
          closure: yard.closure,
          name: yard.name,
          comments: yard.comments,
          scope: yard.scope,
          parameters: rbs.parameters,
          generics: rbs.generics,
          node: yard.node,
          signatures: yard.signatures,
          return_type: best_return_type(rbs.return_type, yard.return_type)
        )
      end
      in_rbs = rbs_map.pins.reject { |pin| in_yard.include?(pin.path) }
      combined + in_rbs
    end

    class << self
      private

      # Select the first defined type.
      #
      # @param choices [Array<ComplexType>]
      # @return [ComplexType]
      def best_return_type *choices
        choices.find { |pin| pin.defined? } || choices.first || ComplexType::UNDEFINED
      end
    end
  end
end
