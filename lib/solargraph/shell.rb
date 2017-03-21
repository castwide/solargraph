require 'thor'
require 'json'
require 'fileutils'
require 'rubygems/package'
require 'zlib'

module Solargraph
  class Shell < Thor
    desc 'prepare', 'Cache YARD files for the current environment'
    option :force, type: :boolean, aliases: :f, desc: 'Force download of YARDOC files if they already exist'
    option :host, type: :string, aliases: :h, desc: 'The host that provides YARDOC files for download', default: 'yardoc.solargraph.org'
    def prepare
      cache_dir = File.join(Dir.home, '.solargraph', 'cache')
      version_dir = File.join(cache_dir, '2.0.0')
      unless File.exist?(version_dir) or options[:force]
        FileUtils.mkdir_p cache_dir
        require 'net/http'
        puts 'Downloading 2.0.0...'
        Net::HTTP.start(options[:host]) do |http|
            resp = http.get("/2.0.0.tar.gz")
            open(File.join(cache_dir, '2.0.0.tar.gz'), "wb") do |file|
                file.write(resp.body)
            end
            puts 'Uncompressing archives...'
            FileUtils.rm_rf version_dir if File.exist?(version_dir)
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
            FileUtils.rm File.join(cache_dir, '2.0.0.tar.gz')
            puts 'Done.'
        end
      end
    end
    
    desc 'server', 'Start a Solargraph server'
    option :port, type: :numeric, aliases: :p, desc: 'The server port', default: 7657
    def server
      Solargraph::Server.set :port, options[:port]
      Solargraph::Server.run!
    end
    
    desc 'serialize DIRECTORY', 'Cache an API map of DIRECTORY'
    def serialize directory
      api_map = ApiMap.new directory
      files = Dir[File.join directory, 'lib', '**', '*.rb'] + Dir[File.join directory, 'app', '**', '*.rb']
      files.each { |f|
        api_map.append_file f
      }
      File.open(File.join(directory, '.solargraph.ser'), 'wb') { |file|
        file << Marshal.dump(api_map)
      }
    end

    desc 'suggest', 'Get code suggestions for the provided input'
    long_desc <<-LONGDESC
      Analyze a Ruby file and output a list of code suggestions in JSON format.
    LONGDESC
    option :line, type: :numeric, aliases: :l, desc: 'Zero-based line number', required: true
    option :column, type: :numeric, aliases: [:c, :col], desc: 'Zero-based column number', required: true
    option :filename, type: :string, aliases: :f, desc: 'File name', required: false
    def suggest(*filenames)
      # HACK: The ARGV array needs to be manipulated for ARGF.read to work
      ARGV.clear
      ARGV.concat filenames
      text = ARGF.read
      filename = options[:filename] || filenames[0]
      begin
        code_map = CodeMap.new(code: text, filename: filename)
        offset = code_map.get_offset(options[:line], options[:column])
        sugg = code_map.suggest_at(offset, with_snippets: true, filtered: true)
        result = { "status" => "ok", "suggestions" => sugg }.to_json
        STDOUT.puts result
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        #result = { "status" => "err", "message" => e.message }.to_json
        result = { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
        STDOUT.puts result
      end
    end
  end
end
