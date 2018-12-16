require 'open3'

module Solargraph
  module LanguageServer
    module Message
      module Extended
        # Update YARD documentation for installed gems. If the `rebuild`
        # parameter is true, rebuild existing yardocs.
        #
        class Environment < Base
          def process
            page = Solargraph::Page.new(host.options['viewsPath'])
            content = page.render('environment', layout: false, locals: { config: host.options })
            set_result(
              content: content
            )
          end
        end
      end
    end
  end
end
