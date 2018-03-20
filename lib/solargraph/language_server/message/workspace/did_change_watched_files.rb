require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Base
    def process
      STDERR.puts "Handle a workspace change: #{params.inspect}"
    end
  end
end
