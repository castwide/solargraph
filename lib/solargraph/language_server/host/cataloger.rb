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

        def stop
          @stopped = true
        end

        def stopped?
          @stopped
        end

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

        attr_reader :host

        attr_reader :mutex
      end
    end
  end
end
