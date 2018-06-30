module Solargraph
  module LanguageServer
    module Transport
      autoload :DataReader, 'solargraph/language_server/transport/data_reader'
      autoload :Socket,     'solargraph/language_server/transport/socket'
      autoload :Stdio,      'solargraph/language_server/transport/stdio'
    end
  end
end
