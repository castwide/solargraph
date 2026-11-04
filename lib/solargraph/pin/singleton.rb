# frozen_string_literal: true

module Solargraph
  module Pin
    class Singleton < Closure
      include ClosureRequired

      def initialize name: '', location: nil, closure: nil, **splat
        super
      end
    end
  end
end
