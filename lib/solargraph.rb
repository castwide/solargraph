require 'solargraph/version'
require 'rubygems/package'
require 'yard-solargraph'

module Solargraph
  class InvalidOffsetError <      RangeError;    end
  class DiagnosticsError <        RuntimeError;  end
  class FileNotFoundError <       RuntimeError;  end
  class SourceNotAvailableError < StandardError; end
  class WorkspaceTooLargeError <  RuntimeError
    # @return [Integer]
    attr_reader :size

    # @return [Integer]
    attr_reader :max

    # @param size [Integer] The number of files included in the workspace
    # @param max [Integer] The maximum number of files allowed
    def initialize size, max
      @size = size
      @max = max
    end
  end

  autoload :Shell,          'solargraph/shell'
  autoload :Source,         'solargraph/source'
  autoload :ApiMap,         'solargraph/api_map'
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
  autoload :Diagnostics,    'solargraph/diagnostics'

  YARDOC_PATH = File.join(File.realpath(File.dirname(__FILE__)), '..', 'yardoc')
  YARD_EXTENSION_FILE = File.join(File.realpath(File.dirname(__FILE__)), 'yard-solargraph.rb')
  VIEWS_PATH = File.join(File.realpath(File.dirname(__FILE__)), 'solargraph', 'views')
end

Solargraph::YardMap::CoreDocs.require_minimum
