# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class If < Link
        def word
          '<if>'
        end

        # @param links [::Array<Link>]
        def initialize links
          @links = links
        end

        # @sg-ignore Fix "Not enough arguments to Module#protected"
        protected def equality_fields
          super + [links]
        end

        def resolve api_map, name_pin, locals
          types = @links.map { |link| link.infer(api_map, name_pin, locals) }
          [Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType.try_parse(types.map(&:tag).uniq.join(', ')))]
        end
      end
    end
  end
end
