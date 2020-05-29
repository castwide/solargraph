# frozen_string_literal: true

module Solargraph
  module Convention
    class Base
      EMPTY_ENVIRON = Environ.new

      # True if the source qualifies for this convention.
      # Subclasses should override this method.
      #
      # @param source [Source]
      def match? source
        false
      end

      # The Environ for this convention.
      # Subclasses should override this method.
      #
      # @return [Environ]
      def environ
        EMPTY_ENVIRON
      end
    end
  end
end
