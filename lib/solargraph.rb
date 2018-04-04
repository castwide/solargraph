require 'solargraph/version'
require 'rubygems/package'
require 'yard-solargraph'

module Solargraph
  autoload :Shell,          'solargraph/shell'
  autoload :Source,         'solargraph/source'
  autoload :ApiMap,         'solargraph/api_map'
  autoload :NodeMethods,    'solargraph/node_methods'
  autoload :Suggestion,     'solargraph/suggestion'
  autoload :Server,         'solargraph/server'
  autoload :YardMap,        'solargraph/yard_map'
  autoload :Pin,            'solargraph/pin'
  autoload :LiveMap,        'solargraph/live_map'
  autoload :ServerMethods,  'solargraph/server_methods'
  autoload :Plugin,         'solargraph/plugin'
  autoload :CoreFills,      'solargraph/core_fills'
  autoload :LanguageServer, 'solargraph/language_server'
  autoload :Workspace,      'solargraph/workspace'
  autoload :Page,           'solargraph/page'
  autoload :Library,        'solargraph/library'
  autoload :Tracer,         'solargraph/tracer'

  YARDOC_PATH = File.join(File.realpath(File.dirname(__FILE__)), '..', 'yardoc')
  YARD_EXTENSION_FILE = File.join(File.realpath(File.dirname(__FILE__)), 'yard-solargraph.rb')
end

Solargraph::YardMap::CoreDocs.require_minimum
