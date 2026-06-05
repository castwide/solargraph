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

      def expand(named_values)
        self
      end

      # @param api_map [ApiMap]
      # @param gates [Array<String>]
      def resolve_rooted(api_map, gates)
        return self if rooted?

        new_path = api_map.qualify(name, *gates)
        if new_path
          # @todo Inefficient but effective
          rooted = api_map.get_path_pins(new_path).any?
          Path.new(new_path, rooted: rooted) if new_path
        else
          self
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

      def expanded?
        true
      end

      def generic?
        false
      end

      def combine _
        self
      end

      def from(base)
        return self if rooted?

        Path.new("#{base.name}::#{name}", rooted: base.rooted?)
      end

      def to_s
        name
      end

      def to_s_for_complex_type
        "#{rooted? ? '::' : ''}#{to_s}"
      end

      ROOT = Path.new('', rooted: true)
    end
  end
end
