# frozen_string_literal: true

module Solargraph
  module Typedef
    class Generic < Token
      def initialize name
        super('generic', Token.new(name))
      end

      def to_s
        "#{name}<#{params.first}>"
      end
    end
  end
end
