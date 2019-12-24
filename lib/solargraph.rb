# frozen_string_literal: true

# require 'yard'
require 'solargraph/version'
# require 'yard-solargraph'

# The top-level namespace for the Solargraph code mapping, documentation,
# static analysis, and language server libraries.
#
module Solargraph
  class InvalidOffsetError <      RangeError;    end
  class DiagnosticsError <        RuntimeError;  end
  class FileNotFoundError <       RuntimeError;  end
  class SourceNotAvailableError < StandardError; end
  class ComplexTypeError        < StandardError; end
  class WorkspaceTooLargeError <  RuntimeError;  end
  class BundleNotFoundError <     StandardError; end

  autoload :Position,         'solargraph/position'
  autoload :Range,            'solargraph/range'
  autoload :Location,         'solargraph/location'
  autoload :Shell,            'solargraph/shell'
  autoload :Source,           'solargraph/source'
  autoload :SourceMap,        'solargraph/source_map'
  autoload :ApiMap,           'solargraph/api_map'
  autoload :YardMap,          'solargraph/yard_map'
  autoload :Pin,              'solargraph/pin'
  autoload :ServerMethods,    'solargraph/server_methods'
  autoload :CoreFills,        'solargraph/core_fills'
  autoload :StdlibFills,      'solargraph/stdlib_fills'
  autoload :LanguageServer,   'solargraph/language_server'
  autoload :Workspace,        'solargraph/workspace'
  autoload :Page,             'solargraph/page'
  autoload :Library,          'solargraph/library'
  autoload :Diagnostics,      'solargraph/diagnostics'
  autoload :ComplexType,      'solargraph/complex_type'
  autoload :Bundle,           'solargraph/bundle'
  autoload :Logging,          'solargraph/logging'
  autoload :TypeChecker,      'solargraph/type_checker'
  autoload :Environ,          'solargraph/environ'
  autoload :Convention,       'solargraph/convention'
  autoload :Documentor,       'solargraph/documentor'

  dir = File.dirname(__FILE__)
  YARDOC_PATH = File.realpath(File.join(dir, '..', 'yardoc'))
  YARD_EXTENSION_FILE = File.join(dir, 'yard-solargraph.rb')
  VIEWS_PATH = File.join(dir, 'solargraph', 'views')

  # A convenience method for Solargraph::Logging.logger.
  #
  # @return [Logger]
  def self.logger
    Solargraph::Logging.logger
  end
end
