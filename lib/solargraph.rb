require 'solargraph/version'
require 'rubygems/package'
require 'yard-solargraph'

module Solargraph
  autoload :Analyzer,    'solargraph/analyzer'
  autoload :Shell,       'solargraph/shell'
  autoload :LiveParser,  'solargraph/live_parser'
  autoload :ApiMap,      'solargraph/api_map'
  autoload :CodeMap,     'solargraph/code_map'
  autoload :NodeMethods, 'solargraph/node_methods'
  autoload :Suggestion,  'solargraph/suggestion'
  autoload :Snippets,    'solargraph/snippets'
  autoload :Server,      'solargraph/server'
  autoload :YardMap,     'solargraph/yard_map'
  autoload :YardMethods, 'solargraph/yard_methods'
  autoload :Pin,         'solargraph/pin'
  autoload :LiveMap,     'solargraph/live_map'

  YARDOC_PATH = File.join(File.realpath(File.dirname(__FILE__)), '..', 'yardoc')
  YARD_EXTENSION_FILE = File.join(File.realpath(File.dirname(__FILE__)), 'yard-solargraph.rb')
end

# Make sure the core and stdlib documentation is available
cache_dir = File.join(Dir.home, '.solargraph', 'cache')
version_dir = File.join(cache_dir, '2.0.0')
unless File.exist?(version_dir)
  FileUtils.mkdir_p cache_dir
  FileUtils.cp File.join(Solargraph::YARDOC_PATH, '2.0.0.tar.gz'), cache_dir
  tar_extract = Gem::Package::TarReader.new(Zlib::GzipReader.open(File.join(cache_dir, '2.0.0.tar.gz')))
  tar_extract.rewind
  tar_extract.each do |entry|
    if entry.directory?
      FileUtils.mkdir_p File.join(cache_dir, entry.full_name)
    else
      FileUtils.mkdir_p File.join(cache_dir, File.dirname(entry.full_name))
      File.open(File.join(cache_dir, entry.full_name), 'wb') do |f|
        f << entry.read
      end
    end
  end
  tar_extract.close
  #FileUtils.rm File.join(cache_dir, '2.0.0.tar.gz')
end
