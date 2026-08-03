# frozen_string_literal: true

module Solargraph
  module Typedef
    class Tuple < Type
      def brackets
        [ '(', ')' ]
      end
    end
  end
end
