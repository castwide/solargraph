# frozen_string_literal: true

module Solargraph
  module Pin
    # Mix-in for pins that state the type an expression has within a range
    # of a file. A variable reference is the simplest expression.
    module ExpressionType
      # @!method presence
      #   @abstract
      #   @return [Range, nil] where the type holds
      # @!method visible_at?(other_closure, other_loc)
      #   @abstract
      #   @param other_closure [Pin::Closure]
      #   @param other_loc [Location]
      #   @return [Boolean]
      # @!method expression
      #   @abstract
      #   @return [String, ::Array<::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #       ::Array(:cvar, ::Symbol), ::Array(:self_call, ::Symbol),
      #       ::Array(:call, ::Symbol),
      #       ::Array(:call, :[], ::Array<::Array(:literal, :str, ::String),
      #         ::Array(:literal, :sym, ::Symbol), ::Array(:literal, :int, ::Integer),
      #         ::Array(:lvar, ::Symbol), ::Array(:ivar, ::Symbol),
      #         ::Array(:cvar, ::Symbol)>)>] the expression the type is for:
      #     a variable name, or ExpressionNarrowing steps

      # @sg-ignore Declared return type ::Array<::Solargraph::Pin::BaseVariable> does not match inferred type ::Array<::Solargraph::Pin::ExpressionType> for Solargraph::Pin::ExpressionType.variables
      # @param expression_types [::Array<ExpressionType>] e.g. a source map's expression_types
      # @return [::Array<BaseVariable>] the variables among `expression_types`,
      #   without expression narrowings such as h[k]
      def self.variables expression_types
        expression_types.grep(BaseVariable)
      end
    end
  end
end
