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
          [Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType.new(types.uniq))]
        end
      end
    end
  end
end
