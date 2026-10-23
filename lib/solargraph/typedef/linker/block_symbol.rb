# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class BlockSymbol < Base
        def resolve
          [Pin::ProxyType.anonymous(ComplexType.try_parse('::Proc'), source: :chain)]
        end
      end
    end
  end
end
