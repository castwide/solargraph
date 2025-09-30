# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      class Link
        include Equality

        # @return [String]
        attr_reader :word

        # @return [Pin::Base]
        attr_accessor :last_context

        # @param word [String]
        def initialize word = '<undefined>'
          @word = word
        end

        # @sg-ignore two problems - Declared return type
        #   ::Solargraph::Source::Chain::Array does not match inferred
        #   type ::Array(::Class<::Solargraph::Source::Chain::Link>,
        #   ::String) for
        #   Solargraph::Source::Chain::Link#equality_fields
        #   and
        #   Not enough arguments to Module#protected
        protected def equality_fields
          [self.class, word]
        end

        def undefined?
          word == '<undefined>'
        end

        def constant?
          is_a?(Chain::Constant)
        end

        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Enumerable<Pin::Base>]
        # @return [::Array<Pin::Base>]
        def resolve api_map, name_pin, locals
          []
        end

        # debugging description of contents; not for machine use
        # @return [String]
        def desc
          word
        end

        def to_s
          desc
        end

        def inspect
          "#<#{self.class} - `#{desc}`>"
        end

        def head?
          @head ||= false
        end

        # Make a copy of this link marked as the head of a chain
        #
        # @return [self]
        def clone_head
          clone.mark_head(true)
        end

        # Make a copy of this link unmarked as the head of a chain
        #
        # @return [self]
        def clone_body
          clone.mark_head(false)
        end

        def nullable?
          false
        end

        # debugging description of contents; not for machine use
        #
        # @return [String]
        def desc
          word
        end

        def inspect
          "#<#{self.class} - `#{desc}`>"
        end

        include Logging

        protected

        # Mark whether this link is the head of a chain
        #
        # @param bool [Boolean]
        # @return [self]
        def mark_head bool
          @head = bool
          self
        end
      end
    end
  end
end
