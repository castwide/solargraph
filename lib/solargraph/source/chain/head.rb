# frozen_string_literal: true

module Solargraph
  class Source
    class Chain
      # Chain::Head is a link for ambiguous words, e.g.; `String` can refer to
      # either a class (`String`) or a function (`Kernel#String`).
      #
      # @note Chain::Head is only intended to handle `self` and `super`.
      class Head < Link
        # @param api_map [ApiMap]
        # @param name_pin [Pin::Base]
        # @param locals [::Array<Pin::Base>]
        # @param _receiver_path [::Array<String>, nil]
        def resolve api_map, name_pin, locals, _receiver_path = nil
          return [Pin::ProxyType.anonymous(name_pin.binder, source: :chain)] if word == 'self'
          # return super_pins(api_map, name_pin) if word == 'super'
          []
        end
      end
    end
  end
end
