module Solargraph
  module LanguageServer
    class Host
      # An asynchronous library cataloging handler.
      #
      class Cataloger
        def initialize host
          @host = host
          @mutex = Mutex.new
          @stopped = true
        end

        # Stop the catalog thread.
        #
        # @return [void]
        def stop
          @stopped = true
        end

        # True if the cataloger is stopped.
        #
        # @return [Boolean]
        def stopped?
          @stopped
        end

        # Start the catalog thread.
        #
        # @return [void]
        def start
          return unless stopped?
          @stopped = false
          Thread.new do
            until stopped?
              tick
              sleep 0.01
            end
          end
        end

        # Perform cataloging.
        #
        # @return [void]
        def tick
          mutex.synchronize { host.catalog }
        end

        private

        # @return [Host]
        attr_reader :host

        # @return [Mutex]
        attr_reader :mutex
      end
    end
  end
end
