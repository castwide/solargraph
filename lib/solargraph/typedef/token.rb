# frozen_string_literal: true

module Solargraph
  module Typedef
    class Token
      RESERVED_NAMES = %w[nil undefined]

      attr_reader :name

      attr_reader :params

      def initialize name, *params
        @name = name
        @params = params
      end

      def expand(named_values)
        return self unless named_values[name]
        Typedef.tokenize(named_values[name])
      end

      def resolve_rooted(api_map, gates)
        self
      end

      def resolved?
        RESERVED_NAMES.include?(name)
      end

      def expanded?
        RESERVED_NAMES.include?(name)
      end

      def generic?
        name.start_with?('generic<')        
      end

      def to_s
        "#{([name] + params).join(', ')}"
      end
    end
  end
end
