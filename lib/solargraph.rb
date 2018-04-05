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

  def self.trace
    tracer = Tracer.load(Dir.pwd)
    at_exit do
      tracer.stop
      # puts "Results of trace: #{tracer.log}"
      File.open 'solargraph.txt', 'w' do |file|
        tracer.log.each do |issue|
          file.puts "[#{issue.severity}] #{issue.message}"
          file.puts "  #{issue.backtrace.join("\n  ")}"
        end
      end
      if tracer.log.empty?
        puts "Solargraph trace found 0 issues."
      else
        errors = tracer.log(:error).length
        warnings = tracer.log(:warning).length
        puts "Solargraph trace found #{errors} error#{errors == 1 ? '' : 's'} and #{warnings} warning#{warnings == 1 ? '' : 's'}."
      end
    end
    tracer.run
  end
end

Solargraph::YardMap::CoreDocs.require_minimum
