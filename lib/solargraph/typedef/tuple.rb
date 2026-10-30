# frozen_string_literal: true

module Solargraph
  module Typedef
    class Tuple < Concrete
      def brackets
        ['(', ')']
      end
    end
  end
end
