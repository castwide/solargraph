# frozen_string_literal: true

module Solargraph
  module Pin
    # Answers whether a pin is abstract from its #abstract note.
    #
    # @abstract This mixin relies on these -
    #   methods:
    #     abstract()
    module Abstractable
      # @!method abstract
      #   @return [String, nil]

      # @return [Boolean]
      def abstract?
        !abstract.nil?
      end

      # The text explaining why this pin is abstract.
      #
      # @return [String, nil]
      def abstract_note
        abstract
      end
    end
  end
end
