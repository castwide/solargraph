require 'solargraph/version'
require 'rubygems/package'
require 'yard-solargraph'
require 'sinatra'

module Solargraph
  class InvalidOffsetError <      RangeError; end
  class DiagnosticsError <        RuntimeError; end
  class FileNotFoundError <       RuntimeError; end
  class SourceNotAvailableError < StandardError; end

  class WorkspaceTooLargeError < RuntimeError
    attr_reader :size
    def initialize size
      @size = size
    end
  end

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
  autoload :Diagnostics,    'solargraph/diagnostics'

  YARDOC_PATH = File.join(File.realpath(File.dirname(__FILE__)), '..', 'yardoc')
  YARD_EXTENSION_FILE = File.join(File.realpath(File.dirname(__FILE__)), 'yard-solargraph.rb')
  VIEWS_PATH = File.join(File.realpath(File.dirname(__FILE__)), 'solargraph', 'views')

  def self.trace logfile: 'solargraph.log', level: :error
    tracer = Tracer.load(Dir.pwd)
    at_exit do
      tracer.stop
      File.open logfile, 'w' do |file|
        tracer.log.each do |issue|
          next unless level == :warning or issue.severity == :error
          file.puts "[#{issue.severity}] #{issue.message}"
          file.puts "  #{issue.backtrace[0, 2].join($/ + '  ')}"
        end
      end
      if tracer.log.empty?
        puts "Solargraph trace found 0 issues."
      else
        errors = tracer.log(:error).length
        warnings = tracer.log(:warning).length
        puts "Solargraph trace found #{errors} error#{errors == 1 ? '' : 's'} and #{level == :error ? 'ignored ' : ''}#{warnings} warning#{warnings == 1 ? '' : 's'}."
      end
    end
    tracer.run
  end
end

Solargraph::YardMap::CoreDocs.require_minimum
