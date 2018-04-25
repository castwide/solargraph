require 'thor'
require 'json'
require 'fileutils'
require 'rubygems/package'
require 'zlib'
require 'eventmachine'

module Solargraph
  class Shell < Thor
    include Solargraph::ServerMethods

    map %w[--version -v] => :version

    desc "--version, -v", "Print the version"
    def version
      puts Solargraph::VERSION
    end

    desc 'server', 'Start a Solargraph server'
    option :port, type: :numeric, aliases: :p, desc: 'The server port', default: 7657
    option :views, type: :string, aliases: :v, desc: 'The view template directory', default: nil
    option :files, type: :string, aliases: :f, desc: 'The public files directory', default: nil
    def server
      port = options[:port]
      port = available_port if port.zero?
      Solargraph::Server.set :port, port
      Solargraph::Server.set :views, options[:views] unless options[:views].nil?
      Solargraph::Server.set :public_folder, options[:files] unless options[:files].nil?
      my_pid = nil
      Solargraph::Server.run! do
        # This line should not be necessary with WEBrick
        #STDERR.puts "Solargraph server pid=#{Process.pid} port=#{port}"
        my_pid = Process.pid
        Signal.trap("INT") do
          Solargraph::Server.stop!
        end
        Signal.trap("TERM") do
          Solargraph::Server.stop!
        end
      end
    end

    desc 'socket', 'Run a Solargraph socket server'
    option :host, type: :string, aliases: :h, desc: 'The server host', default: '127.0.0.1'
    option :port, type: :numeric, aliases: :p, desc: 'The server port', default: 7658
    def socket
      port = options[:port]
      port = available_port if port.zero?
      EventMachine.run do
        Signal.trap("INT") do
          EventMachine.stop
        end
        Signal.trap("TERM") do
          EventMachine.stop
        end
        EventMachine.start_server options[:host], port, Solargraph::LanguageServer::Transport::Socket
        # Emitted for the benefit of clients that start the process on port 0
        STDERR.puts "Solargraph is listening PORT=#{port} PID=#{Process.pid}"
      end
    end

    desc 'suggest', 'Get code suggestions for the provided input'
    long_desc <<-LONGDESC
      Analyze a Ruby file and output a list of code suggestions in JSON format.
    LONGDESC
    option :line, type: :numeric, aliases: :l, desc: 'Zero-based line number', required: true
    option :column, type: :numeric, aliases: [:c, :col], desc: 'Zero-based column number', required: true
    option :filename, type: :string, aliases: :f, desc: 'File name', required: false
    def suggest(*filenames)
      STDERR.puts "WARNING: The `solargraph suggest` command is a candidate for deprecation. It will either change drastically or not exist in a future version."
      # HACK: The ARGV array needs to be manipulated for ARGF.read to work
      ARGV.clear
      ARGV.concat filenames
      text = ARGF.read
      filename = options[:filename] || filenames[0]
      begin
        code_map = CodeMap.new(code: text, filename: filename)
        offset = code_map.get_offset(options[:line], options[:column])
        sugg = code_map.suggest_at(offset, filtered: true)
        result = { "status" => "ok", "suggestions" => sugg }.to_json
        STDOUT.puts result
      rescue Exception => e
        STDERR.puts e
        STDERR.puts e.backtrace.join("\n")
        result = { "status" => "err", "message" => e.message + "\n" + e.backtrace.join("\n") }.to_json
        STDOUT.puts result
      end
    end

    desc 'config [DIRECTORY]', 'Create or overwrite a default configuration file'
    option :extensions, type: :boolean, aliases: :e, desc: 'Add installed extensions', default: true
    def config(directory = '.')
      matches = []
      if options[:extensions]
        Gem::Specification.each do |g|
          puts g.name
          if g.name.match(/^solargraph\-[A-Za-z0-9_\-]*?\-ext/)
            require g.name
            matches.push g.name
          end
        end
      end
      conf = Solargraph::Workspace::Config.new.raw_data
      unless matches.empty?
        matches.each do |m|
          conf['extensions'].push m
        end
      end
      File.open(File.join(directory, '.solargraph.yml'), 'w') do |file|
        file.puts conf.to_yaml
      end
      STDOUT.puts "Configuration file initialized."
    end

    desc 'download-core [VERSION]', 'Download core documentation'
    def download_core version = nil
      ver = version || Solargraph::YardMap::CoreDocs.best_download
      puts "Downloading docs for #{ver}..."
      Solargraph::YardMap::CoreDocs.download ver
    end

    desc 'list-cores', 'List the local documentation versions'
    def list_cores
      puts Solargraph::YardMap::CoreDocs.versions.join("\n")
    end

    desc 'available-cores', 'List available documentation versions'
    def available_cores
      puts Solargraph::YardMap::CoreDocs.available.join("\n")
    end

    desc 'clear-cores', 'Clear the cached core documentation'
    def clear_cores
      Solargraph::YardMap::CoreDocs.clear
    end

    desc 'reporters', 'Get a list of diagnostics reporters'
    def reporters
      puts Solargraph::Diagnostics::REPORTERS.keys.sort
    end
  end
end
