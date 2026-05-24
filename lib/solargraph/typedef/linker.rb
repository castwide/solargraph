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
        when Source::Chain::InstanceVariable
          ivars = api_map.get_instance_variable_pins(closure.context.namespace, closure.context.scope).select do |p|
            p.name == link.word
          end
          out = api_map.var_at_location(ivars, link.word, closure, location)
          [out].compact
        when Source::Chain::Literal
          type_name = link.word.sub(/^</, '').sub(/>$/, '')
          complex_type = ComplexType.parse(type_name)
          [Pin::ProxyType.anonymous(complex_type, source: :chain)]
        when Source::Chain::Or
          types = link.links.map { |link| link.infer(api_map, closure, locals) }
          combined_type = Solargraph::ComplexType.new(types)
          unless types.all?(&:nullable?)
            # @sg-ignore flow sensitive typing should be able to handle redefinition
            combined_type = combined_type.without_nil
          end

          [Solargraph::Pin::ProxyType.anonymous(combined_type, source: :chain)]
        else
          raise "#{link.class} not implemented"
        end
      end
    end
  end
end
