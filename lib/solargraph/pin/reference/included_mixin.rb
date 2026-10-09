# frozen_string_literal: true

module Solargraph
  module Pin
    class Reference
      # A mixin that a module's +self.included+ hook applies to every class
      # that includes the module, e.g. +base.extend ClassMethods+. The closure
      # is the hooking module and the name is the mixed-in module.
      class IncludedMixin < Reference
        # @return [::Symbol] :include, :prepend or :extend
        attr_reader :keyword

        # @param keyword [::Symbol] :include, :prepend or :extend
        # @param splat [Hash{Symbol => Object}]
        def initialize keyword:, **splat
          super(**splat)
          @keyword = keyword
        end
      end
    end
  end
end
