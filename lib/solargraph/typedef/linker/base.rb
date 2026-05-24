# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Base
        # @return [Dictionary]
        attr_reader :dictionary

        attr_reader :link

        attr_reader :closure

        def initialize(dictionary, link, closure)
          @dictionary = dictionary
          @link = link
          @closure = closure
        end

        def api_map
          dictionary.api_map
        end

        # @param pin [Pin::Base]
        def delegate pin
          # @todo This delegation doesn't work for some reason
          # result = Dictionary.new(api_map, pin.filename, pin.location.range.start).infer
          result = pin.probe(api_map)
          if result.defined?
            [Pin::ProxyType.anonymous(result)]
          else
            [pin]
          end
        end

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
