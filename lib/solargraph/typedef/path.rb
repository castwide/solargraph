# frozen_string_literal: true

module Solargraph
  module Typedef
    class Path
      attr_reader :name

      def initialize name, rooted: false
        @name = name
        @rooted = rooted
        if name.start_with?('::')
          @name = @name[2..]
          @rooted = true
        end
      end

      def rooted?
        @rooted
      end

      def join(base)
        return self if rooted?

        Route.new("#{base.name}::#{name}", rooted: base.rooted)
      end
    end
  end
end
