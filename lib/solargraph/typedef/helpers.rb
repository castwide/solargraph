# frozen_string_literal: true

module Solargraph
  module Typedef
    module Helpers
      module_function

      # @param pin [Pin::Base]
      # @param receiver [Pin::Closure]
      # @return [Array<Typedef::Type>]
      def expand_tokens pin, receiver
        pin.typedef_return_types.map do |type|
          next type if type.expanded?

          named_values = if type.generic?
            # The type has generics. Crawl back up the closures to find their names. Apply values from the receiver. Replace the generics.
            generic_keys = pin.closure.generics.map { |name| "generic<#{name}>" }
            generic_values = receiver.typedef_return_types.find { |type| type.params.length == generic_keys.length }
            generic_keys.zip(generic_values&.params || []).to_h
          else
            {}
          end
          named_values['self'] = receiver&.namespace
          type.resolve_named_tokens(named_values)
        end
      end
    end
  end
end
