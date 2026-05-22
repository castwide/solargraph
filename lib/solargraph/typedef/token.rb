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

      def resolved?
        RESERVED_NAMES.include?(name)
      end

      def to_s
        "#{([name] + params).join(', ')}"
      end
    end
  end
end
