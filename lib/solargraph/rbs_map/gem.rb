# frozen_string_literal: true

module Solargraph
  module RbsMap
    class Gem < Base
      # Where a gem may publish signatures. Deliberately not the gem root:
      # the rbs gem keeps Ruby's own core/ there, so adding the root loads
      # core a second time on top of Collection::Core and doubles the method
      # pins in every core namespace.
      #
      # stdlib/ stays. Dropping it leaves Ripper::SexpBuilderPP unresolved
      # (castwide/solargraph#1376) even though Collection::Stdlib supplies a
      # pin for it, which is not yet explained.
      SIGNATURE_DIRECTORIES = %w[sig stdlib].freeze

      # @param metagem [Metagem]
      def initialize metagem
        super()
        root = Pathname.new(metagem.full_path)
        SIGNATURE_DIRECTORIES.each do |dir|
          path = root + dir
          loader.add path: path if path.directory?
        end
      end
    end
  end
end
