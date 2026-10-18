# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Head < Base
        # @return [Array<Pin::Base>]
        def resolve
          return [Lexicon.new(Pin::ProxyType.anonymous(receiver.context, source: :chain), receiver.typedef_typeset)] if link.word == 'self'
          []
        end
      end
    end
  end
end
