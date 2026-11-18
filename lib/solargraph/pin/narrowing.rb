# frozen_string_literal: true

module Solargraph
  module Pin
    # Mix-in for pins that refine the type of a subject, such as a variable
    # or an expression, within a range of a file.
    module Narrowing
      # @!method presence
      #   @abstract
      #   @return [Range, nil] where the refinement holds
      # @!method visible_at?(other_closure, other_loc)
      #   @abstract
      #   @param other_closure [Pin::Closure]
      #   @param other_loc [Location]
      #   @return [Boolean]
      # @!method narrowing_subject
      #   @abstract
      #   @return [String, ::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #       ::Array(:call, ::Symbol),
      #       ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #         ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #         ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #         ::Array(:cvar, ::Symbol)>)>] what the refinement is about:
      #     a variable name, or ExpressionNarrowing steps

      # @sg-ignore Declared return type ::Array<::Solargraph::Pin::BaseVariable> does not match inferred type ::Array<::Solargraph::Pin::Narrowing> for Solargraph::Pin::Narrowing.variables
      # @param narrowings [::Array<Narrowing>] e.g. a source map's locals
      # @return [::Array<BaseVariable>] the variables among `narrowings`,
      #   without expression narrowings such as h[k]
      def self.variables narrowings
        narrowings.grep(BaseVariable)
      end
    end
  end
end
