# frozen_string_literal: true

require_relative "macros/version"

module Gem
  module With
    module Yard
      module Macros
        class Error < StandardError; end
        # Your code goes here...

        class MyStruct
          # @!macro my_attribute
          #   @!method $1
          #     @return [$2]
          def self.my_attribute(name, type) 
          end
        end
      end
    end
  end
end
