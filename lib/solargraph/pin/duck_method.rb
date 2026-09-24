# frozen_string_literal: true

module Solargraph
  module Pin
    # DuckMethod pins are used to add completion items for type tags that
    # use duck typing, e.g., `@param file [#read]`.
    #
    class DuckMethod < Pin::Method
      # A duck-type tag has no syntax for arguments, so the default empty
      # #parameters would synthesize a zero-arg signature no real call matches.
      #
      # @param splat [Hash{Symbol => Object}]
      def initialize **splat
        super(parameters: accepts_any_arguments, **splat)
      end

      # @return [::Array<Pin::Parameter>]
      def accepts_any_arguments
        [
          Pin::Parameter.new(decl: :restarg, name: 'args', closure: self, source: :api_map),
          Pin::Parameter.new(decl: :kwrestarg, name: 'kwargs', closure: self, source: :api_map)
        ]
      end

      # A synthetic pin sits in no ancestor chain and has no closure. Letting
      # the inherited walk find a type sends #typify on to `closure.gates`,
      # which raises.
      #
      # @param _api_map [ApiMap]
      # @return [Array<Pin::Method>]
      def rest_of_stack _api_map
        []
      end
    end
  end
end
