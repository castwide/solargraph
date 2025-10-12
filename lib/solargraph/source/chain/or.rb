# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Or < Link
        def word
          '<or>'
        end

        # @param links [::Array<Link>]
        def initialize links
          @links = links
        end

        def resolve api_map, name_pin, locals
          types = @links.map { |link| link.infer(api_map, name_pin, locals) }
          combined_type = Solargraph::ComplexType.new(types)
          unless types.all?(&:nullable?)
            combined_type = combined_type.without_nil
          end

          [Solargraph::Pin::ProxyType.anonymous(combined_type, source: :chain)]
        end
      end
    end
  end
end
