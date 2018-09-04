module Solargraph
  module LanguageServer
    class Host
      class Cataloger
        def initialize host
          @host = host
          @mutex = Mutex.new
          @last_cataloged = 0
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
              sleep 0.1
              next if host.libver <= @last_cataloged
              @last_cataloged = host.libver
              host.catalog
            end
          end
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
