module Solargraph
  module LanguageServer
    module Message
      module Extended
        class Search < Base
          def process
            results = host.library.search(params['query'])
            page = Solargraph::Page.new(host.options['viewsPath'])
            content = page.render('search', locals: {query: params['query'], results: results})
            set_result(
              content: content
            )
          end
        end
      end
    end
  end
end
