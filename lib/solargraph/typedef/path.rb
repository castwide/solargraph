# frozen_string_literal: true

module Solargraph
  module Typedef
    class Path
      attr_reader :name

      attr_reader :parts

      def initialize name, rooted: false
        @name = name
        @rooted = rooted
        @parts ||= name.split('::')
        if name.start_with?('::')
          @name = @name[2..]
          @rooted = true
        end
      end

      def rooted?
        @rooted
      end

      def resolved?
        rooted?
      end

      def root?
        name.empty?
      end

      def from(base)
        return self if rooted?

        Path.new("#{base.name}::#{name}", rooted: base.rooted?)
      end

      def to_s
        name
      end
    end
  end
end
