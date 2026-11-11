# frozen_string_literal: true

module Solargraph
  module Pin
    # Lets the pin with the higher combine_priority win a combine field by
    # field, as an @!override does over the pin it targets.
    #
    # @abstract This mixin relies on these -
    #   methods:
    #     combine_priority()
    #     comments()
    #     docstring()
    module CombinePriority
      # @!method combine_priority
      #   @return [::Numeric, nil]

      # @!method comments
      #   @return [String, nil]

      # @!method docstring
      #   @return [YARD::Docstring]

      # The docstring belonging to whichever pin supplied the combined
      # comments. Taking it independently leaves the two disagreeing,
      # so that tags written in the comments that won are not the tags
      # the combined pin reports. #choose_longer returns one of the two
      # comments, so one of these pins always supplied them.
      #
      # @param other [Pin::Base]
      # @param chosen_comments [String, nil]
      # @return [YARD::Docstring]
      def docstring_for other, chosen_comments
        winner = higher_priority(other)
        return overlay_docstring(winner, winner.equal?(self) ? other : self) unless winner.nil?

        comments == chosen_comments ? docstring : other.docstring
      end

      # The base pin's docstring with every tag name the authoritative pin
      # supplies replaced by that pin's tags. Tags it says nothing about
      # survive, which is what makes an override a refinement.
      #
      # @param winner [Pin::Base, CombinePriority]
      # @param base [Pin::Base, CombinePriority]
      # @return [YARD::Docstring]
      def overlay_docstring winner, base
        merged = base.docstring.dup
        winner.docstring.tags.map(&:tag_name).uniq.each { |name| merged.delete_tags(name) }
        winner.docstring.tags.each { |tag| merged.add_tag(tag) }
        merged
      end

      # The pin whose values win a field-by-field merge, or nil when neither
      # outranks the other. A nil combine_priority ranks below any number.
      #
      # @param other [Pin::Base]
      # @return [Pin::Base, nil]
      def higher_priority other
        mine = combine_priority
        theirs = other.combine_priority
        return nil if mine == theirs
        return other if mine.nil?
        return self if theirs.nil?

        mine > theirs ? self : other
      end

      # The authoritative pin's value for one attribute. nil when there is no
      # authority, or it supplies nothing, and the ordinary merge decides.
      #
      # @param other [Pin::Base]
      # @param attr [::Symbol]
      # @return [Object, nil]
      def authoritative_value other, attr
        winner = higher_priority(other)
        return nil if winner.nil?

        value = winner.send(attr)
        return nil if value.nil?
        return nil if value.respond_to?(:empty?) && value.empty?

        value
      end
    end
  end
end
