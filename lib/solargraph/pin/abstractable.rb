# frozen_string_literal: true

module Solargraph
  module Pin
    # Reads a pin's abstract marker from either channel: state supplied at
    # construction, as RBS interfaces do, or a YARD @abstract tag written in
    # Ruby comments.
    #
    # @abstract This mixin relies on these -
    #   methods:
    #     abstract()
    #     docstring()
    module Abstractable
      # @!method abstract
      #   @return [String, nil]

      # @!method docstring
      #   @return [YARD::Docstring]

      # @return [Boolean]
      def abstract?
        !abstract.nil? || docstring.has_tag?('abstract')
      end

      # The text explaining why this pin is abstract.
      #
      # @return [String, nil]
      def abstract_note
        abstract || docstring.tag(:abstract)&.text
      end
    end
  end
end
