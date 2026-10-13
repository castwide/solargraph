# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class If < Link
        # @param links [::Array<Chain>]
        def initialize links
          super('<if>')

          @links = links
        end

        def resolve api_map, name_pin, locals
          types = @links.map { |link| link.infer(api_map, name_pin, locals) }
          [Solargraph::Pin::ProxyType.anonymous(Solargraph::ComplexType.try_parse(types.map(&:tag).uniq.join(', ')),
                                                source: :chain)]
        end

        protected

        # @sg-ignore Fix "Not enough arguments to Module#protected"
        def equality_fields
          # @sg-ignore https://github.com/castwide/solargraph/pull/1223
          super + [@links]
        end
      end
    end
  end
end
