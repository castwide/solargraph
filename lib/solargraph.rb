require 'solargraph/version'

module Solargraph
  autoload :Analyzer, 'solargraph/analyzer'
  autoload :Shell, 'solargraph/shell'
  autoload :LiveParser, 'solargraph/live_parser'
  autoload :ApiMap, 'solargraph/api_map'
  autoload :CodeMap, 'solargraph/code_map'
  autoload :NodeMethods, 'solargraph/node_methods'
  autoload :CodeData, 'solargraph/code_data'
  autoload :SNIPPETS, 'solargraph/snippets'

  STUB_PATH = File.realpath(File.dirname(__FILE__) + "/../stubs")
end
