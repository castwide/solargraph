# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Head < Base
        # @return [Array<Pin::Base>]
        def resolve
          return [Pin::ProxyType.anonymous(receiver.context, source: :chain)] if link.word == 'self'
          []
        end
      end
    end
  end
end
