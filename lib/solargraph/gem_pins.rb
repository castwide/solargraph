# frozen_string_literal: true

require 'rbs'

module Solargraph
  module GemPins
    module_function

    def build(gemspec)
      Yardoc.cache(gemspec) unless Yardoc.cached?(gemspec)
      yardoc = Yardoc.load!(gemspec)
      yard_pins = YardMap::Mapper.new(yardoc, gemspec).map
      rbs_map = RbsMap.from_gemspec(gemspec)
      yard_pins.map do |yard|
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
          return_type: rbs.return_type
        )
      end
    end
  end
end
