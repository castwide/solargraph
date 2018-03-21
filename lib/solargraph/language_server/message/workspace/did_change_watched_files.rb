require 'uri'

module Solargraph::LanguageServer::Message::Workspace
  class DidChangeWatchedFiles < Solargraph::LanguageServer::Message::Base
    def process
      STDERR.puts "Handle a workspace change: #{params.inspect}"
    end
  end
end
