module Solargraph
  module LanguageServer
    module Message
      module CompletionItem
        # completionItem/resolve message handler
        #
        class Resolve < Base
          def process
            pin = host.locate_pin params
            if pin.nil?
              set_result params
            else
              STDERR.puts "Pin is #{pin.class}"
              STDERR.puts "Resolved: #{pin.resolve_completion_item}"
              set_result(
                params.merge(pin.resolve_completion_item)
              )
            end
          rescue Exception => e
            STDERR.puts "Exception: #{e.message}"
            STDERR.puts e.backtrace
          end
        end
      end
    end
  end
end
