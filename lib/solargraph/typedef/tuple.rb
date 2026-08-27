# frozen_string_literal: true

module Solargraph
  module Typedef
    class Tuple < Unique
      def brackets
        [ '(', ')' ]
      end
    end
  end
end
