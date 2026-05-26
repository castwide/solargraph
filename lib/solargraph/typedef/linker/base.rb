# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Base
        # @return [Dictionary]
        attr_reader :dictionary

        # @return [Source::Chain::Link]
        attr_reader :link

        # @return [Pin::Closure]
        attr_reader :closure

        # @param dictionary [Dictionary]
        # @param link [Source::Chain::Link]
        # @param closure [Pin::Closure]
        def initialize(dictionary, link, closure)
          @dictionary = dictionary
          @link = link
          @closure = closure
        end

        def api_map
          dictionary.api_map
        end

        def source_map
          dictionary.source_map
        end

        # @return [Array<Pin::Base>]
        def resolve
          raise 'Not implemented'
        end

        def self.resolve(dictionary, link, closure)
          new(dictionary, link, closure).resolve
        end
      end
    end
  end
end
