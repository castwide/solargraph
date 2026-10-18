# frozen_string_literal: true

module Solargraph
  module Typedef
    module Linker
      class Literal < Base
        # @return [Array<Pin::Base>]
        def resolve
          type_name = link.word.sub(/^</, '').sub(/>$/, '')
          complex_type = ComplexType.parse(type_name)
          [Lexicon.new(Pin::ProxyType.anonymous(complex_type, source: :chain), receiver.typedef_typeset)]
        end
      end
    end
  end
end
