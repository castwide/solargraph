# frozen_string_literal: true

module Solargraph
  module Pin
    # Mix-in for the pins every construction site gives a closure, so a
    # missing one raises instead of returning nil.
    module ClosureRequired
      # @!parse
      #   # @return [Pin::Closure, nil]
      #   def raw_closure; end
      #   # @return [String]
      #   def name; end

      # @return [Pin::Closure]
      def closure
        value = raw_closure
        return value unless value.nil?

        raise "Closure not set on #{self.class} #{name.inspect}"
      end
    end
  end
end
