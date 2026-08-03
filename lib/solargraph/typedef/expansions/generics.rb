# frozen_string_literal: true

module Solargraph
  module Typedef
    module Expansions
      # Contextual expansion of generic tokens
      #
      class Generics < Base
        # @return [Typeset]
        def expand
          pin.typedef_typeset
            .expand(zip_generic_values(pin))
            .expand(zip_generic_values(receiver))
        end

        def names
          generics_from(pin).concat(generics_from(receiver))
        end

        private

        # @param pin [Pin::Base]
        def generics_from pin
          names = []
          cursor = pin
          while cursor
            names.concat(cursor.typedef_generics)
            cursor = cursor.closure
          end
          names
        end

        # @param reference [Pin::Base]
        def zip_generic_values reference
          generic_names = names.map { |name| "generic<#{name}>"}
          type = unless generic_names.empty?
            receiver.typedef_typeset.flat_types.find { |type| type.params.length == generic_names.length }
          end
          named_values = if type
            generic_names.zip(type.params).to_h
          else
            {}
          end
        end
      end
    end
  end
end
