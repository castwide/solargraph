require 'solargraph/language_server/error_codes'
require 'solargraph/language_server/completion_item_kinds'
require 'solargraph/language_server/symbol_kinds'

module Solargraph
  module LanguageServer
    autoload :Host, 'solargraph/language_server/host'
    autoload :Message, 'solargraph/language_server/message'
    autoload :Transport, 'solargraph/language_server/transport'
    autoload :UriHelpers, 'solargraph/language_server/uri_helpers'
    autoload :MessageTypes, 'solargraph/language_server/message_types'
  end
end
