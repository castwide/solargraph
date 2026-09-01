# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Or < Link
        attr_reader :links

        # @param links [::Array<Chain>]
        # @param rhs_never_returns [Boolean] true if the right-hand side
        #   necessarily leaves the enclosing compound statement (e.g.,
        #   `x || raise('missing')`) - it never contributes a value to
        #   this expression's result, so continuing past this
        #   expression implies the left-hand side was truthy
        def initialize links, rhs_never_returns: false
          super('<or>')

          @links = links
          @rhs_never_returns = rhs_never_returns
        end

        def resolve api_map, name_pin, locals
          types = @links.map { |link| link.infer(api_map, name_pin, locals) }

          if @rhs_never_returns
            lhs_type = types.first
            return [Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType::UNDEFINED, source: :chain)] if lhs_type.nil?

            return [Solargraph::Pin::ProxyType.anonymous(lhs_type.without_nil, source: :chain)]
          end

          combined_type = Solargraph::ComplexType.new(types)
          unless types.all?(&:nullable?)
            # @sg-ignore flow sensitive typing should be able to handle redefinition
            combined_type = combined_type.without_nil
          end

          [Solargraph::Pin::ProxyType.anonymous(combined_type, source: :chain)]
        end

        protected

        # @sg-ignore return type could not be inferred
        def equality_fields
          # @sg-ignore literal arrays in this module turn into ::Solargraph::Source::Chain::Array
          super + [@links, @rhs_never_returns]
        end
      end
    end
  end
end
