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

      def resolve_named_tokens(named_values)
        return self unless named_values[name]
        Typedef.tokenize(named_values[name])
      end

      def resolve_rooted(api_map, gates)
        self
      end

      def resolved?
        RESERVED_NAMES.include?(name)
      end

      def to_s
        "#{([name] + params).join(', ')}"
      end
    end
  end
end
