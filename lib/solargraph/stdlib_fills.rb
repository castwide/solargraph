# frozen_string_literal: true

module Solargraph
  module StdlibFills
    Override = Pin::Reference::Override

    LIBS = {
      'pathname' => [
        Override.method_return('Pathname#join', 'Pathname')
      ]
    }

    def self.get path
      LIBS[path] || []
    end
  end
end
