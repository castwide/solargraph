module Solargraph
  module HelperMethods
    module_function

    # @return [Position]
    def pos(line, column)
      Position.new(line, column)
    end

    # @return [Range]
    def rng(lin_1, col_1, lin_2, col_2)
      Range.from_to(lin_1, col_1, lin_2, col_2)
    end
  end
end
