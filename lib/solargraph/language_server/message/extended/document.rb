# frozen_string_literal: true

module Solargraph
  module LanguageServer
    module Message
      module Extended
        class Document < Base
          def process
            api_map, pins = host.document(params['query'])
            page = Solargraph::Page.new(host.options['viewsPath'])
            content = page.render('document', layout: true, locals: { api_map: api_map, pins: pins })
            set_result(
              content: content
            )
          rescue StandardError => e
            Solargraph.logger.warn "Error processing document: [#{e.class}] #{e.message}"
            Solargraph.logger.debug e.backtrace.join("\n")
          end
        end
      end
    end
  end
end
