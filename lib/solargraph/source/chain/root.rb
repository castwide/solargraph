module Solargraph
  class Source
    class Chain
      # @todo Determine if this class is necessary. Its primary purpose is to
      #   point the tops of chain queries to the global namespace.
      class Root < Link
        def initialize
          @word = ''
        end

        def resolve_pins api_map, context, locals
          [context_type(api_map, context)]
        end

        private

        def context_type api_map, context
          if ['Class', 'Module'].include?(context.name)
            namespace = api_map.qualify(context.namespace)
            api_map.get_path_suggestions(namespace)
          else
            # @todo Infer from ApiMap? Maybe not necessary; pin namespaces
            #   should always be fully qualified, unlike complex type
            #   namespaces.
            Pin::ProxyType.anonymous(ComplexType.parse(context.namespace))
          end
        end
      end
    end
  end
end
