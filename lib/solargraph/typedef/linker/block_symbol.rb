# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class BlockSymbol < Base
        def resolve
          [Lexicon.new(Pin::ProxyType.anonymous(ComplexType.try_parse('::Proc'), source: :chain), receiver.typedef_typeset)]
        end
      end
    end
  end
end
