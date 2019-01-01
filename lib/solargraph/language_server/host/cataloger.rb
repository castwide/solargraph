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
          @pings = []
        end

        # Notify the Cataloger that changes are pending.
        #
        # @param lib [Library] The library that needs cataloging
        # @return [void]
        def ping lib
          mutex.synchronize { pings.push lib }
        end
        alias schedule ping

        def synchronizing?
          !pings.empty?
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
          return if pings.empty?
          mutex.synchronize do
            lib = pings.shift
            break if pings.include?(lib)
            host.catalog lib
          end
        end

        private

        # @return [Host]
        attr_reader :host

        # @return [Mutex]
        attr_reader :mutex

        # @return [Array]
        attr_reader :pings
      end
    end
  end
end
