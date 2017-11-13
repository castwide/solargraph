module Solargraph
  module Plugin
    # A placeholder plugin for disabling the default Runtime plugin.
    #
    class Canceler < Base
      def runtime?
        true
      end
    end
  end
end
