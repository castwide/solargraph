module Solargraph
  module LanguageServer
    module Message
      module Extended
        class Document < Base
          def process
            objects = host.document(params['query'])
            page = Solargraph::Page.new(host.options['viewsPath'])
            content = page.render('document', locals: {objects: objects})
            set_result(
              content: content
            )
          end
        end
      end
    end
  end
end
