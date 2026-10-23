# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Gem < Base
      # @param metagem [Metagem]
      def initialize metagem
        super()
        loader.add path: Pathname.new(metagem.full_path)
      end
    end
  end
end
