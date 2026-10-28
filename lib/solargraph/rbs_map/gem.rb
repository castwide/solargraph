# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Gem < Base
      # @param metagem [Metagem]
      def initialize metagem
        super()
        # Gems ship their signatures in sig/, the directory RBS itself
        # loads; other .rbs files (e.g., the rbs gem's core/) are not the
        # gem's own API
        loader.add path: Pathname.new(metagem.full_path).join('sig')
      end
    end
  end
end
