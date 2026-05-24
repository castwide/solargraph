# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      def hitch link, closure
        case link
        when Solargraph::Source::Chain::Head
          return [Pin::ProxyType.anonymous(closure.binder, source: :chain)] if link.word == 'self'
          []
        when Solargraph::Source::Chain::Call
          closure.typedef_return_types
                 .map { |type| type.resolve_rooted(api_map, [closure.namespace]) }
                 .flat_map { |type| api_map.typedef_path_methods(type.base) }
                 .select { |pin| pin.name == link.word }
        when Solargraph::Source::Chain::Constant
          return [Pin::ROOT_PIN] if link.word.empty?
          if link.word.start_with?('::')
            base = link.word[2..]
            gates = ['']
          else
            base = link.word
            gates = closure.gates
          end
          # @sg-ignore Need to add nil check here
          fqns = api_map.resolve(base, gates)
          # @sg-ignore Need to add nil check here
          api_map.get_path_pins(fqns)
        else
          raise "#{link.class} not implemented"
        end
      end
    end
  end
end
