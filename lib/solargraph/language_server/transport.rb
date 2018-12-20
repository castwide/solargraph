module Solargraph
  module LanguageServer
    # The Transport namespace contains concrete implementations of
    # communication protocols for language servers.
    #
    module Transport
      autoload :DataReader, 'solargraph/language_server/transport/data_reader'
      autoload :Socket,     'solargraph/language_server/transport/socket'
      autoload :Stdio,      'solargraph/language_server/transport/stdio'
      autoload :BackportTcp, 'solargraph/language_server/transport/backport_tcp'
    end
  end
end
