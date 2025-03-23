# frozen_string_literal: true

require 'backport'

module Solargraph
  module LanguageServer
    module Transport
      # A common module for running language servers in Backport.
      #
      module Adapter
        # This runs in the context of Backport::Adapter, which
        # provides write() - but if we didn't hide this behind a parse
        # tag, it would override the one in the class.
        #
        # @!method write(text)
        #   @abstract
        #   Write the change to the specified text.
        #   @param text [String] The text to be changed.
        #   @return [String] The updated text.

        # @return [void]
        def opening
          @host = Solargraph::LanguageServer::Host.new
          @host.add_observer self
          @host.start
          @data_reader = Solargraph::LanguageServer::Transport::DataReader.new
          @data_reader.set_message_handler do |message|
            process message
          end
        end

        # @return [void]
        def closing
          @host.stop
        end

        # @param data [String]
        # @return [void]
        def receiving data
          @data_reader.receive data
        end

        # @return [void]
        def update
          if @host.stopped?
            shutdown
          else
            tmp = @host.flush
            write tmp unless tmp.empty?
          end
        end

        private

        # @param request [Hash]
        # @return [void]
        def process request
          @host.process(request)
        end

        # @return [void]
        def shutdown
          Backport.stop unless @host.options['transport'] == 'external'
        end
      end
    end
  end
end
